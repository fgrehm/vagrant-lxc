# vagrant-lxc

Highly experimental, soon to come, Linux Containers support for the unreleased
Vagrant 1.1.

Please refer to the [closed issues](https://github.com/fgrehm/vagrant-lxc/issues?labels=&milestone=&page=1&state=closed)
to find out whats currently supported.


## WARNING

Please keep in mind that this is not even alpha software and things might go wrong.


## Dependencies

Just LXC and `bsdtar` as of now, which on Ubuntu 12.10 means:

```
sudo apt-get install lxc bsdtar
```


## Current limitations that I can remember

* Ruby >= 1.9.3 only, patches for 1.8.7 are welcome
* There is no support for setting a static IP. I'm using
  [LXC's built in dns server](lib/vagrant-lxc/container.rb#L100) to determine
  containers' IPs
* `sudo`s
* only ubuntu cloudimg supported, I'm still [figuring out what should go on the .box](https://github.com/fgrehm/vagrant-lxc/issues/4)
* "[works](https://github.com/fgrehm/vagrant-lxc/issues/20) on [my machine](https://github.com/fgrehm/vagrant-lxc/issues/7)" (TM)
* plus a bunch of other [core features](https://github.com/fgrehm/vagrant-lxc/issues?labels=core&milestone=&page=1&state=open)


## Usage

For now you'll need to install the gem from sources:

```
git clone git://github.com/fgrehm/vagrant-lxc.git --recurse
cd vagrant-lxc
bundle install
bundle exec rake install
bundle exec rake boxes:build:ubuntu-cloud
vagrant-lxc box add ubuntu-cloud boxes/output/ubuntu-cloud.box
```

Since Vagrant 1.1 has not been released yet and to avoid messing up with you
current Vagrant installation, I've vendored Vagrant's sources from the master
and made it available from [`vagrant-lxc`](bin/vagrant-lxc). So after `vagrant-lxc`
gets installed, create a `Vagrantfile` like the one below and run `vagrant-lxc up --provider=lxc`:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu-cloud"

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
end
```

If you don't trust me and believe that it will mess up with your current Vagrant
installation and / or are afraid that something might go wrong with your machine,
fire up the [same Vagrant VirtualBox machine I'm using for development](#using-virtualbox-for-development)
to try things out and do the same as above. That might also get you up and running
if you are working on a mac ;)


## Development

If you know what you'll be doing and want to develop from your physical machine,
just sing that same old song:

```
git clone git://github.com/fgrehm/vagrant-lxc.git --recurse
cd vagrant-lxc
bundle install
bundle exec rake boxes:build:ubuntu-cloud
bundle exec rake # to run all specs
```

### Using VirtualBox for development

I've also prepared a Vagrant 1.0 VirtualBox machine for development that you can
get up and running with the [`setup-vagrant-dev-box`](setup-vagrant-dev-box)
script. Feel free to use it :)

```
cp Vagrantfile.dev Vagrantfile
./setup-vagrant-dev-box
vagrant ssh
```

*NOTE: `setup-vagrant-dev-box` takes around 10 minutes on a 15mb connection
after the [base vagrant box](Vagrantfile.dev#L5) and ubuntu [lxc cloud img](setup-vagrant-dev-box#L15-L16)
have been downloaded*


## Protip

If you want to find out more about what's going on under the hood, prepend `VAGRANT_LOG=debug`
to your `vagrant-lxc` commands like:

```
VAGRANT_LOG=debug vagrant-lxc up
```


## Help!

### I've accidentaly ran `vagrant-lxc` on a Vagrant 1.0 project and I can't use it anymore

That happened to me before so here's how to recover:

```
rm -rf .vagrant
mv .vagrant.v1* .vagrant
```

### The container does not stop from `vagrant halt`

There is some hidden bug which I wasn't able to reproduce properly, if that
happens to you, just run `lxc-shutdown -n container_name` and try again.

### I'm unable to start containers!

Sometimes the Virtual Box dev machine I'm using is not able to `lxc-start`
containers anymore. Most of the times it was an issue with the [arguments](https://github.com/fgrehm/vagrant-lxc/blob/master/lib/vagrant-lxc/container.rb#L85)
[I provided](https://github.com/fgrehm/vagrant-lxc/blob/master/example/Vagrantfile#L12-L15)
to it. If you run into that, just try to `vagrant reload` the dev box since most
of the times things get back to normal. If it still doesn't work, you can try
to run `setup-vagrant-dev-box` again to restore an snapshot that [it creates](https://github.com/fgrehm/vagrant-lxc/blob/master/setup-vagrant-dev-box#L132-L137)
automagically for you.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
