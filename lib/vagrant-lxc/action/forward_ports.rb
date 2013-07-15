module Vagrant
  module LXC
    module Action
      class ForwardPorts
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::lxc::action::forward_ports")
        end

        def call(env)
          @env = env

          # Continue, we need the VM to be booted in order to grab its IP
          @app.call env

          # Get the ports we're forwarding
          env[:forwarded_ports] = compile_forwarded_ports(env[:machine].config)

          # Warn if we're port forwarding to any privileged ports
          env[:forwarded_ports].each do |fp|
            if fp[:host] <= 1024
              env[:ui].warn I18n.t("vagrant.actions.vm.forward_ports.privileged_ports")
              break
            end
          end

          if @env[:forwarded_ports].any?
            env[:ui].info I18n.t("vagrant.actions.vm.forward_ports.forwarding")

            if redir_installed?
              forward_ports
            else
              raise Errors::RedirNotInstalled
            end
          end
        end

        def forward_ports
          @container_ip = @env[:machine].provider.driver.assigned_ip

          @env[:forwarded_ports].each do |fp|
            message_attributes = {
              # TODO: Add support for multiple adapters
              :adapter    => 'eth0',
              :guest_port => fp[:guest],
              :host_port  => fp[:host]
            }

            # TODO: Remove adapter from logging
            @env[:ui].info(I18n.t("vagrant.actions.vm.forward_ports.forwarding_entry",
                                  message_attributes))

            redir_pid = redirect_port(fp[:host], fp[:guest])
            store_redir_pid(fp[:host], redir_pid)
          end
        end

        private

        def compile_forwarded_ports(config)
          mappings = {}

          config.vm.networks.each do |type, options|
            if type == :forwarded_port && options[:id] != 'ssh'
              mappings[options[:host]] = options
            end
          end

          mappings.values
        end

        def redirect_port(host, guest)
          redir_cmd = "sudo redir --laddr=127.0.0.1 --lport=#{host} --cport=#{guest} --caddr=#{@container_ip} 2>/dev/null"

          @logger.debug "Forwarding port with `#{redir_cmd}`"
          spawn redir_cmd
        end

        def store_redir_pid(host_port, redir_pid)
          data_dir = @env[:machine].data_dir.join('pids')
          data_dir.mkdir unless data_dir.directory?

          data_dir.join("redir_#{host_port}.pid").open('w') do |pid_file|
            pid_file.write(redir_pid)
          end
        end

        def redir_installed?
          system "sudo which redir"
        end
      end
    end
  end
end
