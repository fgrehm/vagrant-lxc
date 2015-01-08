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
            bridge_ip      = config.fetch(:lxc__bridge_ip) { build_bridge_ip(ip) }
            bridge         = config.fetch(:lxc__bridge_name) # { build_bridge_name(config.fetch(:lxc__bridge_prefix, 'br'), bridge_ip) }

            # TODO: ensure_ip_is_not_in_use!
            configure_single_network(bridge, bridge_ip, container_name, ip)
          end
        end

        def configure_single_network(bridge, bridge_ip, container_name, ip)
          cmd = [
            'sudo',
            Vagrant::LXC.source_root.join('scripts/private-network').to_s,
            bridge,
            container_name,
            "#{ip}/24"
          ]
          execute(cmd)

          # TODO: Run only if bridge is not up and move it to the private network script
          cmd = [
            'sudo',
            'ip',
            'addr',
            'add',
            "#{bridge_ip}/24",
            'dev',
            bridge
          ]
          execute(cmd)
        end

        def execute(cmd)
          puts cmd.join(' ')
          system cmd.join(' ')
        end

        def build_bridge_ip(ip)
          ip.sub(/^(\d+\.\d+\.\d+)\.\d+/, '\1.254')
        end

        def bridge_name(prefix, bridge_ip)
          # if a bridge with the provided ip and prefix exist, get its name and return it
          # if no bridges can be found, grab the max bridge number, increment it and return the new name
          'br3'
        end
      end
    end
  end
end
