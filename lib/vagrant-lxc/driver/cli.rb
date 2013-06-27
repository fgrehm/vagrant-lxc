require "vagrant/util/retryable"
require "vagrant/util/subprocess"

require "vagrant-lxc/errors"

module Vagrant
  module LXC
    class Driver
      class CLI
        attr_accessor :name

        class TransitionBlockNotProvided < RuntimeError; end
        class TargetStateNotReached < RuntimeError
          def initialize(target_state, state)
            msg = "Target state '#{target_state}' not reached, currently on '#{state}'"
            super(msg)
          end
        end

        # Include this so we can use `Subprocess` more easily.
        include Vagrant::Util::Retryable

        def initialize(name = nil)
          @name   = name
          @logger = Log4r::Logger.new("vagrant::provider::lxc::container::cli")
        end

        def list
          run(:ls).split(/\s+/).uniq
        end

        def version
          if run(:version) =~ /lxc version:\s+(.+)\s*$/
            $1.downcase
          else
            # TODO: Raise an user friendly error
            raise 'Unable to parse lxc version!'
          end
        end

        def state
          if @name && run(:info, '--name', @name) =~ /^state:[^A-Z]+([A-Z]+)$/
            $1.downcase.to_sym
          elsif @name
            :unknown
          end
        end

        def create(template, config_file, template_opts = {})
          if config_file
            config_opts = ['-f', config_file]
          end

          extra = template_opts.to_a.flatten
          extra.unshift '--' unless extra.empty?

          run :create,
              '--template', template,
              '--name',     @name,
              *(config_opts),
              *extra
        end

        def destroy
          run :destroy, '--name', @name
        end

        def start(overrides = [], extra_opts = [])
          options = overrides.map { |key, value| ["-s", "lxc.#{key}=#{value}"] }.flatten
          options += extra_opts if extra_opts
          run :start, '-d', '--name', @name, *options
        end

        def stop
          run :stop, '--name', @name
        end

        def shutdown
          run :shutdown, '--name', @name
        end

        def attach(*cmd)
          cmd = ['--'] + cmd

          if cmd.last.is_a?(Hash)
            opts       = cmd.pop
            namespaces = Array(opts[:namespaces]).map(&:upcase).join('|')
            extra      = ['--namespaces', namespaces] if namespaces
          end

          run :attach, '--name', @name, *((extra || []) + cmd)
        end

        def transition_to(target_state, tries = 30, timeout = 1, &block)
          raise TransitionBlockNotProvided unless block_given?

          yield self

          while (last_state = self.state) != target_state && tries > 0
            @logger.debug "Target state '#{target_state}' not reached, currently on '#{last_state}'"
            sleep timeout
            tries -= 1
          end

          unless last_state == target_state
            raise TargetStateNotReached.new target_state, last_state
          end
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
