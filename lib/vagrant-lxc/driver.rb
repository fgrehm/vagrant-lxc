require "vagrant/util/retryable"
require "vagrant/util/subprocess"

require "vagrant-lxc/errors"
require "vagrant-lxc/driver/cli"

require "etc"

module Vagrant
  module LXC
    class Driver
      # This is raised if the container can't be found when initializing it with
      # a name.
      class ContainerNotFound < StandardError; end

      # Root folder where container configs are stored
      CONTAINERS_PATH = '/var/lib/lxc'

      attr_reader :container_name,
                  :customizations

      def initialize(container_name, sudo_wrapper, cli = nil)
        @container_name = container_name
        @sudo_wrapper   = sudo_wrapper
        @cli            = cli || CLI.new(sudo_wrapper, container_name)
        @logger         = Log4r::Logger.new("vagrant::provider::lxc::driver")
        @customizations = []
      end

      def validate!
        raise ContainerNotFound if @container_name && ! @cli.list.include?(@container_name)
      end

      def base_path
        Pathname.new("#{CONTAINERS_PATH}/#{@container_name}")
      end

      def rootfs_path
        Pathname.new(base_path.join('config').read.match(/^lxc\.rootfs\s+=\s+(.+)$/)[1])
      end

      def mac_address
        @mac_address ||= base_path.join('config').read.match(/^lxc\.network\.hwaddr\s+=\s+(.+)$/)[1]
      end

      def create(name, template_path, config_file, template_options = {})
        @cli.name = @container_name = name

        import_template(template_path) do |template_name|
          @logger.debug "Creating container..."
          @cli.create template_name, config_file, template_options
        end
      end

      def share_folders(folders)
        folders.each do |folder|
          guestpath = rootfs_path.join(folder[:guestpath].gsub(/^\//, ''))
          unless guestpath.directory?
            begin
              @logger.debug("Guest path doesn't exist, creating: #{guestpath}")
              @sudo_wrapper.run('mkdir', '-p', guestpath.to_s)
            rescue Errno::EACCES
              raise Vagrant::Errors::SharedFolderCreateFailed, :path => guestpath.to_s
            end
          end

          @customizations << ['mount.entry', "#{folder[:hostpath]} #{guestpath} none bind 0 0"]
        end
      end

      def start(customizations)
        @logger.info('Starting container...')

        if ENV['LXC_START_LOG_FILE']
          extra = ['-o', ENV['LXC_START_LOG_FILE'], '-l', 'DEBUG']
        end

        prune_customizations
        write_customizations(customizations + @customizations)

        @cli.start(extra)
      end

      def forced_halt
        @logger.info('Shutting down container...')
        @cli.transition_to(:stopped) { |c| c.shutdown }
      rescue CLI::TargetStateNotReached
        @cli.transition_to(:stopped) { |c| c.stop }
      end

      def destroy
        @cli.destroy
      end

      def attach(*command)
        @cli.attach(*command)
      end

      def version
        @version ||= @cli.version
      end

      # TODO: This needs to be reviewed and specs needs to be written
      def compress_rootfs
        # TODO: Pass in tmpdir so we can clean up from outside
        target_path    = "#{Dir.mktmpdir}/rootfs.tar.gz"

        Dir.chdir base_path do
          @logger.info "Compressing '#{rootfs_path}' rootfs to #{target_path}"
          @sudo_wrapper.run('rm', '-f', 'rootfs.tar.gz')
          @sudo_wrapper.run('tar', '--numeric-owner', '-czf', target_path, 'rootfs')

          @logger.info "Changing rootfs tarball owner"
          user_details = Etc.getpwnam(Etc.getlogin)
          @sudo_wrapper.run('chown', "#{user_details.uid}:#{user_details.gid}", target_path)
        end

        target_path
      end

      def state
        if @container_name
          @cli.state
        end
      end

      def prune_customizations
        # Use sed to just strip out the block of code which was inserted by Vagrant
        @logger.debug 'Prunning vagrant-lxc customizations'
        @sudo_wrapper.su_c("sed -e '/^# VAGRANT-BEGIN/,/^# VAGRANT-END/ d' -ibak #{base_path.join('config')}")
      end

      protected

      def write_customizations(customizations)
        customizations = customizations.map do |key, value|
          "lxc.#{key}=#{value}"
        end
        customizations.unshift '# VAGRANT-BEGIN'
        customizations      << '# VAGRANT-END'

        config_file = base_path.join('config').to_s
        customizations.each do |line|
          @sudo_wrapper.su_c("echo '#{line}' >> #{config_file}")
        end
      end

      def import_template(path)
        template_name     = "vagrant-tmp-#{@container_name}"
        tmp_template_path = templates_path.join("lxc-#{template_name}").to_s

        @logger.info 'Copying LXC template into place'
        @sudo_wrapper.run('cp', path, tmp_template_path)
        @sudo_wrapper.run('chmod', '+x', tmp_template_path)

        yield template_name
      ensure
        @logger.info 'Removing LXC template'
        @sudo_wrapper.run('rm', tmp_template_path)
      end

      TEMPLATES_PATH_LOOKUP = %w(
        /usr/share/lxc/templates
        /usr/lib/lxc/templates
        /usr/lib64/lxc/templates
        /usr/local/lib/lxc/templates
      )
      def templates_path
        return @templates_path if @templates_path

        path = TEMPLATES_PATH_LOOKUP.find { |candidate| File.directory?(candidate) }
        # TODO: Raise an user friendly error
        raise 'Unable to identify lxc templates path!' unless path

        @templates_path = Pathname(path)
      end
    end
  end
end
