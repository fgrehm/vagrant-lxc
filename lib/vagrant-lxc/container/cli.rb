require "vagrant/util/retryable"
require "vagrant/util/subprocess"

require "vagrant-lxc/errors"

module Vagrant
  module LXC
    class Container
      class CLI
        attr_accessor :name

        class TransitionBlockNotProvided < RuntimeError; end

        # Include this so we can use `Subprocess` more easily.
        include Vagrant::Util::Retryable

        def initialize(name = nil)
          @name   = name
          @logger = Log4r::Logger.new("vagrant::provider::lxc::container::cli")
        end

        def list
          run(:ls).split(/\s+/).uniq
        end

        def state
          if @name && run(:info, '--name', @name) =~ /^state:[^A-Z]+([A-Z]+)$/
            $1.downcase.to_sym
          elsif @name
            :unknown
          end
        end

        def create(template, template_opts = {})
          extra = template_opts.to_a.flatten
          extra.unshift '--' unless extra.empty?

          run :create,
              # lxc-create options
              '--template', template,
              '--name',     @name,
              *extra
        end

        def destroy
          run :destroy, '--name', @name
        end

        def start(configs = [])
          configs = configs.map { |conf| ["-s", conf] }.flatten
          run :start, '-d', '--name', @name, *configs
        end

        def shutdown
          run :shutdown, '--name', @name
        end

        def transition_to(state, &block)
          raise TransitionBlockNotProvided unless block_given?

          yield self

          run :wait, '--name', @name, '--state', state.to_s.upcase
        end

        private

        def run(command, *args)
          execute('sudo', "lxc-#{command}", *args)
        end

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
          r.stdout.gsub("\r\n", "\n")
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
end
