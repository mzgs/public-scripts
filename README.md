# public-scripts


## Install Wireguard and Squid Proxy  
```
PROXY_USER="zehrap"; PROXY_PASS="zehrap123"; wget -O vpn_proxy.sh https://raw.githubusercontent.com/mzgs/public-scripts/refs/heads/main/vpn_proxy.sh && chmod +x vpn_proxy.sh && printf "1\n\n\n2\n" | ./vpn_proxy.sh "$PROXY_USER" "$PROXY_PASS" && nano /root/client.conf
```

## install wireguard vpn  
```
bash <(curl -fsSL https://raw.githubusercontent.com/mzgs/public-scripts/main/wireguard_vpn.sh)
```

## install Squid Proxy  
```
bash <(curl -fsSL https://raw.githubusercontent.com/mzgs/public-scripts/main/squid_proxy.sh)
```


## macos fresh install 

#### Apps 
```
bash <(curl -fsSL https://raw.githubusercontent.com/mzgs/public-scripts/main/1-brew-apps.sh)
```

#### Mac Settings 
```
bash <(curl -fsSL https://raw.githubusercontent.com/mzgs/public-scripts/main/2-mac-settings.sh)
```
