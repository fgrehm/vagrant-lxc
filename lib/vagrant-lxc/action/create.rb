module Vagrant
  module LXC
    module Action
      class Create < BaseAction
        def call(env)
          machine_id         = env[:machine].provider.container.create(env[:machine].box.metadata)
          env[:machine].id   = machine_id
          env[:just_created] = true
          @app.call env
        end
      end
    end
  end
end
