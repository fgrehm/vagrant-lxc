require 'unit_helper'

require 'vagrant-lxc/sudo_wrapper'
require 'vagrant-lxc/driver/cli'

describe Vagrant::LXC::Driver::CLI do
  let(:sudo_wrapper) { double(Vagrant::LXC::SudoWrapper, run: true) }

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
    let(:lxc_version_out) { "lxc version:  0.x.y-rc1\n" }

    before do
      allow(subject).to receive(:run).with(:version).and_return(lxc_version_out)
    end

    it 'parses the version from the output' do
      expect(subject.version).to eq('0.x.y-rc1')
    end
  end

  describe 'create' do
    let(:template)      { 'quantal-64' }
    let(:name)          { 'quantal-container' }
    let(:config_file)   { 'config' }
    let(:template_args) { { '--extra-param' => 'param', '--other' => 'value' } }

    subject { described_class.new(sudo_wrapper, name) }

    before do
      allow(subject).to receive(:run) { |*args| @run_args = args }
    end

    it 'issues a lxc-create with provided template, container name and hash of arguments' do
      subject.create(template, config_file, template_args)
      expect(subject).to have_received(:run).with(
        :create,
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
        subject.create(template, config_file, template_args)
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

  describe 'shutdown' do
    let(:name) { 'a-running-container' }
    subject    { described_class.new(sudo_wrapper, name) }

    before do
      subject.stub(system: true)
      allow(subject).to receive(:run)
    end

    it 'issues a lxc-shutdown with provided container name' do
      subject.shutdown
      expect(subject).to have_received(:run).with(:shutdown, '--name', name)
    end

    it 'raises a ShutdownNotSupported in case it is not supported' do
      allow(subject).to receive(:system).with('which lxc-shutdown > /dev/null').and_return(false)
      expect { subject.shutdown }.to raise_error(described_class::ShutdownNotSupported)
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
    let(:name) { 'a-running-container' }
    subject    { described_class.new(name) }

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
end
