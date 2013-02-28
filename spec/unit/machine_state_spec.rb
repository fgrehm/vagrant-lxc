require 'unit_helper'
require 'vagrant-lxc/machine_state'

describe Vagrant::LXC::MachineState do
  let(:machine)         { mocked_machine }
  let(:state_file_path) { subject.send(:state_file_path) }

  subject { described_class.new(machine) }

  after { File.delete state_file_path if File.exists? state_file_path }

  # Yeah, I know, this test is not really useful, but vagrant will complain
  # if the state is not a Vagrant::MachineState:
  #   https://github.com/mitchellh/vagrant/blob/master/lib/vagrant/machine.rb#L300
  it { should be_a Vagrant::MachineState }

  describe 'state id' do
    context 'when machine id is not present' do
      let(:machine) { mocked_machine(id: nil) }

      its(:id) { should == :not_created }
    end

    context 'when machine id is present' do
      let(:machine) { mocked_machine(id: 'machine-id') }

      context 'and state file exists' do
        before { File.stub(read: 'running', exists?: true) }
        after  { File.unstub!(:exists?) }

        it 'reads it from file' do
          subject.id.should == :running
        end
      end

      context 'and state file does not exist' do
        it 'returns :unknown' do
          subject.id.should == :unknown
        end
      end
    end
  end

  describe 'short description' do
    before { subject.stub(id: :not_created) }

    it 'is a humanized version of state id' do
      subject.short_description.should == 'not created'
    end
  end

  describe 'long description' do
    before do
      subject.stub(id: 'short')
      I18n.stub(t: 'some really long description')
    end

    it 'is a localized version of the state id' do
      subject.long_description.should == 'some really long description'
    end

    it 'uses the status locale "namespace"' do
      I18n.should have_received(:t).with('vagrant.commands.status.short')
    end
  end

  context 'when state id is :running' do
    before { subject.stub(id: :running) }

    it { should be_created }
    it { should be_running }
    it { should_not be_off }
  end

  context 'when state id is :poweroff' do
    before { subject.stub(id: :poweroff) }

    it { should be_created }
    it { should be_off }
    it { should_not be_running }
  end

  MACHINE_DEFAULTS = {id: nil}
  def mocked_machine(stubbed_methods = {})
    fire_double('Vagrant::Machine', MACHINE_DEFAULTS.merge(stubbed_methods))
  end
end
