module Vagrant
  module LXC
    module Action
      class CheckCreated < BaseAction
        def call(env)
          unless env[:machine].state.created?
            raise Vagrant::Errors::VMNotCreatedError
          end

          # Call the next if we have one (but we shouldn't, since this
          # middleware is built to run with the Call-type middlewares)
          @app.call(env)
        end
      end
    end
  end
end
