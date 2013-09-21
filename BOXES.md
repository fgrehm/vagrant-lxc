# vagrant-lxc base boxes

Although the official documentation says it is only supported for VirtualBox
environments, you can use the [`vagrant package`](http://docs.vagrantup.com/v2/cli/package.html)
command to export a `.box` file from an existing vagrant-lxc container.

There is also a set of [bash scripts](https://github.com/fgrehm/vagrant-lxc/tree/master/boxes)
that you can use to build base boxes as needed. By default it won't include any
provisioning tool and you can pick the ones you want by providing some environment
variables.

For example:

```
git clone https://github.com/fgrehm/vagrant-lxc.git
cd vagrant-lxc/boxes
PUPPET=1 CHEF=1 sudo -E ./build-ubuntu-box.sh precise amd64
```

Will build a Ubuntu Precise x86_64 box with latest Puppet and Chef pre-installed, please refer to the scripts for more information.

## "Anatomy" of a box

If you need to go deeper and build your scripts from scratch or if you are interested
on knowing what makes a base box for vagrant-lxc, here's what's needed:

### Expected `.box` contents

| FILE            | DESCRIPTION |
| ---             | ---         |
| `lxc-template`  | Script responsible for creating and setting up the container (used with `lxc-create`), a ["generic script"]() is provided along with project's source. |
| `rootfs.tar.gz` | Compressed container rootfs tarball (need to remeber to pass in `--numeric-owner` when creating it) |
| `lxc.conf`      | |
| `metadata.json` | |

### metadata.json

```json
{
  "provider": "lxc",
  "version":  "3",
  "built-on": "Sat Sep 21 21:10:00 UTC 2013",
  "template-opts": {
    "--arch":    "amd64",
    "--release": "quantal"
  }
}
```

| KEY             | REQUIRED? | DESCRIPTION |
| ---             | ---       | ---         |
| `provider`      | Yes       | Required by Vagrant |
| `version`       | Yes       | Tracks backward incompatibilities |
| `built-on`      | No        | Date / time when the box was packaged |
| `template-opts` | No        | Extra options to be passed to the `lxc-template` script provided with the .box package |
