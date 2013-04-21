module AcceptanceExampleGroup
  def self.included(base)
    base.metadata[:type] = :acceptance
  end

  def destroy_container
    `sudo lxc-shutdown -n \`cat /vagrant/spec/.vagrant/machines/default/lxc/id\` 2>/dev/null`
    `sudo lxc-wait -n \`cat /vagrant/spec/.vagrant/machines/default/lxc/id\` --state STOPPED 2>/dev/null`
    `sudo lxc-destroy -n \`cat /vagrant/spec/.vagrant/machines/default/lxc/id\` 2>/dev/null`
    `sudo killall -9 redir 2>/dev/null`
  end

  def vagrant_up
    opts = { cwd: 'spec' }
    env  = Vagrant::Environment.new(opts)
    env.cli('up', '--provider', 'lxc')
    env.unload
  end

  def vagrant_halt
    opts = { cwd: 'spec' }
    env  = Vagrant::Environment.new(opts)
    env.cli('halt')
    env.unload
  end

  def vagrant_destroy
    opts = { cwd: 'spec' }
    env  = Vagrant::Environment.new(opts)
    env.cli('destroy', '-f')
    env.unload
  end

  def vagrant_ssh(cmd)
    opts   = { cwd: 'spec', ui_class: TestUI }
    env    = Vagrant::Environment.new(opts)
    result = env.cli('ssh', '-c', cmd)
    if result.to_i != 0
      raise "SSH command failed: '#{cmd}'\n#{env.ui.messages.inspect}"
    end
    output = env.ui.messages[:info].join("\n").chomp
    env.unload
    output
  end
end
