require "vagrant"

module Vagrant
  module LXC
    class Plugin < Vagrant.plugin("2")
      name "vagrant-lxc"
      description <<-EOF
      The LXC provider allows Vagrant to manage and control
      LXC-based virtual machines.
      EOF

      command "lxc" do
        require_relative 'command/root'
        Command::Root
      end

      provider(:lxc, parallel: true) do
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

    def self.vagrant_1_3_or_later
      Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new('1.3.0')
    end
  end
end
