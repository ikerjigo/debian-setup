#!/bin/bash
setxkbmap es # Set keyboard to spanish

sudo apt update # Update repos of the ISO, tend to be outdated

sudo apt install tmux neovim flameshot bat# Install needed tools and personal preference tools

flameshot & # Start flameshot in background

echo "alias cat=batcat" >> ~/.bashrc # Add batcat alias to cat

sudo apt install bind9 dnsutils nmap # Install class packages

cat << EOF
#
#
EOF
read -p "# Enter last octet of IP: " ip
cat << EOF
#
#
EOF

if ! [[ "$ip" =~ ^[0-9]+$ ]]; then
	echo "Not a number. Not changing IP."
elif [ "$ip" -lt 255 ]; then
cat << EOF

#############################
-----------------------------
Changing IP to 192.168.202.$ip
-----------------------------
#############################

EOF

cat << EOF | sudo tee -a /etc/network/interfaces > /dev/null

auto eno1
iface eno1 inet static
	address 192.168.202.$ip
	netmask 255.255.0.0
	gateway 192.168.88.88
EOF

sudo systemctl stop networking
cat << EOF

#######################################
---------------------------------------
Waiting 20 seconds for service to stop
*Sometimes, manual restart is required*
---------------------------------------
#######################################

EOF
	
sleep 20
	
sudo systemctl start networking
cat << EOF
	
######################## 
------------------------
Starting network service
------------------------
########################
	
EOF
else 
	echo "Number not valid (bigger than 254)"
fi

ip -c a show dev eno1

cat << EOF
#################
-----------------
DNS Config + zone
-----------------
#################

EOF

echo "Setting 192.168.88.88 as forwarder"
sleep 2

sudo tee /etc/bind/named.conf.options > /dev/null << EOF 
options {
	directory "/var/cache/bind";
	forwarders {
		192.168.88.88;
	};
};
EOF

read -p "Enter zone name: " zoneN
echo "-------------------"
read -p "Enter zone NS: " ns
echo "-------------------"
read -p "Enter admin name: " admN

sudo tee /etc/resolv.conf > /dev/null << EOF
search $zoneN
nameserver 127.0.0.1
EOF

cat << EOF | sudo tee -a /etc/bind/named.conf.local > /dev/null
zone $zoneN {
	type master;
	file "/etc/bind/db.$zoneN";
};
EOF

cat << EOF | sudo tee -a /etc/bind/db.$zoneN > /dev/null 
\$TTL 1w

@	IN	SOA	$ns	$admN (
	1;	Serial
	12h;	Refresh
	4h;	Retry
	4d;	Expire
	2h;	Negative cache
)

@	IN	NS	$ns
$ns	IN	A	192.168.202.$ip
@	IN	A	192.168.202.$ip

; REMEMBER TO CHANGE SERIAL AFTER CHANGES
EOF

cat << EOF
########################
------------------------
Restarting BIND9 service
------------------------
########################
EOF

sudo systemctl stop named
sleep 1
sudo systemctl start named

nslookup -type=SOA $zoneN
