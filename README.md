# vagrant-lxc

[![Build Status](https://travis-ci.org/fgrehm/vagrant-lxc.png?branch=master)](https://travis-ci.org/fgrehm/vagrant-lxc)

Highly experimental, soon to come, Linux Containers support for the unreleased
Vagrant 1.1.

Please refer to the [closed issues](https://github.com/fgrehm/vagrant-lxc/issues?labels=&milestone=&page=1&state=closed)
to find out whats currently supported.


## Vagrant 1.1 is out!

Yeah, I know :) I just need to remove the vendorized vagrant code that I used to
get started and turn this into a real plugin. I'll do that ASAP.


## WARNING

Please keep in mind that although I'm already using this on my laptop, this is
"almost alpha" software and things might go wrong.


## Dependencies

LXC, `bsdtar` and `fping` packages and a Kernel [higher than 3.5.0-17.28](#im-unable-to-restart-containers),
which on Ubuntu 12.10 means:

```
sudo apt-get update && sudo apt-get dist-upgrade
sudo apt-get install lxc bsdtar fping
```


## What is currently supported?

* Vagrant's `up`, `halt`, `reload`, `destroy`, and `ssh` commands
* Shared folders
* Provisioners
* Setting container's host name
* Host-only / private networking


## Current limitations

* Ruby >= 1.9.3 only, patches for 1.8.7 are welcome
* Port forwarding does not work [yet](https://github.com/fgrehm/vagrant-lxc/issues/4)
* A hell lot of `sudo`s
* Only a [single ubuntu box supported](boxes), I'm still [figuring out what should go
  on the .box file](https://github.com/fgrehm/vagrant-lxc/issues/4)
* "[works on  my machine](https://github.com/fgrehm/vagrant-lxc/issues/20)" (TM)
* + bunch of other [core features](https://github.com/fgrehm/vagrant-lxc/issues?labels=core&milestone=&page=1&state=open)
  and some known [bugs](https://github.com/fgrehm/vagrant-lxc/issues?labels=bug&page=1&state=open)


## Usage

For now you'll need to install the gem from sources:

```
git clone git://github.com/fgrehm/vagrant-lxc.git --recurse
cd vagrant-lxc
bundle install
bundle exec rake install
```

Since Vagrant 1.1 has not been released yet and to avoid messing up with you
current Vagrant installation, I've vendored Vagrant's sources from the master
and made it available from [`vagrant-lxc`](bin/vagrant-lxc). So after installing
`vagrant-lxc`, create a `Vagrantfile` like the one below and run
`vagrant-lxc up --provider=lxc`:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box     = "lxc-quantal64"
  config.vm.box_url = 'http://dl.dropbox.com/u/13510779/lxc-quantal64-2013-03-10.box'

  # Share an additional folder to the guest Container. The first argument
  # is the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  config.vm.synced_folder "/tmp", "/host_tmp"

  config.vm.provider :lxc do |lxc|
    # Same as 'customize ["modifyvm", :id, "--memory", "1024"]' for VirtualBox
    lxc.start_opts << 'lxc.cgroup.memory.limit_in_bytes=400M'
    # Limits swap size
    lxc.start_opts << 'lxc.cgroup.memory.memsw.limit_in_bytes=500M'
  end

  # ... your puppet / chef / shell provisioner configs here ...
end
```

If you don't trust me and believe that it will mess up with your current Vagrant
installation and / or are afraid that something might go wrong with your machine,
fire up the [same Vagrant VirtualBox machine I'm using for development](#using-virtualbox-and-vagrant-10-for-development)
to try things out and do the same as above. That might also get you up and running
if you are working on a mac or windows host ;)


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
vagrant-lxc box add quantal64 boxes/output/lxc-quantal64.box
```


### Using `vagrant-lxc` to develop itself

Yes! The gem has been [bootstrapped](http://en.wikipedia.org/wiki/Bootstrapping_(compilers)
and since you can boot a container from within another, after cloning the
project you can run the commands below from the host machine to get a container
ready for development:

```sh
bundle install
cd development
cp Vagrantfile.1.1 Vagrantfile
# Required in order to allow nested containers to be started
sudo apt-get install apparmor-utils
sudo aa-complain /usr/bin/lxc-start
bundle exec vagrant-lxc up lxc --provider=lxc
bundle exec vagrant-lxc ssh lxc
```

That should result in a container ready to be `bundle exec vagrant-lxc ssh`ed.
Once you've SSH into the guest container, you'll be already on the project's root.
Keep in mind that you'll probably need to run `sudo aa-complain /usr/bin/lxc-start`
on the host whenever you want to hack on it, otherwise you won't be able to
start nested containers there to try things out.


### Using VirtualBox and Vagrant 1.0 for development

```
cd development
cp Vagrantfile.1.0 Vagrantfile
vagrant up
vagrant reload
vagrant ssh
```

### Using VirtualBox and Vagrant 1.1 for development

```
cd development
cp Vagrantfile.1.1 Vagrantfile
bundle exec vagrant-lxc up vbox
bundle exec vagrant-lxc reload vbox
bundle exec vagrant-lxc ssh vbox
```


## Protips

If you want to find out more about what's going on under the hood on vagrant,
prepend `VAGRANT_LOG=debug` to your `vagrant-lxc` commands. For `lxc-start`s
debugging set `LXC_START_LOG_FILE`:

```
LXC_START_LOG_FILE=/tmp/lxc-start.log VAGRANT_LOG=debug vagrant-lxc up
```

This will output A LOT of information on your terminal and some useful information
about `lxc-start` to `/tmp/lxc-start.log`.


## Help!

### I've accidentaly ran `vagrant-lxc` on a Vagrant 1.0 project and I can't use it anymore

That happened to me before so here's how to recover:

```
rm -rf .vagrant
mv .vagrant.v1* .vagrant
```

### I'm unable to restart containers!

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
