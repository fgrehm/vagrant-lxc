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
    let(:last_command) { @last_command }
    let(:machine_id)   { 'random-machine-id' }
    let(:machine)      { fire_double('Vagrant::Machine', id: machine_id) }

    before do
      subject.stub(:lxc) do |*cmds|
        @last_command = cmds.join(' ')
        mock(exit_code: 0, stdout: '')
      end
      subject.wait_until :running
    end

    it 'runs lxc-wait with the machine id' do
      last_command.should include "--name #{machine_id}"
    end

    it 'runs lxc-wait with upcased state' do
      last_command.should include "--state RUNNING"
    end
  end

  describe 'creation' do
    let(:last_command)   { @last_command }
    let(:new_machine_id) { 'random-machine-id' }

    before do
      subject.stub(:lxc) do |*cmds|
        @last_command = cmds.join(' ')
        mock(exit_code: 0, stdout: '')
      end
      SecureRandom.stub(hex: new_machine_id)
      subject.create
    end

    it 'calls lxc-create with the right arguments' do
      last_command.should =~ /^create/
      last_command.should include "--name #{new_machine_id}"
      last_command.should include "--template ubuntu-cloud"
      last_command.should =~ /\-\- \-S (\w|\/|\.)+\/id_rsa\.pub$/
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
      subject.should have_received(:lxc).with(:start, '-d', '--name', machine.id)
    end

    it 'waits for container state to be RUNNING' do
      subject.should have_received(:wait_until).with(:running)
    end
  end
end
