module Vagrant
  module Backports
    class << self
      def vagrant_1_3_or_later?
        Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new('1.3.0')
      end

      def vagrant_1_4_or_later?
        Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new('1.4.0')
      end

      def vagrant_1_5_or_later?
        Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new('1.5.0')
      end
    end
  end
end
