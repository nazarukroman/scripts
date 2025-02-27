# Wireguard commands

## Installation

```sh
apt install wireguard

nano /etc/wireguard/wg0.conf
```

В файле /etc/sysctl.conf добавьте или раскомментируйте строку:

```sh
net.ipv4.ip_forward = 1
```

```sh
sysctl -p

apt install openresolv
```

## Run

```sh
systemctl start wg-quick@wg0
```
