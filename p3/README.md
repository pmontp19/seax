# Pràcitca 3 - Montpeó Ossó Pere

Fitxers involucrats:

- p3_montpeo_pere.txt
- informa_wifi.sh script
- info_wifi.txt d'exemple
- /etc/network/interfaces

## Descripció
VirtualBox com està explicat a la p1 permet gestionar diferents dispositius connectats a la màquina host. En aquest cas la configuració de la màquina virtual (MV) permet afegir dispositius connectats al host per USB (en l'apartat USB).

En el cas de la targeta wifi cal veure quin chipset porta. La que tinc és ALFA Network AWUS036NH i necessita el driver rt2800usb (chipset RT2800).

dpkg -s wireless-tools per comprovar que tenim les eines per manipular les Linux Wireless Extension. En principi ve instal·lat per defecte amb Debian.

## Accions a fer
Instal·lar el driver rt2800usb per l'adaptador USB sense fils d'Alfa Network. Afegir el següent repositori a la llista de fonts del gestor de paquets /etc/apt/sources.list
  deb http://http.debian.net/debian/ stretch main contrib non-free

Actualitzar la llista de paquets amb apt-get update i instal·lar els paquets
   apt-get install firmware-misc-nonfree

Instal·lar el paquet wpasupplicant que dóna suport a WEP, WPA i WPA2 i negocia l'autenticació.
  apt-get install wpasupplicant

Amb aquestes eines ja tenim el driver instal·lat i preparat per auto carregar-se al kernel quan el sistema detecti l'aparell. Ara connectem l'USB. Veurem que amb lsmod es carrega el mòdul del kernel automàticament per aquest dispositiu i el reconeix com a targeta de xarxa.

Amb la comanda `ip` a veurem que tenim una nova interficie de xarxa en estat DOWN i que és wireless (nom comença per wl). Cal reiniciar la màquina.

Per començar a escanejar per xarxes properes
  ip link set [interface] up
  iwlist scan [interficie]

Aquesta última comanda, és important no oblidar fer-la com a superusuari (com la majoria de les que treballem), llistarà les xarxes properes.

Per llistar més visualment les xarxes properes
  iwlist scan | grep ESSID
si ens guiem pel nom de la xarxa, però es pot filtrar qualsevol paràmetre.

Separem el mètode de connexió depenent si és amb seguretat o no, i més endavant com fer la connexió permanent. Per manejar directament la interficie sense configurar el fitxer d'interficies es pot fer mitjançant la comanda `iwconfig` que ja ve amb el paquet `wireless-tools`.

### Xarxa oberta

  `iwconfig [interface] [essid X]`
Per exemple:
  `iwconfig wlan0 essid wifi_de_casa`

Ara estem connectats però encara no tenim adreça IP. Perquè el servidor DHCP ens en doni una hem de ejecutar el client de DHCP.
  `dhclient`

Només amb aquesta comanda si tot va bé rebrem l'adreça IP i tindrem accés a la xarxa.

### Xarxa amb WEP

Si la xarxa té seguretat WEP, es pot connectar com si fos una xarxa oberta però passant la contrasenya com un paràmetre de la comanda
  `iwconfig [interface] [essid X] [key K]`
Per exemple,
  `iwconfig wlan0 essid wifi_de_casa key contrasenya123`

Perquè el servidor DHCP ens en doni una hem de ejecutar el client de DHCP.
  `dhclient`

Es pot comprovar que estem connectats amb la comanda `iwconfig`. Ha d'apareixer l'ESSID de la xarxa a la qual estem connectats.

### Xarxa amb WPA o WPA2

Per connectar-se a una xarxa amb autenticació WPA o WPA2 s'utilitza el paquet wpasupplicant instal·lat.

Generar el hash de la contrassenya, per no guardar en pla la clau de la xarxa. EL que obtenim s'anomena PSK (Pre-Shared Key). I la sortida la guardarem en un arxiu perquè la farem servir.
  `wpa_passphrase [ssid] [passphrase] > arxiu.conf`

Per exemple:
  `wpa_passphrase wifi_de_casa contrassenya123 > /etc/wpa_supplicant/wpa_supplicant.conf`

La sortida té aquest format

```;
  network={
    ssid="wifi_de_casa"
    #psk="contrasesnya123"
    psk=8b88be48454fea60b688eb81d092a09b033352f84328ee8a8b3b0db597004e7
  }
```

Amb la següent comanda ens connectarem a la xarxa que haguem especificat abans
  `wpa_supplicant -B -i [interface] -c [arxiu_configuracio]`
Per exemple
  `wpa_passphrase -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf`

La opció `-B `significa que correrà en background. Pot ser interessant per fer debug no marcar la opció per veure els missatges de sortida de la comanda si no aconseguim connectar. Si alguna cosa sortis malament podem matar els procesos suplicants amb `killall wpa_supplicant`.

Després amb iwconfig podem veure que estem connectats a la xarxa que voliem i la resta de paràmetres de la connexió. Només queda obtenir una adreça IP
  `dhclient [interface]`

Si per alguna raó necessitem renovar la cessió de DHCP podem fer aquesta comanda per deslliurar-nos de la cessió d'IP actual
  `dhclient [interface] -r`

Per raons de seguretat seria interessant canviar l'ownership del fitxer `wpa_supplicant.conf` a root:root i fer `chmod 600` perquè només root pugui veur en clar el password de les xarxes.

### Connexió automàtica al fer login

Podem editar el fitxer `/etc/network/interfaces` per tal d'afegir la configuració i que automàticament aixequi la interficie i provi de connectar-se a la xarxa. De la mateixa forma que amb una connexió cablejada, tenim la opció de fer-la estàtica o dinàmica mitjançant dhcp vist a la p2.

L'arxiu interfaces quedaria per exemple així en dinàmic per l'apartat de la nostra targeta WiFi en cas de seguretat WPA/2

```;
  auto <interface>
  iface <interface> inet dhcp
    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
```

Canviar la ubicació de l'arxiu de configuració allà on l'haguem guardat.

Si la xarxa és sense seguretat només caldria indicar el nom de la xarxa, per exemple

```;
  auto wlan0
  iface wlan inet dhcp
    wireless-essid wifi_de_casa
```

### Comprovacions

Amb les comandes de la pràctica anterior podem comprovar la connectivitat, per exemple amb ip a podem veure si l'interfície de xarxa està aixecada i tenim una IP assignada.

Després amb un `ping` o un `dig` podem comprovar que tenim connectivitat a Internet.

### Gestor de xarxes

També existeix la opció de instal·lar un aplicació gestor de xares, que maneja automàticament el procés per exemple d'autenticació amb `wpa_supplicant` de forma transparent o llista de forma "humana" les xarxes disponibles en les diferents interficies.

Un exemple és el Network Manager, que s'instala amb `apt` i el paquet es diu `network-manager`. L'utilitat `nmcli` permet a través de la línia de comandes configurar tot l'anterior.

## Referències
https://wiki.debian.org/rt2800usb
https://wiki.debian.org/WiFi
https://wiki.archlinux.org/index.php/WPA_supplicant
https://linux.die.net/man/8/iwconfig
