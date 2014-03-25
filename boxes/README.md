# vagrant-lxc base boxes

This repository contains a set of scripts for creating base boxes for usage with
[vagrant-lxc](https://github.com/fgrehm/vagrant-lxc) 1.0+.

## What distros / versions can I build with this?

* Ubuntu
  - Precise 12.04
  - Quantal 12.10
  - Raring 13.04
  - Saucy 13.10
  - Trusty 14.04
* Debian
  - Squeeze
  - Wheezy
  - Jessie
  - Sid

## Building the boxes

```sh
git clone https://github.com/fgrehm/vagrant-lxc-base-boxes.git
cd vagrant-lxc-base-boxes
make precise
```

By default no provisioning tools will be included but you can pick the ones
you want by providing some environmental variables. For example:

```sh
PUPPET=1 CHEF=1 SALT=1 BABUSHKA=1 \
make precise
```

Will build a Ubuntu Precise x86_64 box with latest Puppet, Chef, Salt and
Babushka pre-installed.


## Pre built base boxes

| Box | VagrantCloud | Direct URL |
| --- | ------------ | ---------- |
|     |              |            |


## What makes up for a vagrant-lxc base box?

See [vagrant-lxc/BOXES.md](https://github.com/fgrehm/vagrant-lxc/blob/master/BOXES.md)


## Known issues

* We can't get the NFS client to be installed on the containers used for building
  Ubuntu 13.04 / 13.10 / 14.04 base boxes.
* Puppet can't be installed on Ubuntu 14.04 / Debian Sid
* Salt can't be installed on Ubuntu 13.04
