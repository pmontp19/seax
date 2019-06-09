# Pràctica 4 - Montpeó Pere

Fitxers involucrats
- p4_montpeo_pere.txt
- ssh_server_install.log: logs de la instal·lació servidor ssh
- debug_ssh.log: logs de la comanda ssh -v
- captura_tunel: captura tcpdump de redireccionament de ports remot SSH -R

## Continguts

1. Instal·lació client SSH
2. Instal·lació servidor SSH
3. Configuració client
4. Configuració servidor
5. Procediment: connexió amb contrasenya
6. Procediment: connexió amb certificat digital
7. Generar certificats
8. Distribució clau pública
9. Proves de validació
10. Túnels SSH

## 1. Instal·lació client

Per instal·lar el client de ssh a la màquina

```;
  sudo apt-get install openssh-client
```

## 2. Instal·lació servidor

Per instal·lar el servdor ssh a la màquina

```;
  sudo apt-get install openssh-server
```

## 3. Configuració client

El client obté la configuració en l’ordre següent:

1. Opcions de la línia de comandes a l’executar
2. Configuració de l'usuari (~/.ssh/config)
3. Configuració del sistema (etc/ssh/ssh_config)

Si encara no s'ha fet servir el client, la carpeta al Home de l'usuari no existirà, ni tampoc l'arxiu de configuració. En canvi, amb la instal·lació sí que es creen les claus públiques/privades que identifiquen el nostre host (ssh_host_[tipus de clau]), però no l'usuari.

Es pot configurar la informació d'un host remot recurrent, per no haver-la d’introduir cada cop per la línia de comandes a l'arxiu de configuració. Per exemple:

```;
Host servidor1
  HostName servidor1.epsevg.upc.edu
  User estudiant
  Port 2222
  IdentityFile /home/estudiant/keys/id_rsa
```

Amb la configuració anterior ja podríem fer la comanda "ssh servidor1" i ens agafaria els paràmetres que li hem especificat a l'arxiu de configuració.

Per configurar quin xifrat usar en les sessions com a client, s'han d'incloure a l'opció 'Ciphers' separats per comes, també es pot configurar la compressió si n'hi ha o no i quin nivell (Compression, CompressionLevel), o si s'han d'enviar missatges TCP per saber si l'altra host encara està en línia (TCPKeepAlive).

Per provar que està ben instal·lat ens podem connectar a un servidor que tingui ssh en funcionament, com per exemple el servidor ****:

```;
  ssh user@host.server
```

O amb el propi host en local (localhost).

La sintaxi anterior (l'@) indica quin és el nom d'usuari. També es pot indicar amb el paràmetre -u. Amb la configuració per defecte ja ens podem connectar a un servidor com ahto amb contrasenya.

Opcions de la comanda `ssh` com a clients

- -f s'executarà en segon pla
- -F especifica fitxer configuració
- -i indica quin fitxer d'identitat s'ha de fer servir, per defecte ~/.ssh/id_rsa
- -l nom de login
- -N per quan es fan tunels, indiquem que no voldrem introduir comandes remotes
- -p indicar el port de la connexió
- -R i -L ja s'han tractat més amunt
- -v mostra missatges debug
- -E anexar els logs de debug en un arxiu
- -o indicar opcions en el format de l'arxiu de configuració
- -X permet redireccionament X11

Més endavant veurem en detall la connexió com a clients.

## 4. Configuració servidor

El servidor és el daemon anomenat `sshd` al sistema. Com en el cas anterior, llegeix la configuració d'un fitxer a `/etc/ssh/` que s'anomena `sshd`. Els paràmetres de configuració:

- Port:  permet especificar el port que escolta el servidor, per defecte 22
- AddressFamily: si es fa servir només inet (IPv4), inet6 (IPv6) o qualsevol
- HostKey: especifica el fitxer que conté la clau privada
- PermitRootLogin: especifica si l'usuari root es pot logar al servidor, per defecte (prohibit-password) només es pot logar usant claus públiques
- MaxTries : nombre màxim de cops que podem intentar logar-nos
- MaxSessions: nombre màxims de sessions que accepta el servidor
- PubKeyAuthentication: si es permet mètode de clau pública
- AuthroizedKeysFile: quin és el fitxer que conté les claus autoritzades al servidor
- StrictModes: especifica si s'han de comprovar els permisos dels fitxers i carpetes de l'usuari abans d'acceptar el login

Consultar la resta de paràmetres a la documentació. La documentació de Debian fa les recomanacions següents per tal d'assegurar (entenent assegurar com a seguretat) el servidor

- PasswordAuthentication no: desactivar l'ús de password per logar-se a un servidor
- PermitRootLogin no: no permetre fer login com a root
- AllowUsers / AllowGroups: permetre login només a certs usuaris o grup d'usuaris

Existeix l'opció a la part del servidor de mantenir la connexió oberta allargant el temps de 'Alive' però cal tenir en consideració la seguretat, de per exemple, si el client deix desatès l'ordinador. Cal afegir al final de l'arxiu de configuració sshd_config el següent

```;
  # Mantenir la connexió SSH enviant cada 300 segons un petit paquet keep-alive al servidor per poder usar la connexió SSH. 300 segons equival a 5 minuts
  ClientAliveInterval 300
  # Desconnectar al client després de 3333 peticions "ClientAlive". El format és (ClientAliveInterval x ClientAliveCountMax). En aquest exemple (300 segons x 3333) = ~999,900 segons = ~16,665 minuts = ~277 hores = ~11 dies
  ClientAliveCountMax 3333
```

Si es canvien paràmetres, cal reiniciar el daemon de ssh amb la comanda `sudo /etc/init.d/ssh restart` o simplement `sudo service ssh restart`.

De la mateixa manera, cal controlar els permisos de la màquina abans d'obrir el sistema a connexions SSH. Normalment els permisos d'una carpeta d'un usuari al Home són `rwxr-xr-x`. Això  significa que altres usuaris podran veure el contingut però no escriure-hi. La carpeta .ssh dins de la carpeta de cada usuari encara està més restringida `rwx------` per evitar que un tercer pugui alterar les claus d'un usuari.

El servidor ssh detecta quan els permisos són diferents dels anteriors (group o others tenen +w) i bloqueja el login. Això es pot canviar amb l'opció StrictModes esmentada anteriorment.

Una empremta (fingerprint) és una versió reduïda d'una clau pública més llarga que permet identificar de forma correcta un host. El primer cop que ens connectem a un servidor, el client ens preguntarà si confiem en la identitat del servidor tot mostrant aquesta empremta. Aquest és el missatge

```;
  The authenticity of host '192.168.0.160 (192.168.0.160)' can't be established.
  ECDSA key fingerprint is SHA256:p9keM3Fl0DfpXF2aMPm3BiR6egGnfBppSHK/PtfP8tQ.
  Are you sure you want to continue connecting (yes/no)?
```

Aquesta clau pública que ens identifica la trobem a la ruta '/etc/ssh', de fet en diversos formats, començant amb el nom ssh_host_*.pub. És el que com a administradors d'un servidor hauríem de compartir (la pública) amb aquells que necessitin connectar-se al nostre sistema perquè puguin verificar-ne la identitat.

I quan volem connectar amb el mateix host, però aquest ha canviat la seva clau, aquest és el missatge

```;
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
  Someone could be eavesdropping on you right now (man-in-the-middle attack)!
  It is also possible that a host key has just been changed.
  The fingerprint for the ECDSA key sent by the remote host is
  SHA256:/cANWNjc3iJoYMdSVAT98tgU10yB5p2OUaYWTwx/qXE.
  Please contact your system administrator.
  Add correct host key in /home/entel/.ssh/known_hosts to get rid of this message.
  Offending ECDSA key in /home/entel/.ssh/known_hosts:8
    remove with:
    ssh-keygen -f "/home/entel/.ssh/known_hosts" -R 192.168.0.160
  ECDSA host key for 192.168.0.160 has changed and you have requested strict checking.
  Host key verification failed.
```

I no permet connectar amb aquest host a causa de la configuració estricte de la que hem parlat abans, a l'apartat de configuració. Per poder renovar les claus que identifiquen un host s'han d'introduir les següents comandes per esborrar les actuals i crear-ne de noves amb el procés d'instal·lació

```;
sudo rm /etc/ssh/ssh_host_*
sudo dpkg-reconfigure openssh-server
```

Per arreglar-ho en el cas que definitivament sí coneixem, és a dir, el host remot que ha canviat de empremta, podem eliminar l'entrada de l'arxiu "known_hosts" a la carpta de l'usuari .ssh/ o utilitzar la comanda que indicava el missatge anterior `ssh-keygen -f "/home/entel/.ssh/known_hosts" -R 192.168.0.160` tot canviant el nom o adreça del host.

En els adjunts es troba l'arxiu `ssh_server_install.log` que és la sortida de la comanda `sudo apt-get install openssh-server` i es pot veure com genera les claus de host mentre fa la instal·lació

```;
  Creating SSH2 RSA key; this may take some time ...
  2048 SHA256:stAmk2bq9KAdEsCarx4WOd6uhjx27uUxv6zlzjl1Lio root@seax-VirtualBox (RSA)
  Creating SSH2 DSA key; this may take some time ...
  1024 SHA256:8T7/4YoEtRgqd4X5fm0xsreXaPMSN0hMG4L2Mpkf3W4 root@seax-VirtualBox (DSA)
  Creating SSH2 ECDSA key; this may take some time ...
  256 SHA256:wQapDP2YX6QLABcsw0qpaWUPrUc69uPSbJ8JhyDeNuA root@seax-VirtualBox (ECDSA)
  Creating SSH2 ED25519 key; this may take some time ...
  256 SHA256:YzrXgJsaFJt8KfUg6XcPeG7XCqVrOWgbC7HQcGpUBrM root@seax-VirtualBox (ED25519)
```

Per veure persones logades al nostre sistema, amb la comanda `who`, la sortida és la següent

```;
  usuari  terminal  data  ip

```

O també la comanda `w`

```,
  USER  TTY FROM  LOGIN@  IDLE  WHAT

```

## 5. Procediment: connexió amb contrasenya

Volem fer login de una MV seax a una altra igual. En aquest cas la primera té l’IP 192.168.0.159 i l'altra 192.168.0.160 en mode adaptador pont; les dues màquines es de veuen. El login el fem amb usuari i contrasenya. La primera màquina. la .159, és el nostre client que es connecta al servidor que és el .160 i ja té el servidor SSH en marxa.

En el client executem la comanda de connexió

```;
ssh entel@192.168.0.160
```

Seguidament el servidor demanarà quina és la contrasenya, en aquest cas de l'usuari entel al servidor. Després d’introduir la contrasenya, ja estarem logats com a usuari entel al sistema remot.

## 6. Procediment: connexió amb certificat digital

En el cas de SSH apliquem la teòrica de clau asimètrica generant el parell de claus (pública i privada) com a clients. La clau privada ens la quedem al nostre host com a clients i serà la clau pública la que distribuirem al host/s remot/s.

Amb aquest mètode bàsicament s'envia una signatura creada amb la clau privada del client. El servidor comprova amb la clau pública de l'usuari que és qui diu ser i la signatura és vàlida, i permet l'accés.

## 7. Generar certificats

Per crear una identitat digital el programa ssh-keygen pot generar la parella de claus que necessitem. Té a més altres funcions que permeten fer conversions o gestionar les claus.

Per generar una clau privada/pública hem de seguir els passos següents:

1. `ssh-keygen`
2. Ubicació de la clau, en principi directori per defecte ($HOME/.ssh/id_rsa)
3. passphrase és com una contrasenya però amb qualsevol caràcters i de longitud 10-30 i s'utilitza per encriptar la part privada de la clau. Si la clau és per un host la passphrase es pot deixar buida
4. Altra cop passphrase, encara que sigui buida
5. Les claus es generen a la localització indicada (nom_clau.pub, nom_clau) i es mostra per pantalla un randomart de la clau com el següent

```;
  2048 SHA256:Sivm0GEAaWe5sVl25ZkWznH/A0lia8VcRLac0K5+fn8 entel@seax (RSA)
  +---[RSA 2048]----+
  |..  .   .+ +o+== |
  |.o = o .+ B *o=.o|
  |. + B .  B o +.+ |
  |   =    . .   o. |
  |    o . S     .o |
  |   o o o     .  .|
  |  . + o     .    |
  |   + .       . .E|
  |    .         o.=|
  +----[SHA256]-----+
```

Si indiquem una passphrase en el moment de la creació, cada cop que fem logins haurem d’introduit-la per desencriptar la clau. Si un tercer aconseguís la clau privada, podria fer login al host configurat amb aquesta clau (tret de si té passphrase).

Si es creu que la clau pot haver estat compromesa, s'ha de desactivar dels hosts remots (eliminar-la de l'arxiu authorized_keys) i substituir-la per una clau nova. Al moment de generar les claus, es poden indicar moltes opcions diferents, entre les quals tenim, per exemple, definir un interval de validesa de la clau amb -V, el tipus de clau a crear -t, o mostrar l'empremta d'una clau.

## 8. Distribució clau pública

Amb la instal·lació del client ssh també s'ha instal·lat l’eina ssh-copy-id que ens ajudarà a fer la copia al fitxer de authorized_keys d'una màquina remota i poder-la distribuir. La sintaxis és
  
```;
ssh-copy-id -i [fitxer_id] [usuari@]maquina
```

També es pot especificar el port amb -p, -f per mode forçat on no es mira si existeix la clau privada, o -n per no fer canvis i simplement mostrar la clau que s'hauria instal·lat. Per exemple, si volem instal·lar la nostra clau al servidor

```;
ssh-copy-id -i ~/.ssh/id_rsa.pub servidor.edu
```

Seguint amb l'exemple d'abans, copiarem la clau pública del nostre client al servidor d'ssh. Abans però, permetrem l'opció de poder fer login al servidor com a root amb contrasenya, canviant la contrasenya de root per una més forta. La opció és la que necessitem canviar a sshd_config l'opció 'PermitRootLogin yes'

```;
ssh-copy-id -i ~/.ssh/id_rsa.pub root@192.168.0.160

```

Després d’introduir la contrasenya del host remot, ens indicarà que ja s'han copiat les claus. Aquest és el missatge

```;
entel@seax:~$ ssh-copy-id -i ~/.ssh/id_rsa.pub root@192.168.0.160
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/entel/.ssh/id_rsa.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
root@192.168.0.160's password:
Number of key(s) added: 1
Now try logging into the machine, with:   "ssh 'root@192.168.0.160'"
and check to make sure that only the key(s) you wanted were added.
```

Ja tenim la clau pública copiada a l'arxiu de known_hosts de l'usuari root al host remot i podem tornar a establir la configuració del servidor ssh per defecte comentada més amunt, perquè no es pugui fer login amb contrasenya només amb clau (PermitRootLogin without-password). És important recordar que després de canviar l’opció cal reiniciar el servei.

Ara al fer `ssh root@192.168.0.160` es fa el procés d'identificació i estarem logats automàticament. Si intentem fer login com a root des d'un host del qual no haguem intercanviat les claus, obtindrem el missatge de 'Access denied'.

També es pot introduir la clau directament, si estem connectats al servidor remot a l'arxiu d'authorized_keys de l'usuari, o passar-la com un arxiu, per exemple, en un pendrive o similar.

## 9. Proves de validació

Per comprovar que ssh està corrent al port 22 es pot fer un `telnet` al port 22 del servidor i comprovar que el servei està escoltant. En el cas del que hem instal·lat al nostre sistema obtindrem

```;
SSH-2.0-OpenSSH_7.4p1 Debian-10+deb9u2
```

Per analitzar la connexió SSH i els passos que es fan durant la negociació ho farem amb el paquet TCPDUMP, que es troba al repositori de Debian i s'instal·la amb 'sudo apt-get install tcpdump'. Aquesta és la seqüencia d'intercanvi de paquets:

```;
  No  ORIGEN    DESTÍ     PROTOCOL  INFO
  1   client    servidor  SSHv2     Client: Protocol (SSH-2.0-OpenSSH_7.4p1 Debian-10+deb9u2)
  2   servidor  client    SSHv2     Server: Protocol (SSH-2.0-OpenSSH_7.4p1 Debian-10+deb9u2)
  3   servidor  client    SSHv2     Server: Key Exchange Init
  4   client    servidor  SSHv2     Client: Key Exchange Init
  5   client    servidor  SSHv2     Client: Diffie-Hellman Key Exchange Init
  6   servidor  client    SSHv2     Server: Diffie-Hellman Key Exchange Reply, New Keys, Encrypted packet (len=140)
  7   client    servidor  SSHv2     Client: New Keys
```

La comanda per capturar els paquets anteriors és

```;
sudo tcpdump -n -w captura  -i enp0s3 tcp port 22 and host 192.168.0.159
```

Opcions: -n perquè no converteixi les adreces a noms, -w per escriure la sortida a un fitxer, -i per indicar la interfície, i al final la condició boleana que indica que volem els paquets tcp del port 22 i que tinguin com a origen el host de la ip en qüestió.

Durant la negociació, primer els hosts es diuen quin software del protocol SSH i quina versió fan servir (paquets 1 i 2). Seguidament es negocia l'algorisme que es farà servir per l'intercanvi (paquets 3 i 4). Després es fa l'intercanvi amb l'algorisme acordat (paquets 5 i 6). Finalment, el client envia un reconeixement de l'intercanvi (paquet 7). A partir d'aquí la resta de paquets també estan xifrats.

En el detall dels paquets 3 i 4, inici de l'intercanvi, és on s'especificen els paràmetres de la connexió com, per exemple, quins algorismes d'encriptació s'utilitzaran, l'adreça mac, compressió i en quin ordre de prioritat.

En aquest cas concret s'han posat d'acord en usar l'algorisme curve25519-sha256 que és pel mètode d'intercanvi de claus Diffie-Hellman (RFC4419).

L’arxiu adjunt debug_ssh.log adjunt estan els missatges de debug que resulten d’executar la comanda amb l’opció -v. Es pot veure tot el procés: com busca l'arxiu de configuració, llegeix les opcions, busca els certificats al directori per defecte, identifica la versió del protocol tant local com el remot, l'intercanvi de claus (kexinit i kex equival a paquets 3-4 i 5-6 respectivament). Al tancar la sessió també podem veure el resultat d'intercanvi (duració, enviat i rebut)

## 10. Túnels SSH

Hi ha dos tipus de túnels SSH: local i remot. El local estableix una connexió SSH amb un servidor intermediari i es posa a escoltar per un port local. Per les connexions establertes en aquest port, s'iniciarà una connexió ssh del servidor intermediari al servidor final. Per exemple

```;
  ssh -L 9000:server:25 intermediary

```

La comanda estableix una sessió SSH amb el servidor intermediary al nostre port 9000. A través d'aquesta connexió ens connectarem al port 25 del server. Per posar-ho en pràctica ens volem connectar a un servidor web a través d'una altra màquina de la nostra xarxa local que té accés a aquest

```;
  ssh -L 9001:peremontpeo.cat:80 pi@192.168.0.150
```

```;
+----------+<--port 22-->+----------+<--port 80-->+----------+
|  Client  |=====SSH=====| intermed |-------------|  server  |
+----------+             +----------+             +----------+
localhost:9001           192.168.0.150      www.peremontpeo.cat:80
```

Per comprovar el resultat del túnel podem, atès que és un servidor web, obtenir la pàgina amb wget
  `wget localhost:9001`

Aquest és el resultat que obtenim, podem obtenir satisfactòriament el recurs del servidor web al port 80 redirigit al 9001 a través d'una tercera màquina, 192.168.0.150

```;
entel@seax:~$ wget localhost:9001
--2018-03-11 08:07:19--  http://localhost:9001/
Resolving localhost (localhost)... ::1, 127.0.0.1
Connecting to localhost (localhost)|::1|:9001... connected.
HTTP request sent, awaiting response... 200 OK
Length: unspecified [text/html]
Saving to: ‘index.html’

index.html              [ <=>                ]      65  --.-KB/s    in 0s

2018-03-11 08:07:19 (6.92 MB/s) - ‘index.html’ saved [65]
```

En aquest cas, si mirem l'intercanvi de paquets des de la màquina intermediària, l'esquema d'intercanvi és exactament el mateix que l'anterior: protocol, negociació d'algorisme, intercanvi Diffie-Hellman, reconeixement.

L'altra tipus de túnels SSH són els remots (-R). També estableixen una sessió SSH amb l'intermediari, però és aquesta màquina la que escolta al port que li indiquem, no el host local. La connexió que fem en aquest port de l’intermediari obrirà una connexió del host local al port indicat del servidor. Per exemple

```;
ssh -R 8000:server:25 intermediary
```

Estableix una sessió SSH amb el servidor intermediari, però és el port 8000 de l'intermediari que escoltarà les connexions. Amb això obrirem una connexió del host local al port 25 del servidor server.

Per fer la prova disposarem tres equips. El primer és el nostre host client seax, 192.168.0.161. Aquest té accés a un altre host que té un servidor MySQL a 192.168.0.164 al port 3306. Un tercer equip (192.168.0.150) es vol connectar a la base de dades però no té accés directe al segon host (.164). Establirem un túnel de la màquina seax al tercer equip, que redirigirà el port d'aquest del 9002 al 3306 del servidor MySQL. Comanda al primer host, seax .161

```;
ssh -R 9002:192.168.0.164:3306 pi@192.168.0.150
```

```;
  +----------+<--port 22-->+----------+<--port 3306-->+----------+
  | intermed |=====SSH=====|  client  |--------------| SQLserver |
  +----------+             +----------+              +-----------+
  192.168.0.150:9002         localhost         192.168.0.164:3306
```

-R redireccionament remot de ports, 9002 és el port de la màquina que abans li hem dit intermediària, en aquest cas és la .150, i aquest port rediccionarà a la màquina amb el servidor 192.168.0.164:3306. Això significa que quan la màquina intermediària .150 faci la connexió mysql al port 9002, connectarà amb la màquina .164 a través de la seax .161. Aquest només haurà d'executar aquesta comanda per connectar-se

```;
  mysql -h 127.0.0.1 -P 9002 -u test

  Welcome to the MariaDB monitor.  Commands end with ; or \g.
  Your MySQL connection id is 53
  Server version: 5.6.35 MySQL Community Server (GPL)
```captura_tunel

Per poder provar la connexió MySQL s'ha instal·lat en una de les màquines un servidor mysql (paquet mariadb-server) i s'ha posat en marxa amb un usuari 'test' sense contrasenya. El port del servidor s'ha deixat per defecte 3306. I s'ha instal·lat en una altra màquina el client de mysql (paquet `mysql-client`).

També s'ha fet una captura de TCPDUMP a la màquina intermediària, adjunta a l'arxiu comprimit (`captura_tunel`).

## Referències
https://man.openbsd.org/ssh_config
https://www.openssh.com/manual.html
https://linux.die.net/man/1/ssh-copy-id
https://www.ietf.org/rfc/rfc4251.txt
https://www.ietf.org/rfc/rfc4419.txt
https://www.debian.org/doc/manuals/debian-handbook/sect.remote-login.en.html#sect.ssh
