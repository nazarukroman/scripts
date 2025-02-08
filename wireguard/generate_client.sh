#!/bin/bash

# Load environment variables
ENV_FILE="$(dirname "$0")/.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo "Warning: .env file not found at $ENV_FILE, using default values"
fi

# Set default values if not defined in .env
DEFAULT_ADDRESS=$DEFAULT_ADDRESS
CONFIG_DIR=${CONFIG_DIR:-"$(dirname "$0")"}
ENDPOINT=$ENDPOINT
DNS=${DNS:-"9.9.9.9"}
WG_SERVER_CONFIG=${WG_SERVER_CONFIG:-"/etc/wireguard/wg0.conf"}

# Determine last used client IP (only from [Peer] sections)
if [ -f "$WG_SERVER_CONFIG" ]; then
    LAST_IP=$(grep -A4 '\[Peer\]' "$WG_SERVER_CONFIG" | grep -oP '(?<=AllowedIPs = )[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | tail -n1)
    if [ -n "$LAST_IP" ]; then
        IFS='.' read -r ip1 ip2 ip3 ip4 <<< "$LAST_IP"
        DEFAULT_ADDRESS="$ip1.$ip2.$ip3.$((ip4 + 1))"
    fi
fi

echo -n "Enter client name (default: new-client): "
read INTERFACE
INTERFACE=${INTERFACE:-"new-client"}

echo -n "Enter client IP address (default: $DEFAULT_ADDRESS): "
read input_address
ADDRESS=${input_address:-$DEFAULT_ADDRESS}

echo -n "Do you want to use full traffic tunnel? (default: false): "
read full_traffic_tunnel
full_traffic_tunnel=${full_traffic_tunnel:-false}

if [ "$full_traffic_tunnel" = "false" ]; then
    IFS='.' read -r ip1 ip2 ip3 ip4 <<< "$ADDRESS"
    ALLOWED_IPS="${ip1}.${ip2}.${ip3}.0/24"
else
    ALLOWED_IPS="0.0.0.0/0"
fi

CONFIG_DIR="$CONFIG_DIR/$INTERFACE"
CONFIG_FILE="$CONFIG_DIR/wg.conf"

mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

# Generate keys with secure permissions
umask 077
wg genkey | tee "$CONFIG_DIR/privatekey" | wg pubkey > "$CONFIG_DIR/publickey"

PRIVATE_KEY=$(cat "$CONFIG_DIR/privatekey")
PUBLIC_KEY=$(cat "$CONFIG_DIR/publickey")

# Get server's public key
SERVER_PUBLIC_KEY=$(wg show wg0 public-key 2>/dev/null || echo "<server-public-key>")

# Generate client configuration
cat > "$CONFIG_FILE" <<EOL
[Interface]
PrivateKey = $PRIVATE_KEY
Address = $ADDRESS/32
DNS = $DNS

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $ENDPOINT
AllowedIPs = $ALLOWED_IPS
PersistentKeepalive = 25
EOL

chmod 600 "$CONFIG_FILE"

# Update server configuration
if [ -f "$WG_SERVER_CONFIG" ]; then
    {
        echo -e "\n# $INTERFACE\n[Peer]"
        echo "PublicKey = $PUBLIC_KEY"
        echo "AllowedIPs = ${ADDRESS%/32}/32"
    } >> "$WG_SERVER_CONFIG"

    # Restart WireGuard service
    if systemctl restart wg-quick@wg0; then
        echo "WireGuard server restarted successfully"
    else
        echo "Failed to restart WireGuard server!"
    fi
else
    echo "Warning: Server configuration file not found, peer not added!"
fi

echo "WireGuard config file created: $CONFIG_FILE"
cat "$WG_SERVER_CONFIG"
