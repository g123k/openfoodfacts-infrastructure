# Proxmox

On ovh1 and ovh2 we use proxmox to manage VMs.

**TODO** this page is really incomplete !

## Proxmox Backups

Every VM / CT is backuped twice a week using general proxmox backup, in a specific zfs dataset
(see Datacenter -> backup)

## Host network configuration

We configure network through virtual bridges (`vmbr<n>`) that are themselves linked to a physical network device.

Also note that [NGINX proxy] has it's own IP address on a separate bridge, so that it can get network traffic directly.

The local container normally sets their network to be `10.1.0.<ct number>/24`. But they route through `10.0.0.1` (or 2) and for that define the route to `10.0.0.1`. This is all managed by Proxmox.

### On OVH side

vmbr0 is the bridge for the local network.
vmbr1 is the public interface.

Name | Type | Active | Autostart | VLAN | Ports/Slaves | Bond Mode | CIDR | Gateway | Comment
|----|----|----|----|----|----|----|----|----|----|
enp5s0f0  | Network Device  | Yes  | No  | No  |   |   |   |   |   |
enp5s0f1  | Network Device  | Yes  | No  | No  |   |   |   |   |   |
vmbr0  | Linux Bridge  | Yes  | Yes  | No  | enp5s0f1  |   | 10.0.0.1/8  2001:41d0:0203:948c:1::1/80  |   |   |
vmbr1  | Linux Bridge  | Yes  | Yes  | No  | enp5s0f0  |   | 146.59.148.140/24  2001:41d0:0203:948c:0::1/80  | 146.59.148.254  2001:41d0:0203:94ff:ffff:ffff:ffff:ffff  |   |

### On OFF2 side

vmbr0 is the public interface.
vmbr1 is the bridge for the local network.

Name | Type | Active | Autostart | VLAN | Ports/Slaves | Bond Mode | CIDR | Gateway | Comment
|----|----|----|----|----|----|----|----|----|----|
eno1  | Network Device  | Yes  | No  | No  |   |   |   |   |   | 
eno2  | Network Device  | Yes  | No  | No  |   |   |   |   |   | 
vmbr0  | Linux Bridge  | Yes  | Yes  | No  | eno1  |   | 213.36.253.208/27  | 213.36.253.222  |   |
vmbr1  | Linux Bridge  | Yes  | Yes  | No  | eno2  |   | 10.0.0.2/8  |   | Internal network with VM and other free servers  |

This correspond to this settings in `/etc/network/interfaces` (generated by PVE)

```
auto lo
iface lo inet loopback

iface eno1 inet manual

iface eno2 inet manual

auto vmbr0
iface vmbr0 inet static
	address 213.36.253.208/27
	gateway 213.36.253.222
	bridge-ports eno1
	bridge-stp off
	bridge-fd 0

auto vmbr1
iface vmbr1 inet static
	address 10.0.0.2/8
	bridge-ports eno2
	bridge-stp off
	bridge-fd 0
	post-up echo 1 > /proc/sys/net/ipv4/ip_forward
	post-up   iptables -t nat -A POSTROUTING -s '10.1.0.0/16' -o vmbr0 -j MASQUERADE
	post-down iptables -t nat -D POSTROUTING -s '10.1.0.0/16' -o vmbr0 -j MASQUERADE
#Internal network with VM and other free servers
```

**FIXME**: I added the last lines (post-up/down) myself, not sure if PVE would normally add them by itself ?

### Firewall

We use proxmox firewall on host. **FIXME** to be completed.

We have a masquerading rule for 10.1.0.1/24.

## Some Proxmox post-install thing

Remove enterprise repository and add the no-subscription one
```bash
rm /etc/apt/sources.list.d/pve-enterprise.list
echo "deb http://download.proxmox.com/debian/pve "$(lsb_release --short --codename)" pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list
apt update
```

Verify smartclt is activated.

Interesting page: [Techno Tim](https://techno-tim.github.io/posts/first-11-things-proxmox/)

IOMMU ?

Don't forget to schedule [backups](#proxmox-backups).

## HTTP Reverse Proxy

The VM 101 is a http / https proxy to all services.

It has it's own bridge interface with a public facing ip.

See [Nginx reverse proxy](./nginx-reverse-proxy.md)

At OVH we have special DNS entries:
* `proxy1.openfoodfacts.org` pointing to OVH reverse proxy
* `off-proxy.openfoodfacts.org` pointing to Free reverse proxy

## Storage synchronization

VM and container storage are regularly synchronized to ovh3 (and eventually to ovh1/2) to have a continuous backup.

Replication can be seen in the web interface, clicking on "replication" section on a particular container / VM.

This is managed with command line `pvesr` (PVE Storage replication). See [official doc](https://pve.proxmox.com/wiki/Storage_Replication)


## How to migrate a container / VM

You may want to move containers or VM from one server to another.

Just go to the interface, right click on the VM / Container and ask to migrate !

If you have a large disk, you may want to first setup replication of your disk to the target server (see [Storage synchronization](#storage-synchronization)), schedule it immediatly (schedule button)− and then run the migration.

## How to Unlock a Container

Sometimes you may get alerts in email telling backup failed on a VM because it is locked. (`CT is locked`)

This might be a temporary issue, so you should first verify in proxmox console if it's already resolved.

If not you can unlock it using this command:

```
pct unlock <vm-id>
```

## Storage

We use two type of storage: the NVME and zfs storage.
There are also mounts of zfs storage from ovh3.

**TODO** tell much more

### Adding space on a QEMU disk

following https://pve.proxmox.com/wiki/Resize_disks

Example: adding 8GB on VM for monitoring (203) and disk scsi0

On host: `sudo qm resize 203 scsi0 +8G`

On VM:
```bash
sudo parted /dev/sda
(parted) print
Model: QEMU QEMU HARDDISK (scsi)
Disk /dev/sda: 42,9GB
Sector size (logical/physical): 512B/512B
Partition Table: msdos
Disk Flags: 

Number  Start   End     Size    Type      File system     Flags
 1      1049kB  33,3GB  33,3GB  primary   ext4            boot
 2      33,3GB  34,4GB  1022MB  extended
 5      33,3GB  34,4GB  1022MB  logical   linux-swap(v1)
 (parted) quit
```

We have a problem because of swap. We must deactivate swap, remove swap partition and extended partition, augment our main partition, recreate extended and swap partition !

```bash
# deactivate swap
$ sudo swapoff -a
# remove partition in parted, augment main partition, recreate them
$ sudo parted /dev/sda
(parted) rm 5
(parted) rm 2
(parted) print
...
Number  Start   End     Size    Type     File system  Flags
 1      1049kB  33,3GB  33,3GB  primary  ext4         boot
...
(parted) help resizepart
(parted) resizepart 1 41,3GB
(parted) mkpart extended
Start? 41,3GB
End? 100%
(parted) mkpart logical linux-swap 41,3GB 100%
(parted) quit
# resize partition
$ sudo resize2fs /dev/sda1
resize2fs 1.46.2 (28-Feb-2021)
Filesystem at /dev/sda1 is mounted on /; on-line resizing required
old_desc_blocks = 4, new_desc_blocks = 5
The filesystem on /dev/sda1 is now 10082751 (4k) blocks long.
```

Now we have to re-enable swap, but UUID for partition have changed, so we have to edit `/etc/fstab` first.

```bash
# prepare swap
$ sudo mkswap /dev/sda5
Setting up swapspace version 1, size = 1,5 GiB (1648357376 bytes)
no label, UUID=431b8e8e-0691-471c-be8b-2c1039321142
# edit /etc/fstab to point to new UUID
$ sudo vim /etc/fstab
...
# swap was on /dev/sda5 during installation
UUID=431b8e8e-0691-471c-be8b-2c1039321142 none            swap    sw              0       0
/dev/sr0        /media/cdrom0   udf,iso9660 user,noauto     0       0
...
# tell systemd
$ sudo systemctl daemon-reload
# remount swap
sudo swapon -a

```

## Proxmox management interface access

### Create a proxmox user

This user will have the right to use proxmox administration.

see `sudo pveum help user add` and https://pve.proxmox.com/wiki/User_Management#_command_line_tool

`userid`: use something like (for John Doe) `jdoe@pve`.

> **:Pencil: Note:** The user login is the part before `@pve`. Here our user will have to use `jdoe` as username and "Proxmox VE authentication server" as authentication service.

### Reset user password

To reset a user password, use `sudo pveum passwd <userid>`

### Read only group

On proxmox we created a read only group:
```bash
$ pveum group add ro_users -comment "Read only users"
$ pveum acl modify / -group ro_users -role -role PVEAuditor
```

### Admin group

On proxmox we created an administrators group:
```bash
$ pveum group add admin -comment "System Administrators"
$ pveum acl modify / -group admin -role Administrator
```

To add a user to admin group (here `jdoe@pve`):

```bash
$ pveum user modify jdoe@pve -group admin
```

## How to create a new Container

You need to have an account on the Proxmox infra.

Using web interface:
* Login to the Proxmox web interface
* Click on "Create CT"
* Note carefully the container number (ct number)
* Use a "Hostname" to let people know what it is about. Eg. "robotoff", "wiki", "proxy"...
* set Nesting option (systemd recent versions needs it)
* keep "Unprivileged container" option checked… unless you know what you do.
* Password: put something complex and forget it, as we will connect through SSH and not the web interface
* Create a root password - forget about it also (you will use `pct enter` or `lxc-attach`)
* Choose template (normaly debian)
* Disk: try to keep a thight disk space and to avoid using nvme if it's not useful.
* Swap: you might choose 0B (do you really need swap ?) or a sensible value
* Network:
  * Bridge: vmbr0 (may vary, currently vmbr1 on off2 !) - the one which is an "Internal network"
  * IPv4: `10.1.0.<ct number>/24`
    (you need to use /24; end of IPv4 should be the same as the Proxmox container id; container 101 has the 10.1.0.101 IP).
  * Gateway: `10.0.0.1` (may vary, `10.0.0.2` on off2 or ovh2 !)
* Start the server after install

Wait for container to be created and started !

Then connect to the proxmox host:

  * Install useful package and do some other configurations:
    `sudo /root/cluster-scripts/ct_postinstall` choose the container ID when asked.

    See [scripts/proxmox-management/ct_postinstall](https://github.com/openfoodfacts/openfoodfacts-infrastructure/blob/637405791d49abe03f667dae22bd89399ec3c53e/scripts/proxmox-management/ct_postinstall)

  * [create a user](#how-to-create-a-user-in-a-container-or-vm)

Then you can login to the machine (see [logging in to a container or VM](#logging-in-to-a-container-or-vm)).

Using the web interface:

* Check "options" of the container and:
  * Start at boot: Yes
  * Protection: Yes (to avoid deleting it by mistake)

* Add replication to ovh3 or off1/2
  * In the Replication menu of the container, "Add" one
  * Target: ovh3
  * Schedule: */5 if you want every 5 minutes (takes less than 10 seconds, thanks to ZFS)


## Logging in to a container or VM

Most of the time we use ssh to connect to containers and VM. See [how to create a user in a Container or VM](#how-to-create-a-user-in-a-container-or-vm)

For the happy few sudoers on the host, they can attach to containers using `pct enter <num>` (or `lxc-attach -n <num>`) where `<num>` is the VM number. 
This gives a root console in the container and has the advantage of not depending on the container network state.

## how to create a user in a Container or VM


The `sudo /root/cluster-scripts/mkuser` (see script [mkuser](https://github.com/openfoodfacts/openfoodfacts-infrastructure/blob/develop/scripts/proxmox-management/mkuser))  helps you create users using github keys.

Alternatively `sudo /root/cluster-scripts/mkuseralias` can be used if the username on server is different from the GitHub username.

## How to resolve slow ssh login time in container

If when you ssh to a container it takes a long time, here is a possible fix:

See https://gist.github.com/charlyie/76ff7d288165c7d42e5ef7d304245916:

```
# If Debian 11 is ran on a LXC container (Proxmox), SSH login and sudo actions can be slow
# Check if in /var/log/auth.log the following messages 
Failed to activate service 'org.freedesktop.login1': timed out (service_start_timeout=25000ms)

-> Run  systemctl mask systemd-logind
-> Run pam-auth-update (and deselect Register user sessions in the systemd control group hierarchy)
```

## Proxmox installation

Proxmox is installed from a bootable USB disk based on Proxmox VE iso, the way you would install a Debian.
