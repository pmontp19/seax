#!/bin/bash

#variables
INT_IFACE="eth-dmz"
EXT_IFACE="eth-troncal"
INT_IP="10.10.2.1"

#activem redireccionament si no ho esta
/sbin/sysctl -w net.ipv4.ip_forward="1" > /dev/null

#flush totes les taules
iptables -F
iptables -t nat -F

#esborrar les cadenes
iptables -X
iptables -t nat -X

#comptaddors a 0
iptables -Z

#==REGLES==

#politiques per defecte
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

#nat
iptables -t nat -A POSTROUTING -o $EXT_IFACE -j MASQUERADE

#cadena FORWARD
#transit de sortida
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state NEW -i $INT_IFACE -o $EXT_IFACE -j ACCEPT
iptables -A FORWARD -m state --state NEW -i $INT_IFACE -o $INT_IFACE -j ACCEPT
iptables -I FORWARD -s 10.10.2.7 -o eth-dmz -j ACCEPT

#traduim i redirigim peticions web externes al servidor web
iptables -A FORWARD -i $EXT_IFACE -o $INT_IFACE -d 10.10.2.6 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -i $EXT_IFACE -o $INT_IFACE -d 10.10.2.6 -p tcp --dport 443 -j ACCEPT
iptables -t nat -A PREROUTING -p tcp -i $EXT_IFACE --dport 80 -j DNAT --to-dest 10.10.2.6
iptables -t nat -A PREROUTING -p tcp -i $EXT_IFACE --dport 443 -j DNAT --to-dest 10.10.2.6

#redirigim les peticions dns externes als servidors dns
iptables -A FORWARD -i $EXT_IFACE -o $INT_IFACE -d 10.10.2.4 -p tcp --dport 53 -j ACCEPT
iptables -A FORWARD -i $EXT_IFACE -o $INT_IFACE -d 10.10.2.4 -p udp --dport 53 -j ACCEPT
iptables -t nat -A PREROUTING -p udp -i $EXT_IFACE --dport 53 -j DNAT --to-dest 10.10.2.4
iptables -t nat -A PREROUTING -p tcp -i $EXT_IFACE --dport 53 -j DNAT --to-dest 10.10.2.4

#acces ssh
iptables -A FORWARD -d 10.10.2.7,10.10.2.6,10.10.2.4,10.10.2.5,10.10.2.11 -m tcp -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -s 10.10.2.7,10.10.2.6,10.10.2.4,10.10.2.5,10.10.2.11 -m tcp -p tcp --sport 22 -j ACCEPT
iptables -t nat -A PREROUTING -m tcp -p tcp --dport 20022 -j DNAT --to-destination 10.10.2.7:22
iptables -t nat -A PREROUTING -m tcp -p tcp --dport 20024 -j DNAT --to-destination 10.10.2.6:22
iptables -t nat -A PREROUTING -m tcp -p tcp --dport 20026 -j DNAT --to-destination 10.10.2.4:22
iptables -t nat -A PREROUTING -m tcp -p tcp --dport 20028 -j DNAT --to-destination 10.10.2.5:22
iptables -t nat -A PREROUTING -m tcp -p tcp --dport 20030 -j DNAT --to-destination 10.10.2.11:22

#protocol icmp per fer pings
#iptables -A OUTPUT -p icmp -j ACCEPT

iptables -N LOGGING
iptables -A INPUT -j LOGGING
iptables -A LOGGING -m limit --limit 2/min -j LOG --log-prefix "iptables DROP: " --log-level 7
iptables -A LOGGING -j DROP
