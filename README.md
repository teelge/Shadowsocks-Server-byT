# Shadowsocks-Server-byT
this is A simple But Very Effective Script To Install ShadowSocks Server On Your Linux Server

# To Run The Instalation First Update Your Linux Server With This Command
```
sudo -- sh -c 'apt-get update; apt-get upgrade -y; apt-get full-upgrade -y; apt-get autoremove -y; apt-get autoclean -y'
```


# Then Copy And Paste This Line In your Linux Terminal 
```
wget -N --no-check-certificate https://raw.githubusercontent.com/teelge/Shadowsocks-Server-byT/main/SocksByT.sh && chmod +x SocksByT.sh && bash SocksByT.sh
```
# check Status of The Server With This Command 
```
sudo systemctl status shadowsocks-libev-server@config
```
