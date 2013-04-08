module Vagrant
  module LXC
    module Action
      class CheckRunning
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env[:machine].state.id != :running
            raise Vagrant::Errors::VMNotRunningError
          end

          # Call the next if we have one (but we shouldn't, since this
          # middleware is built to run with the Call-type middlewares)
          @app.call(env)
        end
      end
    end
  end
end
