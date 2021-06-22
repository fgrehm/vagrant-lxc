module Vagrant
  module LXC
    module Action
      class FetchIpWithLxcInfo
        # Include this so we can use `Subprocess` more easily.
        include Vagrant::Util::Retryable

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::lxc::action::fetch_ip_with_lxc_info")
        end

        def call(env)
          env[:machine_ip] ||= assigned_ip(env)
        ensure
          @app.call(env)
        end

        def assigned_ip(env)
          config = env[:machine].provider_config
          fetch_ip_tries = config.fetch_ip_tries
          driver = env[:machine].provider.driver
          ip = ''
          return config.ssh_ip_addr if not config.ssh_ip_addr.nil?
          retryable(:on => LXC::Errors::ExecuteError, :tries => fetch_ip_tries, :sleep => 3) do
            unless ip = get_container_ip_from_ip_addr(driver)
              # retry
              raise LXC::Errors::ExecuteError, :command => "lxc-info"
            end
          end
          ip
        end

        # From: https://github.com/lxc/lxc/blob/staging/src/python-lxc/lxc/__init__.py#L371-L385
        def get_container_ip_from_ip_addr(driver)
          output = driver.info '-iH'
          if output =~ /^([0-9.a-f:]+)/
            return $1.to_s
          end
        end
      end
    end
  end
end
