module Vagrant
  module LXC
    module Action
      class Destroy < BaseAction
        def call(env)
          env[:machine].provider.container.destroy
          env[:machine].id = nil
          @app.call env
        end
      end
    end
  end
end
