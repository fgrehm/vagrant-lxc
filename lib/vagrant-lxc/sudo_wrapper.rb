module Vagrant
  module LXC
    class SudoWrapper
      # Include this so we can use `Subprocess` more easily.
      include Vagrant::Util::Retryable

      def initialize(wrapper_path = nil)
        @wrapper_path = wrapper_path
        @logger       = Log4r::Logger.new("vagrant::lxc::shell")
      end

      def run(*command)
        command.unshift @wrapper_path if @wrapper_path
        execute *(['sudo'] + command)
      end

      def su_c(command)
        su_command = if @wrapper_path
            "#{@wrapper_path} \"#{command}\""
          else
            "su root -c \"#{command}\""
          end
        @logger.debug "Running 'sudo #{su_command}'"
        system "sudo #{su_command}"
      end

      private

      # TODO: Review code below this line, it was pretty much a copy and
      #       paste from VirtualBox base driver and has no tests
      def execute(*command, &block)
        # Get the options hash if it exists
        opts = {}
        opts = command.pop if command.last.is_a?(Hash)

        tries = 0
        tries = 3 if opts[:retryable]

        sleep = opts.fetch(:sleep, 1)

        # Variable to store our execution result
        r = nil

        retryable(:on => LXC::Errors::ExecuteError, :tries => tries, :sleep => sleep) do
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
        if opts[:show_stderr]
          {
            :stdout => r.stdout.gsub("\r\n", "\n"),
            :stderr => r.stderr.gsub("\r\n", "\n")
          }
        else
          r.stdout.gsub("\r\n", "\n")
        end
      end

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
