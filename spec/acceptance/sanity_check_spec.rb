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
      expected = 'lxc-test-box'
      # HACK:
      expected = ENV['BOX_NAME'].gsub(/64$/, '') if %w( squeeze64 wheezy64 sid64 ).include? ENV['BOX_NAME']
      expect(vagrant_ssh('hostname')).to eq expected
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

    it 'shuts down container' do
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

    it 'removes files under `/tmp`' do
      container_tmp = Pathname("/var/lib/lxc/#{vagrant_container_name}/rootfs/tmp")
      expect(container_tmp.entries).to have(2).items # basically '.' and '..'
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
end
