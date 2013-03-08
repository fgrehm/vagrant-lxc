module Vagrant
  module LXC
    module Action
      # Prepare arguments to be used for lxc-create
      class HandleBoxMetadata < BaseAction
        LXC_TEMPLATES_PATH = Pathname.new("/usr/share/lxc/templates")
        TEMP_PREFIX        = "vagrant-lxc-rootfs-temp-"

        def initialize(app, env)
          super
          @logger = Log4r::Logger.new("vagrant::lxc::action::handle_box_metadata")
        end

        def call(env)
          # We _could_ extract the rootfs to a folder under ~/.vagrant.d/boxes
          # but it would open up for a few issues:
          #   * The rootfs owner is the root user, so we'd need to prepend "sudo" to
          #     `vagrant box remove`
          #   * We'd waste a lot of disk space: a compressed Ubuntu rootfs fits 80mb,
          #     extracted it takes 262mb
          #   * If something goes wrong during the Container creation process and
          #     somehow we don't handle, writing to /tmp means that things will get
          #     flushed on next reboot
          rootfs_cache  = Dir.mktmpdir(TEMP_PREFIX)
          box           = env[:machine].box
          template_name = "vagrant-#{box.name}"

          # Prepends "lxc-" to the template file so that `lxc-create` is able to find it
          lxc_template_src = box.directory.join('lxc-template').to_s
          unless File.exists?(lxc_template_src)
            raise Errors::TemplateFileMissing.new name: box.name
          end
          dest = LXC_TEMPLATES_PATH.join("lxc-#{template_name}").to_s
          @logger.debug('Copying LXC template into place')
          system(%Q[sudo su root -c "cp #{lxc_template_src} #{dest}"])

          @logger.debug('Extracting rootfs')
          system(%Q[sudo su root -c "cd #{box.directory} && tar xfz rootfs.tar.gz -C #{rootfs_cache}"])

          box.metadata.merge!(
            'template-name'     => template_name,
            'rootfs-cache-path' => rootfs_cache
          )

          @app.call(env)

        ensure
          system %Q[sudo su root -c "rm -rf #{rootfs_cache}"]
        end
      end
    end
  end
end
