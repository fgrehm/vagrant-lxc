module Vagrant
  module LXC
    module Action
      class RemoveTemporaryFiles
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::lxc::action::remove_tmp_files")
        end

        def call(env)
          # Continue execution, we need the container to be stopped
          @app.call env

          if env[:machine].state.id == :stopped
            @logger.debug 'Removing temporary files'
            tmp_path = env[:machine].provider.driver.rootfs_path.join('tmp')
            system "sudo rm -rf #{tmp_path}/*"
          end
        end
      end
    end
  end
end
