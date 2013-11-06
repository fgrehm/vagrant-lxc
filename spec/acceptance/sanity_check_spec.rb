require 'acceptance_helper'

describe 'Sanity check' do
  after(:all) { destroy_container }

  context 'running `vagrant up` from scratch' do
    before(:all) do
      destroy_container
      vagrant_up
    end

    it 'creates a container' do
      containers = `sudo lxc-ls`.chomp.split(/\s+/).uniq
      expect(containers).to include vagrant_container_name
    end

    it 'starts the newly created container' do
      status = `sudo lxc-info -n #{vagrant_container_name}`
      expect(status).to include 'RUNNING'
    end

    it "is able to be SSH'ed" do
      expect(vagrant_ssh('hostname')).to eq 'lxc-test-box'
    end

    it 'mounts shared folders with the right permissions' do
      vagrant_ssh 'mkdir -p /vagrant/tmp && echo -n "Shared" > /vagrant/tmp/shared'
      shared_file_contents = File.read('/vagrant/spec/tmp/shared')
      expect(shared_file_contents).to eq 'Shared'
    end

    it 'provisions the container based on Vagrantfile configs' do
      provisioned_file_contents = File.read('/vagrant/spec/tmp/provisioning')
      expect(provisioned_file_contents).to eq 'Provisioned'
    end

    it 'forwards configured ports' do
      output = `curl -s localhost:8080`.strip.chomp
      expect(output).to include 'It works!'
    end
  end

  context '`vagrant halt` on a running container' do
    before(:all) do
      destroy_container
      vagrant_up
      vagrant_ssh 'touch /tmp/{some,files}'
      vagrant_halt
    end

    it 'shuts down the container' do
      status = `sudo lxc-info -n #{vagrant_container_name}`
      expect(status).to include 'STOPPED'
    end

    it 'clears forwarded ports' do
      `curl -s localhost:8080 --connect-timeout 2`
      expect($?.exitstatus).to_not eq 0
    end

    it 'kills redir processes' do
      processes = `pgrep redir`
      expect($?.exitstatus).to_not eq 0
    end

    xit 'removes files under `/tmp`' do
      container_tmp_files = `sudo ls -l "/var/lib/lxc/#{vagrant_container_name}/rootfs/tmp"`.split("\n")
      puts container_tmp_files.join("\n")
      expect(container_tmp_files).to be_empty
    end
  end

  context '`vagrant destroy`' do
    before(:all) do
      destroy_container
      vagrant_up
      @container_name = vagrant_container_name
      vagrant_destroy
    end

    it 'destroys the underlying container' do
      containers = `sudo lxc-ls`.chomp.split(/\s+/).uniq
      expect(containers).to_not include @container_name
    end
  end

  pending 'box packaging' do
    before(:all) do
      destroy_container
      vagrant_box_remove('new-box')
      vagrant_up
      vagrant_package
      @box_name = ENV['BOX_NAME']
      # This will make
      ENV["BOX_NAME"] = 'new-box'
      ENV['BOX_URL']  = '/vagrant/spec/tmp/package.box'
    end

    after(:all) do
      vagrant_box_remove('new-box')
      ENV["BOX_NAME"] = @box_name
      ENV['BOX_URL']  = nil
    end

    it 'creates a package that can be successfully brought up on a later `vagrant up`' do
      vagrant_up
      # Just to make sure we packaged it properly
      expect(vagrant_ssh('cat /home/vagrant/original-box')).to eq @box_name
    end
  end
end
