# vagrant-lxc [![Build Status](https://travis-ci.org/fgrehm/vagrant-lxc.png?branch=master)](https://travis-ci.org/fgrehm/vagrant-lxc) [![Gem Version](https://badge.fury.io/rb/vagrant-lxc.png)](http://badge.fury.io/rb/vagrant-lxc) [![Code Climate](https://codeclimate.com/github/fgrehm/vagrant-lxc.png)](https://codeclimate.com/github/fgrehm/vagrant-lxc) [![Coverage Status](https://coveralls.io/repos/fgrehm/vagrant-lxc/badge.png?branch=master)](https://coveralls.io/r/fgrehm/vagrant-lxc)

Linux Containers support for Vagrant 1.1+

Check out this [blog post](http://fabiorehm.com/blog/2013/04/28/lxc-provider-for-vagrant)
to see the plugin in action and find out more about it.

## Dependencies

* Vagrant 1.1+ (1.1.3+ recommended)
* lxc 0.7.5+ (0.8.0-rc1+ recommended)
* redir (if you are planning to use port forwarding)
* A Kernel [higher than 3.5.0-17.28](#help-im-unable-to-restart-containers)

On a clean Ubuntu 12.10 machine it means something like:

```
sudo apt-get update && sudo apt-get dist-upgrade
sudo apt-get install lxc redir
# Downloads and install Vagrant 1.1.5
wget "http://files.vagrantup.com/packages/64e360814c3ad960d810456add977fd4c7d47ce6/vagrant_`uname -m`.deb" -O /tmp/vagrant.deb
sudo dpkg -i /tmp/vagrant.deb
```


## Installation

```
vagrant plugin install vagrant-lxc
```


## Usage

After installing, add a [base box](#available-boxes) using any name you want, for example:

```
vagrant box add lxc-quantal64 http://dl.dropbox.com/u/13510779/lxc-quantal-amd64-2013-04-21.box
```

Make a Vagrantfile that looks like the following, filling in your information where necessary:

```ruby
Vagrant.configure("2") do |config|
  # Change it to the name of the box you have just added
  config.vm.box = "lxc-quantal64"

  # You can omit this block if you don't need to override any container setting
  config.vm.provider :lxc do |lxc|
    # OPTIONAL: Same effect as as 'customize ["modifyvm", :id, "--memory", "1024"]' for VirtualBox
    lxc.customize 'cgroup.memory.limit_in_bytes', '1024M'
    # OPTIONAL: Limits swap size
    lxc.customize 'cgroup.memory.memsw.limit_in_bytes', '512M'
  end
end
```

And finally run `vagrant up --provider=lxc`. If you are using Vagrant 1.2+ you can
also set `VAGRANT_DEFAULT_PROVIDER` environmental variable to `lxc`.

If you are on a mac or window host and still want to try this plugin out, you
can use the [same Vagrant VirtualBox machine I use for development](#using-virtualbox-for-development).

### Available boxes

| LINK | DESCRIPTION |
| --- | ---         |
| [lxc-raring-amd64-2013-04-21.box](http://dl.dropbox.com/u/13510779/lxc-raring-amd64-2013-04-21.box) | Ubuntu 13.04 Raring x86_64 (Puppet 3.1.1) |
| [lxc-quantal-amd64-2013-04-21.box](http://dl.dropbox.com/u/13510779/lxc-quantal-amd64-2013-04-21.box) | Ubuntu 12.10 Quantal x86_64 (Puppet 3.1.1 & Chef 11.4.0) |
| [lxc-precise-amd64-2013-04-21.box](http://dl.dropbox.com/u/13510779/lxc-precise-amd64-2013-04-21.box) | Ubuntu 12.04 Precise x86_64 (Puppet 3.1.1 & Chef 11.4.0) |

*Please note that I'm currently using only the quantal x86_64 on a daily basis,
and I've only done some basic testing with the others*

There is a set of [rake tasks](tasks/boxes.rake) that you can use to build base
boxes as needed. By default it won't include any provisioning tool and you can
pick the one you want by providing some environment variables.

For example:

```
CHEF=1 rake boxes:ubuntu:build:precise64
```

Will build a Ubuntu Precise x86_64 box with chef pre-installed.

### Storing container's rootfs on a separate partition

Before the 0.3.0 version of this plugin, there used to be a support for specifying
the container's rootfs path from the `Vagrantfile`, on 0.3.0 this was removed as you
can achieve the same effect by symlinking or mounting `/var/lib/lxc` on a separate
partition.

### NFS shared folders

NFS shared folders are not supported and will behave as a "normal" shared folder
so we can share the same Vagrantfile with VBox environments.


## What is currently supported?

Pretty much everything you need from Vagrant:

* Vagrant's `up`, `halt`, `reload`, `destroy`, `ssh` and `package` commands (box packaging is kind of experimental)
* Shared folders
* Provisioning
* Setting container's host name
* Port forwarding

*Please refer to the [closed issues](https://github.com/fgrehm/vagrant-lxc/issues?labels=&milestone=&page=1&state=closed)
and the [changelog](CHANGELOG.md) for most up to date information.*


## Current limitations

* Does not detect forwarded ports collision, right now you are responsible for taking care of that
* A hell lot of `sudo`s (this will probably be like this until [user namespaces](http://s3hh.wordpress.com/2013/02/12/user-namespaces-lxc-meeting/) are supported)
* [Does not tell you if dependencies are not met](https://github.com/fgrehm/vagrant-lxc/issues/11)
  (will probably just throw up some random error)
* + bunch of other [core features](https://github.com/fgrehm/vagrant-lxc/issues?labels=core&milestone=&page=1&state=open)
  and some known [bugs](https://github.com/fgrehm/vagrant-lxc/issues?labels=bug&page=1&state=open)


## Development

If  want to develop from your physical machine, just sing that same old song:

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

To build the provided quantal64 box:

```
bundle exec rake boxes:quantal64:build
vagrant box add quantal64 boxes/output/lxc-quantal64.box
```

### Using `vagrant-lxc` to develop itself

Yes! The gem has been [bootstrapped](http://en.wikipedia.org/wiki/Bootstrapping_(compilers)
and since you can boot a container from within another, after cloning the
project you can run the commands below from the host machine to get a container
ready for development:

```sh
# Required in order to allow nested containers to be started
sudo apt-get install apparmor-utils
sudo aa-complain /usr/bin/lxc-start
bundle install
cd development
bundle exec vagrant up lxc --provider=lxc
bundle exec vagrant ssh lxc
```

That should result in a container ready to be `bundle exec vagrant ssh`ed.
Once you've SSH into the guest container, you'll be already on the project's root.
Keep in mind that you'll probably need to run `sudo aa-complain /usr/bin/lxc-start`
on the host whenever you want to hack on it, otherwise you won't be able to
start nested containers there to try things out.

### Using VirtualBox for development

```
cd development
bundle exec vagrant up vbox
# A reload is needed to ensure the updated kernel gets loaded
bundle exec vagrant reload vbox
bundle exec vagrant ssh vbox
```


## Protips

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
to it for customization (or a *buggy* kernel). If you run into that, rollback your changes
and try to `vagrant reload` the dev box. If it still doesn't work,
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
