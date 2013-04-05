module Vagrant
  module LXC
    module Action
      # Prepare arguments to be used for lxc-create
      class HandleBoxMetadata
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::lxc::action::handle_box_metadata")
        end

        def call(env)
          env[:ui].info I18n.t("vagrant.actions.vm.import.importing",
                               :name => env[:machine].box.name)

          box = env[:machine].box

          template_src = box.directory.join('lxc-template').to_s
          unless File.exists?(template_src)
            raise Errors::TemplateFileMissing.new name: box.name
          end

          # TODO: Validate box version

          @logger.debug('Merging metadata with template name and rootfs tarball')

          template_opts = box.metadata.fetch('template-opts', {}).dup
          template_opts.merge!(
            '--tarball'  => box.directory.join('rootfs.tar.gz').to_s,
						'--auth-key' => Vagrant.source_root.join('keys', 'vagrant.pub').expand_path.to_s
          )

          env[:lxc_template_opts] = template_opts
          env[:lxc_template_src]  = template_src

          @app.call env
        end
      end
    end
  end
end
