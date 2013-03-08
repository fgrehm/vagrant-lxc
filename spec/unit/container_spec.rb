require 'unit_helper'

require 'vagrant-lxc/container'

describe Vagrant::LXC::Container do
  # Default subject and container name for specs
  let(:name) { nil }
  subject { described_class.new(name) }

  describe 'container name validation' do
    let(:unknown_container) { described_class.new('unknown') }
    let(:valid_container)   { described_class.new('valid') }
    let(:new_container)     { described_class.new(nil) }

    before do
      unknown_container.stub(lxc: 'valid')
      valid_container.stub(lxc: 'valid')
    end

    it 'raises a NotFound error if an unknown container name gets provided' do
      expect {
        unknown_container.validate!
      }.to raise_error(Vagrant::LXC::Container::NotFound)
    end

    it 'does not raise a NotFound error if a valid container name gets provided' do
      expect {
        valid_container.validate!
      }.to_not raise_error(Vagrant::LXC::Container::NotFound)
    end

    it 'does not raise a NotFound error if nil is provider as name' do
      expect {
        new_container.validate!
      }.to_not raise_error(Vagrant::LXC::Container::NotFound)
    end
  end

  describe 'lxc commands execution' do
    let(:args) { @args }

    before do
      subject.stub(:execute) { |*args| @args = args }
      subject.lxc :command, '--state', 'RUNNING'
    end

    it 'prepends sudo' do
      args[0].should == 'sudo'
    end

    it 'uses the first argument as lxc command suffix' do
      args[1].should == 'lxc-command'
    end

    it 'pass through remaining arguments' do
      args[2].should == '--state'
      args[3].should == 'RUNNING'
    end
  end

  describe 'guard for container state' do
    let(:name) { 'random-container-name' }

    before do
      subject.stub :lxc
      subject.wait_until :running
    end

    it 'runs lxc-wait with the machine id and upcased state' do
      subject.should have_received(:lxc).with(
        :wait,
        '--name', name,
        '--state', 'RUNNING'
      )
    end
  end

  describe 'creation' do
    let(:name)            { 'random-container-name' }
    let(:template_name)   { 'template-name' }
    let(:rootfs_cache)    { '/path/to/cache' }
    let(:public_key_path) { Vagrant.source_root.join('keys', 'vagrant.pub').expand_path.to_s }

    before do
      subject.stub(lxc: true)
      SecureRandom.stub(hex: name)
      subject.create 'template-name' => template_name, 'rootfs-cache-path' => rootfs_cache, 'template-opts' => { '--foo' => 'bar'}
    end

    it 'calls lxc-create with the right arguments' do
      subject.should have_received(:lxc).with(
        :create,
        '--template', template_name,
        '--name', name,
        '--',
        '--auth-key', public_key_path,
        '--cache', rootfs_cache,
        '--foo', 'bar'
      )
    end
  end

  describe 'destruction' do
    let(:name) { 'container-name' }

    before do
      subject.stub(lxc: true)
      subject.destroy
    end

    it 'calls lxc-destroy with the right arguments' do
      subject.should have_received(:lxc).with(
        :destroy,
        '--name', name,
      )
    end
  end

  describe 'start' do
    let(:config) { mock(:config, start_opts: ['a=1', 'b=2']) }
    let(:name)   { 'container-name' }

    before do
      subject.stub(lxc: true, wait_until: true)
      subject.start(config)
    end

    it 'calls lxc-start with the right arguments' do
      subject.should have_received(:lxc).with(
        :start,
        '-d',
        '--name', name,
        '-s', 'a=1',
        '-s', 'b=2'
      )
    end

    it 'waits for container state to be RUNNING' do
      subject.should have_received(:wait_until).with(:running)
    end
  end

  describe 'halt' do
    let(:name) { 'random-container-name' }

    before do
      subject.stub(lxc: true, wait_until: true)
      subject.halt
    end

    it 'calls lxc-shutdown with the right arguments' do
      subject.should have_received(:lxc).with(
        :shutdown,
        '--name', name
      )
    end

    it 'waits for container state to be STOPPED' do
      subject.should have_received(:wait_until).with(:stopped)
    end
  end

  describe 'state' do
    let(:name) { 'random-container-name' }

    before do
      subject.stub(lxc: "state: STOPPED\npid: 2")
    end

    it 'calls lxc-info with the right arguments' do
      subject.state
      subject.should have_received(:lxc).with(
        :info,
        '--name', name
      )
    end

    it 'maps the output of lxc-info status out to a symbol' do
      subject.state.should == :stopped
    end
  end

  describe 'dhcp ip' do
    let(:name) { 'random-container-name' }
    let(:ip)   { "10.0.3.123" }

    before do
      subject.stub(:raw) {
        mock(stdout: "#{ip}\n", exit_code: 0)
      }
    end

    it 'digs the container ip from lxc dns server' do
      subject.dhcp_ip.should == ip
      subject.should have_received(:raw).with('dig', name, '@10.0.3.1', '+short')
    end
  end
end
