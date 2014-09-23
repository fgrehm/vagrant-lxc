require "vagrant-lxc/version"
require "vagrant-lxc/plugin"

module Vagrant
  module LXC
    def self.source_root
      @source_root ||= Pathname.new(File.dirname(__FILE__)).join('..').expand_path
    end

    def self.sudo_wrapper_path
      "/usr/local/bin/vagrant-lxc-wrapper"
    end
  end
end
