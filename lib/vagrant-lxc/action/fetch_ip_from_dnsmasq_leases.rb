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
          mac_address = env[:machine].provider.driver.mac_address
          ip = nil
          10.times do
            dnsmasq_leases = read_dnsmasq_leases
            @logger.debug "Attempting to load ip from dnsmasq leases (mac: #{mac_address})"
            @logger.debug dnsmasq_leases
            if dnsmasq_leases =~ /#{Regexp.escape mac_address}\s+([0-9.]+)\s+/i
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
          /var/lib/misc/dnsmasq.*.leases
          /var/lib/misc/dnsmasq.leases
          /var/lib/dnsmasq/dnsmasq.leases
          /var/db/dnsmasq.leases
          /var/lib/libvirt/dnsmasq/*.leases
        )

        def read_dnsmasq_leases
          Dir["{#{LEASES_PATHS.join(',')}}"].map do |file|
            File.read(file)
          end.join("\n")
        end
      end
    end
  end
end
