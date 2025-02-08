# Wireguard commands

## Installation

```sh
apt install wireguard

nano /etc/wireguard/wg0.conf

net.ipv4.ip_forward = 1

sysctl -p

systemctl start wg-quick@wg0
```

## Run

```sh

```
