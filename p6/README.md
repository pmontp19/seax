# Pràctica 6 - Montpeó Pere

Fitxers involucrats

- topologia_xarxa.png i topologia_xarxa.pdf: esquema de la topologia de xarxa amb el nom de les interficies i adreces
- grub: arxiu comú, pel canvi de nom interficies de xarxa
- Router extern
  - interfaces: arxiu configuració interficies xarxa
  - fw_extern.sh: script per configurar regles de tallafocs i nat
  - 10-network.rules: arxiu que conté el nom de les interficies

- Router intern
  - interfaces: arxiu configuració interficies xarxa
  - fw_intern.sh: script per configurar regles de tallafocs
  - dropped.log: arxiu de log amb els paquets caiguts de les cadenes del tallafocs (exemple SSH)
  - 10-network.rules: arxiu que conté el nom de les interficies

- Proxy web
  - interfaces: arxiu configuració interficies xarxa
  - captura tcpdump proxy: captura de xarxa amb tcpdump on es veuen les peticions GET d'HTTP i com l'adreça d'origen/destí no és el router sinó el servidor proxy
  - squid.conf: arxiu de configuració del proxy squid3
  - facebook.com.txt: pàgina html que retorna proxy squid a un client que demana una pàgina prohibida

## Continguts

1. Interficies de xarxa
2. Serveis als routers
3. Proxy web

## 1. Interficies de xarxa

Pel cas del router extern el primer adaptador està configurat com a adaptador pont per tal d'accedir a la xarxa "real" per accedir a internet i amb MAC 08:00:27:00:01:22, el segon adaptador configurat com xarxa interna per accedir a la xarxa DMZ i amb la MAC 08:00:27:00:02:01 i el tercer també a xarxa interna per la VPN amb MAC 08:00:27:10:04:01.

Per al router intern, els dos adaptadors estan configurats com a xarxa interna: el primer es connectarà amb la xarxa DMZ i el segon amb la xarxa clients amb les MAC 08:00:27:10:02:02 i 08:00:27:10:03:01, respectivament.

Ja amb els dos sistemes en marxa, s'han modificat els noms de les interficies de xarxa per identificar-les. Per al router extern, la interficie que connecta a l'exterior s'anomena 'eth-troncal', la a DMZ 'eth-dmz' i la de VPN 'eth-vpn'.

Per al router intern, la interficie que connecta amb la DMZ s'anomena 'eth-dmz' i la que connecta amb la xarxa clients 'eth-clients'.

### Canviar nom interficies xarxa

Modifiquem el gestor d'arrencada GRUB per desactivar el sistema de noms de xarxa i afegim la línia següent:
  $ sudo nano /etc/default/grub
  GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"

Actualitzem grub:
  $ sudo update-grub

Ara creem l'arxiu que conté les regles de xarxa que s'apliquen al iniciar el sistema i que defineixen el nom per cada adreça MAC. L'arxiu ha d'estar a la següent ubicació amb el nom indicat:
  $ sudo nano /etc/udev/rules.d/10-network.rules

Aquesta és un exemple de quin és el format perquè s'afegeixi amb el nom que volem:
  SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="aa:bb:cc:dd:ee:ff", NAME="net1"

S'adjunta l'arxiu '10-network.rules' de cada màquina amb el nom i adreça de cada interficie.

Abans de reiniciar, s'ha de modificar l'arxiu /etc/network/interfaces per tal de canviar els noms de les interficies i que puguin agafar la configuració amb el nom que acabem de modificar quan s'apliquin els canvis.

Per tal de poder actuar com a routers i poder redireccionar paquets activem l'opció del sistema canviant-la al fitxer /etc/sysctl.conf amb la comanda pels dos routers:
  $ sysctl -w net.ipv4.ip_forward=1

S'ha d'afegir una ruta estàtica al router extern perquè pugui respondre al redireccionament de paquets cap a la xarxa clients (10.10.3.0/28), ja que en cas contrari reenviaria a la seva gateway, és a dir, cap a internet:
  $ sudo ip route add 10.10.3.0/28 via 10.10.2.2 dev eth-dmz

Això significa que s'han d'enrutar els paquets que vagin cap a la xarxa clients per la interficie eth-dmz cap a l'equip 10.10.2.2.

Arribats a aquest punt, la configuració entre xarxes internes ha de funcionar, és a dir, els equips dins de la xarxa clients i dmz s'han de poder veure entre ells. Per exemple, el monitor de la xarxa clients (10.10.3.11) pot apuntar al monitor de la xarxa dmz (10.10.2.11) fent un ping:
  $ ping 10.10.2.11
  PING 10.10.2.11 (10.10.2.11) 56(84) bytes of data.
  64 bytes from 10.10.2.11: icmp_seq=1 ttl=62 time=1.61 ms
  64 bytes from 10.10.2.11: icmp_seq=2 ttl=62 time=4.07 ms

Podem provar el mateix, per exemple, amb el router extern (10.10.2.1) a un client (10.10.3.3):
  $ ping 10.10.3.3
  PING 10.10.3.3 (10.10.3.3) 56(84) bytes of data.
  64 bytes from 10.10.3.3: icmp_seq=1 ttl=62 time=0.399 ms
  64 bytes from 10.10.3.3: icmp_seq=2 ttl=62 time=0.909 ms

### Configuració interficies

- Router extern

```;
allow-hotplug eth-troncal
iface eth-troncal inet dhcp

allow-hotplug eth-dmz
iface eth-dmz inet static
adadress 10.10.2.1
netmask 255.255.255.240

auto eth-vpn
iface eth-vpn inet static
address 10.10.4.1
netmask 255.255.255.240
```

- Router intern

```;
allow-hotplug eth-dmz
iface eth-dmz inet static
adadress 10.10.2.2
netmask 255.255.255.240
gateway 10.10.2.1

auto eth-clients
iface eth-clients inet static
address 10.10.3.1
netmask 255.255.255.240
```

- Monitor client

```;
allow-hotplug enp0s3
iface enp0s3 inet static
address 10.10.3.11
netmask 255.255.255.240
gateway 10.10.3.1
```

- Monitor dmz

```;
allow-hotplug enp0s3
iface enp0s3 inet static
address 10.10.2.11
netmask 255.255.255.240
gateway 10.10.2.1
```

- Proxy web

```;
allow-hotplug enp0s3
iface enp0s3 inet static
address 10.10.2.7
netmask 255.255.255.240
gateway 10.10.2.1
```

Com es pot veure, els clients tindran com a router per defecte el router intern, és a dir, 10.10.3.1. Els equips de la xarxa DMZ tenen com a router per defecte l'extern a 10.10.2.1.

En el cas del mateix router intern, també té com a router per defecte l'extern 10.10.2.1. I el router extern té com a router per defecte el següent router al que està connectat a internet, que adquireix automàticament gràcies al DHCP.

És per aquesta raó que és necessària la ruta estàtica al router extern per les adreces de la xarxa clients.

Tots els equips estan configurats com es pot veure a la configuració de les interficies tots en mode estàtic, tret de l'interficie externa del router extern. Els clients es podrien configurar de forma dinàmica però el servidor DHCP intern no està implmentat.

## 2. Serveis als routers

Els serveis als routers els afegirem a través de les iptables. El paquet ve instal·lat per defecte en les versions 9.4 de Debian. S'han de definir regles al router extern, per tal de permetre l'encaminament d'alguns paquets i actuar com a tallafocs i NAT.

Perquè actui com a NAT es fa servir la següent directiva, que basicament emmascara l'adreça interna dels paquets sortints amb l'adreça de la interifcie eth-troncal:
  $ iptables -t nat -A POSTROUTING -o eth-troncal -j MASQUERADE

També afegim regles per acceptar el trànsit de sortida i local:
  $ iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  $ iptables -A FORWARD -m conntrack --ctstate NEW -i eth-dmz -o eth-troncal -j ACCEPT
  $ iptables -A FORWARD -m conntrack --ctstate NEW -i eth-dmz -o eth-dmz -j ACCEPT

Com que també necessitem una solució perquè l'administrador es pugui connectar des de casa, redirigirem les seves connexions SSH a les diferents màquines a les quals necessita accés:
  proxy web 10.10.2.7
  servidor web 10.10.2.6
  servidor dns 10.10.2.4 i 10.10.2.5
  monitor xarxa 10.10.2.11

Per tant assignarem un port a cadascún d'aquests equips per permetre la connexió directa des de internet, apuntant únicament a l'adreça d'internet i a un port diferent:
  proxy web port 20022
  servidor web port 20024
  servidor dns ports 20026 i 20028
  monitor xarxa port 20030

Un exemple de com queden les regles de redirecció és el següent (la resta de regles estan al script adjunt). La primera accepta el trànsit SSH, la segona redirigeix el trànsit de retorn de SSH i l'última redirigeix els paquets a la màquina destinació:
  $ iptables -I FORWARD -d 10.10.2.7 -m tcp -p tcp --dport 22 -j ACCEPT
  $ iptables -I FORWARD -s 10.10.2.7 -m tcp -p tcp --sport 22 -j ACCEPT
  $ iptables -t nat -I PREROUTING -m tcp -p tcp --dport 20022 -j DNAT --to-destination 10.10.2.7:22

També volem que es pugui accedir als serveis de la DMZ, per exemple, que les peticions a l'adreça pública pel port 80 haurien d'anar al servidor web:
  $ iptables -A FORWARD -i $EXT_IFACE -o $INT_IFACE -d 10.10.2.6 -p tcp --dport 80 -j ACCEPT
  $ iptables -A FORWARD -i $EXT_IFACE -o $INT_IFACE -d 10.10.2.6 -p tcp --dport 443 -j ACCEPT
  $ iptables -t nat -A PREROUTING -p tcp -i $EXT_IFACE –dport 80 -j DNAT –to-dest 10.10.2.6
  $ iptables -t nat -A PREROUTING -p tcp -i $EXT_IFACE –dport 443 -j DNAT –to-dest 10.10.2.6

Amb les regles anteriors traduïm les peticions perquè apuntin a l'adreça del servidor i permetem la redirecció dels paquets, tant al port 80, que és el de HTTP, com el 443, en el cas de HTTPS.

Apliquem regles també per les peticions de DNS

A part de les regles anteriors, s'ha de definir el comportament per defecte de cadascuna de les diferents cadenes. Per maximizar la seguretat, s'estableixen les polítiques següents per defecte:
  $ iptables -P INPUT DROP
  $ iptables -P OUTPUT DROP
  $ iptables -P FORWARD DROP

Per al router intern maximizarem la seguretat per aïllar la xarxa de l'exterior, per tant, definirem també les polítiques per defecte i permetrem, el trànsit sortint de la xarxa clients, però no l'entrant:
  $ iptables -P INPUT DROP
  $ iptables -P OUTPUT DROP
  $ iptables -P FORWARD DROP

  $ iptables -t filter -A FORWARD -i eth-clients -o eth-dmz -m state –state NEW,ESTABLISHED,RELATED -j ACCEPT
  $ iptables -t filter -A FORWARD -i eth-dmz -o eth-clients -m state –state ESTABLISHED,RELATED -j ACCEPT

Amb aquestes dues directives permetem el trànsit sortint de l'interficie eth-clients i les respostes que tornen de connexions ja establertes, però no a l'inversa. Per exemple, ara un client pot veure les màquines de la xarxa DMZ:
  $ ping 10.10.2.11
  PING 10.10.2.11 (10.10.2.11) 56(84) bytes of data.
  64 bytes from 10.10.2.11: icmp_seq=1 ttl=62 time=1.57 ms

En canvi, si provem de fer un ping des d'aquest monitor de la dmz 10.10.2.11, no arriba al client:
  $ ping 10.10.3.3
  PING 10.10.3.3 (10.10.3.3) 56(84) bytes of data.

  --- 10.10.3.3 ping statistics ---
  3 packets transmited, 0 received, 100% packet loss, time 2025ms

Per tal de fer les regles persistents als reboots del sistema, es pot fer servir el paquet 'iptables-persistent':
  $ sudo apt-get install iptables-persistent

Durant la instal·lació pregunta si volem guardar les taules actuals. En cas de voler modificar les guardades, es pot fer amb la comanda següent:
  $ sudo netfilter-persistent save

Es possible guardar les regles en un fitxer per després restaurar-lo. La comanda és
  $ sudo sh -c "iptables-save > /etc/iptables.rules"

La comanda anterior (es necessita permisos) guarda la sortida de la comanda iptables-save en un fitxer ubicat a /etc. Per restaurar les regles es pot fer amb la següent comanda:
  $ sudo iptables-restore < /etc/iptables.rules

Suposant que estan a la mateixa ubicació on les hem guardat.

D'aquesta manera, a l'inici del sistema, s'aplicaran automàticament les regles que estiguin guardades en aquest moment. Això s'ha de fer tant pel router extern com l'intern per tal de preservar les regles.

Per activar el logging dels packets que fem DROP podem fer-ho amb les següents comandes dins del mateix script de configuració de les regles, al final:
  $ iptables -N LOGGING
  $ iptables -A INPUT -j LOGGING
  $ iptables -A LOGGING -m limit --limit 2/min -j LOG --log-prefix "iptables DROP: " --log-level 7
  $ iptables -A LOGGING -j DROP

Al log per defecte del kernel (/var/log/kern.log) veurem el missatge amb el prefix que hem especificat amb tota la informació, a l'exemple següent ens hem intentat connectar al router per SSH quan no està permès
  May  1 10:24:03 seax kernel: [ 1059.900753] IPTables Packet Dropped: IN=eth-clients OUT= MAC=08:00:27:10:03:01:08:00:27:37:e4:4b:08:00 SRC=10.10.3.3 DST=10.10.3.1 LEN=60 TOS=0x00 PREC=0x00 TTL=64 ID=34781 DF PROTO=TCP SPT=56114 DPT=22 WINDOW=29200 RES=0x00 SYN URGP=0

Per tant amb aquesta configuració permetem que els clients puguin accedir a la web, ja sigui per HTTP o HTTPS, als diferents equips de la xarxa DMZ i als seus serveis. En canvi els equips de la DMZ no poden accedir a la xarxa clients a no ser que el client hagi establert ja una conneixó.

D'altra banda des de l'exterior només es pot accedir a través de SSH en els ports especificats anteriorment a màquines de la xarxa DMZ, i als servidors web i DNS.

La resta de ports i serveis estan restringits a no se que s'enmarquin dins d'algun dels casos anteriors. Per exemple, els routers no poden fer pings a altres màquines perquè les polítiques OUTPUT i INPUT per defecte no els hi ho permeten.

Per tal de limitar els usuaris i que només puguin navegar a través del proxy web, es pot fer també a través de les regles de les taules ip, permetent només peticions HTTP i HTTPS a l'adreça 10.10.2.7 i no a qualsevol altra. També existeix la possiblitat de redirigir el trànsit web del router intern automàticament al proxy web, però no he aconseguit que la petició tornés al client.

### 3. Proxy web

Per tal de posar en marxa un proxy web fem servir el paquet 'squid3' que estarà corrent en una de les nostres màquines, concretament a l'adreça 10.10.2.7
  $ sudo apt-get install squid3

Per defecte aquest programa funciona pel port 3128. Modifiquem el fitxer de configuració per defecte per bloquejar una pàgina web. En aquest cas, volem bloquejar totes les pàgines del domini .facebook.com siguin HTTP o HTTPS.

Hem d'afegir les següents directrius a /etc/squid/squid.conf:
  acl fb dstdomain .facebook.com
  http_reply_access deny fb
  http_access deny CONNECT fb

Al acabar de configurar s'ha de reiniciar squid:
  $ sudo systemctl restart squid

Per mirar que no ens hem equivocat amb la sintaxi de l'arxiu de configuració, podem fer la següent comanda per veure la línia de l'error. En cas d'error, squid no s'inicia:
  $ squid -k parse

Tots els clients de la xarxa clients que han d'accedir a la web ho hauran de fer a través d'aquest proxy que hem configurat. Per tal de que utilitzin aquest proxy a nivell de sistema, s'han de fer servir les variables del sistema amb les següents comandes:
  $ export http_proxy="http://10.10.2.7:3128"
  $ export https_proxy="http://10.10.2.7:3128"

Això serà tant per les connexions HTTP (port 80) com les HTTPS (port 443). Podem fer la prova per exemple amb un navegador CLI i tcpdump en el mateix client per veure que realment és el proxy qui ens respon i no el recurs.

Per exemple aquí tenim la petició GET del navegador per recuperar google.com:
  10.10.3.3	10.10.2.7	HTTP	346	GET http://www.google.com/ HTTP/1.0

I la resposta
  10.10.2.7	10.10.3.3	HTTP	2516	HTTP/1.1 200 OK  (text/html)

En ambdós casos el servidor és el nostre proxy a 10.10.2.7. Si no estigués configurat el proxy l'adreça de resposta és la mateixa de google.com. Si ara provem facebook.com que és un dels recursos bloquejats squid ens contesta amb que el recurs està prohibit.
  10.10.3.3	10.10.2.7	HTTP	350	GET http://www.facebook.com/ HTTP/1.0
  10.10.2.7	10.10.3.3	HTTP	4094	HTTP/1.1 403 Forbidden  (text/html)

I apareix una pàgina personalitzable amb un text amb una petita explicació. La sortida d'aquesta pàgina està adjunta.


## Referències

https://www.revsys.com/writings/quicktips/nat.html
https://www.unixtutorial.org/2014/05/how-to-make-ip-forwarding-permanent-in-linux/
http://freelinuxtutorials.com/tutorials/linux-as-a-router-and-firewall/
https://www.leaseweb.com/labs/2013/12/setup-linux-gateway-using-iptables/
https://debian-handbook.info/browse/stable/sect.ipv6.html
