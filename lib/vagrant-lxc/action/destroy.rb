module Vagrant
  module LXC
    module Action
      class Destroy < BaseAction
        def call(env)
          env[:ui].info I18n.t("vagrant.actions.vm.destroy.destroying")
          env[:machine].provider.container.destroy
          env[:machine].id = nil
          @app.call env
        end
      end
    end
  end
end
