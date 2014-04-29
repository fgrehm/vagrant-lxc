module Vagrant
  module LXC
    module Action
      class ClearForwardedPorts
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::lxc::action::clear_forwarded_ports")
        end

        def call(env)
          @env = env

          if redir_pids.any?
            env[:ui].info I18n.t("vagrant.actions.vm.clear_forward_ports.deleting")
            redir_pids.each do |pid|
              next unless is_redir_pid?(pid[0])
              @logger.debug "Killing pid #{pid[0]}"
	      if pid[1]
		system  "sudo pkill -TERM -P #{pid[0]}"
	      else
		system "pkill -TERM -P #{pid[0]}"
	      end
            end

            @logger.info "Removing redir pids files"
            remove_redir_pids
          else
            @logger.info "No redir pids found"
          end

          @app.call env
        end

        protected

        def redir_pids
          @redir_pids = Dir[@env[:machine].data_dir.join('pids').to_s + "/redir_*.pid"].map do |file|
	     port_number = file.split(/[^\d]/).join
	     privileged_port = true if Integer(port_number) > 1024
	     a = [ File.read(file).strip.chomp , privileged_port ]
          end
        end

        def is_redir_pid?(pid)
          @logger.debug "Checking if #{pid} is a redir process with `ps -o cmd= #{pid}`"
          `ps -o cmd= #{pid}`.strip.chomp =~ /redir/
        end

        def remove_redir_pids
          Dir[@env[:machine].data_dir.join('pids').to_s + "/redir_*.pid"].each do |file|
            File.delete file
          end
        end
      end
    end
  end
end
