require 'unit_helper'

require 'vagrant-lxc/machine_state'

describe Vagrant::LXC::MachineState do
  describe 'short description' do
    subject { described_class.new(:not_created) }

    it 'is a humanized version of state id' do
      subject.short_description.should == 'not created'
    end
  end

  describe 'long description' do
    subject { described_class.new(:short_name) }
    before  { I18n.stub(t: 'some really long description') }

    it 'is a localized version of the state id' do
      subject.long_description.should == 'some really long description'
      I18n.should have_received(:t).with('vagrant.commands.status.short_name')
    end
  end

  context 'when state id is :running' do
    subject { described_class.new(:running) }

    it { should be_created }
    it { should be_running }
    it { should_not be_off }
  end

  context 'when state id is :poweroff' do
    subject { described_class.new(:poweroff) }

    it { should be_created }
    it { should be_off }
    it { should_not be_running }
  end
end
