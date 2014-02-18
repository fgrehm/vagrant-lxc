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
              container_name = "#{env[:root_path].basename}_#{env[:machine].name}"
              container_name.gsub!(/[^-a-z0-9_]/i, "")
              # milliseconds + random number suffix to allow for simultaneous
              # `vagrant up` of the same box in different dirs
              container_name << "_#{(Time.now.to_f * 1000.0).to_i}_#{rand(100000)}"
          end

          if config.existing_container_name
            env[:machine].provider.driver.clone(config.existing_container_name, container_name)
          else
            env[:machine].provider.driver.create(
              container_name,
              config.backingstore,
              config.backingstore_options,
              env[:lxc_template_src],
              env[:lxc_template_config],
              env[:lxc_template_opts])
          end

          env[:machine].id = container_name

          @app.call env
        end
      end
    end
  end
end
