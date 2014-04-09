module Vagrant
  module LXC
    class SyncedFolder < Vagrant.plugin("2", :synced_folder)
      def usable?(machine)
        # These synced folders only work if the provider is LXC
        machine.provider_name == :lxc
      end

      def prepare(machine, folders, _opts)
        machine.ui.output(I18n.t("vagrant.actions.lxc.share_folders.preparing"))
        # short guestpaths first, so we don't step on ourselves
        folders = folders.sort_by do |id, data|
          if data[:guestpath]
            data[:guestpath].length
          else
            # A long enough path to just do this at the end.
            10000
          end
        end

        folders.each do |id, data|
          host_path  = Pathname.new(File.expand_path(data[:hostpath], machine.env.root_path))
          guest_path = data[:guestpath]

          machine.env.ui.warn(I18n.t("vagrant_lxc.messages.warn_owner")) if data[:owner]
          machine.env.ui.warn(I18n.t("vagrant_lxc.messages.warn_group")) if data[:group]

          if !host_path.directory? && data[:create]
            # Host path doesn't exist, so let's create it.
            @logger.info("Host path doesn't exist, creating: #{host_path}")

            begin
              host_path.mkpath
            rescue Errno::EACCES
              raise Vagrant::Errors::SharedFolderCreateFailed,
                :path => hostpath.to_s
            end
          end

          mount_opts = data[:mount_options]
          machine.provider.driver.share_folder(host_path, guest_path, mount_opts)
          # Guest path specified, so mount the folder to specified point
          machine.ui.detail(I18n.t("vagrant.actions.vm.share_folders.mounting_entry",
                                guestpath:  data[:guestpath],
                                hostpath:   data[:hostpath],
                                guest_path: data[:guestpath]))
        end
      end
    end
  end
end
