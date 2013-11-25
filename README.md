# vagrant-lxc

[![Build Status](https://travis-ci.org/fgrehm/vagrant-lxc.png?branch=master)](https://travis-ci.org/fgrehm/vagrant-lxc) [![Gem Version](https://badge.fury.io/rb/vagrant-lxc.png)](http://badge.fury.io/rb/vagrant-lxc) [![Code Climate](https://codeclimate.com/github/fgrehm/vagrant-lxc.png)](https://codeclimate.com/github/fgrehm/vagrant-lxc) [![Coverage Status](https://coveralls.io/repos/fgrehm/vagrant-lxc/badge.png?branch=master)](https://coveralls.io/r/fgrehm/vagrant-lxc)

[LXC](http://lxc.sourceforge.net/) provider for [Vagrant](http://www.vagrantup.com/) 1.1+

This is a Vagrant plugin that allows it to control and provision Linux Containers
as an alternative to the built in VirtualBox provider for Linux hosts. Check out
[this blog post](http://fabiorehm.com/blog/2013/04/28/lxc-provider-for-vagrant/)
to see it in action.


## Features / Limitations

* Provides the same workflow as the Vagrant VirtualBox provider
* Port forwarding via [`redir`](http://linux.die.net/man/1/redir)
* Does not support public / private networks
* Assumes you have a `lxcbr0` bridge configured on your host similar to [Ubuntu's built-in](https://help.ubuntu.com/lts/serverguide/lxc.html#lxcbr0)


## Requirements

* [Vagrant 1.1+](http://downloads.vagrantup.com/)
* lxc 0.7.5+
* redir (if you are planning to use port forwarding)
* A [bug-free](https://github.com/fgrehm/vagrant-lxc/wiki/Troubleshooting#im-unable-to-restart-containers) kernel

The plugin is known to work better and pretty much out of the box on Ubuntu 12.04+
hosts and installing the dependencies on it basically means a `apt-get install lxc lxc-templates cgroup-lite redir`
and a `apt-get update && apt-get dist-upgrade` to upgrade the kernel. For Debian
hosts you'll need to follow the instructions described on the [Wiki](https://github.com/fgrehm/vagrant-lxc/wiki/Usage-on-debian-hosts).

Some manual steps are required to set up a Linode machine prior to using this
plugin, please check [the wiki](https://github.com/fgrehm/vagrant-lxc/wiki/Usage-on-Linode)
for more information. Documentation on how to set things up for other distros
[are welcome](https://github.com/fgrehm/vagrant-lxc/wiki) :)

If you are on a Mac or Windows machine, you might want to have a look at [this](http://the.taoofmac.com/space/HOWTO/Vagrant)
blog post for some ideas on how to set things up or check out [this other repo](https://github.com/fgrehm/vagrant-lxc-vbox-hosts)
for a set of Vagrant VirtualBox machines ready for vagrant-lxc usage.

**NOTE: Some users have been experiencing networking issues and right now you might need to
disable checksum offloading as described on [this comment](https://github.com/fgrehm/vagrant-lxc/issues/153#issuecomment-26441273)**


## Installation

```
vagrant plugin install vagrant-lxc
```


## Usage

After installing, add a [base box](#base-boxes) using any name you want, for example:

```
vagrant box add quantal64 http://bit.ly/vagrant-lxc-quantal64-2013-10-23
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
    # Same effect as 'customize ["modifyvm", :id, "--memory", "1024"]' for VirtualBox
    lxc.customize 'cgroup.memory.limit_in_bytes', '1024M'
  end
end
```

vagrant-lxc will then write out `lxc.cgroup.memory.limit_in_bytes='1024M'` to the
container config file (usually kept under `/var/lib/lxc/<container>/config`)
prior to starting it.

For other configuration options, please check the [lxc.conf manpages](http://manpages.ubuntu.com/manpages/quantal/man5/lxc.conf.5.html).

### Avoiding `sudo` passwords

This plugin requires **a lot** of `sudo`ing since [user namespaces](https://wiki.ubuntu.com/UserNamespace)
are not supported on mainstream kernels. Have a look at the [Wiki](https://github.com/fgrehm/vagrant-lxc/wiki/Avoiding-'sudo'-passwords)
to find out how to work around that specially if you are running an OS with sudo
< 1.8.4 (like Ubuntu 12.04) as you might be affected by a bug.

### Base boxes

Please check [the wiki](https://github.com/fgrehm/vagrant-lxc/wiki/Base-boxes)
for a list of [pre built](https://github.com/fgrehm/vagrant-lxc/wiki/Base-boxes#available-boxes)
base boxes and have a look at [`BOXES.md`](https://github.com/fgrehm/vagrant-lxc/tree/master/BOXES.md)
for more information on building your own.


## More information

Please refer the [wiki](https://github.com/fgrehm/vagrant-lxc/wiki).


## Problems / ideas?

Please review the [Troubleshooting](https://github.com/fgrehm/vagrant-lxc/wiki/Troubleshooting)
wiki page + [known bugs](https://github.com/fgrehm/vagrant-lxc/issues?labels=bug&page=1&state=open)
list if you have a problem and feel free to use the [issue tracker](https://github.com/fgrehm/vagrant-lxc/issues)
propose new functionality and / or report bugs.


## Support

Support this project and [others by fgrehm](https://github.com/fgrehm)
via [gittip](https://www.gittip.com/fgrehm/).

[![Support via Gittip](https://rawgithub.com/twolfson/gittip-badge/0.1.0/dist/gittip.png)](https://www.gittip.com/fgrehm/)


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/fgrehm/vagrant-lxc/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
