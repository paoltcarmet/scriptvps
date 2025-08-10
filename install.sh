#!/bin/bash

if [ "${EUID}" -ne 0 ]; then
		echo "You need to run this script as root"
		exit 1
fi

apt update
apt install wget curl gnupg openssl perl ruby jq git -y
apt install bc -y
apt install lsb-release -y
apt install lolcat -y
apt install sudo -y
apt install stress-ng -y
gem install lolcat

# Utils
apt install util-linux coreutils binutils -y

# Fix DNS
cat <(echo "nameserver 8.8.8.8") /etc/resolv.conf > /etc/resolv.conf.tmp && mv /etc/resolv.conf.tmp /etc/resolv.conf && cat <(echo "nameserver 1.1.1.1") /etc/resolv.conf > /etc/resolv.conf.tmp && mv /etc/resolv.conf.tmp /etc/resolv.conf

# Fix Port OpenSSH
cd /etc/ssh
find . -type f -name "*sshd_config*" -exec sed -i 's|#Port 22|Port 22|g' {} +
echo -e "Port 3303" >> sshd_config
cd
systemctl daemon-reload
systemctl restart ssh
systemctl restart sshd

# Require Domain
clear
read -rp "Input Your Domain: " domain
mkdir -p /etc/v2ray
echo -e "${domain}" > /etc/v2ray/domain
domain=$(cat /etc/v2ray/domain)

# Setup SSH Dropbear
apt install dropbear -y
systemctl stop dropbear
bash <(curl -s https://raw.githubusercontent.com/FN-Rerechan02/tools/refs/heads/main/dropbear.sh)
cd /etc/default
rm -f /etc/dropbear/dropbear_rsa_host_key
dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key
rm -f /etc/dropbear/dropbear_dss_host_key
dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key
rm -f /etc/dropbear/dropbear_ecdsa_host_key
dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key
rm -f dropbear
echo -e '# All configuration by Project Rerechan / Rerechan02
# disabled because OpenSSH is installed
# change to NO_START=0 to enable Dropbear
NO_START=0
# the TCP port that Dropbear listens on
DROPBEAR_PORT=109

# any additional arguments for Dropbear
#DROPBEAR_EXTRA_ARGS="-p 69"
# specify an optional banner file containing a message to be
# sent to clients before they connect, such as "/etc/issue.net"
DROPBEAR_BANNER="/etc/issue.net"

# RSA hostkey file (default: /etc/dropbear/dropbear_rsa_host_key)
DROPBEAR_RSAKEY="/etc/dropbear/dropbear_rsa_host_key"

# DSS hostkey file (default: /etc/dropbear/dropbear_dss_host_key)
#DROPBEAR_DSSKEY="/etc/dropbear/dropbear_dss_host_key"

# ECDSA hostkey file (default: /etc/dropbear/dropbear_ecdsa_host_key)
DROPBEAR_ECDSAKEY="/etc/dropbear/dropbear_ecdsa_host_key"

# Receive window size - this is a tradeoff between memory and
# network performance
DROPBEAR_RECEIVE_WINDOW=65536' > dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
echo -e "Telegram: @project_rerechan Official Script Dev" > /etc/issue.net
clear
systemctl daemon-reload
/etc/init.d/dropbear restart

# Setup WebSocket
wget -O /usr/local/bin/proxy "https://raw.githubusercontent.com/FN-Rerechan02/tools/refs/heads/main/proxy"
chmod +x /usr/local/bin/proxy
echo -e '[Unit]
Description=Websocket By Rerecha02
Documentation=https://t.me/project_rerechan
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
Restart=on-failure
ExecStart=/usr/local/bin/proxy
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/ws.service
systemctl daemon-reload
systemctl start ws
systemctl enable ws 

# Setup Bad VPN / UDP Port 7300
wget -O /usr/local/bin/badvpn "https://raw.githubusercontent.com/FN-Rerechan02/tools/refs/heads/main/badvpn"
chmod +x /usr/local/bin/badvpn
echo -e '[Unit]
Description=UDPGW SSH
Documentation=https://t.me/fn_project
After=syslog.target network-online.target

[Service]
User=root
NoNewPrivileges=true
ExecStart=/usr/local/bin/badvpn --listen-addr 127.0.0.1:7300 --max-clients 500
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/badvpn.service
systemctl daemon-reload
systemctl start badvpn
systemctl enable badvpn

# Setup Other Feature
wget -O /usr/local/bin/rerechan "https://raw.githubusercontent.com/FN-Rerechan02/tools/refs/heads/main/fn"
wget -O /usr/local/bin/speedtest "https://raw.githubusercontent.com/FN-Rerechan02/tools/refs/heads/main/speed"
chmod +x /usr/local/bin/rerechan
chmod +x /usr/local/bin/speedtest

# Setup V2ray
mkdir -p /etc/v2ray/ssh/expired
cd /usr/local/bin
apt install bzip2 -y
wget https://raw.githubusercontent.com/Rerechan02/Rerechan02/main/v2ray.bz2 ; bzip2 -d v2ray.bz2 ; rm -fr v2ray.bz2 ; clear ; chmod +x v2ray
cd /etc/v2ray
wget -O config.json "https://raw.githubusercontent.com/FN-Rerechan02/tools/refs/heads/main/config.json"
uuid=$(cat /proc/sys/kernel/random/uuid)
sed -i "s|xxxxx|${uuid}|g" /etc/v2ray/config.json
mkdir -p /var/log/v2ray
touch /var/log/v2ray/access.log
touch /var/log/v2ray/error.log
chmod +x /var/log/v2ray/*.log
echo -e '[Unit]
Description=V2ray Service
Documentation=https://t.me/project_rerechan
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/v2ray run -c /etc/v2ray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/v2ray.service
systemctl daemon-reload
systemctl start v2ray
systemctl enable v2ray

# Get Certificate
apt install lsof socat certbot -y
port=$(lsof -i:80 | awk '{print $1}')
systemctl stop apache2
systemctl disable apache2
pkill $port
yes Y | certbot certonly --standalone --preferred-challenges http --agree-tos --email dindaputri@rerechanstore.eu.org -d $domain 
cp /etc/letsencrypt/live/$domain/fullchain.pem /etc/v2ray/v2ray.crt
cp /etc/letsencrypt/live/$domain/privkey.pem /etc/v2ray/v2ray.key
cd /etc/v2ray
chmod 644 /etc/v2ray/v2ray.key
chmod 644 /etc/v2ray/v2ray.crt

# Setup Nginx
bash <(curl -s https://raw.githubusercontent.com/FN-Rerechan02/tools/refs/heads/main/nginx.sh)
systemctl stop nginx
wget -O /etc/nginx/nginx.conf "https://raw.githubusercontent.com/Rerechan-Team/websocket-proxy/fn_project/nginx.conf"
wget -O /etc/nginx/fn.conf "https://raw.githubusercontent.com/FN-Rerechan02/tools/refs/heads/main/fn.conf"
sed -i "s|xxx|${domain}|g" /etc/nginx/fn.conf
systemctl daemon-reload
systemctl start nginx

# Setup Htop & Trafik Checker
apt install htop vnstat -y

# Setup Main
cd /usr/local/sbin
wget -O main.zip "https://raw.githubusercontent.com/FN-Rerechan02/tools/refs/heads/main/main.zip"
apt install zip unzip -y
unzip main.zip
chmod +x /usr/local/sbin/*
rm -f main.zip

# Setup Auto Expired
apt install cron -y
echo "* * * * * root xp" >> /etc/crontab
echo "0 0 * * * root reboot" >> /etc/crontab
systemctl daemon-reload
systemctl restart cron

# Setup UDP Custom
bash <(curl -s https://raw.githubusercontent.com/FN-Rerechan02/tools/refs/heads/main/udp.sh)
clear

# Setup Swap Ram +4GB
sh <(curl -s https://raw.githubusercontent.com/FN-Rerechan02/tools/refs/heads/main/swap.sh)
clear

echo -e "clear
rerechan" >> /root/.profile

cd
clear
echo -e "Success Install"
rm -f /root/*.sh
rm -rf /root/dropbe*
rm -rf /root/nginx*
rm -rf /root/*.txt
rm -rf /root/*.*