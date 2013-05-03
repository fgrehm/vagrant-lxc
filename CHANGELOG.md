## [0.3.3](https://github.com/fgrehm/vagrant-lxc/compare/v0.3.2...v0.3.3) (April 23, 2013)

BUG FIXES:

  - Properly kill `redir` child processes [#59][]
  - Use `uname -m` on base Ubuntu lxc-template [#53][]

IMPROVEMENTS:

  - Initial acceptance test suite
  - New rake tasks for building Ubuntu precise and raring base amd64 boxes

## [0.3.2](https://github.com/fgrehm/vagrant-lxc/compare/v0.3.1...v0.3.2) (April 18, 2013)

  - Do not display port forwarding message in case no forwarded ports were set

## [0.3.1](https://github.com/fgrehm/vagrant-lxc/compare/v0.3.0...v0.3.1) (April 18, 2013)

  - Improved output to match lxc "verbiage"

## [0.3.0](https://github.com/fgrehm/vagrant-lxc/compare/v0.2.0...v0.3.0) (April 10, 2013)

BACKWARDS INCOMPATIBILITIES:

  - Boxes `lxc-template` should support a `--tarball` parameter
  - `start_opts` config was renamed to `customize`, please check the README for the expected parameters
  - V1 boxes are no longer supported
  - `target_rootfs_path` is no longer supported, just symlink `/var/lib/lxc` to the desired folder in case you want to point it to another partition
  - Removed support for configuring private networks. It will come back at some point in the future but if you need it you should be able to set using `customize 'network.ipv4', '1.2.3.4'`

IMPROVEMENTS:

  - lxc templates are removed from lxc template dir after container is created
  - Treat NFS shared folders as a normal shared folder instead of ignoring it so we can share the same Vagrantfile with VBox environments
  - Support for lxc 0.7.5 (tested on Ubuntu 12.04) [#49][]
  - Remove `/tmp` files when packaging quantal64 base box [#48][]
  - Avoid picking the best mirror on quantal64 base box [#38][]

BUG FIXES:

  - Redirect `redir`'s stderr output to `/dev/null` [#51][]
  - Switch from `ifconfig` to `ip` to grab container's IP to avoid localization issues [#50][]

## [0.2.0](https://github.com/fgrehm/vagrant-lxc/compare/v0.1.1...v0.2.0) (March 30, 2013)

  - Experimental box packaging (only tested with Ubuntu 64 base box)

## [0.1.1](https://github.com/fgrehm/vagrant-lxc/compare/v0.1.0...v0.1.1) (March 29, 2013)

  - Removed support for development under Vagrant < 1.1
  - Removed rsync from base quantal64 box to speed up containers creation [#40][]
  - Containers are now named after project's root dir [#14][]
  - Skip Vagrant's built in SSH redirect
  - Allow setting rootfs from Vagrantfile [#30][]

## [0.1.0](https://github.com/fgrehm/vagrant-lxc/compare/v0.0.3...v0.1.0) (March 27, 2013)

  - Support for chef added to base quantal64 box
  - Puppet upgraded to 3.1.1 on base quantal64 box
  - Port forwarding support added [#6][]

## Previous

The changelog began with version 0.1.0 so any changes prior to that
can be seen by checking the tagged releases and reading git commit
messages.
