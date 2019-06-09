# Pràctica 1 - Montpeó Pere

Fitxers involucrats:

- p1_montpeo_pere.txt

## Descripció

Obtenir VirtualBox versió 5.2 directament de la seva web www.virtualbox.org, on també es troba la documentació i software complementari.
VirtualBox permet crear màquines virtuals amb diferents paràmetres i també virtualitzar xarxes.

Oracle també posa a disposició extension pack que afegeix més funcionalitats a VirtualBox. És un arxiu .vbox-extpack i és important que sigui la mateixa versió que el propi VirtualBox.

D'entrada, al crear una màquina nova, permet configurar diferents paràmetres i amb característiques. A part del nom haurem d'indicar el hardware que virtualitzarem. En aquest cas la configuració serà mínima: 1 core, 512MB de RAM, 4GB de disc i 1 interfície ethernet.

La RAM és un paràmetre que es pot editar més endavant amb la màquina parada, però el disc és un disc virtual que creem en aquest moment. Pot ser d'una mida dinàmica o fixe. VirtualBox permet però ampliar la capacitat del disc de mida fixe més endavant. En aquest cas serà fixe de 4GB i del tipus VirtualBox Disk Image (VDI).

Existeixen l'anterior VDI, un contenidor propi de VirtualBox, el contenidor VMDK (Virtual Machine Disk) que també és un contenidor obert i que també el fan servir altres softwares de virtualització com VMware. També suporta discos virtuals del tipus HDD (Parallels), QCOW (QEMU Copy-On-Write) i QED (QEMU enchanced disk).

Aquesta acció ens crea un fitxer (per defecte a la carpeta VirtualBox VMs) amb un fitxer amb el mateix nom de la màquina i extensió vdi, una mica més gran de la mida indicada.

Després de crear el disc dur es finalitza la creació de la màquina i ja queda preparada per començar a córrer. 

VirtualBox permet virtualitzar una infraestructura de xarxa (Virtual Distributed Ethernet, VDE) com per exemple routers i switchs i té sis tipus diferents de hardware per virtualitzar. A més del hardware a emular també s'ha d'escollir el mode de xarxa, són principalment 5.

- Not attached: hi ha targeta a la màquina però no connectada
- Network Address Translation (NAT): simplement permet sortir a internet a través de la connexió de la màquina host. No requereix configuració i ve seleccionat per defecte, però no permet interactuar entre màquines o amb el host
- Bridged networking: és el més avançat perquè és la targeta virtualitzada la que intercanvia els paquets directament, sí permet interactuar no només amb internet i la porta d'enllaç, sinó amb el host i la resta de màquines virtuals. Es posa al mateix nivell que el host
- Internal networking: disenyat per interactuar amb diferents màquines virtuals dintre del host pero no amb el host o el món exterior
- Host-only networking: semblant a l'anterior però no inclou el maquinari de xarxa del host sinó que es crea una interficie virtual per connectar MV i també el host

Des dels paràmetres de la màquina, en la part de xarxa avançat també es pot configurar el port forwarding per redireccionar alguns ports concrets per aplicacions i establir manualment l'adreça MAC de la MV.

La resta de hardware també es pot configurar als paràmetres de la màquina. La majoria només canviaran quan la MV està parada. Podrem ajustar per exemple quina interficie de xarxa utilitza, quin discs, àudio i pantalla, o els paràmetres que hem configurat inicialment.

Els snapshots són com una fotografia d'un moment concret. Ens permet guardar l'estat de la màquina virtual per poder-hi tornar més endavant. Es pot revertir a aquest estat en qualsevol moment. N'hi pot haver varies a diferència de l'estat guardat (per exemple quan volem tancar la màquina de cop en marxa). Quants més snapshots més espai ocuparà la MV al nostre host.

Tenim l'opció de clonar la MV per poder probar varies configuracions o tenir un backup. Es pot marcar l'opció de reinicialitzar l'adreça MAC de la MV si la resultant ha de treballar al mateix host. També hi ha la opció de fer un clon total (MV independents) o un clon enllaçat que quedarà com el nom indica al disk/s virtuals de la màquina original. El clon es poden incloure o no els snapshots i/o l'estat guardat.

De forma alternativa existeix la opció d'exportar la MV en format OVF (Open Virtualization Format), preparat per altres productes de virtualització. Concreament té dues variants, la que normalment s'utilitza és l'extensió .ova que empaqueta tots els arxius de la MV (l'estructura és d'un arxiu TAR).

De la mateixa manera que es pot exportar també podem importar una MV format OVF/OVA. Aquesta s'importarà amb les mateixes configuracions que quan va ser exportada, tot i que poden ser variats.

És important entendre que per canviar la màquina de host cal exportar la MV, no fer un clon. 

Existeix un altre front-end diferent de la interficie gràfica de VirtualBox com és VBoxManage, que és la CLI i permet automatizar tasques i un control més al detall.

Per gestionar les xarxes virtuals existeix un menú a part dins de Global Tools anomenat Host Network Manager que emula una xarxa i se'n poden crear varies amb diferents paràmetres com l'adreça de la xarxa o la màscara, així com activar o desactivar el servidor DHCP de la xarxa.

Per fer servir aquesta xarxa virtual hauriem de configurar la MV host-only adapter i ja ens apareixerien les xarxes virtuals per seleccionar-ne una.

En aquest mateix apartat de Global Tools també tenim el Virtual Media Manager, que porta un seguiment de totes les imatges de discos durs, discs i disquets virtuals que fan ús les MV. Permet fer-ne còpies, canviar-ne la ubicació, desmuntar-lo, així com canviar-ne alguns atributs o mostrar en el cas dels hdd UUID d'aquest.

VirtualBox ja porta la imatge de les Guest Additions llesta per inserir a la MV i instal·lar. Abans però s'ha de preparar el sistema per poder compilar mòduls externs del kernel. Segons la documentació aquests són normalment, a part del compilador GCC i el make, les capçaleres del nostre kernel (linux-headers).

Una de les accions que ens permeten fer les Guest Additions és Shared Folders. Podem connectar com si d'una unitat de xarxa es tractés una carpeta del host a la màquina virtual i muntar-la com qualsevol altra mitjà. Es poden configurar els paràmetres perquè per exemple es monti automàticament o sigui només de lectura.

Necessitarem també ssh per poder accedir a la màquina de forma remota, per tant s'haurà d'instal·lar els paquets openssh-client i openssh-server per poder accedir a altres màquines o per poder-hi accedir en aquesta respectivament. En el cas de la nostra MV ja està instal·lat.

## Accions a fer

Instalar el paquet auto executable VirtualBox 5.2 descarregat de la pàgina.
L'extension pack també es descarrega de la mateixa pàgina.
Al obrir l'arxiu extension pack directament s'obre a VirtualBox i només cal acceptar la llicència.

Crear una nova màquina, amb el nom seax.epsevg.upc.edu, 512MB de RAM, creant un disc dur virtual de tipus VDI de mida fixe 4 GB.
Per instal·lar Debian cal carregar la imatge iso que hem descarregat com a disc a la MV i seguir els pasos que van apareixent per pantalla (regió, teclat, particions, nom de l'equip, usuari, etc)
Després d'una reiniciada tenim la màquina llesta per funcionar

Per instal·larar Guest Additions, clica Devices > Insert Guest Additions CD imagex, comanda `mount /dev/cdrom /media/cdrom` per muntar el disc, canviar de directori `cd /media/cdroom`
`apt-get update` per actualitzar la llista de paquets
`apt-get dist-upgrade` per actualitzar el sistema
`apt-get install build-essential` per compilar paquets
Comanda `uname -r` obtenim el nom de la versió del kernel, i el posem a la comanda per instal·lar les dependències `apt-get install linux-headers-$(uname -r) dkms`
`apt-get install module-assitant` per compilar hardware no soportat pel kernel
Instal·lar el paquet per linux `./VBoxLinuxAdditions.run` i reiniciar la màquina `init 6`
Es pot comprovar que està instal·lat mirant si s'ha carregat el mòdul vboxguest amb la comanda `lsmod`

## John the Ripper

Per instal·lar John the Ripper `apt-get install john`

John the Ripper és una eina que permet "petar" contrasenyes. Està dissenyat per detectar contrasenyes dèbils. La comanda per utilitzar-lo és john.

Per verificar per exemple les contrasenyes del nostre sistema únicament li hauriem de passar com a paràmetre el nostre fitxer de contrasenyes john /etc/shadow i mostrarà si ha trobat contrasenyes dèbils, quina, i de quin usuari. En el nostre cas les que hem especificat per root i entel són lògicament dèbils.

Es poden especifiar també arxius anomenats diccionaris que contenen llistats de noms d'usuari o contrasenyes. Hi han dos mètodes. El primer és generar parelles de nom d'usuaris i contrasenyes o la segona és proveïr el llistat (diccionari).

Per especificar un llistat al John la opció és `--wordlist=nom_arxiu`. 

- Referències
https://www.debian.org/distrib/
https://www.virtualbox.org/wiki/Downloads
https://www.virtualbox.org/manual/
http://www.openwall.com/john/doc/