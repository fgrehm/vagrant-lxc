module Vagrant
  module LXC
    class Config < Vagrant.plugin("2", :config)
      # An array of options to be passed to lxc-start when booting the machine.
      #
      # @return [Array]
      attr_reader :start_opts

      def initialize
        @start_opts  = []
      end
    end
  end
end
