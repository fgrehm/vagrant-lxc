# FIXME: Ruby 1.8 users dont have SecureRandom
require 'securerandom'

require 'vagrant/util/retryable'
require 'vagrant/util/subprocess'

require "vagrant-lxc/errors"

module Vagrant
  module LXC
    class Container
      # Include this so we can use `Subprocess` more easily.
      include Vagrant::Util::Retryable

      CONTAINER_STATE_FILE_PATH = '/tmp/vagrant-lxc-container-state-%<id>s'

      def initialize(machine)
        @machine = machine
        @logger  = Log4r::Logger.new("vagrant::provider::lxc::container")
      end

      def create
        # FIXME: Ruby 1.8 users dont have SecureRandom
        machine_id  = SecureRandom.hex(6)
        log, status = lxc(:create, {'--template' => 'ubuntu-cloud', '--name' => machine_id}, {'-S' => '/home/vagrant/.ssh/id_rsa.pub'})
        machine_id
      end

      def start
        puts 'TODO: Start container'
        update!(:running)
      end

      def halt
        update!(:poweroff)
      end

      def destroy
        puts "TODO: Destroy container"
        File.delete(state_file_path) if state_file_path
      end

      def state
        # TODO: Grab the real machine state here
        read_state_from_file
      end

      private

      def lxc(command, params, extra = {})
        params = params.map { |opt, val| "#{opt}='#{val}'" }
        params << '--' if extra.any?
        # Handles extra options passed to templates when using lxc-create
        params << extra.map { |opt, val| "#{opt} #{val}" }
        execute('sudo', "lxc-#{command}", *params.flatten)
      end

      def update!(state)
        File.open(state_file_path, 'w') { |f| f.print state }
      end

      def read_state_from_file
        if File.exists?(state_file_path)
          File.read(state_file_path).to_sym
        elsif @machine.id
          :unknown
        end
      end

      def state_file_path
        CONTAINER_STATE_FILE_PATH % {id: @machine.id}
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
