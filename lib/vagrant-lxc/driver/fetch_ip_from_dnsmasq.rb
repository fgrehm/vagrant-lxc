module Vagrant
  module LXC
    class Driver
      module FetchIpFromDsnmasq
        def assigned_ip
          @logger.debug 'Loading ip from dnsmasq leases'
          ip = nil
          # TODO: Use Vagrant::Util::Retryable
          10.times do
            if dnsmasq_leases =~ /#{Regexp.escape mac_address}\s+([0-9.]+)\s+/
              ip = $1.to_s
              break
            else
              @logger.debug 'Ip could not be parsed from dnsmasq leases file'
              sleep 2
            end
          end
          # TODO: Raise an user friendly error
          raise 'Unable to identify container IP!' unless ip
          ip
        end

        def mac_address
          @mac_address ||= base_path.join('config').read.match(/^lxc\.network\.hwaddr\s+=\s+(.+)$/)[1]
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
