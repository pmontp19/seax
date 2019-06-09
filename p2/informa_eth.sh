#!/bin/sh

#exec > /dev/null 2>&1
echo Dades de lequip >> info_eth.txt
echo =============== >> info_eth.txt
echo "Data: `date`" >> info_eth.txt
echo "Usuaris humans: `cat /etc/passwd | grep '/home' | cut -d: -f1`" >> info_eth.txt
echo "Nom de l'equip: `hostname`" >> info_eth.txt
echo "Adreca IP del router: `ip route show | grep 'default' | cut -d ' ' -f3 `" >> info_eth.txt
echo "Adreca IP externa: `wget --timeout=30 http://ipinfo.io/ip -qO -`" >> info_eth.txt #adreça ip externa
echo "Adreces IP dels DNS: `more /etc/resolv.conf | grep 'nameserver' | cut -d ' ' -f2`" >> info_eth.txt
echo "apunt d'entrar" >> info_eth.txt
for interface in `ip address show | cut -d ' ' -f2 | tr ':' '\n' | awk NF`; do
  echo 'a dins' >> info_eth.txt
  echo "Nom de la inteficie: $interface" >> info_eth.txt
  #if esta conectat a la xarxa
  echo "Adreça IP: `ip address show $interface | grep 'link/ether' | cut -d ' ' -f6`" >> info_eth.txt
  echo "Nom local de l'equip: `hostname`" >> info_eth.txt
  echo "Màscara de xarxa: `ip address show $interface | grep 'inet' | cut -d ' ' -f6 | tail -c 4`" >> info_eth.txt
  echo "Adreça de broadcast: `ip -f inet addr show $interface | awk '/scope global/ {print $6}'`" >> info_eth.txt
  echo "Adreça de la xarxa: `ip address show $interface | grep 'inet' | cut -d ' ' -f6`" >> info_eth.txt
  echo "Nom local de la xarxa: " >> info_eth.txt
  echo "Nom DNS de la xarxa: " >> info_eth.txt
  echo "MTU: `ip address show $interface | grep 'mtu' | cut -d ' ' -f5`" >> info_eth.txt

done
echo '\n' >> info_eth.txt

