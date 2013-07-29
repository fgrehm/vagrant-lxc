module Vagrant
  module LXC
    module Action
      class FetchIpFromDnsmasqLeases
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::lxc::action::fetch_ip_from_dnsmasq_leases")
        end

        def call(env)
          env[:machine_ip] ||= assigned_ip(env)
          @app.call(env)
        end

        def assigned_ip(env)
          @logger.debug 'Loading ip from dnsmasq leases'
          mac_address = env[:machine].provider.driver.mac_address
          ip = nil
          10.times do
            if dnsmasq_leases =~ /#{Regexp.escape mac_address}\s+([0-9.]+)\s+/
              ip = $1.to_s
              break
            else
              @logger.debug 'Ip could not be parsed from dnsmasq leases file'
              sleep 2
            end
          end
          ip
        end

        LEASES_PATHS = %w(
          /var/lib/misc/dnsmasq.leases
          /var/lib/dnsmasq/dnsmasq.leases
          /var/db/dnsmasq.leases
        )

        def dnsmasq_leases
          LEASES_PATHS.map do |path|
            File.read(path) if File.exists?(path)
          end.join("\n")
        end
      end
    end
  end
end
