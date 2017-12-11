require "vagrant-lxc/version"
require "vagrant-lxc/plugin"
require "vagrant-lxc/sudo_wrapper"

module Vagrant
  module LXC
    def self.source_root
      @source_root ||= Pathname.new(File.dirname(__FILE__)).join('..').expand_path
    end

    def self.sudo_wrapper_path
      "/usr/local/bin/vagrant-lxc-wrapper"
    end

    def self.sudo_wrapper
      wrapper = Pathname.new(sudo_wrapper_path).exist? &&
        sudo_wrapper_path || nil
      SudoWrapper.new(wrapper)
    end

  end
end
