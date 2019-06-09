# Pràctica 2 - Montpeó Pere

Fitxers involucrats

- p1_montpeo_pere.txt
- informa_eth.sh

## Configurar interficies

bridge 
nat
169.254.x.y link local, connexió de maquines directament connectades sense router pel mig, pensades per poder-se connectar si falla el dhcp per exemple, muntar una xarxa sense router servidors, apple

Per defecte amb VirtualBox i Debian la primera targeta de xarxa ja ve configurada per a que es connecti de forma dinàmica. Això ho podem veure el arxiu que es troba a `/etc/network/interfaces`.

Amb el sistema acabat d'instal·lar hi trobarem la primera interficie lo, que és una interficie virtual que es fa servir el sistema per comunicar-se localment amb ell mateix. Això s'anomena interficie de xarxa loopback i arrenca amb l'arrencada del sistema gràcies a la fòrmula auto (explicat més endavant). Sempre existeix i té el mateix format

```;
auto lo
iface lo inet loopback
```

La sintaxi de l'arxiu `/etc/network/interfaces` es la següent

- `auto <nom_interficie>`: arrenca la interficie <nom_interficie> amb l'arrencada del sistema
- `allow-hotplug <nom_interficie>`: arrenca la interficie <nom_interficie> quan el kernel detecta un esdeveniment de connexió en calent (hotplug) de la interficie
- Línies que comencen per `iface <config_name>`: defineix la configuració de xarxa
- Línies que comencen per hash `#`: són comentaris
- Línia que acaba amb backslash `\`: extendre la configuració fins la següent línia

La configuració de xarxa té la següent sintaxi

```;
iface <nom_configuració> <família_adreces> <nom_mètode>
<opcio1> <valor1>
<opcio2> <valor2>
...
```

Amb el sistema que ens ve per defecte, juntament amb la instal·lació a través de VirtualBox, es crea la interficie de xarxa enp0s3. La nomenclatura ara ha canviat de la tradicional eth0, wlan0... al que s'anomena Predictable Network Interfaces Names desde Debian 9. Ara la nomenclatura depèn de la localització física, en el cas que veurem és una targeta de xarxa ethernet PCI col·locada al primer slot. D'aquesta manera podriem reemplaçar el hardware i el nom no canviaria.

Existeix la opció de canviar el nom de les interficies de xarxa a un altre que ens convingui. Per poder reanomenar una interficie de xarxa es pot fer creant un nou arxiu a la ruta /lib/systemd/network/ que casi el nom que volem amb l'adreça MAC de l'adaptador, seguint la sintaxi de la pàgina man de systemd.link, ejectutant la comanda `update-initramfs -u` perquè els canvis s'apliquin al reiniciar la màquina.

La que ens interessa és la següent configurada actualment que serà la primària, està configurada amb dhcp i s'anomena enp0s3.

La part de configuració de la interficie primària és

```;
allow-hotplug enp0s3
iface enp0s3 inet dhcp
```

Aquí estem dient que permetem connectar el hardware amb la màquina arrencada, i configurar el mode de xarxa de la interficie enp0s3 en dhcp quan aquesta detecta físicament la interficie.

Per configurar manualment una interficie amb una IP stàtica canviariem la opció de inet a static. Editar el fitxer `/etc/network/interfaces` i modificar la interficie que es vol modificar, inet seguit de static:

```;
allow-hotplug enp0s3
iface enp0s3 inet static
  address 10.0.2.15
  netmask 255.255.255.0
  gateway 10.0.2.2
```

Per configurar de mode static una interficie hem de conèixer la xarxa a la que ens volem connectar, com per exemple el rang d'adreces IP, l'adreça de la porta d'enllaç, i una adreça lliure. 

La operativa anterior de configurar a través dels fitxers el mode o l'adreça també es poden fer amb la comanda `ip link`. La sintaxis és

```;
ip link set <nom_dispositiu> <comanda>
```

Per poder aixecar o tirar una interficie de xarxa (les mateixes comandes que invoca l'allow-hotplug o auto) són `ifup <nom_interficie>` per arrencar la interficie i `ifdown <nom_interficie>` per tirar-la.

Les comandes poden ser

```;
[ { up | down } ]
			[ type ETYPE TYPE_ARGS ]
			[ arp { on | off } ]
[ dynamic { on | off } ]
[ multicast { on | off } ]
[ allmulticast { on | off } ]
[ promisc { on | off } ]
[ protodown { on | off } ]
[ trailers { on | off } ]
[ txqueuelen PACKETS ]
[ name NEWNAME ]
[ address LLADDR ]
[ broadcast LLADDR ]
[ mtu MTU ]
[ netns { PID | NETNSNAME } ]
[ link-netnsid ID ]
[ alias NAME ]
	[ vf NUM [ mac LLADDR ]
	[ VFVLAN-LIST ]
	[ rate TXRATE ]
	[ max_tx_rate TXRATE ]
	[ min_tx_rate TXRATE ]
	[ spoofchk { on | off } ]
	[ query_rss { on | off } ]
	[ state { auto | enable | disable } ]
	[ trust { on | off } ]
	[ node_guid eui64 ]
	[ port_guid eui64 ] ]
[ { xdp | xdpgeneric | xdpdrv | xdpoffload } { off |
	object FILE [ section NAME ] [ verbose ] |
	pinned FILE } ]
[ master DEVICE ]
[ nomaster ]
[ vrf NAME ]
[ addrgenmode { eui64 | none | stable_secret | random } ]
[ macaddr { flush | { add | del } MACADDR | set [ MACADDR [
MACADDR [ ... ] ] ] } ]
```

Les més destacades són `dynamic` per configurar-la en mode estàtic o dinàmic, `promisc` per mode promiscu, `address` per canviar l'adreça, MTU per canviar-lo.

Amb la comanda `ip link show <nom_interficie>` es pot comprovar l'estat de l'interficie i les opcions amb les quals està configurada. Es pot verificar si està en mode promiscu. Si no està en mode promiscu, no apareix.

Amb la comanda `hostname` obtenim el nom del nostre equip local. Aquest nom està a l'arxiu `/etc/hostname`.

A /etc/hosts està l'arxiu que conté els noms dels hosts. Associa les adreces IP amb un hostname, un per cada línia. El format és primer l'adreça IP i després del nom. En el sistema operatiu nou ens trobarem només el localhost.

També es pot preguntar a un servidor de DNS per un nom a partir d'una adreça IP mitjançant la comanda `dig`. 

```;
dig [@servidordns] [-b adreça]
```

En el cas que no s'especifiqui un servidor DNS es mirarà automàticament als servidors del fitxer /etc/resolv.conf. En el cas concret de la màquina virtual amb VirtualBox configurada en mode NAT agafa la configuració DNS de la màquina host.

Acutalment els àlies de xarxa estan obsolets però es pot emular la mateixa funció amb les etiquetes a les xarxes de la comanda `ip`. Al afegir la xarxa se li pot especificar l'etiqueta.

En tot cas a l'arxiu /etc/networks es troben les xarxes i els seus àlies. Normalment trobarem per defecte default, loopback, i link.local amb les seves respectives adreces.

Per tal de saber la adreça externa (IP pública) tenim dues opcions. A través de la comanda `dig` preguntant a un servidor de DNS o com està fet a l'script amb la comanda `wget` per obtenir un recurs d'internet. Per exemple serveix

```;
wget http://ipinfo.io/ip
```

En aquest cas depenem de descargar-nos un recurs d'un tercer.

Per fer un script shell s'ha d'afegir al línia #!/bin/sh o nombrar l'arxiu .sh per indicar al sistema que es tracta d'un script executable. Per fer-lo executable també s'han de donar permisos d'execució amb la comanda `chmod`, com a super usuari.

```;
sudo chmod 755 informa_eth.sh
```

A l'hora d'executar, com les comandes anteriors, s'ha de fer amb permisos

```;
sudo ./informa_eth.sh
```

I crearà un arxiu anomenat info_eth.txt al mateix directori d'execució amb tota la informació de xarxa de la màquina.

## Referències
MAN de cada comanda usada
https://www.debian.org/distrib/
http://metadata.ftp-master.debian.org/changelogs/main/s/systemd/systemd_221-1+deb9u2_udev.README.Debian
http://www.freeos.com/guides/lsst/