# Monkey patch vagrant in order to reuse the UI test object that is set on
# our Vagrant::Environments
#
require 'vagrant/machine'
Vagrant::Machine.class_eval do
  alias :old_action :action

  define_method :action do |action_name, extra_env = nil|
    extra_env = { ui: @env.ui }.merge(extra_env || {})
    old_action action_name, extra_env
  end
end
