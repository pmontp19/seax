#!/bin/bash

# flush de les iptables
iptables -F
iptables -X
iptables -Z
iptables -t nat -F
iptables -t nat -X

#assegurem que podrem fer forward
sysctl -w net.ipv4.ip_forward=1 > /dev/null

#definim les polítiques per defecte
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

#interfície loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

#permetem transit de clients cap a DMZ
iptables -t filter -A FORWARD -i eth-clients -o eth-dmz -m state --state NEW -j ACCEPT

iptables -N LOGGING
iptables -A INPUT -j LOGGING
iptables -A LOGGING -m limit --limit 2/min -j LOG --log-prefix "iptables DROP: " --log-level 7
iptables -A LOGGING -j DROP
