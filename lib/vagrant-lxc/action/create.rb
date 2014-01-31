module Vagrant
  module LXC
    module Action
      class Create
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env[:machine].provider_config.static_name
            container_name = env[:machine].name.to_s
          else
            container_name = "#{env[:root_path].basename}_#{env[:machine].name}"
            container_name.gsub!(/[^-a-z0-9_]/i, "")
            container_name << "-#{Time.now.to_i}"
          end

          env[:machine].provider.driver.create(
            container_name,
            env[:lxc_template_src],
            env[:lxc_template_config],
            env[:lxc_template_opts]
          )

          env[:machine].id = container_name

          @app.call env
        end
      end
    end
  end
end
