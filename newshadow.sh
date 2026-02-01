#!/bin/bash
clear
echo -e "\033[0;36m==============================================\033[0m"
echo -e "\033[0;36m    VLESS + REALITY (AUTO-KEY FIX)           \033[0m"
echo -e "\033[0;36m==============================================\033[0m"

# 1. Install/Update Xray
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)

# 2. Generate Keys properly
UUID=$(xray uuid)
KEYS=$(xray x25519)
PRIVATE_KEY=$(echo "$KEYS" | awk '/Private key:/ {print $3}')
PUBLIC_KEY=$(echo "$KEYS" | awk '/Public key:/ {print $3}')
SHORT_ID=$(openssl rand -hex 8)

# 3. Validation - Stop if keys are empty
if [ -z "$PRIVATE_KEY" ]; then
    echo -e "\033[0;31mError: Key generation failed. Retrying...\033[0m"
    PRIVATE_KEY=$(/usr/local/bin/xray x25519 | awk '/Private key:/ {print $3}')
    PUBLIC_KEY=$(/usr/local/bin/xray x25519 | awk '/Public key:/ {print $3}')
fi

# 4. Write Config
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

# 5. Firewall & Service Restart
sudo ufw allow 443/tcp
sudo ufw allow 443/udp
sudo systemctl restart xray

# 6. Build the Final Link
IP=$(curl -s https://api.ipify.org)
LINK="vless://$UUID@$IP:443?encryption=none&security=reality&sni=www.microsoft.com&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&flow=xtls-rprx-vision#Reality-Anonymity"

echo -e "\n\033[0;32m--- CONFIGURATION SUCCESSFUL ---\033[0m"
echo -e "\033[1;33mCopy the link below into v2rayNG:\033[0m"
echo -e "\n$LINK\n"

# 7. QR Code
qrencode -t ansiutf8 "$LINK"
