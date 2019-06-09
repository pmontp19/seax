#Pràctica 8 - Servidor DNS

Fitxers involucrats

- ns1/etc/bind/named.conf
- ns1/etc/bind/named.conf.local
- ns1/etc/bind/named.conf.options
- ns1/etc/network/interfaces
- ns1/var/lib/bind/10.10.in-addr.arpa
- ns1/var/lib/bind/db.seac.edu

- ns2/etc/bind/named.conf
- ns2/etc/bind/named.conf.local
- ns2/etc/bind/named.conf.options
- ns2/etc/network/interfaces
- ns2/var/lib/bind/10.10.in-addr.arpa
- ns2/var/lib/bind/db.classe.seax.edu

## Continguts

1. Instal·lar servidor DNS
2. Configuració servidor - opcions
3. Configuració servidor - zones
4. Configuració servidor - resolució
5. Proves de validació

## 1. Instal·lar servidor DNS

El servidor DNS que fem servir s'anomena bind9. Per instal·lar-lo juntament amb les eines i la documentació al sistema:
  $ sudo apt-get install bind9 bind9utils bind9doc

En aquest escenari tindrem dues màquines virtuals (ns1 i ns2 respectivament) que faran de servidor de noms. La primera és 10.10.2.4 i la segona 10.10.2.5 en el nostre escenari.

## 2. Configuració servidor - opcions

En els dos servidors farem la mateixa configuració d'opcions a l'arxiu /etc/bind/named.conf.options.

Primer afegim la declaració per saber de quins clients hem de permetre la recursivitat
  acl "trusted" {
  	10.10.2.4;	# ns1
  	10.10.2.5;	# ns2
  	10.10.2.0/28;	# dmz net
  	10.10.3.0/28;	# clients net
  };

I tot seguit, dins de la declaració d'opcions, les següents opcions
  recursion yes;
	allow-recursion { trusted; };
	listen-on { 10.10.2.5; };
	allow-transfer { none; };

	forwarders {
		1.1.1.1;
		1.0.0.1;
	};

Que permeten la recursivitat dels nostres clients declarats abans, per defecte no delegar zones (més endavant ho permetem per cada zona) i la configuració dels servidors de nom per defecte en cas que la petició no sigui del nostre domini.

## 3. Configuració servidor - zones

Primer cal configurar els servidors dels quals permetrem la recursivitat de peticions

Cal configurar les zones per les quals resoldrem les peticions de DNS en el fitxer '/etc/bind/named.conf'. El format sempre és el mateix: zone <nom_zona> { opcions }. Pel cas del servidor dns1la primera zona la definirem com:
  zone "seax.edu" {
    type master;
    allow-transfer {10.10.2.5;};
    file "/var/lb/bind/db.seax.edu";
  };

Això especifica que actua com a master de la zona, que permet copiar zones entre els servidors DNS (delegació d'un domini) i la ubicació de l'arxiu de traduccions.

Per la zona inversa, per tal de poder resoldre adreces per noms, té una sintaxis sembalnt:
  zone "10.10.in-addr.arpa" {
    type master;
    allow-transfer { 10.10.2.5; };
    file "/var/lb/bind/10.10.in-addr.arpa";
  };

En aquest cas especifiquem el nom de zona inversa. Volem especificar només la part 10.10. de l'adreça perquè en la mateixa zona especificarem el nom de les màquines de la xarxa dmz i clients. També es podria especificr una zona per cada xarxa, per exemple "2.10.10.in-addr.arpa".

Pel domini classe l'especificarem de la forma següent en el primer servidor:
  zone "classe.seax.edu" {
    type slave;
    allow-transfer {10.10.2.5;};
    file "/var/lb/bind/db.classe.seax.edu";
  };

En aquest cas la zona passa a ser slave pel primer servidor, ja que serà el segon qui sigui el primari per aquesta zona. I a l'inversa pel segon servidor.

Ens els arxius de configuració adjunts es troba la configuració completa d'ambós servidors per l'arxiu named.conf.

## 4. Configuració servidor - resolució

Ara cal inserir la llista de noms amb les corresponents adreces IP per les nostres zones. Copiarem una plantilla en blanc per intrduïr el noms. Exemple de la primera zona:
  $ cp /etc/bind/db.empty /var/lib/bind/db.seax.edu

I al fitxer introduirem el llistat d'adreces que volem traduïr, amb el següent format:
  <nom> IN  A <ip>

Per exemple, en el fitxer db.seax.edu:
  monitor-dmz IN  A 10.10.2.11

També cal canviar el SOA, Start of Authority que inclou el nom del servidor de noms, amb els paràmetres

- Responsable del domini
- Número de sèrie
- Segons abans d'actualitzar el domini
- Segons abans de reintentar actualitzar el domini
- El límit pel qual una zona ja no es considera autoritària
- El resultat negatiu del TTL Time-To-Live

En aquest cas per exemple, és:
  ns1.seax.edu. admin.ns1.seax.edu. (1 604800 86400 2419200 86400)

Per la zona inversa farem el mateix procediment però copiant un arxiu blanc diferent:
  $ cp /etc/bind/db.127 /var/lib/bind/10.10.in-addr.arpa

En aquest cas la sintaxis és a la inversa.
  <addr> IN PTR <nom>

Per exemple, pel cas del primer servidor:
  11.2  IN  PTR monitor-dmz.seax.edu.

Per tots els canvis que fem als arxius de configuració, s'ha de reiniciar el servei del servidor DNS perquè s'apliquin els canvis
  $ sudo service bind9 restart

## 5. Proves de validació

Per fer les proves de validació hem configurat una nova màquina virtual que actuarà com a client dins de la xarxa dmz de l'escenari de pràctiques anteriors. Configurem perquè apunti als servidors de noms correctes modificant l'arxiu /etc/resolv.conf
  search seax.edu
  nameserver 10.10.2.4
  nameserver 10.10.2.4

Amb aquesta configuració feta podem provar a resoldre un nom dintre del nostre domini
  $ nslookup web
  Server:   10.10.2.4
  Address:  10.10.2.4#53

  Name: web.seax.edu
  Address: 10.10.2.6

Al nostre subdomini
  $ nslookup monitor-clients.classe.seax.edu
  Server:   10.10.2.4
  Address:  10.10.2.4#53

  Name: monitor-clients.classe.seax.edu
  Address: 10.10.3.11

També podem provar la resolució inversa de noms
  $ nslookup 10.10.2.7
  Server:   10.10.2.4
  Address:  10.10.2.4#53

  7.2.10.10.in-addr.arpa name = proxy-web.seax.edu


## Referències
* https://servidordebian.org/es/squeeze/intranet/dns/server
* https://www.digitalocean.com/community/tutorials/how-to-configure-bind-as-a-private-network-dns-server-on-ubuntu-14-04
* https://www.debian.org/doc/manuals/securing-debian-howto/ch-sec-services.en.html#s-sec-bind
