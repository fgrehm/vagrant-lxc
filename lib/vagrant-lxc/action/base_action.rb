module Vagrant
  module LXC
    module Action
      class BaseAction
        def initialize(app, env)
          @app = app
        end

        def call(env)
          puts "TODO: Implement #{self.class.name}"
          @app.call(env)
        end
      end
    end
  end
end
