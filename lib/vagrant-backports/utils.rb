module Vagrant
  module Backports
    class << self
      def vagrant_1_3_or_later?
        Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new('1.3.0')
      end
    end
  end
end
