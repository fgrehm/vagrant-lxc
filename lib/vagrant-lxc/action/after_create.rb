module Vagrant
  module LXC
    module Action
      class AfterCreate < BaseAction
        def call(env)
          # Continue, we need the VM to be booted.
          @app.call env
          if env[:just_created] && (script = env[:machine].box.metadata['after-create-script'])
            env[:machine].provider.container.run_after_create_script script
          end
        end
      end
    end
  end
end
