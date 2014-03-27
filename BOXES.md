# vagrant-lxc base boxes

Although the official documentation says it is only supported for VirtualBox
environments, you can use the [`vagrant package`](http://docs.vagrantup.com/v2/cli/package.html)
command to export a `.box` file from an existing vagrant-lxc container.

There is also a set of [bash scripts](https://github.com/fgrehm/vagrant-lxc-base-boxes)
that you can use to build base boxes as needed. By default it won't include any
provisioning tool and you can pick the ones you want by providing some environment
variables. Please refer to the [base boxes repository](https://github.com/fgrehm/vagrant-lxc-base-boxes)
for more information.

## "Anatomy" of a box

If you need to go deeper and build your scripts from scratch or if you are interested
on knowing what makes a base box for vagrant-lxc, here's what's needed:

### Expected `.box` contents

| FILE            | REQUIRED? | DESCRIPTION |
| ---             | ---       | ---         |
| `metadata.json` | Yes       | Required by Vagrant |
| `rootfs.tar.gz` | Yes       | Compressed container rootfs tarball (need to remeber to pass in `--numeric-owner` when creating it) |
| `lxc-template`  | No, a ["generic script"](scripts/lxc-template) is provided by the plugin if it doesn't exist on the base box | Script responsible for creating and setting up the container (used with `lxc-create`). |
| `lxc-config`    | No        | Box specific configuration to be _appended_ to the system's generated container config file |
| `lxc.conf`      | No        | File passed in to `lxc-create -f` |

### metadata.json

```json
{
  "provider": "lxc",
  "version":  "1.0.0",
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
| `built-on`      | No        | Date / time when the box was packaged for the first time |
| `template-opts` | No        | Extra options to be passed to the `lxc-template` script |
