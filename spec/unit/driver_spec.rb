require 'unit_helper'

require 'vagrant'
require 'vagrant-lxc/driver'
require 'vagrant-lxc/driver/cli'

describe Vagrant::LXC::Driver do
  describe 'container name validation' do
    let(:unknown_container) { described_class.new('unknown', nil, cli) }
    let(:valid_container)   { described_class.new('valid', nil, cli) }
    let(:new_container)     { described_class.new(nil, nil) }
    let(:cli)               { instance_double('Vagrant::LXC::Driver::CLI', list: ['valid']) }

    it 'raises a ContainerNotFound error if an unknown container name gets provided' do
      expect {
        unknown_container.validate!
      }.to raise_error
    end

    it 'does not raise a ContainerNotFound error if a valid container name gets provided' do
      expect {
        valid_container.validate!
      }.not_to raise_error
    end

    it 'does not raise a ContainerNotFound error if nil is provider as name' do
      expect {
        new_container.validate!
      }.not_to raise_error
    end
  end

  describe 'creation' do
    let(:name)           { 'container-name' }
    let(:template_name)  { 'auto-assigned-template-id' }
    let(:template_path)  { '/path/to/lxc-template-from-box' }
    let(:template_opts)  { {'--some' => 'random-option'} }
    let(:config_file)    { '/path/to/lxc-config-from-box' }
    let(:rootfs_tarball) { '/path/to/cache/rootfs.tar.gz' }
    let(:cli)            { instance_double('Vagrant::LXC::Driver::CLI', :create => true, :name= => true) }

    subject { described_class.new(nil, nil, cli) }

    before do
      subject.stub(:import_template).and_yield(template_name)
      subject.create name, template_path, config_file, template_opts
    end

    it 'sets the cli object container name' do
      cli.should have_received(:name=).with(name)
    end

    it 'creates container with the right arguments' do
      cli.should have_received(:create).with(
        template_name,
        config_file,
        template_opts
      )
    end
  end

  describe 'destruction' do
    let(:cli) { instance_double('Vagrant::LXC::Driver::CLI', destroy: true) }

    subject { described_class.new('name', nil, cli) }

    before { subject.destroy }

    it 'delegates to cli object' do
      cli.should have_received(:destroy)
    end
  end

  describe 'start' do
    let(:customizations)         { [['a', '1'], ['b', '2']] }
    let(:internal_customization) { ['internal', 'customization'] }
    let(:cli)                    { instance_double('Vagrant::LXC::Driver::CLI', start: true) }
    let(:sudo)                   { instance_double('Vagrant::LXC::SudoWrapper', su_c: true) }

    subject { described_class.new('name', sudo, cli) }

    before do
      subject.customizations << internal_customization
      subject.start(customizations)
    end

    it 'prunes previous customizations before writing'

    it 'writes configurations to config file'

    it 'starts container with configured customizations' do
      cli.should have_received(:start)
    end
  end

  describe 'halt' do
    let(:cli) { instance_double('Vagrant::LXC::Driver::CLI', shutdown: true) }

    subject { described_class.new('name', nil, cli) }

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

    it 'attempts to force the container to stop in case lxc-shutdown is not supported' do
      cli.stub(:shutdown).and_raise(Vagrant::LXC::Driver::CLI::ShutdownNotSupported)
      cli.should_receive(:transition_to).with(:stopped).twice
      cli.should_receive(:stop)
      subject.forced_halt
    end
  end

  describe 'state' do
    let(:cli_state) { :something }
    let(:cli)       { instance_double('Vagrant::LXC::Driver::CLI', state: cli_state) }

    subject { described_class.new('name', nil, cli) }

    it 'delegates to cli' do
      subject.state.should == cli_state
    end
  end

  describe 'folder sharing' do
    rootfs_path = Pathname('/path/to/rootfs')
    
    let(:shared_folder)       { {guestpath: '/vagrant', hostpath: '/path/to/host/dir'} }
    let(:folders)             { [shared_folder] }
    let(:expected_mount_path) { "vagrant" }
    let(:expected_guest_path) { "#{rootfs_path}/vagrant" }
    let(:sudo_wrapper)        { instance_double('Vagrant::LXC::SudoWrapper', run: true) }

    subject { described_class.new('name', sudo_wrapper) }

    describe "with fixed rootfs" do
      before do
        subject.stub(rootfs_path: rootfs_path, system: true)
        subject.share_folders(folders)
      end

      it "creates guest folder under container's rootfs" do
        sudo_wrapper.should have_received(:run).with("mkdir", "-p", expected_guest_path)
      end

      it 'adds a mount.entry to its local customizations' do
        subject.customizations.should include [
          'mount.entry',
          "#{shared_folder[:hostpath]} #{expected_mount_path} none bind 0 0"
        ]
      end
    end

    describe "with directory-based LXC config" do
      config_string = <<-ENDCONFIG.gsub(/^\s+/, '')
        # Blah blah comment
        lxc.mount.entry = proc proc proc nodev,noexec,nosuid 0 0
        lxc.mount.entry = sysfs sys sysfs defaults  0 0
        lxc.tty = 4
        lxc.pts = 1024
        lxc.rootfs = #{rootfs_path}
        # VAGRANT-BEGIN
        lxc.network.type=veth
        lxc.network.name=eth1
        # VAGRANT-END
      ENDCONFIG
      
      before do
        subject { described_class.new('name', sudo_wrapper) }
        subject.stub(config_string: config_string)
        subject.share_folders(folders)
      end
      
      it 'adds a mount.entry to its local customizations' do
        subject.customizations.should include [
          'mount.entry',
          "#{shared_folder[:hostpath]} #{expected_mount_path} none bind 0 0"
        ]
      end
    end

    describe "with overlayfs-based LXC config" do
      config_string = <<-ENDCONFIG.gsub(/^\s+/, '')
        # Blah blah comment
        lxc.mount.entry = proc proc proc nodev,noexec,nosuid 0 0
        lxc.mount.entry = sysfs sys sysfs defaults  0 0
        lxc.tty = 4
        lxc.pts = 1024
        lxc.rootfs = overlayfs:/path/to/master/directory:#{rootfs_path}
        # VAGRANT-BEGIN
        lxc.network.type=veth
        lxc.network.name=eth1
        # VAGRANT-END
      ENDCONFIG

      before do
        subject { described_class.new('name', sudo_wrapper) }
        subject.stub(config_string: config_string)
        subject.share_folders(folders)
      end

      it 'adds a mount.entry to its local customizations' do
        subject.customizations.should include [
          'mount.entry',
          "#{shared_folder[:hostpath]} #{expected_mount_path} none bind 0 0"
        ]
      end
    end
  end
end
