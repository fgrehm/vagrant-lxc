require 'unit_helper'

require 'vagrant-lxc/driver'
require 'vagrant-lxc/driver/cli'
require 'vagrant-lxc/sudo_wrapper'

describe Vagrant::LXC::Driver do
  describe 'container name validation' do
    let(:unknown_container) { described_class.new('unknown', nil, cli) }
    let(:valid_container)   { described_class.new('valid', nil, cli) }
    let(:new_container)     { described_class.new(nil, nil) }
    let(:cli)               { double(Vagrant::LXC::Driver::CLI, list: ['valid']) }

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
    let(:name)              { 'container-name' }
    let(:backingstore)      { 'btrfs' }
    let(:backingstore_opts) { [['--dir', '/tmp/foo'], ['--foo', 'bar']] }
    let(:template_name)     { 'auto-assigned-template-id' }
    let(:template_path)     { '/path/to/lxc-template-from-box' }
    let(:template_opts)     { {'--some' => 'random-option'} }
    let(:config_file)       { '/path/to/lxc-config-from-box' }
    let(:rootfs_tarball)    { '/path/to/cache/rootfs.tar.gz' }
    let(:cli)               { double(Vagrant::LXC::Driver::CLI, :create => true, :name= => true) }

    subject { described_class.new(nil, nil, cli) }

    before do
      allow(subject).to receive(:import_template).and_yield(template_name)
      subject.create name, backingstore, backingstore_opts, template_path, config_file, template_opts
    end

    it 'sets the cli object container name' do
      expect(cli).to have_received(:name=).with(name)
    end

    it 'creates container with the right arguments' do
      expect(cli).to have_received(:create).with(
        template_path,
        backingstore,
        backingstore_opts,
        config_file,
        template_opts
      )
    end
  end

  describe 'destruction' do
    let(:cli) { double(Vagrant::LXC::Driver::CLI, destroy: true) }

    subject { described_class.new('name', nil, cli) }

    before { subject.destroy }

    it 'delegates to cli object' do
      expect(cli).to have_received(:destroy)
    end
  end

  describe 'supports_attach?' do
    let(:cli) { double(Vagrant::LXC::Driver::CLI, supports_attach?: true) }

    subject { described_class.new('name', nil, cli) }

    it 'delegates to cli object' do
      expect(subject.supports_attach?).to be_truthy
      expect(cli).to have_received(:supports_attach?)
    end
  end

  describe 'start' do
    let(:customizations)         { [['a', '1'], ['b', '2']] }
    let(:internal_customization) { ['internal', 'customization'] }
    let(:cli)                    { double(Vagrant::LXC::Driver::CLI, start: true) }
    let(:sudo)                   { double(Vagrant::LXC::SudoWrapper) }

    subject { described_class.new('name', sudo, cli) }

    before do
      sudo.should_receive(:run).with('cat', '/var/lib/lxc/name/config').exactly(2).times.
        and_return('# CONFIGURATION')
      sudo.should_receive(:run).twice.with('cp', '-f', %r{/(run|tmp)/.*}, '/var/lib/lxc/name/config')
      sudo.should_receive(:run).twice.with('chown', 'root:root', '/var/lib/lxc/name/config')
      expect(cli).to receive(:config).with("lxc.lxcpath").and_return("/var/lib/lxc")

      subject.customizations << internal_customization
      subject.start(customizations)
    end

    it 'prunes previous customizations before writing'

    it 'writes configurations to config file'

    it 'starts container with configured customizations' do
      expect(cli).to have_received(:start)
    end
  end

  describe 'halt' do
    let(:cli) { double(Vagrant::LXC::Driver::CLI, stop: true) }

    subject { described_class.new('name', nil, cli) }

    before do
      allow(cli).to receive(:transition_to).and_yield(cli)
    end

    it 'delegates to cli stop' do
      expect(cli).to receive(:stop)
      subject.forced_halt
    end

    it 'expects a transition to running state to take place' do
      expect(cli).to receive(:transition_to).with(:stopped)
      subject.forced_halt
    end

    it 'attempts to force the container to stop in case a shutdown doesnt work' do
      allow(cli).to receive(:shutdown).and_raise(Vagrant::LXC::Driver::CLI::TargetStateNotReached.new :target, :source)
      expect(cli).to receive(:transition_to).with(:stopped)
      expect(cli).to receive(:stop)
      subject.forced_halt
    end
  end

  describe 'state' do
    let(:cli_state) { :something }
    let(:cli)       { double(Vagrant::LXC::Driver::CLI, state: cli_state) }

    subject { described_class.new('name', nil, cli) }

    it 'delegates to cli' do
      expect(subject.state).to eq(cli_state)
    end
  end

  describe 'containers_path' do
    let(:cli) { double(Vagrant::LXC::Driver::CLI, config: cli_config_value) }

    subject { described_class.new('name', nil, cli) }

    describe 'lxc version after 1.x.x' do
      let(:cli_config_value)                 { '/etc/lxc' }

      it 'delegates to cli' do
        expect(subject.containers_path).to eq(cli_config_value)
      end
    end
  end

  describe 'folder sharing' do
    let(:shared_folder)       { {guestpath: '/vagrant', hostpath: '/path/to/host/dir'} }
    let(:ro_rw_folder)        { {guestpath: '/vagrant/ro_rw', hostpath: '/path/to/host/dir', mount_options: ['ro', 'rw']} }
    let(:with_space_folder)   { {guestpath: '/tmp/with space', hostpath: '/path/with space'} }
    let(:folders)             { [shared_folder, ro_rw_folder, with_space_folder] }
    let(:expected_guest_path) { "vagrant" }
    let(:sudo_wrapper)        { double(Vagrant::LXC::SudoWrapper, run: true) }
    let(:rootfs_path)         { Pathname('/path/to/rootfs') }

    subject { described_class.new('name', sudo_wrapper) }

    describe "with fixed rootfs" do
      before do
        subject.stub(rootfs_path: Pathname('/path/to/rootfs'), system: true)
        subject.share_folders(folders)
      end

      it 'adds a mount.entry to its local customizations' do
        expect(subject.customizations).to include [
          'mount.entry',
          "#{shared_folder[:hostpath]} #{expected_guest_path} none bind,create=dir 0 0"
        ]
      end

      it 'supports additional mount options' do
        expect(subject.customizations).to include [
          'mount.entry',
          "#{ro_rw_folder[:hostpath]} vagrant/ro_rw none ro,rw 0 0"
        ]
      end

      it 'supports directories with spaces' do
        expect(subject.customizations).to include [
          'mount.entry',
          "/path/with\\040space tmp/with\\040space none bind,create=dir 0 0"
        ]
      end
    end

    describe "with directory-based LXC config" do
      let(:config_string) {
        <<-ENDCONFIG.gsub(/^\s+/, '')
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
      }

      before do
        subject { described_class.new('name', sudo_wrapper) }
        subject.stub(config_string: config_string)
        subject.share_folders(folders)
      end

      it 'adds a mount.entry to its local customizations' do
        expect(subject.customizations).to include [
          'mount.entry',
          "#{shared_folder[:hostpath]} #{expected_guest_path} none bind,create=dir 0 0"
        ]
      end
    end

    describe "with overlayfs-based LXC config" do
      let(:config_string) {
        <<-ENDCONFIG.gsub(/^\s+/, '')
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
      }

      before do
        subject { described_class.new('name', sudo_wrapper) }
        subject.stub(config_string: config_string)
        subject.share_folders(folders)
      end

      it 'adds a mount.entry to its local customizations' do
        expect(subject.customizations).to include [
          'mount.entry',
          "#{shared_folder[:hostpath]} #{expected_guest_path} none bind,create=dir 0 0"
        ]
      end
    end
  end
end
