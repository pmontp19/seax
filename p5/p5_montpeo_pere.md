# Pràctica 5 - Montpeó Pere

Fitxers involucrats

- p5_montpeo_pere.txt
- captura_nfs.pcap -> captura de xarxa connexió nfs
- captura_nfs10M.pcap -> captura de xarxa còpia fitxer 10MB sobre nfs
- captura_sftp.pcap -> captura connexió sftp
- captura_sftp_1M.pcap -> captura còpia fitxer 1MB
- captura_smb_10M_mac.pcap -> captura còpia fitxer 10MB amb OS X com a client
- captura_smb_10M.pcap -> captura còpia fitxer 10MB sobre Samba
- exports -> fitxer configuració servidor NFS
- fstab -> muntatge dels 3 sistemes al client
- smb.conf -> fitxer configuració servidor Samba
- smb-credentials -> credencials client per connectar-se al servidor Samba

## Continguts

1. Servidor SFTP
2. Client SFTP
3. Connexió SFTP
4. Gàbia SFTP
5. Muntar recursos SFTP
6. Servidor NFS
7. Client NFS
8. Servidor SMB
9. Client SMB

## 1. Servidor SFTP

Introduir la comanda següent per tal de comprovar si el servidor SFTP està instal·lat:

```;
dpkg -l openssh-sftp-server
```

Si ho està, ens ha de tornar el paquet i la versió del servidor mitjançant la comanda següent:

```;
openssh-sftp-server 1:7.4p1-10+d
```

Si no ho està, no torna cap resposta. Al repositori de Debian es troba el paquet per poder-lo instal·lar amb la comanda següent:

```;
sudo apt-get install openssh-sftp-server
```

Si hem instal·lat anteriorment les eines de OpenSSH, concretament el paquet openssh-server, SFTP estarà ja al sistema.

Les opcions de configuració s'especifiquen a l'arxiu de configuració de sshd_config. Els arguments d'execució també s'especifiquen dins de l'arxiu de configuració. Primer, per tal de configurar l'execució del daemon de SFTP cal comprovar sshd_config:

```;
Subsystem sftp  /usr/lib/openssh/sftp-server
```

Subsystem: configura subsistemes externs, com per exemple l'SFTP, i els arguments s'especifiquen sobre la mateixa línia. 'sftp-server' implementa la transferència de fitxers i alternativament 'internal-sftp' implementa el servidor com a procés. Els dos daemons són diferents. En aquest cas, utilitzarem el segon que dóna facilitats per l'engabiament de l'usuari:

```;
Subsystem sftp  internal-sftp
```

Les opcions del servidor sftp es poden afegir a la línia anterior:

- -d start_directory: especifica un directori de partida diferent pels usuaris i permet inserir tokens com %d pel directori home de l'usuari que s'està autenticant, %u nom d'usuari. Si no especifiquem el directori de partida amb l’opció anterior, per defecte es mostra el home de l'usuari.
- -e: informació de logs per stderr en lloc de syslog
- -f log_facility: codi per fer log de diferents missatges
- -h: ajuda sftp-server
- -l log_level: quins missatges aniran al log
- -P blacklisted_requests: llista (separat per comes) de peticions a SFTP que han de ser bloquejades pel servidor i respondrà al client amb una fallada.
- -p whitelisted_request: llista (separat per comes) de peticions a SFTP que són permeses pel servidor.
- -R: la instància de sftp-server entra en mode només de lectura. Operacions d'escriptura o canvi del sistema de fitxers serà denegada.

Per exemple si afegim -d al final de la línia, amb l'argument /root totes les sessions que facin login en aquest servidor començaran la sessió en el directori especificat:

```;
sftp>pwd
Remote working directory: /root
```

Per compartir una carpeta sftp_dir de l'usuari entel, primer crearem la carpeta dins del seu home:

```;
  cd
  mkdir sftp_dir
```

Amb la configuració actual l'usuari entel que es logui en aquest sistema ja té accés a tot l'arbre del sistema de fitxers, per tant no caldria definir permisos perquè aquest usuari ja hi té accés. Per restringir l'accés, passem a l'apartat 4, en què fem la gàbia per a un usuari concret.

Per aplicar els canvis al servidor s'ha de reiniciar 'sudo service ssh restart'.

## 2. Client SFTP

El client SFTP és el que permet connectar-se a un servidor de fitxers SFTP sobre ssh encriptat. També usa característiques de ssh, com l'autenticació de clau publica, la compressió i altres paràmetres de ssh_config.

Com en el cas anterior, si el paquet openssh-client està instal·lat (dpkg -l openssh-client), ja tenim el client de sftp. La sintaxi de sftp és molt semblant a la del client ssh:
  sftp destination

Destination es pot especificar `[user@]host[:path]` i també en forma de URI `sftp://[user@]host[:port][/path]`.

A part de les opcions (algunes compartides amb el propi SSH) hi ha totes les comandes interactives pròpies de quan s'estableix la connexió sftp. Algunes són pròpies de Linux, com ara cd, `chmod`, `chown` i `pwd`, però algunes tenen una `l` precedida de local. Aquestes últimes, mentre estem a la connexió remota, permeten, per exemple, canviar el directori local amb `lcd`, mostrar el contingut del directori local amb `lls`, crear un directori amb `lmkdir` o veure la ruta amb `lpwd`.

## 3. Connexió SFTP

Provem de fer una connexió a una màquina servidor sftp amb adreça 10.0.2.100 i executar diverses comandes al servidor:

```;
entel@seax:~$ sftp 10.0.2.100
entel@10.0.2.100's password:
Connected to 10.0.2.100.
sftp> pwd
Remote working directory: /home/entel
sftp> ls
connexio_sftp   mbox            test.txt
sftp>
```

Volem, per exemple, agafar del servidor el fitxer test.txt i desar-lo al sistema client. Una manera de fer-ho és amb la comanda `get`:

```;
sftp> ls
connexio_sftp   mbox            test.txt
sftp> get test.txt
Fetching /home/entel/test.txt to test.txt
sftp> lls
captura  test.txt
sftp>
```

Una altra forma és directament sense obrir la sessió interactiva, indicant a la comanda de connexió l'arxiu que volem recuperar:

```;
entel@seax:~$ sftp 10.0.2.100:test.txt
entel@10.0.2.100's password:
Connected to 10.0.2.100.
Fetching /home/entel/test.txt to test.txt
entel@seax:~$
```

## 4. Gàbia SFTP

Engabiariem un usuari especial (mateix procediment per a un group), de manera que només li permetrem connectar-se per SFTP dins d'un directori concret, en aquest cas sftp_dir. Primer creem l'usuari:

```;
sudo useradd sftpuser -d /home/entel/sftp_dir -s /bin/false
```

I li assignem una contrasenya amb la comanda `passwd sftpuser` (*user).

La ruta del directori home de l'usuari és la carpeta que volem compartir i indiquem que no tingui shell interactiva per impedir l'accés SSH. A continuació, afegim el següent bloc al final de l'arxiu de configuració SSH:

```;
Match User sftpuser
  AllowTcpForwarding no
  ChrootDirectory %h
  ForceCommand internal-sftp
```

Desactivem la redirecció de ports, el directori on fem el chroot és el seu home i forcem el daemon internal-sftp.

En aquest tipus de bloc condicional a sshd_config podem especificar diferents criteris que sobrescriuran les opcions de les línies més amunt, la secció global. Si hi ha diversos blocs que compleixen la condició, només s'aplica el primer bloc.

Els criteris són All, User, Group, Host, LocalAddress, LocalPort, RDomain, i Address.

Segons la documentació ChrootDirectory, per seguretat, necessita que els components de l'arbre de fitxers del directori que hem definit home (/sftp_dir) siguin propietat de root. Sempre ho comprova quan s'estableix la sessió SSH i és independent de la opció StrictMode.

Qualsevol problema en el procés de negociació al establir la connexió es pot debuguejar buscant per /var/log/auth.log. Per exemple, si els permisos no són els correctes, veurem el missatge següent:

```;
Mar 17 17:36:40 seax_server sshd[1813]: fatal: bad ownership or modes for chroot directory component "/home/entel/"
```

Com que en aquest cas hem posat la carpeta sftp_dir dins de /home/entel/ i els components de la ruta home que hem definit a sshd_config, hem de canviar la propietat de entel:

```;
sudo chown root:root /home/entel
```

En les captures de xarxa de la connexió, al ser xifrada, no es pot inspeccionar l'intercanvi d'arxius, però segueix el mateix intercanvi de claus que la connexió SSH vista a la pràctica 4.

Gràcies al bloc condicional Match indicat anteriorment, si intentem fer login amb una sessió SSH rebem aquest missatge:

```;
  entel@seax:~$ ssh sftpuser@10.0.2.100
  sftpuser@10.0.2.100's password:
  This service allows sftp connections only.
  Connection to 10.0.2.100 closed.
```

## 5. Muntar recursos SFTP

Per poder muntar recursos compartits per SFTP des de la part del servidor no s'ha de fer cap acció, però si en la del client. El client necessita instal·lar SSHFS que permet muntar un sistema de fitxers remot:

```;
sudo apt-get install sshfs
mkdir sftp_dir
```

I de pas creem la carpeta que serà el punt de muntatge. No tenim perquè nombrar-la de la mateixa manera. Per muntar el recurs al client:

```;
entel@seax:~$ sshfs sftpuser@10.0.2.100: sftp_dir/
sftpuser@10.0.2.100's password:
entel@seax:~$ ls sftp_dir/
dummy.dat  test2.txt
```

Amb la comanda `less /proc/mounts` o `mount` podem veure els sistemes muntats actualment, i al final trobarem el que acabem de muntar

```;
fusectl /sys/fs/fuse/connections fusectl rw,relatime 0 0
sftpuser@10.0.2.100: /home/entel/sftp_dir fuse.sshfs rw,nosuid,nodev,relatime,user_id=1000,group_id=1000 0 0
```

El recurs es pot desmuntar amb la comanda següent:

```;  
fusermount -u /home/entel/sftp_dir
```

Per muntar el recurs automàticament cada cop que posem en marxa el sistema, s'ha d’utilitzar el sistema d'autenticació de clau pública/privada en comptes de contrasenya. Per tant, s'ha de fer l'intercanvi de claus descrit a la pràctica 4.

## 6. Servidor NFS

NFS és part del kernel de Debian, però si s'ha d'iniciar automàticament al fer boot, s'ha d'instal·lar el paquet següent ja que porta scripts d'inici:

```;
sudo apt-get install nfs-kernel-server
```

L'arxiu /etc/exports és la llista de control on hi ha els directoris que es volen posar a disposició de la xarxa. La sintaxi és

```;
/directori/a/compartir  maquina1(opcio1,opcio2...) maquina2(...)...
```

Durant la instal·lació haurem vist que apareix un error i no es pot iniciar el servidor. Això és perquè d'entrada no hi ha directoris a la llista export. Després d'afegir entrades podem iniciar el servidor amb la comanda següent:

```;
sudo service nfs-kernel-server start
```

Si volem compartir una carpeta que es diu nfs_dir, afegirem la entrada següent al final del fitxer:

```;  
/home/entel/nfs_dir 10.0.2.7(rw,sync,fsid=0)
```

Es podria compartir amb una xarxa de la mateixa manera, tot indicant l'adreça de la xarxa seguit de la màscara en format CIDR.

I, després la comanda, sudo `exportsfs -a` per actualitzar la taula de directoris compartits que manté el servidor NFS.

## 7. Client NFS

Tal com s'ha comentat anteriorment, NFS forma part del kernel de Debian. Només instal·larem nfs-common que porta eines tant pel client com servidor per gestionar la connexió NFS. Un cop instal·lat (sudo apt-get install nfs-common), ja podem muntar el directori compartit a la xarxa local:

```;
sudo mount -t nfs4 10.0.2.100:/home/entel/nfs_dir /mnt/nfs_dir
```

Tipus de sistema de fitxers nfs4, ens connectem a la màquina remota a la ruta indicada i el punt de muntatge és un directori de la màquina client.

Per comprovar quins directoris exporta el servidor podem utilitzar la comanda següent per veure la llista amb la següent sortida:

```;
sudo showmount -e 10.0.2.100
Export list for 10.0.2.100:
/home/entel/nfs_dir 10.0.2.7
```

Ens apareix correctament la llista de directoris i el detall que indica amb quines màquines l'hem compartit.

Si volem fer el muntatge permanent per a cada cop que fem boot a la màquina, hem d'afegir una entrada al fitxer /etc/fstab:

```;
10.0.2.100:/home/entel/nfs_dir /mnt/nfs_dir nfs4 rw,nosuid 0 0
```

Després de reiniciar podem comprovar que la unitat remota està muntada amb la comanda: `mount | grep nfs`

```;
10.0.2.100:/home/entel/nfs_dir on /mnt/nfs_dir type nfs (rw,nosuid,realtime,vers=3,rsize=65536,wsize=65536,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sex=sys,mountaddr=10.0.2.100,mountvers=3,mountport=41741,mountproto=udp,local_lock=none,addr=10.0.2.100)
```

A l'arxiu 'captura_nfs_10M', hi ha els paquets capturats durant la còpia d'un fitxer de 10M d'una unitat del servidor muntada al client, copiant a un directori local. Es poden veure els diversos procediments de NFS: GETATTR, ACCESS, READ, etc.

## 8. Servidor SMB

Per instal·lar el servidor Samba s'ha de instal·lar el paquet següent:

```;
sudo apt-get install samba
```

La configuració del servidor es troba a /etc/samba/smb.conf. Té tres seccions especials: global, homes i printers. A la secció global podem trobar el nom del workgroup que canviarem per 'SEAXGROUP'.

A l'apartat de Share Definitions trobem l'especificació de com es comparteixen els directoris home dels usuaris. Per defecte són només de lectura, però canviant l'opció read only a no farem que siguin de read-write.

En el cas de Samba, també s'han de crear els usuaris com a usuaris del sistema (és a dir, han d'existir a /etc/passwd), però Samba té el seu propi sistema de contrasenyes. Primer afegim un usuari del sistema i després l'afegirem a Samba:

```;
sudo adduser samba1
sudo smbpasswd -a samba1
```

Opció -a d'afegir i ens demanarà una contrasenya per Samba.

```;
New SMB password:
Retypenew SMB password:
Added user samba1.
```

Amb la comanda `sudo pdbedit -w -L`, podem llistar els usuaris actuals de Samba com si es tractés del fitxer /etc/passwd.

Després d'haver fet els canvis al servidor, hem de reiniciar perquè llegeixi el fitxer de configuració:

```;
sudo /etc/init.d/samba restart
```

## 9. Client SMB

Per instal·lar el client de Samba cal introduir la comanda següent:

```;
sudo apt-get install samba-client
```

Si es vol comprovar el llistat de comparticions d'un servidor es pot fer amb la comanda `smbclient -L [server]`

```;
  entel@seax:~$ smbclient -L 10.0.2.100
  WARNING: The "syslog" option is deprecated
  Enter entel's password:
  Domain=[SEAXGROUP] OS=[Windows 6.1] Server=[Samba 4.5.12-Debian]

        Sharename       Type      Comment
        ---------       ----      -------
        print$          Disk      Printer Drivers
        IPC$            IPC       IPC Service (Samba 4.5.12-Debian)
  Domain=[SEAXGROUP] OS=[Windows 6.1] Server=[Samba 4.5.12-Debian]

        Server               Comment
        ---------            -------
        SEAX_SERVER          Samba 4.5.12-Debian

        Workgroup            Master
        ---------            -------
        NEPTUNE              ESL-DYF2ZF2
        SEAXGROUP            SEAX_SERVER
```

Amb el servidor preparat, ja es pot començar la connexió, ja que el client d'entrada no necessita configuració. Es pot accedir com un mateix usuari o com un altre usuari per accedir a les respectives home o a altres fitxers compartits. En el següent exemple accedim com a l'usuari que hem creat abans al sistema:

```;
  entel@seax:~$ smbclient -U samba1 //10.0.2.100/samba1
  WARNING: The "syslog" option is deprecated
  Enter samba1's password:
  Domain=[SEAXGROUP] OS=[Windows 6.1] Server=[Samba 4.5.12-Debian]
  smb: \> ls
    .                                   D        0  Sat Mar 17 08:44:15 2018
    ..                                  D        0  Sat Mar 17 08:26:42 2018
    .bashrc                             H     3526  Sat Mar 17 08:26:42 2018
    .bash_logout                        H      220  Sat Mar 17 08:26:42 2018
    .profile                            H      675  Sat Mar 17 08:26:42 2018
    dummy_10M.dat                       N 10485760  Sat Mar 17 08:39:20 2018

                  3545824 blocks of size 1024. 1810456 blocks available
  smb: \>
```

A l'arxiu 'captura_smb_10M_mac.pcapng', es pot veure l'intercanvi de paquets amb protocol SMB i SMB2, capturat des d'un host OS X actuant com a client i copiant un arxiu de 10MB. Es pot observar la negociació la versió del protocol, el request per l'arxiu dummy_10M.dat i la transferència.

## 10. Muntar recursos SMB

Per poder muntar recursos Samba a la part del client necessitem instal·lar el paquet cifs-utils perquè ens deixi muntar aquest tipus d'unitats:

```;
sudo apt-get install cifs-utils
```

Amb el paquet instal·lat ja podem muntar el recurs. Abans, però, crearem un fitxer amb permisos 600 a /etc amb el nom smb-credentials on hi emmagatzamarem les credencials de Samba perquè no estiguin com a text pla, més endavant, al fitxer fstab. A dins del fitxer hi posarem el següent sense espais:

```;
username=samba1
password=1abmas
```

Ara ja es pot muntar amb la següent comanda:

```;
  sudo mount -t cifs //10.0.2.100/samba1 /mnt/smb_dir -o credentials=/etc/smb-credentials
  entel@seax:~$ ls /mnt/smb_dir/
  dummy_10M.dat
```

Podem comprovar com podem llegir el contingut de la carpeta remota. Per muntar el recurs a cada boot del sistema, podem afegir la següent línia al fitxer fstab com en el cas anterior:

```;
//10.0.2.100/samba1 /mnt/smb_dir cifs credentials=/etc/smb-credentials,uid=0 0 0
```

Podem comprovar com després de reiniciar el sistema client amb la comanda `mount` el sistema de fitxers SMB està muntat correctament al punt on s'ha especificat:

```;
//10.0.2.100/samba1 on /mnt/smb_dir type cifs (rw,relatime,vers=1.0,cache=strict,username=samba1,domain=SEAX_SERVER,uid=0,forceuid,gid=0,noforcegid,addr=10.0.2.100,unix,posixpaths,serverino,mapposix,acl,rsize=1048576,wsize=65536,echo_interval=60,actimeo=1)
```

## Referències

https://debian-handbook.info/browse/stable/sect.remote-login.html#sect.ssh
https://debian-handbook.info/browse/es-ES/stable/sect.nfs-file-server.html
https://help.ubuntu.com/community/NFSv4Howto
https://debian-handbook.info/browse/stable/sect.nfs-file-server.html
https://debian-handbook.info/browse/stable/sect.windows-file-server-with-samba.html
https://wiki.debian.org/SambaServerSimple
