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
              next unless is_redir_pid?(pid)
              @logger.debug "Killing pid #{pid}"
              system "sudo pkill -TERM -P #{pid}"
            end

            remove_redir_pids
          end

          @app.call env
        end

        protected

        def redir_pids
          @redir_pids = Dir[@env[:machine].data_dir.join('pids').to_s + "/redir_*.pid"].map do |file|
            File.read(file).strip.chomp
          end
        end

        def is_redir_pid?(pid)
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
