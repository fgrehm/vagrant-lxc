module Vagrant
  module LXC
    module Action
      class Boot
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env

          config = env[:machine].provider_config

          utsname = env[:machine].config.vm.hostname || env[:machine].id
          config.customize 'utsname', utsname

          # Fix apparmor issues when starting Ubuntu 14.04 containers
          # See https://github.com/fgrehm/vagrant-lxc/issues/278 for more information
          if Dir.exists?('/sys/fs/pstore')
            config.customize 'mount.entry', '/sys/fs/pstore sys/fs/pstore none bind,optional 0 0'
          end

          # Make selinux read-only, see
          # https://github.com/fgrehm/vagrant-lxc/issues/301
          if Dir.exists?('/sys/fs/selinux')
            config.customize 'mount.entry', '/sys/fs/selinux sys/fs/selinux none bind,ro 0 0'
          end

          env[:ui].info I18n.t("vagrant_lxc.messages.starting")
          env[:machine].provider.driver.start(config.customizations)

          @app.call env
        end
      end
    end
  end
end
