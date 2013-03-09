# FIXME: Ruby 1.8 users dont have SecureRandom
require 'securerandom'

require "vendored_vagrant"
require "vagrant/util/retryable"
require "vagrant/util/subprocess"

require "vagrant-lxc/errors"

module Vagrant
  module LXC
    # REFACTOR: Encapsulate lxc commands with name
    class Container
      # Include this so we can use `Subprocess` more easily.
      include Vagrant::Util::Retryable

      # This is raised if the container can't be found when initializing it with
      # an UUID.
      class NotFound < StandardError; end

      CONTAINERS_PATH = '/var/lib/lxc'

      attr_reader :name

      def initialize(name)
        @name   = name
        @logger = Log4r::Logger.new("vagrant::provider::lxc::container")
      end

      def validate!
        raise NotFound if @name && ! lxc(:ls).split("\n").include?(@name)
      end

      def create(metadata = {})
        # FIXME: Ruby 1.8 users dont have SecureRandom
        @logger.debug('Creating container using lxc-create...')

        @name      = SecureRandom.hex(6)
        public_key = Vagrant.source_root.join('keys', 'vagrant.pub').expand_path.to_s

        meta_opts  = metadata.fetch('template-opts', {}).to_a.flatten

        # TODO: Handle errors
        lxc :create,
            # lxc-create options
            '--template', metadata['template-name'],
            '--name', @name,
            '--',
              # Template options
              '--auth-key',   public_key,
              '--cache', metadata['rootfs-cache-path'],
              *meta_opts

        @name
      end

      def rootfs_path
        Pathname.new("#{CONTAINERS_PATH}/#{@name}/rootfs")
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
        # @logger.info('Starting container...')
        opts = config.start_opts.map { |opt| ["-s", opt] }.flatten
        opts += ['-o', ENV['LXC_START_LOG_FILE'], '-l', 'DEBUG'] if ENV['LXC_START_LOG_FILE']
        lxc :start, '-d', '--name', @name, *opts
        wait_until :running
      end

      def halt
        lxc :shutdown, '--name', @name
        wait_until :stopped
        # TODO: issue an lxc-stop if a timeout gets reached
      end

      def destroy
        lxc :destroy, '--name', @name
      end

      # REFACTOR:
      #   transition_to :state do
      #     ... code ...
      def wait_until(state)
        lxc :wait, '--name', @name, '--state', state.to_s.upcase
      end

      def lxc(command, *args)
        execute('sudo', "lxc-#{command}", *args)
      end

      def update!(state)
        File.open(state_file_path, 'w') { |f| f.print state }
      end

      def state
        if @name && lxc(:info, '--name', @name) =~ /^state:[^A-Z]+([A-Z]+)$/
          $1.downcase.to_sym
        elsif @name
          :unknown
        end
      end

      def dhcp_ip(server_ip)
        ip = ''
        # Right after creation lxc reports the container as running
        # before DNS is returning the right IP, so have to wait for a while
        retryable(:on => LXC::Errors::ExecuteError, :tries => 10, :sleep => 3) do
          # By default LXC supplies a dns server on 10.0.3.1 so we request the IP
          # of our target from there.
          # Tks to: https://github.com/neerolyte/vagueant/blob/master/bin/vagueant#L340
          r = (raw 'dig', @name, "@#{server_ip}", '+short')

          # If the command was a failure then raise an exception that is nicely
          # handled by Vagrant.
          if r.exit_code != 0
            if @interrupted
              @logger.info("Exit code != 0, but interrupted. Ignoring.")
            else
              raise LXC::Errors::ExecuteError, :command => ['dig', @name, "@#{server_ip}", '+short'].inspect
            end
          end

          ip = r.stdout.gsub("\r\n", "\n").strip
          if ip.empty?
            raise LXC::Errors::ExecuteError, 'Unable to identify container ip'
          end

          # Sometimes lxc reports the container as running before DNS is returning
          # the right IP, so have to try a couple of times sometimes.
          # Tks to https://github.com/neerolyte/vagueant/blob/master/bin/vagueant#L318-L330
          r = raw 'ping', '-c', '1', ip
          if r.exit_code != 0
            raise LXC::Errors::ExecuteError, 'Unable to reach container'
          end
        end
        ip
      end

      # TODO: Review code below this line, it was pretty much a copy and paste from VirtualBox base driver
      def execute(*command, &block)
        # Get the options hash if it exists
        opts = {}
        opts = command.pop if command.last.is_a?(Hash)

        tries = 0
        tries = 3 if opts[:retryable]

        # Variable to store our execution result
        r = nil

        retryable(:on => LXC::Errors::ExecuteError, :tries => tries, :sleep => 1) do
          # Execute the command
          r = raw(*command, &block)

          # If the command was a failure, then raise an exception that is
          # nicely handled by Vagrant.
          if r.exit_code != 0
            if @interrupted
              @logger.info("Exit code != 0, but interrupted. Ignoring.")
            else
              raise LXC::Errors::ExecuteError, :command => command.inspect
            end
          end
        end

        # Return the output, making sure to replace any Windows-style
        # newlines with Unix-style.
        r.stdout.gsub("\r\n", "\n")
      end

      # Executes a command and returns the raw result object.
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
