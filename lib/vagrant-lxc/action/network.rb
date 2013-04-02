module Vagrant
  module LXC
    module Action
      class Network
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env

          env[:machine].config.vm.networks.each do |type, options|
            # We only handle private networks
            next if type != :private_network
            env[:machine].provider_config.start_opts << "lxc.network.ipv4=#{options[:ip]}/24"
          end

          # Continue the middleware chain.
          @app.call(env)
        end
      end
    end
  end
end
