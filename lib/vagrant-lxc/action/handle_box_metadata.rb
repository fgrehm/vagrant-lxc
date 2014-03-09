module Vagrant
  module LXC
    module Action
      # Prepare arguments to be used for lxc-create
      class HandleBoxMetadata
        SUPPORTED_VERSIONS  = ['1.0.0', '2', '3']

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::lxc::action::handle_box_metadata")
        end

        def call(env)
          @env = env
          @box = @env[:machine].box

          @env[:ui].info I18n.t("vagrant.actions.vm.import.importing",
                                :name => @env[:machine].box.name)

          @logger.info 'Validating box contents'
          validate_box

          @logger.info 'Setting box options on environment'
          @env[:lxc_template_src]  = template_src
          @env[:lxc_template_opts] = template_opts

          # FIXME: Remove support for pre 1.0.0 boxes
          if box_version != '1.0.0'
            @env[:ui].warn "WARNING: You are using a base box that has a format that has been deprecated, please upgrade to a new one."
            @env[:lxc_template_opts].merge!(
              '--auth-key' => Vagrant.source_root.join('keys', 'vagrant.pub').expand_path.to_s
            )
          end

          if template_config_file.exist?
            @env[:lxc_template_opts].merge!('--config' => template_config_file.to_s)
          elsif old_template_config_file.exist?
            @env[:lxc_template_config] = old_template_config_file.to_s
          end

          @app.call env
        end

        def template_src
          @template_src ||= @box.directory.join('lxc-template').to_s
        end

        def template_config_file
          @template_config_file ||= @box.directory.join('lxc-config')
        end

        # TODO: Remove this once we remove compatibility for < 1.0.0 boxes
        def old_template_config_file
          @old_template_config_file ||= @box.directory.join('lxc.conf')
        end

        def template_opts
          @template_opts ||= @box.metadata.fetch('template-opts', {}).dup.merge!(
            '--tarball'  => rootfs_tarball
          )
        end

        def rootfs_tarball
          @rootfs_tarball ||= @box.directory.join('rootfs.tar.gz').to_s
        end

        def validate_box
          unless SUPPORTED_VERSIONS.include? box_version
            raise Errors::IncompatibleBox.new name: @box.name,
                                              found: box_version,
                                              supported: SUPPORTED_VERSIONS.join(', ')
          end

          unless File.exists?(template_src)
            raise Errors::TemplateFileMissing.new name: @box.name
          end

          unless File.exists?(rootfs_tarball)
            raise Errors::RootFSTarballMissing.new name: @box.name
          end
        end

        def box_version
          @box.metadata.fetch('version')
        end
      end
    end
  end
end
