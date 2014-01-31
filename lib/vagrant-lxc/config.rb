module Vagrant
  module LXC
    class Config < Vagrant.plugin("2", :config)
      # An array of container's configuration overrides to be provided to `lxc-start`.
      #
      # @return [Array]
      attr_reader :customizations

      # A String that points to a file that acts as a wrapper for sudo commands.
      #
      # This allows us to have a single entry when whitelisting NOPASSWD commands
      # on /etc/sudoers
      attr_accessor :sudo_wrapper

      # A String that sets a static name
      attr_accessor :static_name

      def initialize
        @customizations = []
        @sudo_wrapper   = UNSET_VALUE
        @static_name = UNSET_VALUE
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
        @static_name = nil if @static_name == UNSET_VALUE
      end

      def validate(machine)
        errors = []

        if @sudo_wrapper
          hostpath = Pathname.new(@sudo_wrapper).expand_path(machine.env.root_path)
          if ! hostpath.file?
            errors << I18n.t('vagrant_lxc.sudo_wrapper_not_found', path: hostpath.to_s)
          elsif ! hostpath.executable?
            errors << I18n.t('vagrant_lxc.sudo_wrapper_not_executable', path: hostpath.to_s)
          end
        end

        { "lxc provider" => errors }
      end
    end
  end
end
