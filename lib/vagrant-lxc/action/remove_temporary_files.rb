module Vagrant
  module LXC
    module Action
      class RemoveTemporaryFiles
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::lxc::action::remove_tmp_files")
        end

        def call(env)
          @logger.debug 'Removing temporary files'
          driver = env[:machine].provider.driver
          # To prevent host-side data loss, it's important that all mounts under /tmp are unmounted
          # before we proceed with the `rm -rf` operation. See #68 and #360.
          driver.attach("findmnt -R /tmp -o TARGET --list --noheadings | xargs -L 1 --no-run-if-empty umount")
          driver.attach("rm -rf /tmp/*")

          @app.call env
        end
      end
    end
  end
end
