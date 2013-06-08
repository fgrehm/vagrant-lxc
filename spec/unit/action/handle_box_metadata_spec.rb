require 'unit_helper'

require 'vagrant'
require 'vagrant-lxc/errors'
require 'vagrant-lxc/action/handle_box_metadata'

describe Vagrant::LXC::Action::HandleBoxMetadata do
  let(:app)           { mock(:app, call: true) }
  let(:env)           { {machine: machine, ui: stub(info: true)} }
  let(:machine)       { mock(:machine, box: box) }
  let(:box)           { mock(:box, name: 'box-name', metadata: metadata, directory: box_directory) }
  let(:box_directory) { Pathname.new('/path/to/box') }
  let(:version)       { '2' }
  let(:metadata)      { {'template-opts' => {'--foo' => 'bar'}, 'version' => version} }
  let(:vagrant_key)   { Vagrant.source_root.join('keys', 'vagrant.pub').expand_path.to_s }

  subject { described_class.new(app, env) }

  context 'with valid contents' do
    before do
      File.stub(exists?: true)
      subject.call(env)
    end

    it 'sets the tarball argument for the template' do
      env[:lxc_template_opts].should include(
        '--tarball' => box_directory.join('rootfs.tar.gz').to_s
      )
    end

    it 'sets the auth key argument for the template' do
      env[:lxc_template_opts].should include(
        '--auth-key' => vagrant_key
      )
    end

    it 'sets the template options from metadata on env hash' do
      env[:lxc_template_opts].should include(metadata['template-opts'])
    end

    it 'sets the template source path on env hash' do
      env[:lxc_template_src].should == box_directory.join('lxc-template').to_s
    end
  end

  describe 'with invalid contents' do
    before { File.stub(exists?: true) }

    it 'raises an error if the version is != 2' do
      metadata['version'] = '1'
      expect {
        subject.call(env)
      }.to raise_error(Vagrant::LXC::Errors::IncompatibleBox)
    end

    it 'raises an error if the rootfs tarball cant be found' do
      File.stub(:exists?).with(box_directory.join('rootfs.tar.gz').to_s).and_return(false)
      expect {
        subject.call(env)
      }.to raise_error(Vagrant::LXC::Errors::RootFSTarballMissing)
    end

    it 'raises an error if the lxc-template script cant be found' do
      File.stub(:exists?).with(box_directory.join('lxc-template').to_s).and_return(false)
      expect {
        subject.call(env)
      }.to raise_error(Vagrant::LXC::Errors::TemplateFileMissing)
    end
  end
end
