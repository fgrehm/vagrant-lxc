Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/', '/usr/local/bin'] }

stage { 'preinstall':
  before => Stage['main']
}

class apt_get_update {
  exec { 'apt-get -y update':
    unless => "test -f /etc/default/lxc"
  }
}
class { 'apt_get_update':
  stage => preinstall
}

# Because I'm lazy ;)
exec {
  'echo "alias be=\"bundle exec\"" >> /home/vagrant/.bashrc':
    unless => 'grep -q "bundle exec" /home/vagrant/.bashrc';

  'echo "export VAGRANT_DEFAULT_PROVIDER=lxc" >> /home/vagrant/.bashrc':
    unless => 'grep -q "VAGRANT_DEFAULT_PROVIDER" /home/vagrant/.bashrc';

  'echo "cd /vagrant" >> /home/vagrant/.bashrc':
    unless => 'grep -q "cd /vagrant" /home/vagrant/.bashrc';
}

# Overwrite LXC default configs
exec {
  'config-lxc':
    # We need to do this otherwise IPs will collide with the host's lxc dhcp server.
    # If we install the package prior to setting this configs the container will go crazy.
    command => "cp /vagrant/development/lxc-configs/${hostname} /etc/default/lxc"
  ;
}

# Install dependencies
package {
  [ 'libffi-dev', 'bsdtar', 'exuberant-ctags', 'ruby1.9.1-dev', 'htop', 'git',
    'build-essential', 'redir', 'curl', 'vim', 'btrfs-tools' ]:
    ensure   => 'installed'
  ;

  'lxc':
    require => Exec['config-lxc']
  ;

  'bundler':
    ensure   => 'installed',
    provider => 'gem'
  ;
}

# Make sure we can create and boot nested containers
if $hostname == 'vbox' {
  package { 'apparmor-utils': }
  exec    { 'aa-complain /usr/bin/lxc-start': }
}

# Allow gems to be installed on vagrant user home avoiding "sudo"s
# Tks to http://wiki.railsplayground.com/railsplayground/show/How+to+install+gems+and+non+root+user
file {
  '/home/vagrant/gems':
    ensure => directory,
    owner  => 'vagrant',
    group  => 'vagrant'
  ;

  '/home/vagrant/.gemrc':
    content => '
---
:verbose: true
gem: --no-ri --no-rdoc
:update_sources: true
:sources:
- http://gems.rubyforge.org
- http://gems.github.com
:backtrace: false
:bulk_threshold: 1000
:benchmark: false
gemhome: /home/vagrant/gems
gempath:
- /home/vagrant/gems
- /usr/local/lib/ruby/gems/1.8
'
}
exec {
  'set-gem-paths':
    command => 'cat << EOF >> /home/vagrant/.profile
export GEM_HOME=/home/vagrant/gems
export GEM_PATH=/home/vagrant/gems:/var/lib/gems/1.9.1
export PATH=$PATH:/home/vagrant/gems/bin
EOF',
    unless => 'grep -q "GEM_HOME" /home/vagrant/.profile'
}

# Bundle!
exec {
  'su -l vagrant -c "cd /vagrant && bundle install"':
    # We are checking for guard-rspec here but it could be any gem...
    unless  => 'gem list guard | grep -q rspec',
    cwd     => '/vagrant',
    require => [
      Exec['set-gem-paths'],
      File['/home/vagrant/gems', '/home/vagrant/.gemrc'],
      Package['bundler']
    ]
}

# Setup vagrant default ssh key
file {
  '/home/vagrant/.ssh':
    ensure => directory,
    owner  => 'vagrant',
    group  => 'vagrant'
}
exec {
  'download-private-key':
    command => 'wget https://raw.github.com/mitchellh/vagrant/master/keys/vagrant -O /home/vagrant/.ssh/id_rsa',
    creates => '/home/vagrant/.ssh/id_rsa',
    require => File['/home/vagrant/.ssh'],
    user    => 'vagrant'
  ;

  'wget https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub -O /home/vagrant/.ssh/id_rsa.pub':
    creates => '/home/vagrant/.ssh/id_rsa.pub',
    require => File['/home/vagrant/.ssh'],
    user    => 'vagrant'
  ;
}
file {
  '/home/vagrant/.ssh/id_rsa':
    ensure  => 'present',
    mode    => '0600',
    require => Exec['download-private-key']
}

# Passwordless sudo wrapper script
file {
  '/usr/bin/lxc-vagrant-wrapper':
    ensure  => 'present',
    mode    => '0755',
    content => "
#!/usr/bin/env ruby
exec ARGV.join(' ')
    "
}
