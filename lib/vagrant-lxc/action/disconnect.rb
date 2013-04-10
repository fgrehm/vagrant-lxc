module Vagrant
  module LXC
    module Action
      class Disconnect
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @app.call env
          # FIXME: Vagrant >= 1.1.3 should not need this
          #          https://github.com/mitchellh/vagrant/compare/715539eac30bc9ae62ddbb6337d13f036f7b774d...ec1bae0#L2R128
          env[:machine].instance_variable_set(:@communicator, nil)
        end
      end
    end
  end
end
