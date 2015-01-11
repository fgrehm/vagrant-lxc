module Vagrant
  module LXC
    module Action
      class GcPrivateNetworkBridges
        def initialize(app, env)
          @app = app
        end

        def call(env)
          was_running = env[:machine].provider.state.id == :running

          # Continue execution, we need the container to be stopped
          @app.call(env)

          was_running = was_running && env[:machine].provider.state.id != :running

          if was_running && private_network_configured?(env[:machine].config)
            private_network_configured?(env[:machine].config)
            remove_bridges_that_are_not_in_use(env)
          end
        end

        def private_network_configured?(config)
          config.vm.networks.find do |type, _|
            type.to_sym == :private_network
          end
        end

        def remove_bridges_that_are_not_in_use(env)
          env[:machine].config.vm.networks.find do |type, config|
            next if type.to_sym != :private_network

            bridge = config.fetch(:lxc__bridge_name)
            driver = env[:machine].provider.driver

            if ! driver.bridge_is_in_use?(bridge)
              env[:ui].info I18n.t("vagrant_lxc.messages.remove_bridge", name: bridge)
              # TODO: Output that bridge is being removed
              driver.remove_bridge(bridge)
            end
          end
        end
      end
    end
  end
end
