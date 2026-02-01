#!/bin/bash
clear
echo -e "\033[0;36m==============================================\033[0m"
echo -e "\033[0;36m    VLESS + REALITY (INVISIBLE MODE)         \033[0m"
echo -e "\033[0;36m==============================================\033[0m"

# 1. Install Xray
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)

# 2. Generate Keys
UUID=$(xray uuid)
KEYS=$(xray x25519)
PRIVATE_KEY=$(echo "$KEYS" | awk '/Private key:/ {print $3}')
PUBLIC_KEY=$(echo "$KEYS" | awk '/Public key:/ {print $3}')
SHORT_ID=$(openssl rand -hex 8)

# 3. Configure Xray
cat <<EOF | sudo tee /usr/local/etc/xray/config.json
{
    "log": {"loglevel": "warning"},
    "inbounds": [{
        "port": 443,
        "protocol": "vless",
        "settings": {
            "clients": [{"id": "$UUID", "flow": "xtls-rprx-vision"}],
            "decryption": "none"
        },
        "streamSettings": {
            "network": "tcp",
            "security": "reality",
            "realitySettings": {
                "show": false,
                "dest": "www.microsoft.com:443",
                "xver": 0,
                "serverNames": ["www.microsoft.com"],
                "privateKey": "$PRIVATE_KEY",
                "shortIds": ["$SHORT_ID"]
            }
        }
    }],
    "outbounds": [{"protocol": "freedom"}]
}
EOF

# 4. Restart & Firewall
sudo systemctl restart xray
sudo ufw allow 443/tcp
sudo ufw allow 443/udp

# 5. Generate Link
IP=$(curl -s https://api.ipify.org)
LINK="vless://$UUID@$IP:443?encryption=none&security=reality&sni=www.microsoft.com&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&flow=xtls-rprx-vision#Reality-Anonymity"

echo -e "\n\033[0;32m--- SETUP COMPLETE ---\033[0m"
echo -e "Copy this link into v2rayNG:\n"
echo -e "\033[1;33m$LINK\033[0m\n"
qrencode -t ansiutf8 "$LINK"
