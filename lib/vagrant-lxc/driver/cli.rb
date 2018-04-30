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
          return @version if @version
          @version = run(:create, '--version')
          if @version =~ /(lxc version:\s+|)(.+)\s*$/
            @version = $2.downcase
          else
            # TODO: Raise an user friendly error
            raise 'Unable to parse lxc version!'
          end
        end

        def config(param)
          run(:config, param).gsub("\n", '')
        end

        def update_config(path)
          run('update-config', '-c', path)
        end

        def state
          if @name && run(:info, '--name', @name, retryable: true) =~ /^state:[^A-Z]+([A-Z]+)$/i
            $1.downcase.to_sym
          elsif @name
            :unknown
          end
        end

        def create(template, backingstore, backingstore_options, config_file, template_opts = {})
          if config_file
            config_opts = ['-f', config_file]
          end

          extra = template_opts.to_a.flatten.reject { |elem| elem.empty? }
          extra.unshift '--' unless extra.empty?

          run :create,
              '-B', backingstore,
              '--template', template,
              '--name',     @name,
              *(backingstore_options.to_a.flatten),
              *(config_opts),
              *extra
        rescue Errors::ExecuteError => e
          if e.stderr =~ /already exists/i
            raise Errors::ContainerAlreadyExists, name: @name
          else
            raise
          end
        end

        def destroy
          run :destroy, '--name', @name
        end

        def start(options = [])
          run :start, '-d', '--name', @name, *Array(options)
        end

        ## lxc-stop will exit 2 if machine was already stopped
        # Man Page:
        # 2      The specified container exists but was not running.
        def stop
          attach '/sbin/halt' if supports_attach?
          begin
            run :stop, '--name', @name
          rescue LXC::Errors::ExecuteError => e
            if e.exitcode == 2
               @logger.debug "Machine already stopped, lxc-stop returned 2"
            else
		raise e
            end
          end
        end

        def attach(*cmd)
          cmd = ['--'] + cmd

          if cmd.last.is_a?(Hash)
            opts       = cmd.pop
            namespaces = Array(opts[:namespaces]).map(&:upcase).join('|')

            # HACK: The wrapper script should be able to handle this
            if @sudo_wrapper.wrapper_path
              namespaces = "'#{namespaces}'"
            end

            if namespaces
              extra = ['--namespaces', namespaces]
            end
          end

          run :attach, '--name', @name, *((extra || []) + cmd)
        end

        def info(*cmd)
          run(:info, '--name', @name, *cmd)
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
            # TODO: Raise an user friendly message
            raise TargetStateNotReached.new target_state, last_state
          end
        end

        def supports_attach?
          unless defined?(@supports_attach)
            begin
              @supports_attach = true
              run(:attach, '--name', @name, '--', '/bin/true')
            rescue LXC::Errors::ExecuteError
              @supports_attach = false
            end
          end

          return @supports_attach
        end

        private

        def run(command, *args)
          @sudo_wrapper.run("lxc-#{command}", *args)
        end
      end
    end
  end
end
