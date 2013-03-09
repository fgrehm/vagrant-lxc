module Vagrant
  module LXC
    class Config < Vagrant.plugin("2", :config)
      # An array of options to be passed to lxc-start when booting the machine.
      #
      # @return [Array]
      attr_reader :start_opts

      # The ip set for the built in LXC dhcp server (defaults to configured ip
      # at /etc/default/lxc or 10.0.3.1)
      #
      # @return [String]
      attr_accessor :lxc_dhcp_ip

      def initialize
        @start_opts  = []
        @lxc_dhcp_ip = '10.0.3.1'
      end
    end
  end
end
