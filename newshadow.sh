#!/bin/bash
clear
echo -e "\033[0;36m==============================================\033[0m"
echo -e "\033[0;36m    VLESS + REALITY + gRPC (ULTIMATE)        \033[0m"
echo -e "\033[0;36m==============================================\033[0m"

# 1. Force Reset Xray
sudo systemctl stop xray 2>/dev/null
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)

# 2. Generate Credentials
UUID=$(xray uuid)
KEYS=$(xray x25519)
PRIVATE_KEY=$(echo "$KEYS" | awk '/Private key:/ {print $3}')
PUBLIC_KEY=$(echo "$KEYS" | awk '/Public key:/ {print $3}')
SHORT_ID=$(openssl rand -hex 8)

# 3. Write Config (Using Port 8443 to avoid conflicts)
cat <<EOF | sudo tee /usr/local/etc/xray/config.json
{
    "log": {"loglevel": "warning"},
    "inbounds": [{
        "port": 8443,
        "protocol": "vless",
        "settings": {
            "clients": [{"id": "$UUID", "flow": ""}],
            "decryption": "none"
        },
        "streamSettings": {
            "network": "grpc",
            "security": "reality",
            "realitySettings": {
                "show": false,
                "dest": "www.google.com:443",
                "xver": 0,
                "serverNames": ["www.google.com"],
                "privateKey": "$PRIVATE_KEY",
                "shortIds": ["$SHORT_ID"]
            },
            "grpcSettings": {"serviceName": "grpc-service"}
        }
    }],
    "outbounds": [{"protocol": "freedom"}]
}
EOF

# 4. Critical Firewall & Routing
sudo ufw allow 8443/tcp
sudo ufw allow 8443/udp
sudo sysctl -w net.ipv4.ip_forward=1
sudo systemctl restart xray

# 5. Generate Link
IP=$(curl -s https://api.ipify.org)
LINK="vless://$UUID@$IP:8443?encryption=none&security=reality&sni=www.google.com&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=grpc&serviceName=grpc-service#Ultimate-Anonymity"

echo -e "\n\033[0;32m--- CONFIGURATION COMPLETE ---\033[0m"
echo -e "Import this into v2rayNG:\n"
echo -e "\033[1;33m$LINK\033[0m\n"
qrencode -t ansiutf8 "$LINK"
