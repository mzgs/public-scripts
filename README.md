# public-scripts


## Install VPN + PROXY 

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mzgs/public-scripts/main/wireguard_vpn.sh) && \
bash <(curl -fsSL https://raw.githubusercontent.com/mzgs/public-scripts/main/squid_proxy.sh)
```
 
## Install wireguard vpn  
```
bash <(curl -fsSL https://raw.githubusercontent.com/mzgs/public-scripts/main/wireguard_vpn.sh)
```

## Install Squid Proxy  
```
bash <(curl -fsSL https://raw.githubusercontent.com/mzgs/public-scripts/main/squid_proxy.sh)
```


## macOS 15+ setup

Run both scripts as your normal user, without `sudo`. Script 1 requests your
administrator password when installing Homebrew; script 2 requests it to clear
global local account policies and set login-window and battery sleep preferences.
Open a new terminal after script 1.
Close System Settings and the apps whose preferences you want to change before
running script 2. Log out and back in afterward.

Both scripts continue after individual failures, show the original error and a
failure summary, and exit with status 1 when something fails. They do not promise
that writing an undocumented `defaults` key makes every macOS release honor it.

#### Apps 
```
bash <(curl -fsSL https://raw.githubusercontent.com/mzgs/public-scripts/main/1-brew-apps.sh)
```

#### Mac Settings 
```
bash <(curl -fsSL https://raw.githubusercontent.com/mzgs/public-scripts/main/2-mac-settings.sh)
```

 
 