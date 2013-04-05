require "vagrant/util/retryable"
require "vagrant/util/subprocess"

require "vagrant-lxc/errors"
require "vagrant-lxc/driver/cli"

module Vagrant
  module LXC
    class Driver
      # Include this so we can use `Subprocess` more easily.
      include Vagrant::Util::Retryable

      # This is raised if the container can't be found when initializing it with
      # a name.
      class ContainerNotFound < StandardError; end

      attr_reader :name

      def initialize(name, cli = CLI.new(name))
        @name   = name
        @cli    = cli
        @logger = Log4r::Logger.new("vagrant::provider::lxc::driver")
      end

      def validate!
        raise ContainerNotFound if @name && ! @cli.list.include?(@name)
      end

      def base_path
        Pathname.new("#{CONTAINERS_PATH}/#{@name}")
      end

      def rootfs_path
        Pathname.new(base_path.join('config').read.match(/^lxc\.rootfs\s+=\s+(.+)$/)[1])
      end

      def create(name, template_path, template_options = {})
        @cli.name = @name = name

        import_template(template_path) do |template_name|
          @logger.debug "Creating container..."
          @cli.create template_name, template_options
        end
      end

      def share_folders(folders, config)
        folders.each do |folder|
          guestpath = rootfs_path.join(folder[:guestpath].gsub(/^\//, ''))
          unless guestpath.directory?
            begin
              system "sudo mkdir -p #{guestpath.to_s}"
            rescue Errno::EACCES
              raise Vagrant::Errors::SharedFolderCreateFailed,
                :path => guestpath.to_s
            end
          end

          config.start_opts << "lxc.mount.entry=#{folder[:hostpath]} #{guestpath} none bind 0 0"
        end
      end

      def start(config)
        @logger.info('Starting container...')

        opts = config.start_opts.dup
        if ENV['LXC_START_LOG_FILE']
          extra = ['-o', ENV['LXC_START_LOG_FILE'], '-l', 'DEBUG']
        end

        @cli.transition_to(:running) { |c| c.start(opts, (extra || nil)) }
      end

      def halt
        @logger.info('Shutting down container...')

        # TODO: issue an lxc-stop if a timeout gets reached
        @cli.transition_to(:stopped) { |c| c.shutdown }
      end

      def destroy
        @cli.destroy
      end

      # TODO: This needs to be reviewed and specs needs to be written
      def compress_rootfs
        # TODO: Our template should not depend on container's arch
        arch           = base_path.join('config').read.match(/^lxc\.arch\s+=\s+(.+)$/)[1]
        rootfs_dirname = File.dirname rootfs_path
        basename       = rootfs_path.to_s.gsub(/^#{Regexp.escape rootfs_dirname}\//, '')
        # TODO: Pass in tmpdir so we can clean up from outside
        target_path    = "#{Dir.mktmpdir}/rootfs.tar.gz"

        Dir.chdir base_path do
          @logger.info "Compressing '#{rootfs_path}' rootfs to #{target_path}"
          system "sudo rm -f rootfs.tar.gz && sudo bsdtar -s /#{basename}/rootfs-#{arch}/ --numeric-owner -czf #{target_path} #{basename}/* 2>/dev/null"

          @logger.info "Changing rootfs tarbal owner"
          system "sudo chown #{ENV['USER']}:#{ENV['USER']} #{target_path}"
        end

        target_path
      end

      def state
        if @name
          @cli.state
        end
      end

      def assigned_ip
        ip = ''
        retryable(:on => LXC::Errors::ExecuteError, :tries => 10, :sleep => 3) do
          unless ip = get_container_ip_from_ip_addr
            # retry
            raise LXC::Errors::ExecuteError, :command => "lxc-attach"
          end
        end
        ip
      end

      # From: https://github.com/lxc/lxc/blob/staging/src/python-lxc/lxc/__init__.py#L371-L385
      def get_container_ip_from_ip_addr
        output = @cli.attach '/sbin/ip', '-4', 'addr', 'show', 'scope', 'global', 'eth0', namespaces: 'network'
        if output =~ /^\s+inet ([0-9.]+)\/[0-9]+\s+/
          return $1.to_s
        end
      end

      protected

      LXC_TEMPLATES_PATH = Pathname.new("/usr/share/lxc/templates")

      # Root folder where container configs are stored
      CONTAINERS_PATH = '/var/lib/lxc'

      def base_path
        Pathname.new("#{CONTAINERS_PATH}/#{@name}")
      end

      def rootfs_path
        Pathname.new(base_path.join('config').read.match(/^lxc\.rootfs\s+=\s+(.+)$/)[1])
      end

      def import_template(path)
        template_name     = "vagrant-tmp-#{@name}"
        tmp_template_path = LXC_TEMPLATES_PATH.join("lxc-#{template_name}").to_s

        @logger.debug 'Copying LXC template into place'
        system(%Q[sudo su root -c "cp #{path} #{tmp_template_path}"])

        yield template_name
      ensure
        system(%Q[sudo su root -c "rm #{tmp_template_path}"])
      end
    end
  end
end
