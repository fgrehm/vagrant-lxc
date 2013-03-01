require 'spec_helper'

describe 'vagrant up' do
  context 'given the machine has not been created yet' do
    let(:output)      { @output }
    let(:containers)  { @containers }
    let(:users)       { File.read '/var/lib/lxc/vagrant-container/rootfs/etc/passwd' }
    let(:sudoers)     { `sudo cat /var/lib/lxc/vagrant-container/rootfs/etc/sudoers` }
    let(:rinetd_conf) { File.read('/etc/rinetd.conf') }

    before :all do
      destroy_container!
      configure_box_with :ip => '10.0.3.121'
      @output     = provider_up
      @containers = `sudo lxc-ls`.split
    end

    it 'outputs some debugging info' do
      output.should =~ /INFO lxc: Creating container.../
      output.should =~ /INFO lxc: Container started/
    end

    it 'creates an lxc container' do
      containers.should include 'vagrant-container'
    end

    it 'sets up the vagrant user with passwordless sudo' do
      users.should =~ /vagrant/
      sudoers.should =~ /Defaults\s+exempt_group=admin/
      sudoers.should =~ /%admin ALL=NOPASSWD:ALL/
    end

    it 'automagically shares the root folder' do
      output.should =~ /Sharing \/vagrant\/tmp as \/vagrant/
    end

    it 'automagically redirects 2222 port to 22 on guest machine'
  end

  context 'given the machine was created and is down' do
    let(:output) { @output }
    let(:info)   { @info }

    before :all do
      destroy_container!
      provider_up
      `sudo lxc-stop -n vagrant-container`
      @output = provider_up
      @info   = `sudo lxc-info -n vagrant-container`
    end

    it 'outputs some debugging info' do
      output.should =~ /INFO lxc: Container already created, moving on/
      output.should =~ /INFO lxc: Container started/
    end

    it 'starts the container' do
      info.should =~ /RUNNING/
    end
  end

  context 'given the machine is up already' do
    let(:output)     { @output }
    let(:containers) { @containers }

    before :all do
      destroy_container!
      provider_up
      @output = provider_up
    end

    it 'outputs some debugging info' do
      output.should =~ /INFO lxc: Container already created, moving on/
      output.should =~ /INFO lxc: Container already started/
    end
  end

  context 'given an ip was specified' do
    let(:ip)     { '10.0.3.100' }
    let(:output) { @output }

    before :all do
      destroy_container!
      configure_box_with :ip => ip
      @output = provider_up
    end

    it 'sets up container ip' do
      `ping -c1 #{ip} > /dev/null && echo -n 'yes'`.should == 'yes'
    end
  end

  context 'given a port was configured to be forwarded' do
    let(:ip)          { '10.0.3.101' }
    let(:output)      { @output }
    let(:rinetd_conf) { File.read('/etc/rinetd.conf') }

    before :all do
      destroy_container!
      configure_box_with :forwards => [[3333, 33]], :ip => ip
      @output = provider_up
    end

    after :all do
      restore_rinetd_conf!
    end

    it 'ouputs some debugging info' do
      output.should =~ /Forwarding ports\.\.\./
      output.should =~ /33 => 3333/
      output.should =~ /Restarting rinetd/
    end

    it 'sets configs for rinetd' do
      rinetd_conf.should =~ /0\.0\.0\.0\s+3333\s+#{Regexp.escape ip}\s+33/
    end
  end

  context 'given a folder was configured to be shared' do
    let(:ip)     { '10.0.3.100' }
    let(:output) { @output }

    before :all do
      destroy_container!
      configure_box_with({
        :ip => ip,
        :shared_folders => [
          {'source' => '/vagrant', 'destination' => '/tmp/vagrant-all'}
        ]
      })
      @output = provider_up
      `rm -f /vagrant/tmp/file-from-spec`
    end

    after :all do
      `rm -f /vagrant/tmp/file-from-spec`
    end

    it 'ouputs some debugging info' do
      output.should =~ /Sharing \/vagrant as \/tmp\/vagrant\-all/
    end

    it 'mounts the folder on the right path' do
      `echo 'IT WORKS' > /vagrant/tmp/file-from-spec`
      provider_ssh('c' => 'cat /tmp/vagrant-all/tmp/file-from-spec').should include 'IT WORKS'
    end
  end
end
