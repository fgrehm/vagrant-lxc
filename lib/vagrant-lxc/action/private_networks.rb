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
            ip             = config[:ip]
            configure_single_network('br1', container_name, ip)
          end
        end

        def configure_single_network(bridge, container_name, ip)
          cmd = [
            'sudo',
            Vagrant::LXC.source_root.join('scripts/private-network').to_s,
            bridge,
            container_name,
            "#{ip}/24"
          ]
          puts cmd.join(' ')
          system cmd.join(' ')

          cmd = [
            'sudo',
            'ip',
            'addr',
            'add',
            # TODO: This should not be hard coded and has to run once per bridge
            "192.168.1.254/24",
            'dev',
            bridge
          ]
          puts cmd.join(' ')
          system cmd.join(' ')
        end
      end
    end
  end
end
