# vagrant-lxc base boxes

This repository contains a set of scripts for creating base boxes for usage with
[vagrant-lxc](https://github.com/fgrehm/vagrant-lxc) 1.0+.

## What distros / versions can I build with this?

* Ubuntu
  - Precise 12.04 x86_64
  - Quantal 12.10 x86_64
  - Raring 13.04 x86_64
  - Saucy 13.10 x86_64
  - Trusty 14.04 x86_64
  - Utopic 14.10 x86_64
  - Vivid 15.04 x86_64
  - Wily 15.10 x86_64
  - Xenial 16.04 x86_64
  - Yakkety 16.10 x86_64
  - Bionic 18.04 x86_64
  - Focal 20.04 x86_64
* Debian
  - Squeeze x86_64
  - Wheezy x86_64
  - Jessie x86_64
  - Stretch x86_64
  - Sid x86_64
  - Buster x86_64
* Fedora
  - 19 x86_64
  - 20 x86_64
  - 21 x86_64
  - 22 x86_64
  - 23 x86_64
  - rawhide x86_64
  - 33 x86_64
* CentOS
  - 6 x86_64
  - 7 x86_64

## Building the boxes

_In order to build the boxes you need to have the `lxc-download`
template available on your machine. If you don't have one around please
create one based on [this](https://github.com/lxc/lxc/blob/master/templates/lxc-download.in)
and drop it on your lxc templates path (usually `/usr/share/lxc/templates`)._

```sh
git clone https://github.com/obnoxxx/vagrant-lxc-base-boxes.git
cd vagrant-lxc-base-boxes
make precise
```

List of supported distributions through Makefile

| `make` target | Distribution |
| ----------- | ------------ |
| precise | Ubuntu 12.04 LTS |
| quantal | Ubuntu 12.10 |
| raring | Ubuntu 13.04 |
| saucy | Ubuntu 13.10 |
| trusty | Ubuntu 14.04 LTS |
| utopic | Ubuntu 14.10 |
| vivid | Ubuntu 15.04 |
| wily | Ubuntu 15.10 |
| xenial | Ubuntu 16.04 |
| yakkety | Ubuntu 16.10 |
| bionic | Ubuntu 18.04 LTS |
| focal | Ubuntu 20.04 LTS |
| squeeze | Debian 6 |
| wheezy | Debian 7 |
| jessie | Debian 8 |
| stretch | Debian 9 |
| buster | Debian 10 |
| sid | Debian SID |
| centos6 | CentOS 6 |
| centos7 | CentOS 7 |
| fedora33 | Fedora 33 |
| rawhide | Fedora Rawhide |
| fedora23 | Fedora 23 |
| fedora22 | Fedora 22 |
| fedora21 | Fedora 21 |
| fedora20 | Fedora 20 ( Heisenbug ) |
| fedora19 | Fedora 19 (Schrödinger's Cat) |

By default no provisioning tools will be included but you can pick the ones
you want by providing some environmental variables. For example:

```sh
ANSIBLE=1 PUPPET=1 CHEF=1 SALT=1 BABUSHKA=1 \
make precise
```

Will build a Ubuntu Precise x86_64 box with latest Ansible, Puppet, Chef, Salt and
Babushka pre-installed.

When using ANSIBLE=1, an optional ANSIBLE_VERSION parameter may be passed that will specify which version of ansible to install. By default it will install the latest Ansible.

Additional packages to be installed can be specified with the ADDPACKAGES variable:

```sh
ADDPACKAGES="aptitude htop" \
make trusty
```

Will build a Ubuntu Trusty x86_64 box with aptitude and htop as additional
packages pre-installed. You can also specify the packages in a file
trusty_packages.

Note: ADDPACKAGES is currently only implemented for flavors of debian.

## Pre built base boxes

_**NOTE:** None of the base boxes below have a provisioner pre-installed_

| Distribution | VagrantCloud box |
| ------------ | ---------------- |
| Ubuntu Precise 12.04 x86_64 | [fgrehm/precise64-lxc](https://vagrantcloud.com/fgrehm/precise64-lxc) |
| Ubuntu Trusty 14.04 x86_64 | [fgrehm/trusty64-lxc](https://vagrantcloud.com/fgrehm/trusty64-lxc) |
| Debian Wheezy 7 x86_64 | [fgrehm/wheezy64-lxc](https://vagrantcloud.com/fgrehm/wheezy64-lxc) |
| Debian Jessie 8 x86_64 | [glenux/jessie64-lxc](https://atlas.hashicorp.com/glenux/boxes/jessie64-lxc) |
| CentOS 6 x86_64 | [fgrehm/centos-6-64-lxc](https://vagrantcloud.com/fgrehm/centos-6-64-lxc) |


## What makes up for a vagrant-lxc base box?

See [vagrant-lxc/BOXES.md](https://github.com/fgrehm/vagrant-lxc/blob/master/BOXES.md)


## Known issues

* We can't get the NFS client to be installed on the containers used for building
  Ubuntu 13.04 / 13.10 / 14.04 base boxes.
* Puppet can't be installed on Debian Sid
* Salt can't be installed on Ubuntu 13.04
