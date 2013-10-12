require 'unit_helper'

require 'vagrant-lxc/driver/cli'

describe Vagrant::LXC::Driver::CLI do
  let(:sudo_wrapper) { instance_double('Vagrant::LXC::SudoWrapper', run: true) }

  subject { described_class.new(sudo_wrapper) }

  describe 'list' do
    let(:lxc_ls_out) { "dup-container\na-container dup-container" }
    let(:result)     { @result }

    before do
      subject.stub(:run).with(:ls).and_return(lxc_ls_out)
      @result = subject.list
    end

    it 'grabs previously created containers from lxc-ls output' do
      result.should be_an Enumerable
      result.should include 'a-container'
      result.should include 'dup-container'
    end

    it 'removes duplicates from lxc-ls output' do
      result.uniq.should == result
    end
  end

  describe 'version' do
    let(:lxc_version_out) { "lxc version:  0.x.y-rc1\n" }

    before do
      subject.stub(:run).with(:version).and_return(lxc_version_out)
    end

    it 'parses the version from the output' do
      subject.version.should == '0.x.y-rc1'
    end
  end

  describe 'create' do
    let(:template)      { 'quantal-64' }
    let(:name)          { 'quantal-container' }
    let(:config_file)   { 'config' }
    let(:template_args) { { '--extra-param' => 'param', '--other' => 'value' } }

    subject { described_class.new(sudo_wrapper, name) }

    before do
      subject.stub(:run) { |*args| @run_args = args }
      subject.create(template, config_file, template_args)
    end

      it 'issues a lxc-create with provided template, container name and hash of arguments' do
        subject.should have_received(:run).with(
          :create,
          '--template', template,
          '--name',     name,
          '-f',         config_file,
          '--',
          '--extra-param', 'param',
          '--other',       'value'
        )
      end
  end

  describe 'destroy' do
    let(:name) { 'a-container-for-destruction' }

    subject { described_class.new(sudo_wrapper, name) }

    before do
      subject.stub(:run)
      subject.destroy
    end

    it 'issues a lxc-destroy with container name' do
      subject.should have_received(:run).with(:destroy, '--name', name)
    end
  end

  describe 'start' do
    let(:name) { 'a-container' }
    subject    { described_class.new(sudo_wrapper, name) }

    before do
      subject.stub(:run)
    end

    it 'starts container on the background' do
      subject.start
      subject.should have_received(:run).with(
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
      subject.stub(:run)
      subject.shutdown
    end

    it 'issues a lxc-shutdown with provided container name' do
      subject.should have_received(:run).with(:shutdown, '--name', name)
    end
  end

  describe 'state' do
    let(:name) { 'a-container' }
    subject    { described_class.new(sudo_wrapper, name) }

    before do
      subject.stub(:run).and_return("state: STOPPED\npid: 2")
    end

    it 'calls lxc-info with the right arguments' do
      subject.state
      subject.should have_received(:run).with(:info, '--name', name, retryable: true)
    end

    it 'maps the output of lxc-info status out to a symbol' do
      subject.state.should == :stopped
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
      subject.should have_received(:run).with(:attach, '--name', name, '--', *command)
    end

    it 'supports a "namespaces" parameter' do
      subject.stub(:run).with(:attach, '-h', :show_stderr => true).and_return({:stdout => '', :stderr => '--namespaces'})
      subject.attach *(command + [{namespaces: ['network', 'mount']}])
      subject.should have_received(:run).with(:attach, '--name', name, '--namespaces', 'NETWORK|MOUNT', '--', *command)
    end

    it 'raises a NamespacesNotSupported error if not supported' do
      subject.stub(:run).with(:attach, '-h', :show_stderr => true).and_return({:stdout => '', :stderr => 'not supported'})
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
      subject.stub(:shutdown)
      subject.transition_to(:stopped) { |c| c.shutdown }
      subject.should have_received(:shutdown)
    end

    it 'throws an exception if block is not provided' do
      expect {
        subject.transition_to(:running)
      }.to raise_error(described_class::TransitionBlockNotProvided)
    end

    pending 'waits for the expected container state'
  end
end
