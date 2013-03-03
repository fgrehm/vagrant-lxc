require 'unit_helper'

require 'vagrant-lxc/action/handle_box_metadata'

describe Vagrant::LXC::Action::HandleBoxMetadata do
  let(:tar_cache)     { 'template.zip' }
  let(:template_name) { 'ubuntu-lts' }
  let(:after_create)  { 'setup-vagrant-user.sh' }
  let(:metadata)      { {'template-name' => template_name, 'tar-cache' => tar_cache, 'after-create-script' => after_create} }
  let(:box)						{ mock(:box, name: 'box-name', metadata: metadata, directory: Pathname.new('/path/to/box')) }
  let(:machine)       { mock(:machine, box: box) }
  let(:app)           { mock(:app, call: true) }
  let(:env)           { {machine: machine} }

  subject { described_class.new(app, env) }

  before do
    subject.stub(:system)
    subject.call(env)
  end

  it 'sets box directory as lxc-cache-path' do
    metadata['lxc-cache-path'].should == box.directory.to_s
  end

  it 'prepends box directory to after-create-script' do
    metadata['after-create-script'].should == "#{box.directory.to_s}/#{after_create}"
  end

  it 'prepends vagrant and box name to template-name' do
    metadata['template-name'].should == "vagrant-#{box.name}-#{template_name}"
  end

  it 'copies box template file to the right folder' do
    src  = box.directory.join(template_name).to_s
    dest = "/usr/share/lxc/templates/lxc-#{metadata['template-name']}"
    subject.should have_received(:system).with("sudo su root -c \"cp #{src} #{dest}\"")
  end
end
