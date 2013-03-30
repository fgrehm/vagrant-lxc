# vagrant-lxc [![Build Status](https://travis-ci.org/fgrehm/vagrant-lxc.png?branch=master)](https://travis-ci.org/fgrehm/vagrant-lxc) [![Gem Version](https://badge.fury.io/rb/vagrant-lxc.png)](http://badge.fury.io/rb/vagrant-lxc) [![Code Climate](https://codeclimate.com/github/fgrehm/vagrant-lxc.png)](https://codeclimate.com/github/fgrehm/vagrant-lxc)

Experimental Linux Containers support for Vagrant 1.1+


## Dependencies

Vagrant 1.1+ (1.1.4+ recommended), `lxc` and `redir` packages and a Kernel [higher than 3.5.0-17.28](#help-im-unable-to-restart-containers),
which on Ubuntu 12.10 means something like:

```
sudo apt-get update && sudo apt-get dist-upgrade
sudo apt-get install lxc redir
wget "http://files.vagrantup.com/packages/87613ec9392d4660ffcb1d5755307136c06af08c/vagrant_`uname -m`.deb" -O /tmp/vagrant.deb
sudo dpkg -i /tmp/vagrant.deb
```


## What is currently supported? (v0.2.0)

Pretty much everything you need from Vagrant:

* Vagrant's `up`, `halt`, `reload`, `destroy`, `ssh` and `package` commands (box packaging is kind of experimental)
* Shared folders
* Provisioning
* Setting container's host name
* Port forwarding

*Please refer to the [closed issues](https://github.com/fgrehm/vagrant-lxc/issues?labels=&milestone=&page=1&state=closed)
for the most up to date list.*


## Current limitations

* Does not detect forwarded ports collision, right now you are responsible for taking care of that
* A hell lot of `sudo`s
* Only a [single ubuntu box supported](boxes)
* "[works on  my machine](https://github.com/fgrehm/vagrant-lxc/issues/20)" (TM)
* [Does not tell you if dependencies are not met](https://github.com/fgrehm/vagrant-lxc/issues/11)
  (will probably just throw up some random error)
* + bunch of other [core features](https://github.com/fgrehm/vagrant-lxc/issues?labels=core&milestone=&page=1&state=open)
  and some known [bugs](https://github.com/fgrehm/vagrant-lxc/issues?labels=bug&page=1&state=open)


## Usage

Make sure you have [Vagrant 1.1+](http://downloads.vagrantup.com/) and run:

```
vagrant plugin install vagrant-lxc
```

After that you can create a `Vagrantfile` like the one below and run `vagrant up --provider=lxc`:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box     = "lxc-quantal64"
  config.vm.box_url = 'http://dl.dropbox.com/u/13510779/lxc-quantal64-2013-03-31.box'

  # Share an additional folder to the guest Container. The first argument
  # is the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  config.vm.synced_folder "/tmp", "/host_tmp"

  config.vm.provider :lxc do |lxc|
    # Set the folder where container's rootfs will be stored when created
    lxc.target_rootfs_path = '/path/to/container/rootfs'
    # Same as 'customize ["modifyvm", :id, "--memory", "1024"]' for VirtualBox
    lxc.start_opts << 'lxc.cgroup.memory.limit_in_bytes=400M'
    # Limits swap size
    lxc.start_opts << 'lxc.cgroup.memory.memsw.limit_in_bytes=500M'
  end

  # ... your puppet / chef / shell provisioner configs here ...
end
```

If you are on a mac or window host and still want to try this plugin out, you
can use the [same Vagrant VirtualBox machine I use for development](#using-virtualbox-and-vagrant-11-for-development).


## Development

If  want to develop from your physical machine, just sing that same old song:

```
git clone git://github.com/fgrehm/vagrant-lxc.git --recurse
cd vagrant-lxc
bundle install
bundle exec rake # to run all specs
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
anymore. Most of the times it was an issue with the arguments [I provided](https://github.com/fgrehm/vagrant-lxc/blob/master/example/Vagrantfile#L14-L18)
to it (or a *buggy* kernel). If you run into that, rollback your changes
and try to `vagrant reload` the dev box. If it still doesn't work,
please file a bug at the [issue tracker](https://github.com/fgrehm/vagrant-lxc/issues).


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
