# NFS commands

## Install

```sh
apt install nfs-common

mount -t nfs 10.10.0.10:/backups /var/backups
```

## Automatically Mounting NFS File Systems with /etc/fstab

```sh
nano /etc/fstab
```

```sh
/etc/fstab
# <file system>     <dir>       <type>   <options>   <dump>	<pass>
10.10.0.10:/backups /var/backups  nfs      defaults    0       0
```