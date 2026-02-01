#!/bin/bash
clear
echo -e "\033[0;36m==============================================\033[0m"
echo -e "\033[0;36m    TROJAN-gRPC (ANONYMITY EDITION)          \033[0m"
echo -e "\033[0;36m==============================================\033[0m"

# 1. Install Xray (The gold standard for anonymity)
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)

# 2. Generate Certificates
mkdir -p /etc/xray
openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/xray/self.key -out /etc/xray/self.crt -days 365 -subj "/C=US/ST=NY/L=NY/O=Google/OU=IT/CN=www.google.com"

# 3. Set Password
printf "\033[0;33mSet a Strong Password: \033[0m"
read -r password < /dev/tty

# 4. Configure Xray for Trojan-gRPC
cat <<EOF | sudo tee /usr/local/etc/xray/config.json
{
    "log": {"loglevel": "warning"},
    "inbounds": [{
        "port": 443,
        "protocol": "trojan",
        "settings": {
            "clients": [{"password": "$password"}],
            "fallback": 80
        },
        "streamSettings": {
            "network": "grpc",
            "security": "tls",
            "tlsSettings": {
                "certificates": [{
                    "certificateFile": "/etc/xray/self.crt",
                    "keyFile": "/etc/xray/self.key"
                }]
            },
            "grpcSettings": {"serviceName": "grpc-service"}
        }
    }],
    "outbounds": [{"protocol": "freedom"}]
}
EOF

# 5. Restart & Firewall
sudo systemctl restart xray
sudo ufw allow 443/tcp
sudo ufw allow 443/udp

# 6. Generate Link
IP=$(curl -s https://api.ipify.org)
LINK="trojan://$password@$IP:443?security=tls&encryption=none&type=grpc&serviceName=grpc-service&allowInsecure=1#TrueAnonymity"

echo -e "\n\033[0;32m--- ANONYMITY SERVER READY ---\033[0m"
echo -e "Link: $LINK\n"
qrencode -t ansiutf8 "$LINK"
