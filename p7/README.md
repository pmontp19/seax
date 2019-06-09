# Pràctica 6 - Montpeó Pere

Fitxers involucrats

- captura_dhcpd: captura de xarxa de la negociació DHCP feta des del servidor DHCP
- captura_monitor: captura de xarxa de la negociació DHCP feta des del client monitor-clients
- dhclient.conf: arxiu de configuració del client DHCP de la xarxa clients
- dhcpd.conf: arxiu de configuració del servidor DHCP
- isc-dhcp-server: paràmetres per defecte del isc-server-dhcp
- leases_db: base de dades dels arrendaments d'adreces del servidor
- leases_dhcp.sh: script de la proposta de millora de seguretat
- mail_alerta: missatge enviat per l'script anterior
- syslog_client: log del sistema client amb negociació DHCP
- syslog_monitor: log del sistema monitor-clients amb negociació DHCP
- syslog_server: log del sistema del servidor DHCP

## CONTINGUTS

0. Escenari
1. Instal·lació servidor DHCP
2. Configuració servidor DHCP
3. Arrencada del servidor DHCP
4. Comprovació del servei DHCP
5. Client DHCP
6. Proposta seguretat DHCP
7. Configuració DDNS

*_Nota: la paraula 'lease' s'ha traduït per arrendament_

## 0. Escenari

L'escenari es basa en el de l'anterior pràctica 6. Tenim una màquina que és el router intern amb dues interficies de xarxa: una per la xarxa dmz (eth-dmz, 10.10.2.0/28) i l'altra per la xarxa clients (eth-clients, 10.10.3.0/28).

Per la banda de la xarxa clients per poder fer proves tenim una màquina client configurada amb el client dhcp i una altra que és el monitor-clients configurada amb una IP estàtica.

D'altra banda a la xarxa DMZ hem fet servir el monitor-dmz com a client del servidor DHCP a més d'un client extra anomenat "rogue-client" que serà el que farà saltar l'alerta de la proposta de seguretat del punt 6.

## 1. Instal·lar servidor DHCP

Per instal·lar el paquet de servidor DHCP, versió 4, cal fer la següent comanda
  $ sudo apt-get install isc-dhcp-server

Al acabar la instal·lació intentarà posar en marxa el servidor però com que encara no està configurat fallarà l'arrencada d'aquest.

## 2. Configuració servidor DHCP

Dues possibilitats per configurar les interficies que cal incloure a la configuració del servidor. Primera possibilitat amb el mateix gestor de paquets:
  $ sudo dpkg-reconfigure isc-dhcp-server

I ens demanarà que introduïm les interficies que calen per donar servei de DHCP separades per un espai en el cas que n'hi hagi més d'una. En el nostre cas introduirem:
  $ eth-clients eth-dmz

L'altra alternativa és editar o crear si no està creat l'arxiu /etc/default/isc-dhcp-server amb l'editor de text i incloure:
  $ sudo nano /etc/default/isc-dhcp-server
  INTERFACESv4="eth-clients eth-dmz"

L'arxiu de configuració bàsic del servidor es troba a /etc/dhcp/dhcpd.conf. El que ve per defecte conté comentaris i exemples dels diferents paràmetres. Fer una còpia de seguretat abans d'editar-lo. Ho podem fer per exemple amb la següent comanda:
  $ cp /etc/dhcp/dhcpd.conf{,.backup}

Opcions:
  
- default-lease-time: temps d'arrendament per defecte en segons
- max-lease-time: temps màxim d'arrendament en segons
- ping: boolea, si és True el servidor fa un ping a l'adreça abans d'assignar-li al client
- option domain-name-servers: l'adreça IP dels servidors DNS que el client pot fer servir
- option domain-name: el nom del domini que pot fer servir el client
- authoritative: el servior és authoritative, el servidor hauria d'enviar missatges DHCPACK a clients mal configurats
- subnet 192.168.1.0 netmask 255.255.255.0 { * }: la declaració de la subnet amb les opcions a dins
- range 192.168.1.2 192.168.1.15: defineix el rang d'adreces les quals el servidor arrendarà de forma dinàmica, es pot definir més d'un rang amb adreces no correlatives
Per sintaxi cada declaració acaba amb un punt i coma. La resta d'opcions es poden consultar a la pàgina man de 'dhcpd-options'.
- option routers: defineix l'adreça del gateway per defecte que el client farà servir

En el primer tram de l'arxiu definirem els paràmetres per defecte que prendràn totes les subxarxes si no s'especifica el contrari
  default-lease-time 600;
  max-lease-time 7200;
  option domain-name-servers 147.83.2.3
  option domain-name "backus.upc.es"
  authorative;

Si no s'indica el contrari en la configuració de la subxarxa, el servidor DHCP enviarà aquests paràmetres. Per defecte cada 10 minuts servidor i client hauran de renegociar l'arrendament de l'adreça en qüestió. El client també pot demanar un temps més elevat que el per defecte, però mai superarà les dues hores de màxim. De pas també especifiquem el servidor DNS per defecte que en aquest cas és el de l'universitat.

Ara anem a configurar el servidor per donar les adreces per la xarxa de clients.
  subnet 10.10.3.0 netmask 255.255.255.240 {
    range 10.10.3.2 10.10.3.14;
    option subnet-mask 255.255.255.240;
    option domain-name-servers 147.83.2.3;
    option domain-name "backus.upc.es";
    option routers 10.10.3.1;
    default-lease-time 3600;
    max-lease-time 28800;
  }

L'anterior configuració especifica que per la subxarxa 10.10.3.0/28 repartimrem adreces a partir de la 2 perquè la 1 ja és del router i mai la l'assignarem a cap altra màquina fins a la 14, ja que la 15 és de broadcast i la /28 no té més adreces (16 en total).

A part de la resta de paràmetres el temps d'arrendament és d'una hora per defecte i 8 hores com a màxim perquè a la xarxa clients del nostre escenari s'hi conectarien estacions fixes de d'una oficina petita, per tant no hi ha d'haver molt de moviment de dispositius.

Si es donés el cas que s'hi haguessin de conectar un altre tipus de dispositius com per exemple smartphones, tauletes, portàtils a diverses hores del dia amb més personal podriem definir un temps d'arrendament més petit (com per exemple el de defecte 10 min, màx 2h) perquè hi hagués una correcte rotació de les adreces entre dispositius que surten i els que entren a la xarxa.

Normalment al apagar un equip aquest envia un missatge al servidor per deixar l'adreça assignda, però si es fa de forma sobtada el servidor no sap que aquest dispositiu no està a la xarxa fins que no s'esgota el temps d'arrendament.

Finalment, per acabar amb la configuració de la xarxa clients, farem una reserva de l'equip de monitorització de la xarxa clients perquè volem que sempre tingui l'adreça .11. Es fa amb la següent declaració:
  host monitor {
    harware ethernet 08:00:27:10:03:11;
    fixed-address 10.10.3.11;
  }

Això evitarà que l'adreça .11 se li pugui assignar a un altre equip. Quan el monitor demani al servidor DHCP una adreça, aquest reconeixarà l'adreça MAC i li assignarà l'adreça 10.10.3.11 que s'ha reservat.

Per la part de la xarxa DMZ farem una configuració semblant, aquest és el bloc de subxarxa:
  subnet 10.10.2.0 netmask 255.255.255.240 {
    range 10.10.3 10.10.3.14;
    option subnet-mask 255.255.255.240;
    option domain-name-servers 147.83.2.3;
    option domain-name "backus.upc.es";
    option routers 10.10.2.1;
    default-lease-time 600;
    max-lease-time 7200;
  }

En aquest cas repartim adreces a partir de la .3 perquè les dues primeres són els dos routers (extern i intern respectivament) però el router per defecte és el 10.10.2.1. També assignem un temps més petit per millorar la seguretat (raons explicades al punt 6).

Com que a la xarxa DMZ no hi ha d'haver el mateix ús que la xarxa clients, en principi només l'administrador afegirà equips nous, cal fer la reserva d'adreces pels equips que hi ha a la xarxa. La sintaxis és exactament a l'anterior:
  host proxy {
    harware ethernet 08:00:27:10:02:07;
    fixed-address 10.10.2.07;
  }

Cal fer aquesta reserva per tots els equips que tenim a la xarxa DMZ: servidor DNS (dues adreces), servidor web, proxy web, monitor. Al fitxer adjunt de configuració hi figura la reserva de tots aquests equips.

Pel cas de la xarxa DMZ no cal un servidor DHCP d'entrada ja que les màquines d'aquesta xarxa ja disposen d'una adreça IP estàtica. Però si es dones el cas de que un equip per la configuració de xarxa, podria recuperar la seva adreça gràcies al servidor DHCP.

Abans de posar en marxa el servidor es pot provar la configuració contra errors de sintaxi amb la comanda següent:
  $ sudo dhcpd -t

Per exemple, amb un error de sintaxis la sortida seria la següent:
  Internet System Consortium DHCP Server 4.3.5
  Copyright 2004-2016 Internet Systems Consortium
  All rights reserved.
  For info, please visit https://www.isc.org/software/dhcp/
  /etc/dhcp/dhcpd.conf line 1: dedede exceed max (255) for precision.

  ^
  /etc/dhcp/dhcpd.conf line 2: semicolon expected.
  default-lease-time
   ^
  Configuration file errors encountered -- exiting

## 3. Arrencada del servidor DHCP

Per arrencar el servidor ho podem fer amb la següent comanda
  $ sudo service isc-dhcp-server start

Com la resta de serveis, sempre que es faci un canvi al fitxer de configuració cal reiniciar el servei, amb la mateixa comanda
  $ sudo service isc-dhcp-server restart

Si cal saber si el servidor està actiu o no, es pot fer amb la comanda:
  $ sudo service isc-dhcp-server status

Si hi ha un error tant el l'arxiu de configuració o si les adreces especificades a la configuració con coincideixen amb les de l'adaptaddor de xarxa el servidor no s'inciarà.

## 4. Comprovació del servei DHCP

Podem veure l'activitat del servidor DHCP al log del sistema, si no s'ha especficat una ubicació diferent de logs, amb la comanda següent:
  $ tail -f /var/log/syslog

Les adreces que s'han arrendat es troben a la base de dades del servidor DHCP a /var/lib/dhcpd/dhcpd.leases. En aquest arxiu es pot veure les adreces que ha deixat actualment el servidor, per exemple podem trobar el següent bloc que correspon a un client connectat a la xarxa client:
  lease 10.10.3.2 {
    starts 6 2018/05/05 16:17:16;
    ends 6 2018/05/05 16:27:16;
    cltt 6 2018/05/05 16:17:16;
    binding state active;
    next binding state free;
    rewind binding state free;
    hardware ethernet 08:00:27:37:e4:4b;
    client-hostname "seax";
  }

Hi apareix el temps (dia i hora) d'inici i fi de l'arrendament (starts i ends) i també el temps de l'última transacció amb el client. Hi figura l'adreça MAC i el tipus de hardware i el nom del host. I altres paràmetres del protocol failover quan hi han diversos servidors DHCP per redundància i hi ha un fallada.

Als fitxers adjunts es troba el syslog_server que és el log del sistema servidor, i podem veure com el servidor aten la petició d'un client:
  May  3 05:19:40 seax dhcpd[505]: DHCPRELEASE of 10.0.2.15 from 08:00:27:37:e4:4b via eth-clients (not found)
  May  3 05:19:53 seax dhcpd[505]: DHCPDISCOVER from 08:00:27:37:e4:4b via eth-clients
  May  3 05:19:54 seax dhcpd[505]: DHCPOFFER on 10.10.3.2 to 08:00:27:37:e4:4b (seax) via eth-clients
  May  3 05:19:54 seax dhcpd[505]: DHCPREQUEST for 10.10.3.2 (10.10.3.1) from 08:00:27:37:e4:4b (seax) via eth-clients
  May  3 05:19:54 seax dhcpd[505]: DHCPACK on 10.10.3.2 to 08:00:27:37:e4:4b (seax) via eth-clients

En el cas anterior un client fa una petició amb el missatge 'discover', el servidor respon amb l'adreça 10.10.3.2 al missatge 'offer', el client la demana al missatge 'request' i finalment el servidor acaba la configuració enviant el missatge 'ack'. Es pot veure el mateix pel cantó del client al log (fitxer syslog_client):
  May  3 05:19:52 seax dhclient[322]: DHCPDISCOVER on enp0s3 to 255.255.255.255 port 67 interval 5
  May  3 05:19:53 seax dhclient[322]: DHCPREQUEST of 10.10.3.2 on enp0s3 to 255.255.255.255 port 67
  May  3 05:19:53 seax dhclient[322]: DHCPOFFER of 10.10.3.2 from 10.10.3.1
  May  3 05:19:53 seax dhclient[322]: DHCPACK of 10.10.3.2 from 10.10.3.1

Fent una captura de xarxa també des de la banda del client podem veure en més detall què inclou cadascún dels missatges (fitxer captura_monitor):
  0.0.0.0	255.255.255.255	DHCP	342	DHCP Discover - Transaction ID 0x6d69766e
  10.10.3.1	10.10.3.11	DHCP	342	DHCP Offer    - Transaction ID 0x6d69766e
  0.0.0.0	255.255.255.255	DHCP	342	DHCP Request  - Transaction ID 0x6d69766e
  10.10.3.1	10.10.3.11	DHCP	342	DHCP ACK      - Transaction ID 0x6d69766e

Després de la configuració que hem fet anteriorment, podem veure que el paquet 'offer' del servidor inclou els paràmetres especificats:
  DHCP Server Identifier: 10.10.3.1
  IP Address Lease Time: (600s) 10 minutes
  Subnet Mask: 255.255.255.240
  Router: 10.10.3.1
  Domain Name: backus.upc.es
  Domain Name Server: 147.83.2.3

## 5. Client DHCP

Per fer servir el servidor DHCP com a client es pot fer a través del fitxer de configuració 'interfaces' o a través de la línia de comandes.

Per fer-ho a través del fitxer /etc/network/interfaces només cal especificar-ho a la configuració com fet a les pràctiques 2 i 3:
  allow-hotplug enp0s3
  iface enp0s3 inet dhcp

Amb la configuració anterior durant l'arrencada del sistema el client es connectarà directament a la xarxa i buscarà el servidor DHCP amb el paquet DHCP Discover per començar la negociació de l'adreça IP i obtenir la resta de paràmetres de xarxa.

En el cas de fer-ho per la línia de comandes, la comanda per obtenir una adreça IP és
  $ sudo dhclient

Si volem deixar l'arrendament actual ho podem fer amb la comanda següent per després fer una nova petició
  $ sudo dhclient -r

En el cas de tenir més d'una interfície, es pot especificar a la mateixa comanda
  $ sudo dhclient -r enp0s3
  $ sudo dhclient enp0s3

Es poden veure la resta d'opcions del client DHCP amb 'man dhclient' com per exemple deixar l'arrendament sense avisar al servidor (mata el procés, -x) o augmentar el nivell de verbose (-v).

El client de DHCP també té un arxiu de configuració a /etc/dhcp/dhclient.conf on es pot especificar per exemple el nom del host client, quina informació demana al servidor:
  request subnet-mask, broadcast-address, time-offset, routers,
    domain-name, domain-name-servers, domain-search, host-name,
    dhcp6.name-servers, dhcp6.domain-search, dhcp6.fqdn, dhcp6.sntp-servers,
    netbios-name-servers, netbios-scope, interface-mtu,
    rfc3442-classless-static-routes, ntp-servers;

Que d'altra banda és la informació que podem especificar al servidor dhcpd.conf. La resta de paràmetres es poden consultar a 'man dhclient.conf'.

El client tambe té una base de dades d'arrendaments anteriors i al iniciar el client (INIT-REBOOT) intentarà demanar la mateixa adreça.

## 6. Proposta millora seguretat DHCP

Per millorar la seguretat de la xarxa DMZ del nostre escenari es pot configurar el servidor DHCP amb la reserva de totes les màquines presents en aquesta (srevidor web, proxy, dns, etc.) i configurar el monitor perquè faci auditoria dels logs del servidor i la configuració.

És a dir, l'script hauria primer mirar els logs del servidor DHCP per buscar tots els missatges ACK: significa que s'ha fet una transacció DHCP i s'ha finalitzat correctament (algú ha rebut una adreça IP). D'aquí, com hem vist anteriorment, podriem extreure'n la IP assignada, l'adreça MAC, la interfície per la qual s'ha fet l'intercanvi i el nom del host a part de l'hora.

Aquesta informació s'hauria de contrastar amb les màquines que tenen una adreça reservada al fitxer de configuració del servidor. I per tant descartar i fer un filtre de les màquines diguem-ne conegudes de les que són desconegudes. Només per la interfície eth-dmz en aquest cas.

A partir d'aquí, amb les màquines desconegudes, el primer seria que l'administrador rebés una alerta i podriem prendre accions per tal de protegir els equips de la xarxa.

La proposta implementada és una versió simplificada de l'explicada. L'script vigila la base de dades d'arrendaments del servidor buscant canvis. Partint de que aquestes màquines tenen les adreces estàtiques i igualment una reserva, no haurien d'aparèixer en aquest fitxer. Si hi ha un canvi, s'envia una alerta. L'script es pot programar com una tasca cron perquè es vagi executant cada poc temps.

L'script es basa en la comanda següent:
  $ grep "^lease" /var/lib/dhcpd.leases | sort | grep "10.10.2" | uniq | wc -l

En les proves hem fet que un client anomenat 'rogue-client' amb configuració de xarxa per dhcp es connectés a la xarxa dmz. Aquest ha demanat una adreça al servidor DHCP i el nostre script ha enviat una alerta. Adjunt el missatge d'alerta "mail_alerta".
  From entel@seax.epsevg.upc.edu Sat May 05 14:46:22 2018
  Subject: Alerta!
  To: <entel@seax.epsevg.upc.edu>
  Message-Id: <E1fF2CM-0000UK-35@seax.epsevg.upc.edu>
  From: entel <entel@seax.epsevg.upc.edu>
  Date: Sat, 05 May 2018 14:46:22 -0400

  Tenim una anomalia a la xarxa DMZ, el servidor DHCP ha repartit una adresa a una maquina.

## 7. Configuració DDNS

Els paràmetres del DNS dinàmic es configuren a l'arxiu de configuració del servidor DHCP dhcpd.conf. Primer cal configurar els paràmetres generals
  option domain-name "seax.edu";
  ddns-updates on;
  ddns-update-style interim;
  ignore client-updates;
  update-static-leases on;

El paràmetre client-updates fa que els clients no puguin registrar el seu nom al servidor DNS, update-static-leases fa que pugui actualitzar les DNS de les màquines amb una adreça reservada.

Finalment cal incloure les zones que cal actualitzar, en l'exemple següent s'actualitza el domini "seax.edu" per mostrar el format però haurien de correspondre amb la configuració del nostre servidor DNS.
  include "/etc/dhcp/ddns.key";

  zone seax.edu. {
  primary 10.10.2.4;
  key DDNS_UPDATE;
  }

  zone classe.seax.edu. {
  primary 10.10.2.5;
  key DDNS_UPDATE;
  }

L'include inclou la clau per comunicar-se de forma segura amb el servidor de DNS. Els dos blocs contenen la zona la qual han d'actualitzar i l'adreça del servidor de DNS. Si el servidor DNS estigues a la mateixa màquina que el servidor DHCP, seria l'adreça local 127.0.0.1.

Al acabar aquesta configuració, com s'ha dit anteriorment, s'ha de reiniciar el servidor.
  $ sudo service isc-dhcp-server restart

Per comprovar la configuració, ho podem fer com en el cas anterior amb la comanda:
  $ sudo dhcpd -t

La sortida en el nostre cas, que encara no tenim el servidor DNS en configurat, és:
  Unable to create tsec structure for DDNS_UPDATE

## Referència

- https://wiki.debian.org/DHCP_Server
- https://linux.die.net/man/5/dhcpd-options
- https://linux.die.net/man/5/dhcpd.leases
- https://linux.die.net/man/5/dhclient.conf
