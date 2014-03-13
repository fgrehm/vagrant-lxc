module Vagrant
  module Backports
    class << self
      def vagrant_1_2_or_later?
        greater_than?('1.2.0')
      end

      def vagrant_1_3_or_later?
        greater_than?('1.3.0')
      end

      def vagrant_1_4_or_later?
        greater_than?('1.4.0')
      end

      def vagrant_1_5_or_later?
        greater_than?('1.5.0')
      end

      private

      def greater_than?(version)
        Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new(version)
      end
    end
  end
end
