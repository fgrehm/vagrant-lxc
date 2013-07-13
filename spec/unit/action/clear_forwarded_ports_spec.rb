require 'unit_helper'

require 'vagrant-lxc/action/clear_forwarded_ports'

describe Vagrant::LXC::Action::ClearForwardedPorts do
  let(:app)       { double(:app, call: true) }
  let(:env)       { {machine: machine, ui: double(info: true)} }
  let(:machine)   { double(:machine, data_dir: data_dir) }
  let!(:data_dir) { Pathname.new(Dir.mktmpdir) }
  let(:pids_dir)  { data_dir.join('pids') }
  let(:pid)       { 'a-pid' }
  let(:pid_cmd)   { 'redir' }

  subject { described_class.new(app, env) }

  before do
    pids_dir.mkdir
    pids_dir.join('redir_1234.pid').open('w') { |f| f.write(pid) }
    subject.stub(system: true, :` => pid_cmd)
    subject.call(env)
  end

  after { FileUtils.rm_rf data_dir.to_s }

  it 'removes all files under pid directory' do
    Dir[pids_dir.to_s + "/redir_*.pid"].should be_empty
  end

  context 'with a valid redir pid' do
    it 'kills known processes' do
      subject.should have_received(:system).with("sudo pkill -TERM -P #{pid}")
    end
  end

  context 'with an invalid pid' do
    let(:pid_cmd) { 'sudo ls' }

    it 'does not kill the process' do
      subject.should_not have_received(:system).with("sudo pkill -TERM -P #{pid}")
    end
  end
end
