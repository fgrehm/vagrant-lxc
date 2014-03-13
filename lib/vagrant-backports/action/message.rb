module Vagrant
  module Backports
    module Action
      # This middleware simply outputs a message to the UI.
      class Message
        def initialize(app, env, message, **opts)
          @app     = app
          @message = message
        end

        def call(env)
          env[:ui].info(@message)
          @app.call(env)
        end
      end
    end
  end
end

Vagrant::Action::Builtin.const_set :Message, Vagrant::Backports::Action::Message
