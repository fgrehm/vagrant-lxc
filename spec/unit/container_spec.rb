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

    it 'prepends sudo for execution' do
      args[0].should == 'sudo'
    end

    it 'uses the first argument as lxc command suffix' do
      args[1].should == 'lxc-command'
    end

    it 'sends remaining arguments for execution' do
      args[2].should == '--state'
      args[3].should == 'RUNNING'
    end
  end

  describe 'create' do
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
    let(:last_command) { @last_command }
    let(:machine_id)   { 'random-machine-id' }
    let(:machine)      { fire_double('Vagrant::Machine', id: machine_id) }

    before do
      subject.stub(:lxc) do |*cmds|
        @last_command = cmds.join(' ')
        mock(exit_code: 0, stdout: '')
      end
      subject.start
    end

    it 'calls lxc-start with the right arguments' do
      last_command.should =~ /^start/
      last_command.should include "--name #{machine_id}"
      last_command.should include '-d'
    end
  end
end
