require 'unit_helper'

require 'vagrant-lxc/container'

describe Vagrant::LXC::Container do
  # Default subject and machine for specs
  let(:machine) { fire_double('Vagrant::Machine') }
  subject { described_class.new(machine) }

  describe 'lxc commands execution' do
    let(:args) { @args }

    before do
      subject.stub(:execute) { |*args| @args = args }
      subject.lxc :command, '--state', 'RUNNING'
    end

    it 'prepends sudo' do
      args[0].should == 'sudo'
    end

    it 'uses the first argument as lxc command suffix' do
      args[1].should == 'lxc-command'
    end

    it 'pass through remaining arguments' do
      args[2].should == '--state'
      args[3].should == 'RUNNING'
    end
  end

  describe 'guard for container state' do
    let(:machine_id)   { 'random-machine-id' }
    let(:machine)      { fire_double('Vagrant::Machine', id: machine_id) }

    before do
      subject.stub :lxc
      subject.wait_until :running
    end

    it 'runs lxc-wait with the machine id and upcased state' do
      subject.should have_received(:lxc).with(
        :wait,
        '--name', machine_id,
        '--state', 'RUNNING'
      )
    end
  end

  describe 'creation' do
    let(:new_machine_id)  { 'random-machine-id' }
    let(:public_key_path) { Vagrant.source_root.join('keys', 'vagrant.pub').expand_path.to_s }

    before do
      subject.stub(:lxc)
      SecureRandom.stub(hex: new_machine_id)
      subject.create
    end

    it 'calls lxc-create with the right arguments' do
      subject.should have_received(:lxc).with(
        :create,
        '--template', 'ubuntu-cloud',
        '--name', new_machine_id,
        '--',
        '-S', public_key_path
      )
    end
  end

  describe 'start' do
    let(:machine_id) { 'random-machine-id' }
    let(:machine)    { fire_double('Vagrant::Machine', id: machine_id) }

    before do
      subject.stub(lxc: true, wait_until: true)
      subject.start
    end

    it 'calls lxc-start with the right arguments' do
      subject.should have_received(:lxc).with(
        :start,
        '-d',
        '--name', machine.id
      )
    end

    it 'waits for container state to be RUNNING' do
      subject.should have_received(:wait_until).with(:running)
    end
  end

  describe 'state' do
    let(:machine_id) { 'random-machine-id' }
    let(:machine)    { fire_double('Vagrant::Machine', id: machine_id) }

    before do
      subject.stub(lxc: "state: STOPPED\npid: 2")
    end

    it 'calls lxc-info with the right arguments' do
      subject.state
      subject.should have_received(:lxc).with(
        :info,
        '--name', machine_id
      )
    end

    it 'maps the output of lxc-info status out to a symbol' do
      subject.state.should == :stopped
    end
  end
end
