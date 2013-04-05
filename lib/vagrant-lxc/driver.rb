require 'securerandom'

require "vagrant/util/retryable"
require "vagrant/util/subprocess"

require "vagrant-lxc/errors"
require "vagrant-lxc/driver/cli"

module Vagrant
  module LXC
    class Driver
      # Root folder where containers are stored
      CONTAINERS_PATH = '/var/lib/lxc'

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

      def create(base_name, metadata = {})
        @logger.debug('Creating container using lxc-create...')

        @name      = "#{base_name}-#{SecureRandom.hex(6)}"
        public_key = Vagrant.source_root.join('keys', 'vagrant.pub').expand_path.to_s
        meta_opts  = metadata.fetch('template-opts', {}).merge(
          '--auth-key' => public_key,
          '--tarball'  => metadata.fetch('rootfs-tarball').to_s
        )

        @cli.name = @name
        @cli.create(metadata.fetch('template-name'), meta_opts)

        @name
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
          unless ip = get_container_ip_from_ifconfig
            # retry
            raise LXC::Errors::ExecuteError, :command => "lxc-attach"
          end
        end
        ip
      end

      def get_container_ip_from_ifconfig
        output = @cli.attach '/sbin/ifconfig', '-v', 'eth0', namespaces: 'network'
        if output =~ /\s+inet addr:([0-9.]+)\s+/
          return $1.to_s
        end
      end
    end
  end
end
