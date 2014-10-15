require 'unit_helper'

require 'vagrant-lxc/sudo_wrapper'
require 'vagrant-lxc/driver/cli'

describe Vagrant::LXC::Driver::CLI do
  let(:sudo_wrapper) { double(Vagrant::LXC::SudoWrapper, run: true, wrapper_path: nil) }

  subject { described_class.new(sudo_wrapper) }

  describe 'list' do
    let(:lxc_ls_out) { "dup-container\na-container dup-container" }
    let(:result)     { @result }

    before do
      allow(subject).to receive(:run).with(:ls).and_return(lxc_ls_out)
      @result = subject.list
    end

    it 'grabs previously created containers from lxc-ls output' do
      expect(result).to be_an Enumerable
      expect(result).to include 'a-container'
      expect(result).to include 'dup-container'
    end

    it 'removes duplicates from lxc-ls output' do
      expect(result.uniq).to eq(result)
    end
  end

  describe 'version' do
    before do
      allow(subject).to receive(:run).with(:version).and_return(lxc_version_out)
    end

    describe 'lxc version before 1.x.x' do
      let(:lxc_version_out) { "lxc version:  0.x.y-rc1\n" }

      it 'parses the version from the output' do
        expect(subject.version).to eq('0.x.y-rc1')
      end
    end

    describe 'lxc version after 1.x.x' do
      let(:lxc_version_out) { "1.0.0\n" }

      it 'parses the version from the output' do
        expect(subject.version).to eq('1.0.0')
      end
    end
  end

  describe 'config' do
    before do
      allow(subject).to receive(:run).with(:config, 'lxc.lxcpath').and_return(lxc_config_out)
      allow(subject).to receive(:run).with(:version).and_return(lxc_version_out)
      allow(subject).to receive(:run).with(:create, '--version').and_return(lxc_version_out)
    end

    describe 'lxc version before 1.x.x' do
      let(:support_version_command?) { true }
      let(:lxc_config_out)           { "/var/lib/lxc\n" }
      let(:lxc_version_out)          { "lxc version:  0.x.y-rc1\n" }

      it 'not supported' do
        expect{subject.config('lxc.lxcpath')}.to raise_error(Vagrant::LXC::Errors::CommandNotSupported)
      end
    end

    describe 'lxc version before after 1.x.x'do
      let(:support_version_command?) { false }
      let(:lxc_config_out)           { "/var/lib/lxc\n" }
      let(:lxc_version_out)          { "1.0.0\n" }

      it 'parser the lxc.lxcpath value' do
        expect(subject.config('lxc.lxcpath')).not_to end_with("\n")
      end
    end
  end

  describe 'create' do
    let(:template)          { 'quantal-64' }
    let(:name)              { 'quantal-container' }
    let(:backingstore)      { 'btrfs' }
    let(:backingstore_opts) { [['--dir', '/tmp/foo'], ['--foo', 'bar']] }
    let(:config_file)       { 'config' }
    let(:template_args)     { { '--extra-param' => 'param', '--other' => 'value' } }

    subject { described_class.new(sudo_wrapper, name) }

    before do
      allow(subject).to receive(:run) { |*args| @run_args = args }
    end

    it 'issues a lxc-create with provided template, container name and hash of arguments' do
      subject.create(template, backingstore, backingstore_opts, config_file, template_args)
      expect(subject).to have_received(:run).with(
        :create,
        '-B',         backingstore,
        *(backingstore_opts.flatten),
        '--template', template,
        '--name',     name,
        '-f',         config_file,
        '--',
        '--extra-param', 'param',
        '--other',       'value'
      )
    end

    it 'wraps a low level error into something more meaningful in case the container already exists' do
      allow(subject).to receive(:run) { raise Vagrant::LXC::Errors::ExecuteError, stderr: 'alreAdy Exists' }
      expect {
        subject.create(template, backingstore, backingstore_opts, config_file, template_args)
      }.to raise_error(Vagrant::LXC::Errors::ContainerAlreadyExists)
    end
  end

  describe 'destroy' do
    let(:name) { 'a-container-for-destruction' }

    subject { described_class.new(sudo_wrapper, name) }

    before do
      allow(subject).to receive(:run)
      subject.destroy
    end

    it 'issues a lxc-destroy with container name' do
      expect(subject).to have_received(:run).with(:destroy, '--name', name)
    end
  end

  describe 'start' do
    let(:name) { 'a-container' }
    subject    { described_class.new(sudo_wrapper, name) }

    before do
      allow(subject).to receive(:run)
    end

    it 'starts container on the background' do
      subject.start
      expect(subject).to have_received(:run).with(
        :start,
        '-d',
        '--name',  name
      )
    end
  end

  describe 'stop' do
    let(:name) { 'a-running-container' }
    subject    { described_class.new(sudo_wrapper, name) }

    before do
      allow(subject).to receive(:run)
    end

    context 'lxc-attach is supported' do
      before do
        subject.stub(attach: true, supports_attach?: true)
        subject.stop
      end

      it 'runs a /sbin/halt within the container' do
        expect(subject).to have_received(:attach).with('/sbin/halt')
      end

      it 'issues a lxc-stop with provided container name' do
        expect(subject).to have_received(:run).with(:stop, '--name', name)
      end
    end

    context 'lxc-attach is not supported' do
      before do
        subject.stub(attach: false, supports_attach?: false)
        subject.stop
      end

      it 'runs a /sbin/halt within the container' do
        expect(subject).to_not have_received(:attach)
      end

      it 'issues a lxc-stop with provided container name' do
        expect(subject).to have_received(:run).with(:stop, '--name', name)
      end
    end
  end

  describe 'state' do
    let(:name) { 'a-container' }
    subject    { described_class.new(sudo_wrapper, name) }

    before do
      allow(subject).to receive(:run).and_return("state: STOPPED\npid: 2")
    end

    it 'calls lxc-info with the right arguments' do
      subject.state
      expect(subject).to have_received(:run).with(:info, '--name', name, retryable: true)
    end

    it 'maps the output of lxc-info status out to a symbol' do
      expect(subject.state).to eq(:stopped)
    end

    it 'is not case sensitive' do
      allow(subject).to receive(:run).and_return("StatE: STarTED\npid: 2")
      expect(subject.state).to eq(:started)
    end
  end

  describe 'attach' do
    let(:name)           { 'a-running-container' }
    let(:command)        { ['ls', 'cat /tmp/file'] }
    let(:command_output) { 'folders list' }
    subject              { described_class.new(sudo_wrapper, name) }

    before do
      subject.stub(run: command_output)
    end

    it 'calls lxc-attach with specified command' do
      subject.attach(*command)
      expect(subject).to have_received(:run).with(:attach, '--name', name, '--', *command)
    end

    it 'supports a "namespaces" parameter' do
      allow(subject).to receive(:run).with(:attach, '-h', :show_stderr => true).and_return({:stdout => '', :stderr => '--namespaces'})
      subject.attach *(command + [{namespaces: ['network', 'mount']}])
      expect(subject).to have_received(:run).with(:attach, '--name', name, '--namespaces', 'NETWORK|MOUNT', '--', *command)
    end

    it 'raises a NamespacesNotSupported error if not supported' do
      allow(subject).to receive(:run).with(:attach, '-h', :show_stderr => true).and_return({:stdout => '', :stderr => 'not supported'})
      expect {
        subject.attach *(command + [{namespaces: ['network', 'mount']}])
      }.to raise_error(Vagrant::LXC::Errors::NamespacesNotSupported)
    end
  end

  describe 'transition block' do
    before do
      subject.stub(run: true, sleep: true, state: :stopped)
    end

    it 'yields a cli object' do
      allow(subject).to receive(:shutdown)
      subject.transition_to(:stopped) { |c| c.shutdown }
      expect(subject).to have_received(:shutdown)
    end

    it 'throws an exception if block is not provided' do
      expect {
        subject.transition_to(:running)
      }.to raise_error(described_class::TransitionBlockNotProvided)
    end

    skip 'waits for the expected container state'
  end

  describe 'check for whether lxc-attach is supported' do
    let(:name) { 'a-running-container' }
    subject    { described_class.new(sudo_wrapper, name) }

    context 'lxc-attach is present on system' do
      before { subject.stub(run: true) }

      it 'returns true if `lxc-attach --name CNAME -- /bin/true` works' do
        expect(subject.supports_attach?).to be_truthy
        expect(subject).to have_received(:run).with(
          :attach, '--name', name, '--', '/bin/true'
        )
      end
    end

    context 'lxc-attach is not present on system' do
      before do
        allow(subject).to receive(:run).and_raise(Vagrant::LXC::Errors::ExecuteError.new('msg'))
      end

      it 'returns true if `lxc-attach --name CNAME -- /bin/true` works' do
        expect(subject.supports_attach?).to be_falsy
        expect(subject).to have_received(:run).with(
          :attach, '--name', name, '--', '/bin/true'
        )
      end
    end
  end
end
