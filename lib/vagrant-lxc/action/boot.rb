module Vagrant
  module LXC
    module Action
      class Boot
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env
          driver = env[:machine].provider.driver
          config = env[:machine].provider_config

          utsname = env[:machine].config.vm.hostname || env[:machine].id
          if driver.supports_new_config_format
            config.customize 'uts.name', utsname
          else
            config.customize 'utsname', utsname
          end

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

          if config.tmpfs_mount_size && !config.tmpfs_mount_size.empty?
            # Make /tmp a tmpfs to prevent init scripts from nuking synced folders mounted in here
            config.customize 'mount.entry', "tmpfs tmp tmpfs nodev,nosuid,size=#{config.tmpfs_mount_size} 0 0"
          end

          env[:ui].info I18n.t("vagrant_lxc.messages.starting")
          driver.start(config.customizations)

          @app.call env
        end
      end
    end
  end
end
