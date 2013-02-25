# vagrant-lxc

Highly experimental, soon to come, Linux Containers support for the unreleased Vagrant 1.1


## WARNING

Please keep in mind that this is not even alpha software and things might go wrong.
Although I'm brave enough to use it on my physical machine, its recommended that you
try it out on the Vagrant dev box ;)


## Development

On your host:

```terminal
./setup-vagrant-dev-box
vagrant ssh
```

On the guest machine:

```terminal
mkdir /tmp/vagrant-lxc
cp /vagrant/config.yml.sample /tmp/vagrant-lxc/config.yml
cd /tmp/vagrant-lxc
/vagrant/lib/provider up
/vagrant/lib/provider ssh
```


## Troubleshooting

If your container / dev box start acting weird, run `vagrant reload` to see if
things get back to normal.

In case `vagrant reload` doesn't work, restore the VirtualBox snapshot that was
created automagically right after `./setup-vagrant-dev-box` finished by running
the same script again and selecting the `[r]estore snapshot` option when asked.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
