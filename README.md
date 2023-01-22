<h1 align="center">Welcome to My Github 👋</h1>


  > ✨This is A simple But Very Effective Script To Install ShadowSocks Server On Your Linux Server

## To Run The Instalation First Update Your Linux Server With This Command
```
sudo -- sh -c 'apt-get update; apt-get upgrade -y; apt-get full-upgrade -y; apt-get autoremove -y; apt-get autoclean -y'
```


## 🚀 Then Copy And Paste This Line In your Linux Terminal 
```
wget -N --no-check-certificate https://raw.githubusercontent.com/teelge/Shadowsocks-Server-byT/main/SocksByT.sh && chmod +x SocksByT.sh && bash SocksByT.sh
```
---

##  ‼️ Make Sure that the TCP port That You Chose in the script is open by opening it on your router or server provider's network settings. Otherwise, you will not be able to connect to the server.‼️

##  check Status of The Server With This Command 
```
sudo systemctl status shadowsocks-libev-server@config
```

<p align="center">
  <img width="700" align="center" src="https://raw.githubusercontent.com/teelge/Shadowsocks-Server-byT/main/SocksByT.gif" alt="demo"/>
</p>
