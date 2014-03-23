require 'unit_helper'

require 'tmpdir'
require 'vagrant-lxc/provider'
require 'vagrant-lxc/action/forward_ports'

describe Vagrant::LXC::Action::ForwardPorts do
  let(:app)          { double(:app, call: true) }
  let(:env)          { {machine: machine, ui: double(info: true)} }
  let(:machine)      { double(:machine) }
  let!(:data_dir)    { Pathname.new(Dir.mktmpdir) }
  let(:provider)     { double(Vagrant::LXC::Provider, ssh_info: {host: container_ip}) }
  let(:host_ip)      { '127.0.0.1' }
  let(:host_port)    { 80 }
  let(:guest_port)   { 80 }
  let(:container_ip) { '10.0.1.234' }
  let(:pid)          { 'a-pid' }
  let(:forward_conf) { {guest: guest_port, host: host_port, host_ip: host_ip} }
  let(:networks)     { [[:other_config, {}], [:forwarded_port, forward_conf]] }

  subject { described_class.new(app, env) }

  before do
    machine.stub_chain(:config, :vm, :networks).and_return(networks)
    machine.stub(provider: provider, data_dir: data_dir)

    subject.stub(exec: true)
    subject.stub(spawn: pid)
  end

  after { FileUtils.rm_rf data_dir.to_s }

  it 'forwards ports using redir' do
    subject.stub(system: true)
    subject.call(env)
    expect(subject).to have_received(:spawn).with(
      "sudo redir --laddr=#{host_ip} --lport=#{host_port} --caddr=#{container_ip} --cport=#{guest_port} 2>/dev/null"
    )
  end

  it 'skips --laddr parameter if host_ip is nil' do
    forward_conf.delete(:host_ip)
    subject.stub(system: true)
    subject.call(env)
    expect(subject).to have_received(:spawn).with(
      "sudo redir --lport=#{host_port} --caddr=#{container_ip} --cport=#{guest_port} 2>/dev/null"
    )
  end

  it 'skips --laddr parameter if host_ip is a blank string' do
    forward_conf[:host_ip] = ' '
    subject.stub(system: true)
    subject.call(env)
    expect(subject).to have_received(:spawn).with(
      "sudo redir --lport=#{host_port} --caddr=#{container_ip} --cport=#{guest_port} 2>/dev/null"
    )
  end

  it "stores redir pids on machine's data dir" do
    subject.stub(system: true)
    subject.call(env)
    pid_file = data_dir.join('pids', "redir_#{host_port}.pid").read
    expect(pid_file).to eq(pid)
  end

  it 'allows disabling a previously forwarded port' do
    forward_conf[:disabled] = true
    subject.stub(system: true)
    subject.call(env)
    expect(subject).not_to have_received(:spawn)
  end

  it 'raises RedirNotInstalled error if `redir` is not installed' do
    subject.stub(system: false)
    expect { subject.call(env) }.to raise_error(Vagrant::LXC::Errors::RedirNotInstalled)
  end
end
