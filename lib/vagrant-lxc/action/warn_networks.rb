module Vagrant
  module LXC
    module Action
      class WarnNetworks
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if public_network_configured?(env[:machine].config)
            env[:ui].warn(I18n.t("vagrant_lxc.messages.warn_networks"))
          end

          @app.call(env)
        end

        def public_network_configured?(config)
          config.vm.networks.find do |type, _|
            type.to_sym == :public_network
          end
        end
      end
    end
  end
end
