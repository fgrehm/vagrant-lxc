require 'unit_helper'

require 'vagrant-lxc/action/forward_ports'

describe Vagrant::LXC::Action::ForwardPorts do
  let(:app)          { mock(:app, call: true) }
  let(:env)          { {machine: machine, ui: stub(info: true)} }
  let(:machine)      { mock(:machine) }
  let!(:data_dir)    { Pathname.new(Dir.mktmpdir) }
  let(:networks)     { [[:other_config, {}], [:forwarded_port, {guest: guest_port, host: host_port}]] }
  let(:host_port)    { 8080 }
  let(:guest_port)   { 80 }
  let(:provider)     { fire_double('Vagrant::LXC::Provider', container: container) }
  let(:container)    { fire_double('Vagrant::LXC::Container', assigned_ip: container_ip) }
  let(:container_ip) { '10.0.1.234' }
  let(:pid)          { 'a-pid' }

  subject { described_class.new(app, env) }

  before do
    machine.stub_chain(:config, :vm, :networks).and_return(networks)
    machine.stub(provider: provider, data_dir: data_dir)

    subject.stub(exec: true)
    subject.stub(:fork) { |&block| block.call; pid }
    subject.call(env)
  end

  after { FileUtils.rm_rf data_dir.to_s }

  it 'forwards ports using redir' do
    subject.should have_received(:exec).with(
      "sudo redir --laddr=127.0.0.1 --lport=#{host_port} --cport=#{guest_port} --caddr=#{container_ip}"
    )
  end

  it "stores redir pids on machine's data dir" do
    pid_file = data_dir.join('pids', "redir_#{host_port}.pid").read
    pid_file.should == pid
  end
end
