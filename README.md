# vagrant-lxc [![Build Status](https://travis-ci.org/fgrehm/vagrant-lxc.png?branch=master)](https://travis-ci.org/fgrehm/vagrant-lxc) [![Gem Version](https://badge.fury.io/rb/vagrant-lxc.png)](http://badge.fury.io/rb/vagrant-lxc) [![Code Climate](https://codeclimate.com/github/fgrehm/vagrant-lxc.png)](https://codeclimate.com/github/fgrehm/vagrant-lxc) [![Coverage Status](https://coveralls.io/repos/fgrehm/vagrant-lxc/badge.png?branch=master)](https://coveralls.io/r/fgrehm/vagrant-lxc)

[LXC](http://lxc.sourceforge.net/) provider for [Vagrant](http://www.vagrantup.com/) 1.1+

Check out this [blog post](http://fabiorehm.com/blog/2013/04/28/lxc-provider-for-vagrant)
to see the plugin in action and find out more about it.

## Features

* Vagrant's `up`, `halt`, `reload`, `destroy`, `ssh`, `provision` and `package` commands (box packaging is kind of experimental)
* Shared folders
* Provisioning with any built-in Vagrant provisioner
* Setting container's host name
* Port forwarding

*Please refer to the [closed issues](https://github.com/fgrehm/vagrant-lxc/issues?labels=&milestone=&page=1&state=closed)
and the [changelog](CHANGELOG.md) for most up to date information.*


## Requirements

* [Vagrant 1.1+](http://downloads.vagrantup.com/)
* lxc 0.7.5+
* redir (if you are planning to use port forwarding)
* A [bug-free](#help-im-unable-to-restart-containers) kernel

On a clean Ubuntu 12.10 machine it basically means a `apt-get update && apt-get dist-upgrade`
to upgrade the kernel and `apt-get install lxc redir`.


## Installation

```
vagrant plugin install vagrant-lxc
```


## Usage

After installing, add a [base box](#available-boxes) using any name you want, for example:

```
vagrant box add quantal64 http://dl.dropbox.com/u/13510779/lxc-quantal-amd64-2013-05-08.box
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

If you are on a mac or windows host and still want to try this plugin out, you
can use the [Ubuntu 12.10 VirtualBox machine I use for development](#using-virtualbox-for-development).


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

This will make vagrant-lxc pass in `-s lxc.cgroup.memory.limit_in_bytes=1024M`
to `lxc-start` when booting containers. This will override any previously value
set from container's configuration file that is usually kept under
`/var/lib/lxc/<container-name>/config`.

For other configuration options, please check [lxc.conf manpages](http://manpages.ubuntu.com/manpages/quantal/man5/lxc.conf.5.html).


### Available boxes

| LINK | DESCRIPTION |
| ---  | ---         |
| [lxc-raring-amd64-2013-05-08.box](http://dl.dropbox.com/u/13510779/lxc-raring-amd64-2013-05-08.box) | Ubuntu 13.04 Raring x86_64 (Puppet 3.1.1) |
| [lxc-quantal-amd64-2013-05-08.box](http://dl.dropbox.com/u/13510779/lxc-quantal-amd64-2013-05-08.box) | Ubuntu 12.10 Quantal x86_64 (Puppet 3.1.1 & Chef 11.4.0) |
| [lxc-precise-amd64-2013-05-08.box](http://dl.dropbox.com/u/13510779/lxc-precise-amd64-2013-05-08.box) | Ubuntu 12.04 Precise x86_64 (Puppet 3.1.1 & Chef 11.4.0) |
| [lxc-sid-amd64-2013-05-08.box](http://dl.dropbox.com/u/13510779/lxc-sid-amd64-2013-05-08.box) | Debian Sid (Puppet 3.1.1) |
| [lxc-wheezy-amd64-2013-05-08.box](http://dl.dropbox.com/u/13510779/lxc-wheezy-amd64-2013-05-08.box) | Debian Wheezy (Puppet 3.1.1) |
| [lxc-squeeze-amd64-2013-05-08.box](http://dl.dropbox.com/u/13510779/lxc-squeeze-amd64-2013-05-08.box) | Debian Squeeze (Puppet 3.1.1) |

*Please note that I'm currently using only the quantal x86_64 on a daily basis,
and I've only done some basic testing with the others*

There is a set of [rake tasks](tasks/boxes.rake) that you can use to build base
boxes as needed. By default it won't include any provisioning tool and you can
pick the ones you want by providing some environment variables.

For example:

```
CHEF=1 rake boxes:ubuntu:build:precise64
```

Will build a Ubuntu Precise x86_64 box with Chef pre-installed.


### Storing container's rootfs on a separate partition

Before the 0.3.0 version of this plugin, there used to be a support for specifying
the container's rootfs path from the Vagrantfile, on 0.3.0 this was removed as you
can achieve the same effect by symlinking or mounting `/var/lib/lxc` on a separate
partition.


### NFS synced folders

NFS shared folders are not supported and will behave as a "normal" synced folder
so we can use the same Vagrantfile with VBox environments.


## Current limitations

* The plugin does not detect forwarded ports collision, right now you are
  responsible for taking care of that.
* There is a hell lot of `sudo`s involved and this will probably be around until
  [user namespaces](https://wiki.ubuntu.com/LxcSecurity) are supported.
* [Does not tell you if dependencies are not met](https://github.com/fgrehm/vagrant-lxc/issues/11)
  (will probably just throw up some random error)
* + bunch of other [core features](https://github.com/fgrehm/vagrant-lxc/issues?labels=core&milestone=&page=1&state=open)
  and some known [bugs](https://github.com/fgrehm/vagrant-lxc/issues?labels=bug&page=1&state=open)


## Development

If want to develop from your physical machine, just sing that same old song:

```
git clone git://github.com/fgrehm/vagrant-lxc.git
cd vagrant-lxc
bundle install
bundle exec rake # to run unit specs
```

To run acceptance specs, you'll have to ssh into one of the [development boxes](development/Vagrantfile) and run:

```
bundle exec rake spec:acceptance
```

### Using vagrant-lxc to develop itself

Yes! The gem has been [bootstrapped](http://bit.ly/bootstrapping-compilers)
and since you can boot a container from within another, after cloning the
project you can run the commands below from the host machine to get a container
ready for development:

```sh
# Required in order to allow nested containers to be started
sudo apt-get install apparmor-utils
sudo aa-complain /usr/bin/lxc-start
bundle install
cd development
bundle exec vagrant up quantal --provider=lxc
bundle exec vagrant ssh quantal
```

That should result in a container ready to rock. Once you've SSH into the guest
container, you'll be already on the project's root. Keep in mind that you'll
probably need to run `sudo aa-complain /usr/bin/lxc-start` on the host whenever
you want to hack on it, otherwise you won't be able to start nested containers
there to try things out.

### Using VirtualBox for development

```
bundle install
cd development
# Pass in --provider=virtualbox in case you have VAGRANT_DEFAULT_PROVIDER set to something else
bundle exec vagrant up quantal
# A reload is needed to ensure the updated kernel gets loaded
bundle exec vagrant reload quantal
bundle exec vagrant ssh quantal
```


### Protips

If you want to find out more about what's going on under the hood on vagrant,
prepend `VAGRANT_LOG=debug` to your `vagrant` commands. For `lxc-start`s
debugging set `LXC_START_LOG_FILE`:

```
LXC_START_LOG_FILE=/tmp/lxc-start.log VAGRANT_LOG=debug vagrant up
```

This will output A LOT of information on your terminal and some useful information
about `lxc-start` to `/tmp/lxc-start.log`.


## Help! I'm unable to restart containers!

It happened to me quite a few times in the past and it seems that it is related
to a bug on linux kernel, so make sure you are using a bug-free kernel
(>= 3.5.0-17.28). More information can be found on:

* https://bugzilla.kernel.org/show_bug.cgi?id=47181
* https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1021471
* https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1065434

Sometimes the dev boxes I'm using are not able to `lxc-start` containers
anymore. Most of the times it was an issue with the arguments I provided
to it for customization or the *buggy kernel*. If you run into that, rollback your
changes and try to `vagrant reload` the dev box. If it still doesn't work,
please file a bug at the [issue tracker](https://github.com/fgrehm/vagrant-lxc/issues).


## Similar projects

* [vagabond](https://github.com/chrisroberts/vagabond) - "a tool integrated with Chef to build local nodes easily"
* [vagueant](https://github.com/neerolyte/vagueant) - "vaguely like Vagrant for linux containers (lxc)"


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
