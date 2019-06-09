# Montpeo Pere - Accés Wi-Fi intel·ligent

Fitxer adjunts

```;
  /etc
    /hostapd/hostapd.conf
    rc.local
    /default/hostapd
    dnsmasq.conf
    dhcpcd.conf
  /usr/local/bin
    channel.py        # script escollir millor canal wifi
    hostapdchange.sh  # script notificacions
    tweet.client.key  # claus dev twitter
    tweet.sh          # llibreria client de twitter
```

## Continguts

1. Instal·lar paquets
2. Configurar hostapd
3. Configurar dnsmasq
4. Configurar taules ip
5. Sistema de notificacions Twitter
6. Sistema de notificacions Telegram
7. Elecció del canal

## 1. Instal·lar paquets

Per la part del punt d'accés el software que necessitem és:

- hostapd
- dnsmaq
- iptables-persistent

Per instal·lar amb la comanda següent:

```;
$ apt-get install -y hostapd dnsmasq iptables-persistent
```

## 2. Configurar hostapd

Per configurar hostapd cal modificar dos fitxers
  $ nano /etc/hostapd/hostapd.conf

I introduirem els següents paràmetres:
  interface=wlan0
  ssid=SEAXmola
  hw_mode=g
  channel=7
  ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]
  wmm_enabled=0
  macaddr_acl=0
  auth_algs=1
  wpa=2
  ignore_broadcast_ssid=0
  wpa_passphrase=SEAX2018
  wpa_key_mgmt=WPA-PSK
  wpa_pairwise=TKIP
  rsn_pairwise=CCMP
  ctrl_interface=/var/run/hostapd
  ctrl_interface_group=0

Amb l'anterior especifiquem que volem una xarxa amb les següents característiques:

- Interficie wlan0
- Amb el nom SEAXmola
- Mode g i de moment pel canal 7
- Amb seguretat WPA2 i contrasenya SEAX2018

Perquè hostapd llegeixi aquesta configuració cal editar el fitxer /etc/default/hostapd
  $ nano /etc/default/hostapd

I canviar la línia
  DAEMON_CONF=""

Per
  DAEMON_CONF="/etc/hostapd/hostapd.conf"

## 3. Configurar dnsmasq

Farem servir aquest paquet com a servidor de DHCP tot i que també ofereix DNS. Primer configurarem el dhcp i li assignarem també una IP a la nostra Raspberry com a router i un servidor dns. Cal editar el fiter /etc/dhcpcd.conf i afegir al final el següent:
  $ nano /etc/dhcpcd.conf
  interface wlan0
  static ip_address=10.10.3.1
  static routers=10.10.3.1
  static domain_name_servers=8.8.8.8

I ara definirem el rang d'adreces que donarem quan un dispositiu es connecti al WiFi. Cal editar el fitxer /etc/dnsmasq.conf
  $ nano /etc/dnsmasq.conf
  interface=wlan0
  domain-needed
  bogus-priv
  dhcp-range=10.10.3.2,10.10.3.14,1h
  dhcp-script=/home/pi/script.sh

## 4. Configurar taules ip

Si volem que el trànsit dels clients connectats a la interficie wlan0 puguin tenir conectivitat a internet a través de la interficie eth0 podem afegir les següents regles:

```;
# iptables -t nat -A  POSTROUTING -o eth0 -j MASQUERADE
# iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
# iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
```

Que redirigiran el trànsit de wlan a eth0, de eth0 a wlan0 només aquells paquets amb una connexió establerta prèviament, i actuarà de NAT enmascarant els clients que surten per la eth0.

Perquè els usuaris només puguin establir connexions amb HTTP i HTTPS afegirem les següents regles i polítiques per defecte per descartar la resta de paquets:

```
# iptables -A INPUT -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
# iptables -A OUTPUT -p tcp -m multiport --dports 80,443 -m conntrack --ctstate ESTABLISHED -j ACCEPT
```

Loopback i polítiques per defecte:

```
# iptables -A INPUT -i lo -j ACCEPT
# iptables -A OUTPUT -o lo -j ACCEPT
# iptables -P INPUT DROP
# iptables -P FORWARD DROP
# iptables -P OUTPUT DROP
```

Per fer les regles persistents cal executar:
  $ dkpg-reconfigure iptables-persistent

I guardar les regles IPv4.

I modificar el redireccionament de paquets al fitxer /etc/sysctl.conf i descomentar la següent línia:
  $ nano /etc/sysctl.conf
  net.ipv4.ip_forward=1

## 5. Sistema de notificacions - Twitter

Pel sistema de notificacions hem implementat un bot de Twitter que notifica quan algú es connecta abans de rebre una adreça IP, i també quan deix la xarxa. Els paquets que requereix la llibreria que fa de client de Twitter són

- curl
- jq
- nkf
- openssl

Podem instal·lar amb la següent comanda:
  $ apt-get install -y curl jq nkf openssl

La llibreria es basa en dos fitxers: tweet.client.key i tweet.sh. El primer conté les claus i tokens per tal d'autenticar-se al servei i el segon totes les comandes, de les quals només ens interessa 'post'. Cal definir els següents camps:
  MY_SCREEN_NAME
  MY_LANGUAGE
  CONSUMER_KEY
  CONSUMER_SECRET
  ACCESS_TOKEN
  ACCESS_TOKEN_SECRET

Per rebre els esdeveniments de connexió i desconnexió farem servir el daemon de hostapd_cli. Farem que s'executi al iniciar el sistema amb el nostre script com a paràmetre i en segon pla. Els paràmetres que rep l'script són:

- Interficie de connexió
- Adreça MAC
- Esdeveniment

Cal afegir la línia següent al fitxer /etc/rc.local abans del final exit 0:
  hostapd_cli -B -a/usr/local/bin/hostapdchange.sh

Cada cop que hi hagi un esdeveniment de hostapd s'executarà l'script hostapdchange.sh. Filtra pel tipus d'esdeveniment i executa la part d'entrada o de sortida de la xarxa.

Per aquest cas (notificacions de Twitter) només es notifica que algú ha entrat o sortit de la xarxa, en principi no tindria sentit piular l'adreça MAC.

L'usuari creat per aquesta ocasió es @botdchp
https://twitter.com/BotDhcp

Nota: s'anomna botdhcp perquè primer vaig fer proves amb els sistema d'esdeveniments de dhcp, però finalment vaig decidir canviar al de hostapd ja que els events eren inmediats.

El fitxer de registre.txt es troba a la carpeta de l'usuari pi (/home/pi) i té la següent sintaxi:
  xx:xx:xx:xx:xx:xx 2018-06-06 11:18:49 (sortida)
  xx:xx:xx:xx:xx:xx 2018-06-06 11:18:48 (entrada)

## 6. Sistema de notificacions - Telegram

També hem implementat un bot de Telegram que pot notificar directament al administrador o a un grup de persones sobre un esdeveniment de hostapd per saber quan un dispositiu entra a la xarxa o en surt.

En aquest cas també necessitem els mateixos paquets que la solució de Twitter.

Primer cal crear un bot tal i com explica la documentació de Telegram. En el mateix script que l'apartat anterior pren per un costat l'usuari a enviar la notificació, el token del bot, i dels paràmetres de hostapd per saber quin tipus de missatge ha d'enviar. L'script també està adjunt.

En aquest cas mostra més detalls que el missatge de Twitter.
  El dispositiu xx:xx:xx:xx:xx:xx s'acaba de connectar a la xarxa

Cal notar que abans de que el bot pugui enviar una notificació cal enviar  un missatge al bot des de l'usuari. Per rebre missatges es pot fer el següent:

1. Obtenir el teu número id d'usuari
2. Començar una conversa amb el bot @dhcp_seax_bot
3. Canviar el número id de d'usuari (USERID) al script hostapdchange.sh

Si en un futur es volgués millorar l'script es podria implementar la resolució d'adreces IP a partir de l'adreça MAC i també la resolució dels hostnames.

Nota: igual que en el cas anterior, primer es va provar la solució d'events per dhcp, però es va optar pels de hostapd. Per aquesta raó el bot s'anomena dhcpbot (@dhcp_seax_bot).

## 7. Elecció del canal

Per escollir el millor canal s'executa un script al boot de la màquina que escaneja APs del voltant, guarda tots els canals, i escull el que té menys APs en aquell canal. Si es dóna el cas que hi han 4 canals lliures al voltant triarà el del mig. Sinó sempre escull el més petit.

Per executar l'script al iniciar la màquina cal modificar el fiter /etc/rc.local i afegir la següent línia, abans de exit 0:
  iwlist wlan0 scan | egrep 'Channel:' | python /usr/local/bin/channel.py

L'script està preparat per rebre com a argument la llista ja parsejada de les APs i el canal que ocupen.

Finalment el canal fa servir també el daemon cli de hostapd, hostapd_cli, per canviar el canal i tornar a habilitar l'ap.

## Referència
- https://www.raspberrypi.org/documentation/configuration/wireless/access-point.md
- http://www.thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html
- https://www.raspberrypi.org/forums/viewtopic.php?t=191453
- https://somesquares.org/blog/2017/10/Raspberry-Pi-router/
- https://github.com/piroor/tweet.sh
- https://core.telegram.org/bots
- https://gist.github.com/matriphe/9a51169508f266d97313
