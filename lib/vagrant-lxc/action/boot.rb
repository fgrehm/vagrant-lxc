module Vagrant
  module LXC
    module Action
      class Boot < BaseAction
        def call(env)
          config = env[:machine].provider_config
          env[:machine].provider.container.start(config)
          @app.call env
        end
      end
    end
  end
end
