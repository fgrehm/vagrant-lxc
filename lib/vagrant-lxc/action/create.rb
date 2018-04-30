module Vagrant
  module LXC
    module Action
      class Create
        def initialize(app, env)
          @app = app
        end

        def call(env)
          config = env[:machine].provider_config
          container_name = config.container_name

          case container_name
            when :machine
              container_name = env[:machine].name.to_s
            when String
              # Nothing to do here, move along...
            else
              container_name = generate_container_name(env)
          end

          backingstore = config.backingstore
          if backingstore.nil?
            backingstore = config.privileged ? "best" : "dir"
          end
          driver = env[:machine].provider.driver
          template_options = env[:lxc_template_opts]
          if ! driver.supports_new_config_format
            template_options['--oldconfig'] = ''
          end
          driver.create(
            container_name,
            backingstore,
            config.backingstore_options,
            env[:lxc_template_src],
            env[:lxc_template_config],
            template_options
          )
          driver.update_config_keys

          env[:machine].id = container_name

          @app.call env
        end

        def generate_container_name(env)
          container_name = "#{env[:root_path].basename}_#{env[:machine].name}"
          container_name.gsub!(/[^-a-z0-9_]/i, "")

          # milliseconds + random number suffix to allow for simultaneous
          # `vagrant up` of the same box in different dirs
          container_name << "_#{(Time.now.to_f * 1000.0).to_i}_#{rand(100000)}"

          # Trim container name to 64 chars, keeping "randomness"
          trim_point = container_name.size > 64 ? -64 : -(container_name.size)
          container_name[trim_point..-1]
        end
      end
    end
  end
end
