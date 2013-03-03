module Vagrant
  module LXC
    module Action
      class AfterCreate < BaseAction
        def call(env)
          if env[:just_created] && (script = env[:machine].box.metadata['after-create-script'])
            env[:machine].provider.container.run_after_create_script script
          end
          @app.call env
        end
      end
    end
  end
end
