module Vagrant
  module UI
    class Interface
      def output(*args)
        info(*args)
      end
      def detail(*args)
        info(*args)
      end
    end
  end
end
