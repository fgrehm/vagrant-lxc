require 'unit_helper'

require 'vagrant-lxc/action/compress_rootfs'

describe Vagrant::LXC::Action::CompressRootFS do
  let(:app)                    { mock(:app, call: true) }
  let(:env)                    { {machine: machine, ui: stub(info: true)} }
  let(:machine)                { fire_double('Vagrant::Machine', provider: provider) }
  let(:provider)               { fire_double('Vagrant::LXC::Provider', container: container) }
  let(:container)              { fire_double('Vagrant::LXC::Container', compress_rootfs: compressed_rootfs_path) }
  let(:compressed_rootfs_path) { '/path/to/rootfs.tar.gz' }

  subject { described_class.new(app, env) }

  before do
    provider.stub_chain(:state, :id).and_return(:stopped)
    subject.call(env)
  end

  it 'asks the container to compress its rootfs' do
    container.should have_received(:compress_rootfs)
  end

  it 'sets export.temp_dir on action env' do
    env['package.rootfs'].should == compressed_rootfs_path
  end
end
