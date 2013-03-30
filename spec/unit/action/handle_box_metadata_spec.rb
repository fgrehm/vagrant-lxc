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
  let(:tmpdir)        { '/tmp/rootfs/dir' }

  subject { described_class.new(app, env) }

  before do
    Dir.stub(mktmpdir: tmpdir)
    File.stub(exists?: true)
    subject.stub(:system)
    subject.call(env)
  end

  it 'creates a tmp directory to store rootfs-cache-path' do
    metadata['rootfs-cache-path'].should == tmpdir
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

  it 'extracts rootfs into a tmp folder' do
    subject.should have_received(:system).
                   with(%Q[sudo su root -c "cd #{box_directory} && tar xfz rootfs.tar.gz -C #{tmpdir} 2>/dev/null"])
  end
end
