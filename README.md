# Shadowsocks-Server-byT
this is A simple But Very Effective Script To Install ShadowSocks Server On Your Linux Server

# To Run The Instalation First Update Your Linux Server With This Command
```
sudo -- sh -c 'apt-get update; apt-get upgrade -y; apt-get full-upgrade -y; apt-get autoremove -y; apt-get autoclean -y'
```


# Then Copy And Paste This Line In your Linux Terminal 
```
sudo curl -L https://raw.githubusercontent.com/teelge/Shadowsocks-Server-byT/main/SocksByT.sh | bash
```
# check Status of The Server With This Command 
```
sudo systemctl status shadowsocks-libev-server@config
```
