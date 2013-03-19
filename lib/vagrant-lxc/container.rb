require 'securerandom'

require "vagrant-lxc/errors"
require "vagrant-lxc/container/cli"

require "vagrant/util/retryable"
require "vagrant/util/subprocess"

module Vagrant
  module LXC
    class Container
      # Root folder where containers are stored
      CONTAINERS_PATH = '/var/lib/lxc'

      # Default LXC configs
      LXC_DEFAULTS_PATH = '/etc/default/lxc'

      # Include this so we can use `Subprocess` more easily.
      include Vagrant::Util::Retryable

      # This is raised if the container can't be found when initializing it with
      # a name.
      class NotFound < StandardError; end

      attr_reader :name

      def initialize(name, cli = CLI.new(name))
        @name   = name
        @cli    = cli
        @logger = Log4r::Logger.new("vagrant::provider::lxc::container")
      end

      def validate!
        raise NotFound if @name && ! @cli.list.include?(@name)
      end

      def base_path
        Pathname.new("#{CONTAINERS_PATH}/#{@name}")
      end

      def rootfs_path
        Pathname.new("#{base_path}/rootfs")
      end

      def create(metadata = {})
        @logger.debug('Creating container using lxc-create...')

        @name      = SecureRandom.hex(6)
        public_key = Vagrant.source_root.join('keys', 'vagrant.pub').expand_path.to_s
        meta_opts  = metadata.fetch('template-opts', {}).merge(
          '--auth-key' => public_key,
          '--cache'    => metadata.fetch('rootfs-cache-path')
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
            raise LXC::Errors::ExecuteError, :command => ['arp', '-n'].inspect
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
