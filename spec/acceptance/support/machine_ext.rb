# Monkey patch vagrant in order to reuse the UI test object that is set on
# our Vagrant::Environments
#
# TODO: Find out if this makes sense to be on vagrant core itself
require 'vagrant/machine'
Vagrant::Machine.class_eval do
  alias :old_action :action

  define_method :action do |name, extra_env = nil|
    extra_env = { ui: @env.ui }.merge(extra_env || {})
    old_action name, extra_env
  end
end
