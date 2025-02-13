# public-scripts


## Install Wireguard and Squid Proxy  
PROXY_USER="zehrap"; PROXY_PASS="zehrap123"; wget -O vpn_proxy.sh https://raw.githubusercontent.com/mzgs/public-scripts/refs/heads/main/vpn_proxy.sh && chmod +x vpn_proxy.sh && printf "1\n\n\n2\n" | ./vpn_proxy.sh "$PROXY_USER" "$PROXY_PASS" && nano /root/client.conf
