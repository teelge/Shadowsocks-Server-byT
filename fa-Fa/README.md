<h1 align="center">به گیتهاب من خوش آمدید 👋</h1>
- [🇬🇧 English](../README.md)


|  ا ین کد رو برای ساخت سرور پروکسی درست کردم که در سرور لینوکس نسب کنید |
|---|

  > ✨ کار کردن باهاش خیلی راحته ، برای دور زدن فیلترینگ

<p align="center">
  <img width="700" align="center" src="https://raw.githubusercontent.com/teelge/Shadowsocks-Server-byT/main/SocksByT.gif" alt="demo"/>
</p>

## قبل از نصب باید سیستم عامل سرور لینوکس رو آپدیت کنید (کد زیر رو کپی و در terminal اجرا کنید)
```
sudo -- sh -c 'apt-get update; apt-get upgrade -y; apt-get full-upgrade -y; apt-get autoremove -y; apt-get autoclean -y ; clear'
```


## 🚀 حالا برای نصب برنامه کد زیر رو در terminal اجرا کنید 
```
wget -N --no-check-certificate https://raw.githubusercontent.com/teelge/Shadowsocks-Server-byT/main/SocksByT.sh && chmod +x SocksByT.sh && bash SocksByT.sh
```
---

##  ‼️ بعد از نصب حتما پورت 443 یا همان پورتی که در مراحل نصب انتخاب کردید رو در تنضیمات اینترنتی ارائه دهنده سرور باز کنید (پروتوکول TCP)  ‼️

##  با این دستور وضعیت سرور را بررسی کنید

```
sudo systemctl status shadowsocks-libev-server@config
```

## برای تغییر تنظیمات از این فرمان استفاده کنید (برای کاربران حرفه ای)
 
```
sudo nano /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json
```
---
## 🗑️ برای حذف نرم افزار (فرمان را دوباره اجرا کنید)
```
wget -N --no-check-certificate https://raw.githubusercontent.com/teelge/Shadowsocks-Server-byT/main/SocksByT.sh && chmod +x SocksByT.sh && bash SocksByT.sh
```

