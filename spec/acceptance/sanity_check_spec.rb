require 'acceptance_helper'

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
  end

  def vagrant_halt
    opts = { cwd: 'spec' }
    env  = Vagrant::Environment.new(opts)
    env.cli('halt')
  end

  def vagrant_destroy
    opts = { cwd: 'spec' }
    env  = Vagrant::Environment.new(opts)
    env.cli('destroy', '-f')
  end
end
