require_relative 'fetch_ip_with_attach'
require_relative 'fetch_ip_from_dnsmasq'

module Vagrant
  module LXC
    class Driver
      class Builder
        def self.build(id, shell)
          version = CLI.new(shell).version.match(/^(\d+\.\d+)\./)[1].to_f
          Driver.new(id, shell).tap do |driver|
            mod = version >= 0.8 ?
              Driver::FetchIpWithAttach :
              Driver::FetchIpFromDsnmasq

            driver.extend(mod)
          end
        end
      end
    end
  end
end
