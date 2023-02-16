# Flatcar Container Linux image for OpenNebula

This repository contains a [Packer](https://www.packer.io) template
for creating [Flatcar Container Linux](https://flatcar.org) KVM images for
[OpenNebula](http://opennebula.org).

Based on [@carletes](https://github.com/carletes)'s
[coreos-opennebula-image](https://github.com/carletes/coreos-opennebula-image),
which is based on [@bfraser](https://github.com/bfraser)'s
[packer-coreos-qemu](https://github.com/bfraser/packer-coreos-qemu).


## Building the OpenNebula image

You will need:

* [Packer](https://www.packer.io) (tested with version 1.8.3)
* [QEMU](http://wiki.qemu.org/Main_Page) (tested with version 6.2.0)
* [GNU Make](https://www.gnu.org/software/make/)

A Linux host with KVM support will make the build much faster.

The build process is driven with `make`:

    $ make
	[..]
	Image file builds/flatcar-stable-qemu/flatcar-stable ready
	$

By default, `make` will build a Flatcar image from the
[Flatcar stable channel](https://stable.release.flatcar-linux.net/amd64-usr/current/).
You may specify a particular Flatcar version and channel by passing the appropriate
parameters to `make`:

    $ make FLATCAR_CHANNEL=stable
	[..]
	Image file builds/flatcar-stable-qemu/flatcar-stable ready
	$


## Registering the image with OpenNebula

Once the image has been built, you may upload it to OpenNebula using
the
[Sunstone UI](https://docs.opennebula.io/5.12/operation/vm_management/img_guide.html#managing-images).

Alternatively, if you are allowed to access OpenNebula using its
[command-line tools](https://docs.opennebula.io/5.12/operation/references/cli.html#command-line-interface),
you may upload the image usng `make`:

    $ make register

The `register` target also accepts specific Flatcar channels and
versions:

    $ make register FLATCAR_CHANNEL=stable

If you plan on using OpenNebula's
[EC2 interface](https://docs.opennebula.io/5.12/advanced_components/public_cloud/ec2qug.html#opennebula-ec2-usage),
the image should be tagged with the attribute `EC2_AMI` set to `YES`
(the `register` target does this for you).


## Creating an OpenNebula VM template

Before creating Flatcar VMs, you will need to create an
[OpenNebula VM template](https://docs.opennebula.io/5.12/operation/vm_management/vm_templates.html#managing-virtual-machine-templates)
which uses the Flatcar images you have built. The VM template should
follow these conventions:

* It should use the image you have created and uploaded.
* The first network interface will be used as Flatcar' private IPv4
  address.
* If there is a second network interface defined, it will be used as
  Flatcar' public IPv4 network.
* You should add a user input field called `USER_DATA`, so that you
  may pass extra
  [cloud-config](https://github.com/flatcar/coreos-cloudinit)
  user data to configure your Flatcar instance.

The following template assumes a Flatcar image called `flatcar-stable`,
and two virtual networks called `public-net` and `private-net`, and
uses them to provide the disk and the two network interfaces of a
virtual machine:

	NAME = flatcar-stable
	MEMORY = 512
	CPU = 1
	HYPERVISOR = kvm
	OS = [
	  ARCH = x86_64,
	  BOOT = hd
	]
	DISK = [
	  DRIVER = qcow2,
	  IMAGE = flatcar-stable
	]
	NIC=[
	  NETWORK = private-net
	]
	NIC=[
	  NETWORK = public-net
	]
	GRAPHICS = [
	  TYPE = VNC,
	  LISTEN = 0.0.0.0
	]
	USER_INPUTS = [
	  USER_DATA = "M|text|User data for `cloud-config`"
	]
	CONTEXT = [
	  NETWORK = YES,
	  SET_HOSTNAME = "$NAME",
	  SSH_PUBLIC_KEY = "$USER[SSH_PUBLIC_KEY]",
	  USER_DATA = "$USER_DATA"
	]


### Setting the VM host name

The host name in the VM will be set to the
OpenNebula VM name. If you want the host name to be assigned by
reverse DNS lookup, replace the line:

    SET_HOSTNAME = "SNAME"

with:

    DNS_HOSTNAME = YES

in the `CONTEXT` section, as you would do with any other OpenNebula
template.

If no host name is passed (or none can be found with reverse DNS
lookup), the VM host name will be set to a value based on the MAC
address of the first network interface.

If you specify a value for the `hostname` field in the `cloud-config`
user data, it will take precedence over anything else.


## Contributing

Just fork this repository and open a pull request.
