require 'unit_helper'

require 'vagrant-lxc/action/base_action'
require 'vagrant-lxc/action/handle_box_metadata'

describe Vagrant::LXC::Action::HandleBoxMetadata do
  let(:metadata)      { {'template-opts' => {'--foo' => 'bar'}} }
  let(:box)           { mock(:box, name: 'box-name', metadata: metadata, directory: box_directory) }
  let(:box_directory) { Pathname.new('/path/to/box') }
  let(:machine)       { mock(:machine, box: box) }
  let(:app)           { mock(:app, call: true) }
  let(:env)           { {machine: machine, ui: stub(info: true)} }

  subject { described_class.new(app, env) }

  before do
    File.stub(exists?: true)
    subject.stub(:system)
    subject.call(env)
  end

  it 'sets the rootfs-tarball path on metadata hash' do
    metadata['rootfs-tarball'].should == box_directory.join('rootfs.tar.gz')
  end

  it 'prepends vagrant and box name to template-name' do
    metadata['template-name'].should == "vagrant-#{box.name}"
  end

  it 'copies box template file to the right folder' do
    src  = box_directory.join('lxc-template').to_s
    dest = "/usr/share/lxc/templates/lxc-#{metadata['template-name']}"

    subject.should have_received(:system).
                   with("sudo su root -c \"cp #{src} #{dest}\"")
  end
end
