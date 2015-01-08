require 'vagrant'

module Vagrant
  module LXC
    class Plugin < Vagrant.plugin("2")
      name "vagrant-lxc"
      description <<-EOF
      The LXC provider allows Vagrant to manage and control
      LXC-based virtual machines.
      EOF

      provider(:lxc, parallel: true, priority: 7) do
        require File.expand_path("../provider", __FILE__)

        I18n.load_path << File.expand_path(File.dirname(__FILE__) + '/../../locales/en.yml')
        I18n.reload!

        Provider
      end

      command "lxc" do
        require_relative 'command/root'
        Command::Root
      end

      config(:lxc, :provider) do
        require File.expand_path("../config", __FILE__)
        Config
      end

      synced_folder(:lxc) do
        require File.expand_path("../synced_folder", __FILE__)
        SyncedFolder
      end

      provider_capability("lxc", "public_address") do
        require_relative "provider/cap/public_address"
        Provider::Cap::PublicAddress
      end
    end
  end
end
