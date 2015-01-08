# sudo ifconfig br1 down && sudo brctl delbr br1

module Vagrant
  module LXC
    module Action
      class GcPrivateNetworkBridges
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env[:machine].provider.state.id != :running
            puts 'Cleanup bridges!'
          end

          @app.call(env)
        end
      end
    end
  end
end
