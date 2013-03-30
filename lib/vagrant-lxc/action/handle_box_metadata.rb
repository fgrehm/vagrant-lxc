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
          env[:ui].info I18n.t("vagrant.actions.vm.import.importing",
                               :name => env[:machine].box.name)

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
          # TODO: Ideally the compressed rootfs should not output errors...
          system(%Q[sudo su root -c "cd #{box.directory} && tar xfz rootfs.tar.gz -C #{rootfs_cache} 2>/dev/null"])

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
