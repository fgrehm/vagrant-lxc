require 'unit_helper'

require 'vagrant'
require 'vagrant-lxc/driver'
require 'vagrant-lxc/driver/cli'

describe Vagrant::LXC::Driver do
  describe 'container name validation' do
    let(:unknown_container) { described_class.new('unknown', cli) }
    let(:valid_container)   { described_class.new('valid', cli) }
    let(:new_container)     { described_class.new(nil) }
    let(:cli)               { fire_double('Vagrant::LXC::Driver::CLI', list: ['valid']) }

    it 'raises a ContainerNotFound error if an unknown container name gets provided' do
      expect {
        unknown_container.validate!
      }.to raise_error(Vagrant::LXC::Driver::ContainerNotFound)
    end

    it 'does not raise a ContainerNotFound error if a valid container name gets provided' do
      expect {
        valid_container.validate!
      }.to_not raise_error(Vagrant::LXC::Driver::ContainerNotFound)
    end

    it 'does not raise a ContainerNotFound error if nil is provider as name' do
      expect {
        new_container.validate!
      }.to_not raise_error(Vagrant::LXC::Driver::ContainerNotFound)
    end
  end

  describe 'creation' do
    let(:name)           { 'container-name' }
    let(:template_name)  { 'auto-assigned-template-id' }
    let(:template_path)  { '/path/to/lxc-template-from-box' }
    let(:template_opts)  { {'--some' => 'random-option'} }
    let(:rootfs_tarball) { '/path/to/cache/rootfs.tar.gz' }
    let(:cli)            { fire_double('Vagrant::LXC::Driver::CLI', :create => true, :name= => true) }

    subject { described_class.new(nil, cli) }

    before do
      subject.stub(:import_template).and_yield(template_name)
      subject.create name, template_path, template_opts
    end

    it 'sets the cli object container name' do
      cli.should have_received(:name=).with(name)
    end

    it 'creates container with the right arguments' do
      cli.should have_received(:create).with(
        template_name,
        template_opts
      )
    end
  end

  describe 'destruction' do
    let(:cli) { fire_double('Vagrant::LXC::Driver::CLI', destroy: true) }

    subject { described_class.new('name', cli) }

    before { subject.destroy }

    it 'delegates to cli object' do
      cli.should have_received(:destroy)
    end
  end

  describe 'start' do
    let(:customizations)         { [['a', '1'], ['b', '2']] }
    let(:internal_customization) { ['internal', 'customization'] }
    let(:cli)                    { fire_double('Vagrant::LXC::Driver::CLI', start: true) }

    subject { described_class.new('name', cli) }

    before do
      cli.stub(:transition_to).and_yield(cli)
      subject.customizations << internal_customization
      subject.start(customizations)
    end

    it 'starts container with configured customizations' do
      cli.should have_received(:start).with(customizations + [internal_customization], nil)
    end

    it 'expects a transition to running state to take place' do
      cli.should have_received(:transition_to).with(:running)
    end
  end

  describe 'halt' do
    let(:cli) { fire_double('Vagrant::LXC::Driver::CLI', shutdown: true) }

    subject { described_class.new('name', cli) }

    before do
      cli.stub(:transition_to).and_yield(cli)
    end

    it 'delegates to cli shutdown' do
      cli.should_receive(:shutdown)
      subject.forced_halt
    end

    it 'expects a transition to running state to take place' do
      cli.should_receive(:transition_to).with(:stopped)
      subject.forced_halt
    end

    it 'attempts to force the container to stop in case a shutdown doesnt work' do
      cli.stub(:shutdown).and_raise(Vagrant::LXC::Driver::CLI::TargetStateNotReached.new :target, :source)
      cli.should_receive(:transition_to).with(:stopped).twice
      cli.should_receive(:stop)
      subject.forced_halt
    end
  end

  describe 'state' do
    let(:cli_state) { :something }
    let(:cli)       { fire_double('Vagrant::LXC::Driver::CLI', state: cli_state) }

    subject { described_class.new('name', cli) }

    it 'delegates to cli' do
      subject.state.should == cli_state
    end
  end

  pending 'assigned ip' do
    # This ip is set on the sample-ip-addr-output fixture
    let(:ip)              { "10.0.254.137" }
    let(:ifconfig_output) { File.read('spec/fixtures/sample-ip-addr-output') }
    let(:cli)             { fire_double('Vagrant::LXC::Driver::CLI', :attach => ifconfig_output) }

    subject { described_class.new('name', cli) }

    context 'when ip for eth0 gets returned from lxc-attach call' do
      it 'gets parsed from `ip addr` output' do
        subject.assigned_ip.should == ip
        cli.should have_received(:attach).with(
          '/sbin/ip',
          '-4',
          'addr',
          'show',
          'scope',
          'global',
          'eth0',
          namespaces: 'network'
        )
      end
    end
  end

  describe 'folder sharing' do
    let(:shared_folder)       { {guestpath: '/vagrant', hostpath: '/path/to/host/dir'} }
    let(:folders)             { [shared_folder] }
    let(:rootfs_path)         { Pathname('/path/to/rootfs') }
    let(:expected_guest_path) { "#{rootfs_path}/vagrant" }

    subject { described_class.new('name') }

    before do
      subject.stub(rootfs_path: rootfs_path, system: true)
      subject.share_folders(folders)
    end

    it "creates guest folder under container's rootfs" do
      subject.should have_received(:system).with("sudo mkdir -p #{expected_guest_path}")
    end

    it 'adds a mount.entry to its local customizations' do
      subject.customizations.should include [
        'mount.entry',
        "#{shared_folder[:hostpath]} #{expected_guest_path} none bind 0 0"
      ]
    end
  end
end
