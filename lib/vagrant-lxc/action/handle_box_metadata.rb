require 'vagrant-lxc/action/base_action'

module Vagrant
  module LXC
    module Action
      # Prepare arguments to be used for lxc-create
      class HandleBoxMetadata < BaseAction
        LXC_TEMPLATES_PATH = Pathname.new("/usr/share/lxc/templates")

        def initialize(app, env)
          super
          @logger = Log4r::Logger.new("vagrant::lxc::action::handle_box_metadata")
        end

        def call(env)
          box           = env[:machine].box
          metadata      = box.metadata
          template_name = metadata['template-name']

          metadata.merge!(
            'template-name' => "vagrant-#{box.name}-#{template_name}",
            'tar-cache'     => box.directory.join(metadata['tar-cache']).to_s
          )

          # Prepends "lxc-" to the template file so that `lxc-create` is able to find it
          dest = LXC_TEMPLATES_PATH.join("lxc-#{metadata['template-name']}").to_s
          src  = box.directory.join(template_name).to_s

          @logger.debug('Copying LXC template into place')
          # This should only ask for administrative permission once, even
          # though its executed in multiple subshells.
          system(%Q[sudo su root -c "cp #{src} #{dest}"])

          @app.call(env)
        end
      end
    end
  end
end
