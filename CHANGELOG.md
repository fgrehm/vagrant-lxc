## [1.3.0](https://github.com/fgrehm/vagrant-lxc/compare/v1.2.4...v1.3.0) (Jan 20, 2018)

FEATURES:
  - lxc-template: make runnable by unprivileged users [[GH-447]]
  - Use `lxc-info` instead of `lxc-attach` to retrieve container IP
  - Add support for LXC v2.1+ [[GH-445]]
  - Remove 2Gb limitation on `/tmp`. [[GH-406]]

OTHERS:
  - Bump Vagrant requirements to v1.8+
  - Bump LXC requirements to v1.0+


[GH-447]: https://github.com/fgrehm/vagrant-lxc/pull/447
[GH-445]: https://github.com/fgrehm/vagrant-lxc/pull/445
[GH-406]: https://github.com/fgrehm/vagrant-lxc/pull/406

## [1.2.4](https://github.com/fgrehm/vagrant-lxc/compare/v1.2.3...v1.2.4) (Dec 20, 2017)

BUGFIX:
  - Support alternative `lxcpath` [[GH-413]]
  - Update `pipework` regexp in sudo wrapper for Vagrant 1.9+ [[GH-438]]
  - Work around restrictive `umask` values [[GH-435]]
  - Make `--config` in `lxc-template` optional [[GH-421]]
  - Fix sudo wrapper binpath construction logic [[GH-410]]
  - Fix bug causing CTRL-C on `vagrant up` to destroy the VM [[GH-449]]

[GH-413]: https://github.com/fgrehm/vagrant-lxc/pull/413
[GH-438]: https://github.com/fgrehm/vagrant-lxc/pull/438
[GH-435]: https://github.com/fgrehm/vagrant-lxc/pull/435
[GH-421]: https://github.com/fgrehm/vagrant-lxc/pull/421
[GH-410]: https://github.com/fgrehm/vagrant-lxc/pull/410
[GH-449]: https://github.com/fgrehm/vagrant-lxc/pull/449

## [1.2.3](https://github.com/fgrehm/vagrant-lxc/compare/v1.2.2...v1.2.3) (Dec 20, 2016)

  - Fix bug in Gemfile.lock

## [1.2.2](https://github.com/fgrehm/vagrant-lxc/compare/v1.2.1...v1.2.2) (Dec 20, 2016)

BUGFIX:
  - Make the timeout for fetching container IP's configurable [[GH-426]]
  - Load locale file only once [[GH-423]]
  - Preserve xattrs in container filesystems [[GH-411]]
  - Forward port latest pipework script [[GH-408]]
  - Fix handling of non-fatal lxc-stop return code [[GH-405]]

[GH-426]: https://github.com/fgrehm/vagrant-lxc/pull/426
[GH-423]: https://github.com/fgrehm/vagrant-lxc/pull/423
[GH-411]: https://github.com/fgrehm/vagrant-lxc/pull/411
[GH-408]: https://github.com/fgrehm/vagrant-lxc/pull/408
[GH-405]: https://github.com/fgrehm/vagrant-lxc/pull/405

## [1.2.1](https://github.com/fgrehm/vagrant-lxc/compare/v1.2.0...v1.2.1) (Sep 24, 2015)

BUGFIX:
  - Fix sudo Wrapper [[GH-393]]
 
[GH-393]: https://github.com/fgrehm/vagrant-lxc/pull/393

## [1.2.0](https://github.com/fgrehm/vagrant-lxc/compare/v1.1.0...v1.2.0) (Sep 15, 2015)

FEATURES:
  - Support private networking using DHCP [[GH-352]]

[GH-352]: https://github.com/fgrehm/vagrant-lxc/pull/352

IMPROVEMENTS:

  - Move mountpoint creation to lxc template for lvm rootfs support [[GH-361]] / [[GH-359]]
  - Mount selinux sys dir read-only [[GH-357]] / [[GH-301]]
  - Use correct ruby interpreter when generating sudoers file [[GH-355]]
  - Fix shebangs to be more portable [[GH-376]]
  - Fix removal of lxcbr0/virbr0 when using private networking [[GH-383]]
  - Improve /tmp handling by using tmpfs [[GH-362]]

[GH-301]: https://github.com/fgrehm/vagrant-lxc/issues/301
[GH-355]: https://github.com/fgrehm/vagrant-lxc/pull/355
[GH-357]: https://github.com/fgrehm/vagrant-lxc/pull/357
[GH-359]: https://github.com/fgrehm/vagrant-lxc/issues/359
[GH-361]: https://github.com/fgrehm/vagrant-lxc/pull/361
[GH-376]: https://github.com/fgrehm/vagrant-lxc/pull/376
[GH-383]: https://github.com/fgrehm/vagrant-lxc/pull/383
[GH-362]: https://github.com/fgrehm/vagrant-lxc/pull/362

## [1.1.0](https://github.com/fgrehm/vagrant-lxc/compare/v1.0.1...v1.1.0) (Jan 14, 2015)

BACKWARDS INCOMPATIBILITIES:

  - Support for Vagrant versions prior to 1.5 have been removed. The plugin now targets
    Vagrant 1.7+ but it _might_ work on 1.5+.

FEATURES:

  - New experimental support for private networking [[GH-298]] / [[GH-120]].
  - Support for formatted overlayfs path [[GH-329]]


[GH-298]: https://github.com/fgrehm/vagrant-lxc/pull/298
[GH-120]: https://github.com/fgrehm/vagrant-lxc/issues/120
[GH-329]: https://github.com/fgrehm/vagrant-lxc/pull/329

IMPROVEMENTS:

  - The provider will now have a higher priority over the VirtualBox provider
    in case VirtualBox is installed alongside lxc dependecies.
  - Show an user friendly message when trying to use the plugin on non-Linux
    environments.

BUG FIXES:

  - Allow backingstore options to be used along with the sudo wrapper script [[GH-310]]
  - Trim automatically generated container names to 64 chars [[GH-337]]

[GH-337]: https://github.com/fgrehm/vagrant-lxc/issues/337
[GH-310]: https://github.com/fgrehm/vagrant-lxc/issues/310


## [1.0.1](https://github.com/fgrehm/vagrant-lxc/compare/v1.0.0...v1.0.1) (Oct 15, 2014)

IMPROVEMENTS:

  - Avoid lock race condition when fetching container's IP [[GH-318]] and SSH execution [[GH-321]]
  - Support for custom containers storage path by reading `lxc.lxcpath` [[GH-317]]


[GH-317]: https://github.com/fgrehm/vagrant-lxc/pull/317
[GH-318]: https://github.com/fgrehm/vagrant-lxc/pull/318
[GH-321]: https://github.com/fgrehm/vagrant-lxc/issues/321

## [1.0.0](https://github.com/fgrehm/vagrant-lxc/compare/v1.0.0.alpha.3...v1.0.0) (Sep 23, 2014)

DEPRECATIONS:

  - Support to **all Vagrant versions prior to 1.5 are deprecated**, there is a
    [small layer](lib/vagrant-backports) that ensures compatibility with versions
    starting with 1.1.5 that will be removed on a future release.
  - Official base boxes that were made available from http://bit.ly are no longer
    supported and were removed from @fgrehm's Dropbox, please upgrade your Vagrant
    and vagrant-lxc installation and use a base box from [VagrantCloud](https://vagrantcloud.com/search?provider=lxc)

BACKWARDS INCOMPATIBILITIES:

  - Remove plugin version from config file name generated by the `vagrant lxc sudoers`
    command. Manual removal of `/usr/local/bin/vagrant-lxc-wrapper-*` / `/etc/sudoers.d/vagrant-lxc-*`
    files are required.

IMPROVEMENTS:

  - `vagrant-mounted` upstart event is now emited on containers that support it [[GH-302]]
  - Add support for specifying the `--strip-parameters` used by the [default template](scripts/lxc-template)
    when extracting rootfs tarballs [[GH-311]]

[GH-302]: https://github.com/fgrehm/vagrant-lxc/issues/302

BUG FIXES:

  - Check for outdated base boxes when starting containers [[GH-314]]

[GH-311]: https://github.com/fgrehm/vagrant-lxc/pull/311
[GH-314]: https://github.com/fgrehm/vagrant-lxc/pull/314


## [1.0.0.alpha.3](https://github.com/fgrehm/vagrant-lxc/compare/v1.0.0.alpha.2...v1.0.0.alpha.3) (Aug 9, 2014)

IMPROVEMENTS:

  - Remove `lxc-shutdown` usage in favor of Vagrant's built in graceful halt
  - Add fallback mechanism for platforms without `lxc-attach` support [[GH-294]]

[GH-294]: https://github.com/fgrehm/vagrant-lxc/pull/294

BUG FIXES:

  - Figure out the real executable paths for whitelisted commands on the sudo
    wrapper script instead of hardcoding Ubuntu paths [[GH-304]] / [[GH-305]]
  - Attach to containers using the `MOUNT` namespace when attempting to fetch
    container's IP [[GH-300]]
  - Escape space characters for synced folders [[GH-291]]
  - Use Vagrant's ruby on the sudoers file so that it works on systems that don't
    have a global ruby installation [[GH-289]]

[GH-304]: https://github.com/fgrehm/vagrant-lxc/issues/304
[GH-305]: https://github.com/fgrehm/vagrant-lxc/issues/305
[GH-300]: https://github.com/fgrehm/vagrant-lxc/issues/300
[GH-291]: https://github.com/fgrehm/vagrant-lxc/issues/291
[GH-289]: https://github.com/fgrehm/vagrant-lxc/issues/289


## [1.0.0.alpha.2](https://github.com/fgrehm/vagrant-lxc/compare/v1.0.0.alpha.1...v1.0.0.alpha.2) (May 13, 2014)

BACKWARDS INCOMPATIBILITIES:

  - The `sudo_wrapper` provider configuration was removed in favor of using the
    secure wrapper generated by `vagrant lxc sudoers` [[GH-272]]
  - Support for specifying backingstore parameters from `Vagrantfile`s for `lxc-create`
    was added and it defaults to the `best` option. On older lxc versions that does not
    support that value, it needs to be set to `none`.

FEATURES:

  - Add support for specifying backingstore parameters from `Vagrantfile`s [[GH-277]]

IMPROVEMENTS:

  - Make `dnsmasq` leases MAC address regex check case insensitive [[GH-283]]
  - Use relative paths for `lxc.mount.entry` to avoid issues with `lxc-clone` [[GH-258]].
  - Sort synced folders when mounting [[GH-271]]
  - Privileged ports can now be forwarded with `sudo` [[GH-259]]
  - The `vagrant lxc sudoers` generated sudoers configuration and wrapper script
    are safer and properly whitelists the commands required by vagrant-lxc to run.
    [[GH-272]] / [[GH-269]]

BUG FIXES:

  - Fix `lxc-create` issues with pre 1.0.0 versions [[GH-282]]

[GH-283]: https://github.com/fgrehm/vagrant-lxc/pull/283
[GH-282]: https://github.com/fgrehm/vagrant-lxc/pull/282
[GH-269]: https://github.com/fgrehm/vagrant-lxc/issues/269
[GH-272]: https://github.com/fgrehm/vagrant-lxc/pull/272
[GH-259]: https://github.com/fgrehm/vagrant-lxc/pull/259
[GH-271]: https://github.com/fgrehm/vagrant-lxc/pull/271
[GH-277]: https://github.com/fgrehm/vagrant-lxc/pull/277
[GH-258]: https://github.com/fgrehm/vagrant-lxc/issues/258


## [1.0.0.alpha.1](https://github.com/fgrehm/vagrant-lxc/compare/v0.8.0...v1.0.0.alpha.1) (Apr 06, 2014)

DEPRECATIONS:

  - Support to **all Vagrant versions prior to 1.5 are now deprecated**, there is a
    [small layer](lib/vagrant-backports) that ensures compatibility with versions
    starting with 1.1.5 but there is no guarantee that it will stick for too long.
  - Boxes released prior to this version are now deprecated and won't be available
    after the final 1.0.0 release.
  - `--auth-key` argument is no longer provided to `lxc-template`. This will cause
    all official base boxes prior to 09/28/2013 to break.

FEATURES:

  - New `vagrant lxc sudoers` command for creating a policy for users in order to
    avoid `sudo` passwords [[GH-237]] / [[GH-257]]
  - Support for NFS and rsync synced folders.
  - Support for synced folder mount options allowing for using read only synced
    folders [[GH-193]]

[GH-237]: https://github.com/fgrehm/vagrant-lxc/issues/237
[GH-257]: https://github.com/fgrehm/vagrant-lxc/pull/257
[GH-193]: https://github.com/fgrehm/vagrant-lxc/issues/193

IMPROVEMENTS:

  - `lxc-template` is now optional for base boxes and are bundled with the plugin,
    allowing us to roll out updates without the need to rebuild boxes [[GH-254]]
  - Set container's `utsname` to `config.vm.hostname` by default [[GH-253]]
  - Added libvirt dnsmasq leases file to the lookup paths [[GH-251]]
  - Improved compatibility with Vagrant 1.4 / 1.5 including the ability
    to use `rsync` and `nfs` shared folders to work around synced folders
    permission problems. More information can be found on the following
    issues: [[GH-151]] [[GH-191]] [[GH-241]] [[GH-242]]
  - Warn in case `:group` or `:owner` are specified for synced folders [[GH-196]]
  - Acceptance specs are now powered by `vagrant-spec` [[GH-213]]
  - Base boxes creation scripts were moved out to https://github.com/fgrehm/vagrant-lxc-base-boxes.

[GH-254]: https://github.com/fgrehm/vagrant-lxc/issues/254
[GH-196]: https://github.com/fgrehm/vagrant-lxc/issues/196
[GH-251]: https://github.com/fgrehm/vagrant-lxc/pull/251
[GH-253]: https://github.com/fgrehm/vagrant-lxc/pull/253
[GH-151]: https://github.com/fgrehm/vagrant-lxc/issues/151
[GH-213]: https://github.com/fgrehm/vagrant-lxc/issues/213
[GH-191]: https://github.com/fgrehm/vagrant-lxc/issues/191
[GH-241]: https://github.com/fgrehm/vagrant-lxc/issues/241
[GH-242]: https://github.com/fgrehm/vagrant-lxc/issues/242


## [0.8.0](https://github.com/fgrehm/vagrant-lxc/compare/v0.7.0...v0.8.0) (Feb 26, 2014)

FEATURES:

  - Support for naming containers from Vagrantfiles [#132](https://github.com/fgrehm/vagrant-lxc/issues/132)

IMPROVEMENTS:

  - Use a safer random name for containers [#152](https://github.com/fgrehm/vagrant-lxc/issues/152)
  - Improve Ubuntu 13.10 compatibility [#190](https://github.com/fgrehm/vagrant-lxc/pull/190) / [#197](https://github.com/fgrehm/vagrant-lxc/pull/197)
  - Improved mac address detection from lxc configs [#226](https://github.com/fgrehm/vagrant-lxc/pull/226)

BUG FIXES:

  - Properly detect if lxc is installed on hosts that do not have `lxc-version` on their paths [#186](https://github.com/fgrehm/vagrant-lxc/issues/186)


## [0.7.0](https://github.com/fgrehm/vagrant-lxc/compare/v0.6.4...v0.7.0) (Nov 8, 2013)

IMPROVEMENTS:

  - Support for `vagrant up` in parallel [#152](https://github.com/fgrehm/vagrant-lxc/issues/152)
  - Warn users about unsupported private / public networking configs [#154](https://github.com/fgrehm/vagrant-lxc/issues/154)
  - Respect Vagrantfile options to disable forwarded port [#149](https://github.com/fgrehm/vagrant-lxc/issues/149)

BUG FIXES:

  - Nicely handle blank strings provided to `:host_ip` when specifying forwarded ports [#170](https://github.com/fgrehm/vagrant-lxc/issues/170)
  - Fix "Permission denied" when starting/destroying containers after lxc
    security update in Ubuntu [#180](https://github.com/fgrehm/vagrant-lxc/issues/180)
  - Fix `vagrant package` [#172](https://github.com/fgrehm/vagrant-lxc/issues/172)


## [0.6.4](https://github.com/fgrehm/vagrant-lxc/compare/v0.6.3...v0.6.4) (Oct 27, 2013)

FEATURES:

  - New script for building OpenMandriva base boxes [#167](https://github.com/fgrehm/vagrant-lxc/issues/167)

IMPROVEMENTS:

  - Make `lxc-template` compatible with Ubuntu 13.10 [#150](https://github.com/fgrehm/vagrant-lxc/issues/150)

BUG FIXES:

  - Fix force halt for hosts that do not have `lxc-shutdown` around (like Ubuntu 13.10) [#150](https://github.com/fgrehm/vagrant-lxc/issues/150)

## [0.6.3](https://github.com/fgrehm/vagrant-lxc/compare/v0.6.2...v0.6.3) (Oct 12, 2013)

IMPROVEMENTS:

  - Respect Vagrantfile option to disable synced folders [#147](https://github.com/fgrehm/vagrant-lxc/issues/147)

BUG FIXES:

  - Fix error raised when fetching container's IP with the sudo wrapper disabled [#157](https://github.com/fgrehm/vagrant-lxc/issues/157)

## [0.6.2](https://github.com/fgrehm/vagrant-lxc/compare/v0.6.1...v0.6.2) (Oct 03, 2013)

IMPROVEMENTS:

  - Cache the result of `lxc-attach --namespaces` parameter support checking to
    avoid excessive logging.

BUG FIXES:

  - Fix detection of `lxc-attach --namespaces` parameter support checking.

## [0.6.1](https://github.com/fgrehm/vagrant-lxc/compare/v0.6.0...v0.6.1) (Oct 03, 2013)

IMPROVEMENTS:

  - Fall back to `dnsmasq` leases file if not able to fetch IP with `lxc-attach` [#118](https://github.com/fgrehm/vagrant-lxc/issues/118)
  - Make sure lxc templates are executable prior to `lxc-create` [#128](https://github.com/fgrehm/vagrant-lxc/issues/128)
  - New base boxes with support for lxc 1.0+

BUG FIXES:

  - Fix various issues related to detecting whether the container is running
    and is "SSHable" [#142](https://github.com/fgrehm/vagrant-lxc/issues/142)
  - Nicely handle missing templates path [#139](https://github.com/fgrehm/vagrant-lxc/issues/139)

## [0.6.0](https://github.com/fgrehm/vagrant-lxc/compare/v0.5.0...v0.6.0) (Sep 12, 2013)

IMPROVEMENTS:

  - Compatibility with Vagrant 1.3+ [#136](https://github.com/fgrehm/vagrant-lxc/pull/136)
  - Set plugin name to `vagrant-lxc` so that it is easier to check if the plugin is
    installed with the newly added `Vagrant.has_plugin?`

BUG FIXES:

  - Fix box package ownership on `vagrant package` [#140](https://github.com/fgrehm/vagrant-lxc/pull/140)
  - Fix error while compressing container's rootfs under Debian hosts [#131](https://github.com/fgrehm/vagrant-lxc/issues/131) /
    [#133](https://github.com/fgrehm/vagrant-lxc/issues/133)

## [0.5.0](https://github.com/fgrehm/vagrant-lxc/compare/v0.4.0...v0.5.0) (Aug 1, 2013)

BACKWARDS INCOMPATIBILITIES:

  - To align with Vagrant's core behaviour, forwarded ports are no longer attached
    to 127.0.0.1 and `redir`'s `--laddr` parameter is skipped in case the `:host_ip`
    config is not provided, that means `redir` will listen on connections coming
    from any of the host's IPs.

FEATURES:

  - Add support for salt-minion and add latest dev release for ubuntu codenamed saucy [#116](https://github.com/fgrehm/vagrant-lxc/pull/116)
  - Add support for using a sudo wrapper script [#90](https://github.com/fgrehm/vagrant-lxc/issues/90)
  - `redir` will log to `/var/log/syslog` if `REDIR_LOG` env var is provided

IMPROVEMENTS:

  - Error out if dependencies are not installed [#11](https://github.com/fgrehm/vagrant-lxc/issues/11) / [#112](https://github.com/fgrehm/vagrant-lxc/issues/112)
  - Support for specifying host interface/ip for binding `redir` [#76](https://github.com/fgrehm/vagrant-lxc/issues/76)
  - Add Vagrantfile VM name to the container name [#115](https://github.com/fgrehm/vagrant-lxc/issues/115)
  - Properly handle forwarded port collisions [#5](https://github.com/fgrehm/vagrant-lxc/issues/5)
  - Container's customizations are now written to the config file (usually
    kept under `/var/lib/lxc/CONTAINER/config`) instead of passed in as a `-s`
    parameter to `lxc-start`

## [0.4.0](https://github.com/fgrehm/vagrant-lxc/compare/v0.3.4...v0.4.0) (Jul 18, 2013)

FEATURES:

  - New box format [#89](https://github.com/fgrehm/vagrant-lxc/issues/89)

BUG FIXES:

  - Add translation for stopped status [#97](https://github.com/fgrehm/vagrant-lxc/issues/97)
  - Enable retries when fetching container state [#74](https://github.com/fgrehm/vagrant-lxc/issues/74)
  - Fix error when setting Debian boxes hostname from Vagrantfile [#91](https://github.com/fgrehm/vagrant-lxc/issues/91)
  - BTRFS-friendly base boxes [#81](https://github.com/fgrehm/vagrant-lxc/issues/81)
  - Extended templates path lookup [#77](https://github.com/fgrehm/vagrant-lxc/issues/77) (tks to @aries1980)
  - Fix default group for packaged boxes tarballs on the rake task [#82](https://github.com/fgrehm/vagrant-lxc/issues/82) (tks to @cduez)

## [0.3.4](https://github.com/fgrehm/vagrant-lxc/compare/v0.3.3...v0.3.4) (May 08, 2013)

FEATURES:

  - Support for building Debian boxes (tks to @Val)
  - Support for installing babushka on base boxes (tks to @Val)

IMPROVEMENTS:

  - Replace `lxc-wait` usage with a "[retry mechanism](https://github.com/fgrehm/vagrant-lxc/commit/3cca16824879731315dac32bc2df1c643f30d461#L2R88)" [#22](https://github.com/fgrehm/vagrant-lxc/issues/22)
  - Remove `/tmp` files after the machine has been successfully shut down [#68](https://github.com/fgrehm/vagrant-lxc/issues/68)
  - Clean up base boxes files after they've been configured, resulting in smaller packages
  - Bump development dependency to Vagrant 1.2+ series

BUG FIXES:

  - Issue a `lxc-stop` in case the container cannot shutdown gracefully [#72](https://github.com/fgrehm/vagrant-lxc/issues/72)

## [0.3.3](https://github.com/fgrehm/vagrant-lxc/compare/v0.3.2...v0.3.3) (April 23, 2013)

BUG FIXES:

  - Properly kill `redir` child processes [#59](https://github.com/fgrehm/vagrant-lxc/issues/59)
  - Use `uname -m` on base Ubuntu lxc-template [#53](https://github.com/fgrehm/vagrant-lxc/issues/53)

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
  - Removed support for configuring private networks. It will come back at some point in the future but if you need it you should be able to set using `customize 'network.ipv4', '1.2.3.4/24'`

IMPROVEMENTS:

  - lxc templates are removed from lxc template dir after container is created
  - Treat NFS shared folders as a normal shared folder instead of ignoring it so we can share the same Vagrantfile with VBox environments
  - Support for lxc 0.7.5 (tested on Ubuntu 12.04) [#49](https://github.com/fgrehm/vagrant-lxc/issues/49)
  - Remove `/tmp` files when packaging quantal64 base box [#48](https://github.com/fgrehm/vagrant-lxc/issues/48)
  - Avoid picking the best mirror on quantal64 base box [#38](https://github.com/fgrehm/vagrant-lxc/issues/38)

BUG FIXES:

  - Redirect `redir`'s stderr output to `/dev/null` [#51](https://github.com/fgrehm/vagrant-lxc/issues/51)
  - Switch from `ifconfig` to `ip` to grab container's IP to avoid localization issues [#50](https://github.com/fgrehm/vagrant-lxc/issues/50)

## [0.2.0](https://github.com/fgrehm/vagrant-lxc/compare/v0.1.1...v0.2.0) (March 30, 2013)

  - Experimental box packaging (only tested with Ubuntu 64 base box)

## [0.1.1](https://github.com/fgrehm/vagrant-lxc/compare/v0.1.0...v0.1.1) (March 29, 2013)

  - Removed support for development under Vagrant < 1.1
  - Removed rsync from base quantal64 box to speed up containers creation [#40](https://github.com/fgrehm/vagrant-lxc/issues/40)
  - Containers are now named after project's root dir [#14](https://github.com/fgrehm/vagrant-lxc/issues/14)
  - Skip Vagrant's built in SSH redirect
  - Allow setting rootfs from Vagrantfile [#30](https://github.com/fgrehm/vagrant-lxc/issues/30)

## [0.1.0](https://github.com/fgrehm/vagrant-lxc/compare/v0.0.3...v0.1.0) (March 27, 2013)

  - Support for chef added to base quantal64 box
  - Puppet upgraded to 3.1.1 on base quantal64 box
  - Port forwarding support added [#6](https://github.com/fgrehm/vagrant-lxc/issues/6)

## Previous

The changelog began with version 0.1.0 so any changes prior to that
can be seen by checking the tagged releases and reading git commit
messages.
