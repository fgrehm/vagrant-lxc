module Vagrant
  module LXC
    module Action
      class PrivateNetworks
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @app.call(env)

          if private_network_configured?(env[:machine].config)
            env[:ui].output(I18n.t("vagrant_lxc.messages.setup_private_network"))
            configure_private_networks(env)
          end
        end

        def private_network_configured?(config)
          config.vm.networks.find do |type, _|
            type.to_sym == :private_network
          end
        end

        def configure_private_networks(env)
          env[:machine].config.vm.networks.find do |type, config|
            next if type.to_sym != :private_network

            container_name = env[:machine].provider.driver.container_name
            address_type   = config[:type]
            ip             = config[:ip]
            bridge_ip      = config.fetch(:lxc__bridge_ip) { build_bridge_ip(ip) }
            bridge         = config.fetch(:lxc__bridge_name)

            env[:machine].provider.driver.configure_private_network(bridge, bridge_ip, container_name, address_type, ip)
          end
        end

        def build_bridge_ip(ip)
          if ip
            ip.sub(/^(\d+\.\d+\.\d+)\.\d+/, '\1.254')
          end
        end
      end
    end
  end
end
