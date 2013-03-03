module Vagrant
  module LXC
    module Action
      class Boot < BaseAction
        def call(env)
          env[:machine].provider.container.start
          @app.call env
        end
      end
    end
  end
end
