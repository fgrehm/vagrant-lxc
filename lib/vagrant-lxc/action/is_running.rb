module Vagrant
  module LXC
    module Action
      class IsRunning < BaseAction
        def call(env)
          env[:result] = env[:machine].state.running?

          # Call the next if we have one (but we shouldn't, since this
          # middleware is built to run with the Call-type middlewares)
          @app.call(env)
        end
      end
    end
  end
end
