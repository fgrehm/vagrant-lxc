require 'unit_helper'

require 'tmpdir'
require 'vagrant-lxc/errors'
require 'vagrant-lxc/action/forward_ports'

describe Vagrant::LXC::Action::ForwardPorts do
  let(:app)          { double(:app, call: true) }
  let(:env)          { {machine: machine, ui: double(info: true)} }
  let(:machine)      { double(:machine) }
  let!(:data_dir)    { Pathname.new(Dir.mktmpdir) }
  let(:networks)     { [[:other_config, {}], [:forwarded_port, {guest: guest_port, host: host_port}]] }
  let(:host_port)    { 8080 }
  let(:guest_port)   { 80 }
  let(:provider)     { instance_double('Vagrant::LXC::Provider', driver: driver) }
  let(:driver)       { instance_double('Vagrant::LXC::Driver', assigned_ip: container_ip) }
  let(:container_ip) { '10.0.1.234' }
  let(:pid)          { 'a-pid' }

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
    subject.should have_received(:spawn).with(
      "sudo redir --laddr=127.0.0.1 --lport=#{host_port} --caddr=#{container_ip} --cport=#{guest_port} 2>/dev/null"
    )
  end

  it "stores redir pids on machine's data dir" do
    subject.stub(system: true)
    subject.call(env)
    pid_file = data_dir.join('pids', "redir_#{host_port}.pid").read
    pid_file.should == pid
  end

  it 'raises RedirNotInstalled error if `redir` is not installed' do
    subject.stub(system: false)
    lambda { subject.call(env) }.should raise_error(Vagrant::LXC::Errors::RedirNotInstalled)
  end
end
