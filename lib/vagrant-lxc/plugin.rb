require "vagrant"

module Vagrant
  module LXC
    class Plugin < Vagrant.plugin("2")
      name "Linux Containers (LXC) provider"
      description <<-EOF
      The LXC provider allows Vagrant to manage and control
      LXC-based virtual machines.
      EOF

      provider(:lxc) do
        require File.expand_path("../provider", __FILE__)

        I18n.load_path << File.expand_path(File.dirname(__FILE__) + '/../../locales/en.yml')
        I18n.reload!

        Provider
      end

      config(:lxc, :provider) do
        require File.expand_path("../config", __FILE__)
        Config
      end
    end
  end
end
