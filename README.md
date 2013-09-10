# vagrant-lxc

[![Build Status](https://travis-ci.org/fgrehm/vagrant-lxc.png?branch=master)](https://travis-ci.org/fgrehm/vagrant-lxc) [![Gem Version](https://badge.fury.io/rb/vagrant-lxc.png)](http://badge.fury.io/rb/vagrant-lxc) [![Code Climate](https://codeclimate.com/github/fgrehm/vagrant-lxc.png)](https://codeclimate.com/github/fgrehm/vagrant-lxc) [![Coverage Status](https://coveralls.io/repos/fgrehm/vagrant-lxc/badge.png?branch=master)](https://coveralls.io/r/fgrehm/vagrant-lxc)

[LXC](http://lxc.sourceforge.net/) provider for [Vagrant](http://www.vagrantup.com/) 1.1+

This is a Vagrant plugin that allows it to control and provision Linux Containers
as an alternative to the built in VirtualBox provider for Linux hosts.

Check out this [blog post](http://fabiorehm.com/blog/2013/04/28/lxc-provider-for-vagrant)
to see the plugin in action and find out more about it.

## Features / Limitations

* Provides the same workflow as the Vagrant VirtualBox provider
* Port forwarding via [`redir`](http://linux.die.net/man/1/redir)
* Does not support private networks

*Please refer to the [closed issues](https://github.com/fgrehm/vagrant-lxc/issues?labels=&milestone=&page=1&state=closed)
and the [changelog](CHANGELOG.md) for most up to date information.*

**NOTE: The plugin is currently incompatible with Vagrant 1.3+, please have a look at [#136](https://github.com/fgrehm/vagrant-lxc/issues/136)
for a workaround and updates about it**


## Requirements

* [Vagrant 1.1+](http://downloads.vagrantup.com/)
* lxc 0.7.5+
* redir (if you are planning to use port forwarding)
* A [bug-free](https://github.com/fgrehm/vagrant-lxc/wiki/Troubleshooting#im-unable-to-restart-containers) kernel

The plugin is known to work better and pretty much out of the box on Ubuntu 12.04+
hosts and installing the dependencies on it basically means a `apt-get install lxc lxc-templates cgroup-lite redir`
and a `apt-get update && apt-get dist-upgrade` to upgrade the kernel.

Some manual steps are required to set up a Linode machine prior to using this
plugin, please check https://github.com/fgrehm/vagrant-lxc/wiki/Usage-on-Linode
for more information. Documentation on how to set things up for other distros
[are welcome](https://github.com/fgrehm/vagrant-lxc/wiki) :)

If you are on a Mac or Windows machine, you might want to have a look at this
blog post for some ideas on how to set things up: http://the.taoofmac.com/space/HOWTO/Vagrant
or use use the same [Ubuntu 12.10 VirtualBox machine I use for development](https://github.com/fgrehm/vagrant-lxc/wiki/Development#using-virtualbox-for-development).


## Installation

```
vagrant plugin install vagrant-lxc
```


## Usage

After installing, add a [base box](#base-boxes) using any name you want, for example:

```
vagrant box add quantal64 http://bit.ly/vagrant-lxc-quantal64-2013-07-12
```

Then create a Vagrantfile that looks like the following, changing the box name
to the one you've just added:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "quantal64"
end
```

And finally run `vagrant up --provider=lxc`.

If you are using Vagrant 1.2+ you can also set `VAGRANT_DEFAULT_PROVIDER`
environmental variable to `lxc` in order to avoid typing `--provider=lxc` all
the time.


### Advanced configuration

If you want, you can modify container configurations from within your Vagrantfile
using the [provider block](http://docs.vagrantup.com/v2/providers/configuration.html):

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "quantal64"
  config.vm.provider :lxc do |lxc|
    # Same effect as as 'customize ["modifyvm", :id, "--memory", "1024"]' for VirtualBox
    lxc.customize 'cgroup.memory.limit_in_bytes', '1024M'
  end
end
```

vagrant-lxc will then write out `lxc.cgroup.memory.limit_in_bytes='1024M'` to the
container config file (usually kept under `/var/lib/lxc/<container-name>/config`)
prior to starting it.

For other configuration options, please check the [lxc.conf manpages](http://manpages.ubuntu.com/manpages/quantal/man5/lxc.conf.5.html).


### Avoiding `sudo` passwords

This plugin requires **a lot** of `sudo`ing since [user namespaces](https://wiki.ubuntu.com/UserNamespace)
are not supported on mainstream kernels. In order to work around that we can use
a really dumb **AND INSECURE** Ruby wrapper script like the one below and add
a `NOPASSWD` entry to our `/etc/sudoers` file:

```ruby
#!/usr/bin/env ruby
exec ARGV.join(' ')
```

For example, you can save the code above under your `/usr/bin/lxc-vagrant-wrapper`,
turn it into an executable script by running `chmod +x /usr/bin/lxc-vagrant-wrapper`
and add the line below to your `/etc/sudoers` file:

```
USERNAME ALL=NOPASSWD:/usr/bin/lxc-vagrant-wrapper
```

*__WARNING__: the `/usr/bin/lxc-vagrant-wrapper` + `/etc/sudoers` combination
above allows `USERNAME` to run any privileged command without a password. You
might want to think twice before using that on a machine with sensitive data.*

In order to tell vagrant-lxc to use that script when `sudo` is needed, you can
pass in the path to the script as a configuration for the provider:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provider :lxc do |lxc|
    lxc.sudo_wrapper = '/usr/bin/lxc-vagrant-wrapper'
  end
end
```

If you want to set the `sudo_wrapper` globally, just add the code above to your
`~/.vagrant.d/Vagrantfile`.


### Base boxes

Please check [the wiki](https://github.com/fgrehm/vagrant-lxc/wiki/Base-boxes)
for a list of [pre built](https://github.com/fgrehm/vagrant-lxc/wiki/Base-boxes#available-boxes)
base boxes and information on [how to build your own](https://github.com/fgrehm/vagrant-lxc/wiki/Base-boxes#building-your-own).


## More information

Please refer the [wiki](https://github.com/fgrehm/vagrant-lxc/wiki) for more
information.


## Problems / ideas?

Please review the [Troubleshooting](https://github.com/fgrehm/vagrant-lxc/wiki/Troubleshooting)
wiki page + [known bugs](https://github.com/fgrehm/vagrant-lxc/issues?labels=bug&page=1&state=open)
list if you have a problem and feel free to use the [issue tracker](https://github.com/fgrehm/vagrant-lxc/issues)
to ask questions, propose new functionality and / or report bugs.


## Similar projects

* [vagabond](https://github.com/chrisroberts/vagabond) - "a tool integrated with Chef to build local nodes easily"
* [vagueant](https://github.com/neerolyte/vagueant) - "vaguely like Vagrant for linux containers (lxc)"


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
