require 'unit_helper'

require 'vagrant-lxc/action/setup_package_files'

describe Vagrant::LXC::Action::SetupPackageFiles do
  let(:app)         { mock(:app, call: true) }
  let(:env)         { {machine: machine, tmp_path: tmp_path, ui: stub(info: true), 'package.rootfs' => rootfs_path} }
  let(:machine)     { fire_double('Vagrant::Machine', box: box) }
  let!(:tmp_path)   { Pathname.new(Dir.mktmpdir) }
  let(:box)         { fire_double('Vagrant::Box', directory: tmp_path.join('box')) }
  let(:rootfs_path) { tmp_path.join('rootfs-amd64.tar.gz') }

  subject { described_class.new(app, env) }

  before do
    box.directory.mkdir
    files = %w( lxc-template metadata.json lxc.conf ).map { |f| box.directory.join(f) }
    (files + [rootfs_path]).each do |file|
      file.open('w') { |f| f.puts file.to_s }
    end

    subject.stub(recover: true) # Prevents files from being removed on specs
    subject.call(env)
  end

  after do
    FileUtils.rm_rf(tmp_path.to_s)
  end

  it 'copies box lxc-template to package directory' do
    env['package.directory'].join('lxc-template').should be_file
  end

  it 'copies metadata.json to package directory' do
    env['package.directory'].join('metadata.json').should be_file
  end

  it 'copies box lxc.conf to package directory' do
    env['package.directory'].join('lxc-template').should be_file
  end

  it 'moves the compressed rootfs to package directory' do
    env['package.directory'].join(rootfs_path.basename).should be_file
    env['package.rootfs'].should_not be_file
  end
end
