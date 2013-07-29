module Vagrant
  module LXC
    module Action
        class FetchIpWithLxcAttach
          # Include this so we can use `Subprocess` more easily.
          include Vagrant::Util::Retryable

          def initialize(app, env)
            @app    = app
            @logger = Log4r::Logger.new("vagrant::lxc::action::fetch_ip_with_lxc_attach")
          end

          def call(env)
            env[:machine_ip] ||= assigned_ip(env)
            @app.call(env)
          end

          def assigned_ip(env)
            driver  = env[:machine].provider.driver
            version = driver.version.match(/^(\d+\.\d+)\./)[1].to_f
            unless version >= 0.8
              @logger.debug "lxc version does not support the --namespaces argument to lxc-attach"
              return nil
            end

            ip = ''
            retryable(:on => LXC::Errors::ExecuteError, :tries => 10, :sleep => 3) do
              unless ip = get_container_ip_from_ip_addr(driver)
                # retry
                raise LXC::Errors::ExecuteError, :command => "lxc-attach"
              end
            end
            ip
          end

          # From: https://github.com/lxc/lxc/blob/staging/src/python-lxc/lxc/__init__.py#L371-L385
          def get_container_ip_from_ip_addr(driver)
            output = driver.attach '/sbin/ip', '-4', 'addr', 'show', 'scope', 'global', 'eth0', namespaces: 'network'
            if output =~ /^\s+inet ([0-9.]+)\/[0-9]+\s+/
              return $1.to_s
            end
          end
        end
      end
    end
  end
