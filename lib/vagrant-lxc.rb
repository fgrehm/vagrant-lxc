require "vagrant-lxc/version"

require "vagrant-lxc/plugin"

I18n.load_path << File.expand_path(File.dirname(__FILE__) + '/../locales/en.yml')

module Vagrant
  module LXC
  end
end
