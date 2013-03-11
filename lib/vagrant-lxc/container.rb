# FIXME: Ruby 1.8 users dont have SecureRandom
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
        # FIXME: Ruby 1.8 users dont have SecureRandom
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

          # http://blog.smartlogicsolutions.com/2009/06/04/mount-options-to-improve-ext4-file-system-performance/
          config.start_opts << "lxc.mount.entry=#{folder[:hostpath]} #{guestpath} none bind 0 0"
        end
      end

      def start(config)
        @logger.info('Starting container...')

        opts = config.start_opts.dup
        if ENV['LXC_START_LOG_FILE']
          opts.merge!('-o' => ENV['LXC_START_LOG_FILE'], '-l' => 'DEBUG')
        end

        @cli.transition_to(:running) { |c| c.start(opts) }
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
        unless File.read(base_path.join('config')) =~ /^lxc\.network\.hwaddr\s*=\s*([a-z0-9:]+)\s*$/
          raise 'Unknown Container MAC Address'
        end
        mac_addr = $1

        ip = ''
        retryable(:on => LXC::Errors::ExecuteError, :tries => 10, :sleep => 3) do
          # See: http://programminglinuxblog.blogspot.com.br/2007/11/detecting-ip-address-from-mac-address.html
          unless ip = get_container_ip_from_arp(mac_addr)
            # Ping subnet and try to get ip again
            ping_subnet! and raise LXC::Errors::ExecuteError
          end
        end
        ip
      end

      def get_container_ip_from_arp(mac_addr)
        r = raw 'arp', '-n'

        # If the command was a failure then raise an exception that is nicely
        # handled by Vagrant.
        if r.exit_code != 0
          if @interrupted
            @logger.info("Exit code != 0, but interrupted. Ignoring.")
          else
            raise LXC::Errors::ExecuteError, :command => ['arp', '-n'].inspect
          end
        end

        if r.stdout.gsub("\r\n", "\n").strip =~ /^([0-9.]+).+#{Regexp.escape mac_addr}/
          return $1.to_s
        end
      end

      # FIXME: Should output an error friendly message in case fping is not installed
      def ping_subnet!
        raise LXC::Errors::UnknownLxcConfigFile unless File.exists?(LXC_DEFAULTS_PATH)

        raise LXC::Errors::UnknownLxcBridgeAddress unless
          File.read(LXC_DEFAULTS_PATH) =~ /^LXC_ADDR\="?([0-9.]+)"?.*$/

        raw 'fping', '-c', '1', '-g', '-q', "#{$1}/24"
      end

      # TODO: Review code below this line, it was pretty much a copy and paste from VirtualBox base driver
      def raw(*command, &block)
        int_callback = lambda do
          @interrupted = true
          @logger.info("Interrupted.")
        end

        # Append in the options for subprocess
        command << { :notify => [:stdout, :stderr] }

        Vagrant::Util::Busy.busy(int_callback) do
          Vagrant::Util::Subprocess.execute(*command, &block)
        end
      end
    end
  end
end
