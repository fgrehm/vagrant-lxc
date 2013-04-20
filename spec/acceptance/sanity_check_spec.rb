require 'acceptance_helper'

class TestUI < Vagrant::UI::Interface
  attr_reader :messages

  METHODS = [:clear_line, :report_progress, :warn, :error, :info, :success]

  def initialize(resource = nil)
    super
    @messages = METHODS.each_with_object({}) { |m, h| h[m] = [] }
  end

  def ask(*args)
    super
    # Automated tests should not depend on user input, obviously.
    raise Errors::UIExpectsTTY
  end

  METHODS.each do |method|
    define_method(method) do |message, *opts|
      @messages[method].push message
    end
  end
end

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

describe 'Sanity check' do
  context 'running a `vagrant up` from scratch' do
    before(:all) do
      destroy_container
      vagrant_up
    end

    it 'creates a the container'

    it 'starts the newly created container'

    it 'mounts shared folders with the right permissions'

    it 'provisions the container based on Vagrantfile configs'

    it 'forwards configured ports'

    it "is able to be SSH'ed"
  end

  context '`vagrant halt` on a running container' do
    before(:all) do
      destroy_container
      vagrant_up
      vagrant_halt
    end

    it 'shuts down container'

    it 'clears forwarded ports'
  end

  context '`vagrant destroy`' do
    before(:all) do
      destroy_container
      vagrant_up
      vagrant_destroy
    end

    it 'destroys the underlying container'
  end

  def destroy_container
    `sudo lxc-shutdown -n \`cat /vagrant/spec/.vagrant/machines/default/lxc/id\``
    `sudo lxc-wait -n \`cat /vagrant/spec/.vagrant/machines/default/lxc/id\` --state STOPPED`
    `sudo lxc-destroy -n \`cat /vagrant/spec/.vagrant/machines/default/lxc/id\``
  end

  def vagrant_up
    opts = { cwd: 'spec' }
    env  = Vagrant::Environment.new(opts)
    env.cli('up', '--provider', 'lxc')
    env.unload
  end

  def vagrant_halt
    opts = { cwd: 'spec' }
    env  = Vagrant::Environment.new(opts)
    env.cli('halt')
    env.unload
  end

  def vagrant_destroy
    opts = { cwd: 'spec' }
    env  = Vagrant::Environment.new(opts)
    env.cli('destroy', '-f')
    env.unload
  end

  def vagrant_ssh(cmd)
    opts   = { cwd: 'spec', ui_class: TestUI }
    env    = Vagrant::Environment.new(opts)
    result = env.cli('ssh', '-c', cmd)
    if result.to_i != 0
      raise "SSH command failed: '#{cmd}'\n#{env.ui.messages.inspect}"
    end
    output = env.ui.messages[:info].join("\n").chomp
    env.unload
    output
  end
end
