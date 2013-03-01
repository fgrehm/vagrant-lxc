require 'unit_helper'

require 'vagrant-lxc/container'

describe Vagrant::LXC::Container do
  let(:machine) { fire_double('Vagrant::Machine') }

  subject { described_class.new(machine) }

  describe 'create' do
    let(:last_command)   { @last_command }
    let(:new_machine_id) { 'random-machine-id' }

    before do
      Vagrant::Util::Subprocess.stub(:execute) do |*cmds|
        cmds.pop if cmds.last.is_a?(Hash)
        @last_command = cmds.join(' ')
        mock(exit_code: 0, stdout: '')
      end
      SecureRandom.stub(hex: new_machine_id)
      subject.create
    end

    it 'runs lxc-create with the right arguments' do
      last_command.should include "--name='#{new_machine_id}'"
      last_command.should include "--template='ubuntu-cloud'"
      last_command.should =~ /\-\- \-S (\w|\/|\.)+\/id_rsa\.pub/
    end
  end
end
