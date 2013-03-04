module Vagrant
  module LXC
    module Action
      # DISCUSS: The Boot action has a different meaning on VB provider and it
      # assumes the machine has been started already.
      class Boot < BaseAction
        def call(env)
          config = env[:machine].provider_config

          # Allows this middleware to be called multiple times. We need to
          # support this as base boxes might have after create scripts which
          # require SSH access
          unless env[:machine].state.running?
            env[:machine].provider.container.start(config)
          end

          @app.call env
        end
      end
    end
  end
end
