module Vagrant
  module LXC
    class Config < Vagrant.plugin("2", :config)
      # An array of container's configuration overrides to be provided to `lxc-start`.
      #
      # @return [Array]
      attr_reader :customizations

      # A string to explicitly set the container name. To use the vagrant
      # machine name, set this to :machine
      attr_accessor :container_name

      def initialize
        @customizations = []
        @sudo_wrapper   = UNSET_VALUE
        @container_name = UNSET_VALUE
      end

      # Customize the container by calling `lxc-start` with the given
      # configuration overrides.
      #
      # For example, if you want to set the memory limit, you can use it
      # like: config.customize 'cgroup.memory.limit_in_bytes', '400M'
      #
      # When `lxc-start`ing the container, vagrant-lxc will pass in
      # "-s lxc.cgroup.memory.limit_in_bytes=400M" to it.
      #
      # @param [String] key Configuration key to override
      # @param [String] value Configuration value to override
      def customize(key, value)
        @customizations << [key, value]
      end

      def finalize!
        @sudo_wrapper = nil if @sudo_wrapper == UNSET_VALUE
        @container_name = nil if @container_name == UNSET_VALUE
      end
    end
  end
end
