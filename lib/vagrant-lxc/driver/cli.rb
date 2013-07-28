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

        def initialize(sudo_wrapper, name = nil)
          @sudo_wrapper = sudo_wrapper
          @name         = name
          @logger       = Log4r::Logger.new("vagrant::provider::lxc::container::cli")
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
          if @name && run(:info, '--name', @name, retryable: true) =~ /^state:[^A-Z]+([A-Z]+)$/
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
          options = overrides.map { |key, value| ["-s", "lxc.#{key}='#{value}'"] }.flatten
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
          @sudo_wrapper.run("lxc-#{command}", *args)
        end
      end
    end
  end
end
