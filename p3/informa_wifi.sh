#!/bin/bash

exec > /dev/null 2>&1
echo Dades de lequip >> info_wifi.txt
echo =============== >> info_wifi.txt
echo "Data: `date`" >> info_wifi.txt
echo "Usuaris humans: `cat /etc/passwd | grep '/home' | cut -d: -f1`" >> info_wifi.txt
echo "Nom de l'equip: `hostname`" >> info_wifi.txt
echo "Adreca IP del router: `ip route show | grep 'default' | cut -d ' ' -f3 `" >> info_wifi.txt
echo "Adreca IP externa: `wget --timeout=30 http://ipinfo.io/ip -qO -`" >> info_wifi.txt #adreça ip externa
echo "Adreces IP dels DNS: `more /etc/resolv.conf | grep 'nameserver' | cut -d ' ' -f2`" >> info_wifi.txt
for interface in `iw dev | awk '$1=="Interface"{print $2}'`; do
  echo "Nom de la inteficie: $interface" >> info_wifi.txt
  echo "MAC: `ip addr show $interface | grep 'link/ether' | cut -d ' ' -f6`" >> info_wifi.txt
  #protocols suportats
  essid=`iwconfig $interface | grep ESSID | cut -d: -f2`
  if [ $essid != 'off/any' ]; then
    echo "Adreça IP: `ip addr show $interface | grep 'inet '  | cut -d ' ' -f6`" >> info_wifi.txt
#nomdns
    echo "Màscara de xarxa: `ip address show $interface | grep 'inet' | cut -d ' ' -f6 | tail -c 4`" >> info_wifi.txt
    echo "Adreça de broadcast: `ip -f inet addr show $interface | awk '/scope global/ {print $6}'`" >> info_wifi.txt
    echo "Adreça de la xarxa: `ip address show $interface | grep 'inet' | cut -d ' ' -f6`" >> info_wifi.txt
    echo "Nom de la xarxa: " >> info_wifi.txt
    echo "MTU: `ip address show $interface | grep 'mtu' | cut -d ' ' -f5`" >> info_wifi.txt
  fi
done
iwlist scan > /tmp/wifi_scan_result
end=$(grep -c "ESSID:" /tmp/wifi_scan_result)
start=1
#for i in `grep -c "Cell" /tmp/wifi_scan_result`; do
i=$start

while [ "$i" -le "$end" ]; do
  echo "Xarxa wifi operativa $i" >> info_wifi.txt
  echo  " Adreça MAC AP: `grep -n " Address:" /tmp/wifi_scan_result | awk "NR==$i" | cut -d ' ' -f15`" >> info_wifi.txt
  echo " Nº de canal: `grep -n " Channel:" /tmp/wifi_scan_result | awk "NR==$i" | cut -d: -f3` " >> info_wifi.txt
  echo " Qualitat: ` grep " Quality=" /tmp/wifi_scan_result | awk "NR==$i" | cut -d= -f2 | cut -d ' ' -f1`" >> info_wifi.txt
  echo " Nivell de senyal: `grep " Signal level=" /tmp/wifi_scan_result | awk "NR==$i" | cut -d= -f3`" >> info_wifi.txt
  echo " ESSID: `grep " ESSID:" /tmp/wifi_scan_result | awk "NR==$i" | cut -d: -f2`" >> info_wifi.txt
  key=$(grep "  Encryption key:" /tmp/wifi_scan_result | awk "NR==$i" | cut -d: -f2)
  if [[ "$key" == "off" ]]; then
    echo " Xifrat: no" >> info_wifi.txt
  fi
  if [[ "$key" == "on" ]]; then
    echo " Xifrat: si" >> info_wifi.txt
  fi
  i=$[$i+1]
done
rm /tmp/wifi_scan_result
