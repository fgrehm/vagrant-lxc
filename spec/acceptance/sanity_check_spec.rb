require 'acceptance_helper'

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
  after(:all) { destroy_container }

  context 'running `vagrant up` from scratch' do
    before(:all) do
      destroy_container
      vagrant_up
    end

    it 'creates a container' do
      containers = `sudo lxc-ls`.chomp.split(/\s+/).uniq
      expect(containers).to include File.read('/vagrant/spec/.vagrant/machines/default/lxc/id').strip.chomp
    end

    it 'starts the newly created container' do
      status = `sudo lxc-info -n #{File.read('/vagrant/spec/.vagrant/machines/default/lxc/id').strip.chomp}`
      expect(status).to include 'RUNNING'
    end

    it "is able to be SSH'ed" do
      expect(vagrant_ssh('hostname')).to eq 'lxc-test-box'
    end

    it 'mounts shared folders with the right permissions' do
      vagrant_ssh 'mkdir -p /vagrant/tmp && echo -n "Shared" > /vagrant/tmp/shared'
      shared_file_contents = File.read('/vagrant/spec/tmp/shared')
      expect(shared_file_contents).to eq 'Shared'
    end

    it 'provisions the container based on Vagrantfile configs' do
      provisioned_file_contents = File.read('/vagrant/spec/tmp/provisioning')
      expect(provisioned_file_contents).to eq 'Provisioned'
    end

    it 'forwards configured ports' do
      output = `curl -s localhost:8080`.strip.chomp
      expect(output).to include 'It works!'
    end
  end

  context '`vagrant halt` on a running container' do
    before(:all) do
      destroy_container
      vagrant_up
      vagrant_halt
    end

    it 'shuts down container' do
      status = `sudo lxc-info -n #{File.read('/vagrant/spec/.vagrant/machines/default/lxc/id').strip.chomp}`
      expect(status).to include 'STOPPED'
    end

    it 'clears forwarded ports' do
      `curl -s localhost:8080 --connect-timeout 2`
      expect($?.exitstatus).to_not eq 0
    end
  end

  context '`vagrant destroy`' do
    before(:all) do
      destroy_container
      vagrant_up
      @container_name = File.read('/vagrant/spec/.vagrant/machines/default/lxc/id').strip.chomp
      vagrant_destroy
    end

    it 'destroys the underlying container' do
      containers = `sudo lxc-ls`.chomp.split(/\s+/).uniq
      expect(containers).to_not include @container_name
    end
  end

  def destroy_container
    `sudo lxc-shutdown -n \`cat /vagrant/spec/.vagrant/machines/default/lxc/id\` 2>/dev/null`
    `sudo lxc-wait -n \`cat /vagrant/spec/.vagrant/machines/default/lxc/id\` --state STOPPED 2>/dev/null`
    `sudo lxc-destroy -n \`cat /vagrant/spec/.vagrant/machines/default/lxc/id\` 2>/dev/null`
    `sudo killall -9 redir 2>/dev/null`
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
