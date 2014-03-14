require 'unit_helper'

require 'vagrant'
require 'vagrant-lxc/errors'
require 'vagrant-lxc/action/handle_box_metadata'

describe Vagrant::LXC::Action::HandleBoxMetadata do
  let(:app)           { double(:app, call: true) }
  let(:env)           { {machine: machine, ui: double(info: true, warn: true)} }
  let(:machine)       { double(:machine, box: box) }
  let(:box)           { double(:box, name: 'box-name', metadata: metadata, directory: box_directory) }
  let(:box_directory) { Pathname.new('/path/to/box') }
  let(:version)       { '2' }
  let(:metadata)      { {'template-opts' => {'--foo' => 'bar'}, 'version' => version} }
  let(:vagrant_key)   { Vagrant.source_root.join('keys', 'vagrant.pub').expand_path.to_s }

  subject { described_class.new(app, env) }

  context 'with 1.0.0 box' do
    let(:version) { '1.0.0' }

    before do
      File.stub(exists?: true)
      # REFACTOR: This is pretty bad
      subject.stub_chain(:template_config_file, :exist?).and_return(true)
      subject.stub_chain(:template_config_file, :to_s).and_return(box_directory.join('lxc-config').to_s)
      subject.call(env)
    end

    it 'sets the tarball argument for the template' do
      env[:lxc_template_opts].should include(
        '--tarball' => box_directory.join('rootfs.tar.gz').to_s
      )
    end

    it 'sets the template --config parameter' do
      env[:lxc_template_opts].should include(
        '--config' => box_directory.join('lxc-config').to_s
      )
    end

    it 'does not set the auth key argument for the template' do
      env[:lxc_template_opts].should_not include(
        '--auth-key' => vagrant_key
      )
    end

    it 'sets the template options from metadata on env hash' do
      env[:lxc_template_opts].should include(metadata['template-opts'])
    end

    it 'sets the template source path on env hash' do
      env[:lxc_template_src].should == box_directory.join('lxc-template').to_s
    end

    it 'does not warn about deprecation' do
      env[:ui].should_not have_received(:warn)
    end
  end

  context 'with valid pre 1.0.0 box' do
    before do
      File.stub(exists?: true)
      # REFACTOR: This is pretty bad
      subject.stub_chain(:old_template_config_file, :exist?).and_return(true)
      subject.stub_chain(:old_template_config_file, :to_s).and_return(box_directory.join('lxc.conf').to_s)
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

    it 'sets the lxc config file parameter' do
      env[:lxc_template_config].should == box_directory.join('lxc.conf').to_s
    end

    it 'sets the template options from metadata on env hash' do
      env[:lxc_template_opts].should include(metadata['template-opts'])
    end

    it 'sets the template source path on env hash' do
      env[:lxc_template_src].should == box_directory.join('lxc-template').to_s
    end

    it 'warns about deprecation' do
      env[:ui].should have_received(:warn)
    end
  end

  describe 'with invalid contents' do
    before { File.stub(exists?: true) }

    it 'validates box versions' do
      %w( 2 3 1.0.0 ).each do |v|
        metadata['version'] = v
        expect { subject.call(env) }.to_not raise_error
      end

      metadata['version'] = '1'
      expect { subject.call(env) }.to raise_error
    end

    it 'raises an error if the rootfs tarball cant be found' do
      File.stub(:exists?).with(box_directory.join('rootfs.tar.gz').to_s).and_return(false)
      expect {
        subject.call(env)
      }.to raise_error(Vagrant::LXC::Errors::RootFSTarballMissing)
    end

    it 'does not raise an error if the lxc-template script cant be found' do
      File.stub(:exists?).with(box_directory.join('lxc-template').to_s).and_return(false)
      expect {
        subject.call(env)
      }.to_not raise_error
    end
  end
end
