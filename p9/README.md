## Pràctica 9 - Montpeó Pere

Arxius incolucrats

```;
  Servidor:
    /etc
      sysctl.conf
      /network/interfaces
      /openvpn
        ca.crt
        dh2048.pem
        openvpn-status.log
        server.conf
        server.key
        server.crt
        static.key
        tun0.conf

  Client:
    /etc
      /openvpn
        client.conf
        tun0.conf
        static.key
        /keys
          ca.crt
          usuari1.crt
          usuari1.key

  Smartphone:
    client.ovpn

  Captures de xarxa
```

## Continguts

0. Topologia escenari
1. Instal·lació
2. Configuració servidor
3. Clau estàtica
4. Certificats - CA
5. Certificats - Servidor
6. Certificats - Clients
7. Certificats - Transferència
8. Configuració client
9. Proves de validació

## 0. Topologia escenari

En aquesta pràctica tenim una màquina Debian que fa de servidor, amb dues interficies:
 
- eth0: connectada a l'exterior, internet, la IP és estàtica perquè és un servidor i no volem que canvii mentre fem les proves (mode bridge)
- eth1: connectada a la xarxa DMZ, IP estàtica 10.10.2.1 (mode xarxa interna)

Seria com si haguessim instal·lat el servidor VPN a sobre del router d'accés de la pràctica 6.

El client Linux és una altra màquina Debian amb una sola interficie connectada en mode bridge, simulant estar a internet com la interficie eth0 del servidor.

El client mòbil és un telèfon Android connectat també al router com les màquines anteriors.

Per tant tenim una màquina, el servidor VPN, que fa de frontera, i els altres dos dispositius fora del que seria una xarxa interna.

## 1. Instal·lació

Instal·lem el servidor OpenVPN i el paquet easy-RSA per l'encriptació.

```;
# apt-get install openvpn easy-rsa
```

## 2. Configuració servidor

Agafem la configuració per defecte del propi paquet

```;
# gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz > /etc/openvpn/server.conf
```

Editem aquest mateix fitxer que hem obtingut

```;
# nano /etc/openvpn/server.conf
```

Ens els paràmetres de Diffie hellman ens assegurem que la longitud de les claus RSA és de 2048 bits.
  dh dh2048.pem

Si volem que el tràfic dels clients vagi per defecte pel tunel, en el mateix arxiu, descomentem la línia següent
  push "redirect-gateway def1 bypass-dhcp"

Farem servir l'usuari i grup nobody nogroup per executar el servidor amb un usuari sense privilegis descomentant aquestes línies
  user nobody
  group nogroup

També modificarem la topologia de la xarxa, ja que volem la subxarxa VPN tingu una adreça com 10.10.4.0/28
  server 10.10.4.0 255.255.255.240

Per tal de preservar la topologia de la practica 6 i volem que els usuaris de la xarxa VPN puguin accedir a algun recurs de la xarxa DMZ, la 10.10.2.0/28, afegirem una ruta que s'afegirà als clients
  push "route 10.10.2.0 255.255.255.240"

La resta de paràmetres els deixem tal com venen per defecte.

S'ha d'activar el reenviament de paquets a nivell sistema

```;
# echo 1 > /proc/sys/net/ipv4/ip_forward
```

Per fer-ho permanent descomentem la següent línia a l'arxiu /etc/sysctl.conf
  net.ipv4.ip_forward=1

## 3. Clau estàtica

El primer mètode d'identificació és el de clau compartida.

En el servidor generem una clau amb la següent comanda

```;
# openvpn --genkey --secret /etc/openvpn/static.key
```

Aquesta clau és la que hem de distribuir al client. Al mateix servidor, creem un fitxer:

```;
# nano /etc/openvpn/tun0.conf
```

Amb el següent contingut:
  dev tun0
  ifconfig 10.10.4.1 10.10.4.2
  secret /etc/openvpn/static.key

En aquest cas la primera IP és l'adreça del servidor i la segona la del client.

En la part del client, fem el mateix:

```;
#  nano /etc/openvpn/tun0.conf
```

Amb el següent contingut:
  remote 192.168.0.149
  dev tun0
  ifconfig 10.10.4.2 10.10.4.1
  secret /etc/openvpn/static.key

S'ha de tenir en compte que 192.168.0.149 és la IP pública del servidor VPN. Per tant s'ha de modificar amb la corresponent.

Per posar en marxa manualment el servidor i el client ho podem fer amb la comanda especificant la ubicació i el nivell de verbose si volem veure el detall dels missatges del servidor

```;
# openvpn --config /etc/openvpn/tun0.conf --verb 3
```

Pels següent apartat, caldria modificar l'extensió del tun0.conf perquè el daemon de VPN no l'agafi com a fiter de configuració vàlid si realment volem aplicar la configuració següent TLS.

## 4. Certificats

Primer copiem els scripts de generació de claus RSA del paquet easy-rsa que hem instal·lat abans i també una carpeta on guardarem les claus generades

```;
  # cp -r /usr/share/easy-rsa/ /etc/openvpn
  # mkdir /etc/openvpn/easy-rsa/keys
```

En l'arxiu /etc/openvpn/easy-rsa/vars podem modificar els paràmetres pels nostres certificats. Canviarem variables com el país, provincia, ciutat, etc.
  export KEY_COUNTRY="ES"
  export KEY_PROVINCE="BARCELONA"
  export KEY_CITY="Vilanova"
  export KEY_ORG="seax"
  export KEY_EMAIL="admin@seax.edu"
  export KEY_OU="classe.seax"

També s'han de generar els paràmetres pel Diffie-Helman

```;
# openssl dhparam -out /etc/openvpn/dh2048.pem 2048
```

Canviem de directori al de easy-rsa

```;
# cd /etc/openvpn/easy-rsa
```

Linquem l'arxiu de configuració de openssl

```;
# ln -s openssl-1.0.0.cnf openssl.cnf
```

Generem les variables d'entorn

```;
# source ./vars
```

Netegem la resta de claus

```;
# ./clean-all
```

Finalment generem l'autoritat de certificació amb la següent comanda. Preguntarà per les diferents variables però ja les hem definit abans.

```;
# ./build-ca
```

## 5. Certificats - Servidor

Per generar el certificat pel servidor, hem de compilar la clau al mateix directori. Deixem challenge password i optional name en blanc.

```;
# ./build-key-server server
```

El directori per defecte de les claus és /etc/openvpn per tant hi he de copiar la clau, el certificat i el CA que hem generat

```;
# cp /etc/openvpn/easy-rsa/keys/server.crt /etc/openvpn
# cp /etc/openvpn/easy-rsa/keys/server.key /etc/openvpn
# cp /etc/openvpn/easy-rsa/keys/ca.crt /etc/openvpn
```

Per tal de que el servidor trobi els certificats els hem d'especificar també a l'arxiu de configuració del servidor que hem creat abans, /etc/openvpn/server.conf
  ca /etc/openvpn/ca.crt
  cert /etc/openvpn/server.crt
  key /etc/openvpn/server.key

## 6. Certificats - Clients

Cada client ha de tenir la seva clau. Per defecte el servidor OpenVPN no admet clients amb la mateixa clau de forma simultània. Generarem una clau per l'usuari1, mati procediment que pel servidor

```;
# ./build-key usuari1
```

També copiarem les claus al directori que hem creat anteriorment i l'arxiu de configuració

```;
# cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf /etc/openvpn/easy-rsa/keys/client.conf
```

D'aquest arxiu que acabem de copiar modificarem la IP del servidor i també farem un downgrade dels privilegis al córrer el servidor.

Els arxius de configuració es troben adjunts.

## 7. Certificats - Transferència

El client requereix les claus que hem creat al servidor, per tant, les copiarem a la màquina client. Des de la màquina client podem fer la següent comanda si ssh està habilitat

```;
# scp root@10.10.4.1:/etc/openvpn/easy-rsa/keys/client1.key .
```

El mètode de clau estàtica es podria pensar per un entorn en pocs usuaris, ja que la configuració és manual i requereix distribuir-la.

En canvi el mètode TLS (certificats) implementa un mètode per autenticar-se i intercanviar claus de forma bidireccional. És a dir, les dues parts s'han de certificar. La configuració i distribució del perfil de connexió podria ser més fàcil en un entorn amb més usuaris.

## 8. Configuració client

Primer anem a configurar una altra màquina Debian, en aquest cas simulant una connexió des de l'exterior de la xarxa interna de l'escenari.

Com en el cas anterior del servidor, podem agafar dels arxius d'exemple un arxiu client.conf amb els valors per defecte

```;
# cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf /etc/openvpn/client.conf
```

I ara l'editem. Especifiquem per suposat l'adreça del servidor VPN, en aquest cas, l'adreça publica del servidor, altra cop la ubicació dels certificats i claus.

Perquè agafi la configuració correctament, o en el cas de que tinguessim més d'un perfil de VPN per connectar, es pot especificar a /etc/default/openvpn el nom del perfil de configuració, que en el cas que estem fent es diu client
  AUTOSTART="client"

També es pot especificar que faci autostart de tots els perfils o de cap.

En el cas de voler utilitzar un smartphone com a client, a través de l'aplicació OpenVPN Connect, cal modificar l'arxiu de configuració. Fariem una copia del mateix fitxer del client, renombrant l'extensió a '.ovpn'.

Hi hem d'inserir la clau i certificats, amb les següents comandes, abans però ens hem de moure a la ubicació dels fitxer o en tot cas especificar la ruta absoluta

```;
# cd /etc/openvpn/keys
# echo "key-direction 1" >> client.ovpn
# echo "<ca>" >> client.ovpn
# cat ca.crt | grep -A 100 "BEGIN CERTIFICATE" | grep -B 100 "END CERTIFICATE" >> client.ovpn
# echo "</ca>" >> client.ovpn
# echo "<cert>" >> client.ovpn
# cat client.crt | grep -A 100 "BEGIN CERTIFICATE" | grep -B 100 "END CERTIFICATE" >> client.ovpn
# echo "</cert>" >> client.ovpn
# echo "<key>" >> client.ovpn
# cat client.key | grep -A 100 "BEGIN PRIVATE KEY" | grep -B 100 "END PRIVATE KEY" >> client.ovpn
# echo "</key>" >> client.ovpn
```

Aquestes comandes enganxarà directament el contingut dels certificats i clau al fitxer .ovpn que transferirem al telèfon. És important també modificar on anteriorment especificavem la ubicació dels certificats i clau i comentar les 3 l

```;
# ca /etc/openvpn/keys/ca.crt
# cert /etc/openvpn/keys/usuari1.crt
# key /etc/openvpn/keys/usuari1.key
```

L'aplicació reconeixerà el fitxer com un arxiu de configuració vàlid si els paràmetres i sintaxis són els correctes.

## 9. Proves de validació

Primer provarem de fer una connexió sense autenticació directament des de la màquina Debian.

A la part del servidor, introduïm la següent comanda per posar en marxa el servidor amb els paràmetres diferents dels del arxiu de configuració

```;
# openvpn --dev tun1 --ifconfig 10.10.4.2 10.10.4.3
```

Veurem una sortida semblant a aquesta

```;
Mon May 21 11:14:21 2018 library versions: OpenSSL 1.0.2l  25 May 2017, LZO 2.08
Mon May 21 11:14:21 2018 ******* WARNING *******: all encryption and authentication features disabled -- all data will be tunnelled as cleartext
Mon May 21 11:14:21 2018 TUN/TAP device tun1 opened
Mon May 21 11:14:21 2018 UDPv4 link local (bound): [AF_INET][undef]:1194
Mon May 21 11:14:21 2018 UDPv4 link remote: [AF_UNSPEC]
```

També podem veure que tenim una nova interficie

```;
4: tun1: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN group default qlen 100
```

I a la banda del client

```;
# openvpn --remote 10.10.4.1 --dev tun1 --ifconfig 10.10.4.2 10.10.4.3
```

Veurem també una sortida semblant a l'anterior i una nova interficie de xarxa.

Ara per agafar la configuració anterior i els seus certificats en el servidor només cal que l'arxiu estigui nombrat com server.conf perquè el servidor l'agafi per defecte. Podem comprovar que el servidor està en marxa o que la interficie virtual estàn correctes:

```;
# service openvpn status
# ip a
```

També podem veure que a la ubicació per defecte (/etc/openvpn/) s'hi estan arxivant els logs del servidor, on podem veure per exemple les diferents connexions dels clients al servidor.

Aquesta és la sortida de una de les proves amb certificat i clau on podem veure un client a la llista

```;
OpenVPN CLIENT LIST
Updated,Mon May 21 16:45:01 2018
Common Name,Real Address,Bytes Received,Bytes Sent,Connected Since
usuari1,192.168.0.160:42466,5581,5246,Mon May 21 16:39:44 2018
ROUTING TABLE
Virtual Address,Common Name,Real Address,Last Ref
10.10.4.6,usuari1,192.168.0.160:42466,Mon May 21 16:40:59 2018
GLOBAL STATS
Max bcast/mcast queue length,1
END
```

Tal com ha quedat configurat anteriorment en els punts 2 i 7, al reiniciar les màquines ja iniciaran automàticament el servei VPN servidor i client respectivament.

Podem provar per exemple de fer un ping des del client a la interficie DMZ del servidor

```;
# ping 10.10.2.1
```

I amb TCPDUMP veure com els paquets passen pel tunel i arriben a la DMZ per tornar cap al client

```;
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
  listening on tun0, link-type RAW (Raw IP), capture size 262144 bytes
  18:01:58.506620 IP 10.10.4.6 > 10.10.2.1: ICMP echo request, id 733, seq 1, length 64
  18:01:58.506651 IP 10.10.2.1 > 10.10.4.6: ICMP echo reply, id 733, seq 1, length 64
```;

En el cas de l'smartphone, podem fer el mateix amb una aplicació per a poder fer pings. Després d'agafar l'arxiu de configuració i connectar, fem el mateix ping

```;
  * Pings des de l'smartphone
  PING 10.10.2.1 (10.10.2.1)
  64 bytes from 10.10.2.1 (10.10.2.1): icmp_seq=1 ttl=64 time=16.0 ms
  64 bytes from 10.10.2.1 (10.10.2.1): icmp_seq=2 ttl=64 time=21.0 ms
  64 bytes from 10.10.2.1 (10.10.2.1): icmp_seq=3 ttl=64 time=12.0 ms
```

```;
  * Pings rebuts i contestats pel servidor amb tcpdump
  17:06:32.427563 IP 10.10.4.6 > 10.10.2.1: ICMP echo request, id 531, seq 1, length 64
  17:06:32.427581 IP 10.10.2.1 > 10.10.4.6: ICMP echo reply, id 531, seq 1, length 64
  17:06:33.467753 IP 10.10.4.6 > 10.10.2.1: ICMP echo request, id 532, seq 1, length 64
  17:06:33.467772 IP 10.10.2.1 > 10.10.4.6: ICMP echo reply, id 532, seq 1, length 64
  17:06:34.514818 IP 10.10.4.6 > 10.10.2.1: ICMP echo request, id 533, seq 1, length 64
  17:06:34.514834 IP 10.10.2.1 > 10.10.4.6: ICMP echo reply, id 533, seq 1, length 64
```

## Referència
- https://wiki.debian.org/OpenVPN#Configuration
- https://www.digitalocean.com/community/tutorials/how-to-set-up-an-openvpn-server-on-debian-8
