require 'fileutils'

module Vagrant
  module LXC
    module Action
      class SetupPackageFiles
        def initialize(app, env)
          @app = app

          env["package.include"]     ||= []
          env["package.vagrantfile"] ||= nil
        end

        def call(env)
          @env = env

          create_package_temp_dir
          move_rootfs_to_pkg_dir
          copy_box_files_to_pkg_dir

          @app.call env

          recover # called to cleanup temp directory
        end

        def recover(*)
          if @temp_dir && File.exist?(@temp_dir)
            FileUtils.rm_rf(@temp_dir)
          end
        end

        private

        def create_package_temp_dir
          @env[:ui].info I18n.t("vagrant.actions.vm.export.create_dir")
          @temp_dir = @env["package.directory"] = @env[:tmp_path].join("container-export-#{Time.now.to_i.to_s}")
          FileUtils.mkpath(@temp_dir)
        end

        def move_rootfs_to_pkg_dir
          FileUtils.mv @env['package.rootfs'].to_s, @env['package.directory'].to_s
        end

        def copy_box_files_to_pkg_dir
          box_dir = @env[:machine].box.directory
          FileUtils.cp box_dir.join('lxc-template').to_s, @env['package.directory'].to_s
          FileUtils.cp box_dir.join('metadata.json').to_s, @env['package.directory'].to_s
          FileUtils.cp box_dir.join('lxc.conf').to_s, @env['package.directory'].to_s
        end
      end
    end
  end
end
