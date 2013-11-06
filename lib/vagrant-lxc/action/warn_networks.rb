module Vagrant
  module LXC
    module Action
      class WarnNetworks
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if public_or_private_network_configured?
            env[:ui].warn(I18n.t("vagrant_lxc.messages.warn_networks"))
          end

          @app.call(env)
        end

        def public_or_private_network_configured?
          config.vm.networks.find do |type|
            [:private_network, :public_network].include?(type.to_sym)
          end
        end
      end
    end
  end
end
