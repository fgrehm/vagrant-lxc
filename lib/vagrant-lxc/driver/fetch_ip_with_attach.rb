module Vagrant
  module LXC
    class Driver
      module FetchIpWithAttach
        # Include this so we can use `Subprocess` more easily.
        include Vagrant::Util::Retryable

        def assigned_ip
          ip = ''
          retryable(:on => LXC::Errors::ExecuteError, :tries => 10, :sleep => 3) do
            unless ip = get_container_ip_from_ip_addr
              # retry
              raise LXC::Errors::ExecuteError, :command => "lxc-attach"
            end
          end
          ip
        end

        # From: https://github.com/lxc/lxc/blob/staging/src/python-lxc/lxc/__init__.py#L371-L385
        def get_container_ip_from_ip_addr
          output = @cli.attach '/sbin/ip', '-4', 'addr', 'show', 'scope', 'global', 'eth0', namespaces: 'network'
          if output =~ /^\s+inet ([0-9.]+)\/[0-9]+\s+/
            return $1.to_s
          end
        end
      end
    end
  end
end
