require "fileutils"

module Vagrant
  module LXC
    module Action
      class CompressRootFS
        def initialize(app, env)
          @app = app
        end

        def call(env)
          raise Vagrant::Errors::VMPowerOffToPackage if env[:machine].provider.state.id != :stopped

          env[:ui].info I18n.t("vagrant.actions.lxc.compressing_rootfs")
          @rootfs = env['package.rootfs'] = env[:machine].provider.driver.compress_rootfs

          @app.call env

          recover # called to remove the rootfs tarball
        end

        def recover(*)
          if @rootfs && File.exist?(@rootfs)
            FileUtils.rm_rf(File.dirname @rootfs)
          end
        end
      end
    end
  end
end
