module AcceptanceExampleGroup
  def self.included(base)
    base.metadata[:type] = :acceptance
  end

  ID_FILE = "/vagrant/spec/.vagrant/machines/default/lxc/id"
  def vagrant_container_name
    File.read(ID_FILE).strip.chomp if File.exists?(ID_FILE)
  end

  def destroy_container
    if name = vagrant_container_name
      `sudo lxc-stop -n #{name} 2>/dev/null`
      `sudo lxc-wait -n #{name} --state STOPPED 2>/dev/null`
      `sudo lxc-destroy -n #{name} 2>/dev/null`
      `rm -rf /vagrant/spec/.vagrant/`
    end
    `sudo killall -9 redir 2>/dev/null`
  end

  def with_vagrant_environment
    opts = { cwd: '/vagrant/spec', ui_class: TestUI }
    env  = Vagrant::Environment.new(opts)
    yield env
    env.unload
  end

  def vagrant_up
    with_vagrant_environment do |env|
      env.cli('up', '--provider', 'lxc')
    end
  end

  def vagrant_halt
    with_vagrant_environment do |env|
      env.cli('halt')
    end
  end

  def vagrant_destroy
    with_vagrant_environment do |env|
      env.cli('destroy', '-f')
    end
  end

  def vagrant_ssh(cmd)
    output = nil
    with_vagrant_environment do |env|
      result = env.cli('ssh', '-c', cmd)
      if result.to_i != 0
        raise "SSH command failed: '#{cmd}'\n#{env.ui.messages.inspect}"
      end
      output = env.ui.messages[:info].join("\n").chomp
    end
    output
  end

  def vagrant_package
    with_vagrant_environment do |env|
      pkg = '/vagrant/spec/tmp/package.box'
      `rm -f #{pkg}`
      env.cli('package', '--output', pkg)
    end
  end

  def vagrant_box_remove(name)
    with_vagrant_environment do |env|
      env.cli('box', 'list')
      output = env.ui.messages[:info].join("\n").chomp

      if output.include?(name)
        env.cli('box', 'remove', name)
      end
    end
  end
end
