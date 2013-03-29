module Vagrant
  module LXC
    module Action
      class Create < BaseAction
        def call(env)
          base_name = env[:root_path].basename.to_s
          base_name.gsub!(/[^-a-z0-9_]/i, "")

          machine_id         = env[:machine].provider.container.create(base_name, env[:machine].box.metadata)
          env[:machine].id   = machine_id
          env[:just_created] = true
          @app.call env
        end
      end
    end
  end
end
