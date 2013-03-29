module Vagrant
  module LXC
    class Config < Vagrant.plugin("2", :config)
      # An array of options to be passed to lxc-start when booting the machine.
      #
      # @return [Array]
      attr_reader :start_opts

      # Base directory to store container's rootfs
      #
      # Defaults to nil, which means it will be stored wherever the lxc template
      # tells it to be stored
      attr_accessor :target_rootfs_path

      def initialize
        @start_opts         = []
        @target_rootfs_path = nil
      end
    end
  end
end
