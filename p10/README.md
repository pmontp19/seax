# Pràctica 10 - Montpeó Pere

Arxius involucrats

```;
  /etc
    /network/interfaces
    /apache2
      apache2.conf
      /conf-available
        ssl-params.conf
      /sites-available
        default-ssl.conf
  /var/www/html
    .htaccess

  wp-config.php
  get http i https.pcapng
  mysql_secure_installation.log
```

## Continguts

1. Escenari
2. Instal·lar paquets
3. Configuració Apache
4. Configuració MySQL
5. Instal·lació Wordpress
6. Personalització Wordpress
7. Seguretat Wordpress
8. Opcional: certificat SSL

## 1. Escenari

Si ens situem en l'escenari de la pràctica 6 ara muntem la peça 10.10.2.6 que correspon al servidor web. Gràcies a les taules ip del router extern qui accedís a la IP pública pel port 80 (amb un navegador) es redigiria a aquest servidor web, de la mateixa manera el servidor queda assegurat a la xarxa DMZ.

Per fer que la màquina virtual no depengui de la resta de l'escenari per funcionar l'hem configurat amb dues interficies:

- Adaptador 1 només amfitrió: amb ip estàtica 192.168.56.6 per tal de poder accedir des del mateix host
- Adaptador 2 NAT per poder fer la instal·lació dels paquets des d'internet

Per tant per poder fer funcionar el servidor web cal primer crear un adaptador de xarxa virtual a VirtualBox amb la xarxa 192.168.56.1/24 per poder-hi connectar l'adaptador 1 de la màquina.

I després perquè la web funcioni correctament s'ha de modificar el fitxer 'hosts' de l'ordinador host perquè redirigeixi el domini a la IP fixe corresponent. El nostre domini és seax.org per tant cal afegir:
  192.168.56.6		seax.org

## 2. Instal·lar paquets

Per poder fer córrer un lloc Wordpress ens cal un servidor web, en aquest cas Apache, un gestor de bases de dades, MySQL, i finalment l'intèrpret de PHP.

Per instal·lar el servidor web juntament amb la documentació:

```
# apt-get install apache2 apache2-doc
```

Per instal·lar el gestor de base de dades:

```
# apt-get install mysql-server mysql-client
```

Per instal·lar l'intèrpret de PHP i el mòdul per apache:
```
# apt-get install php libapache2-mod-php7.0
```

A més a més ens faltarà el mòdul MySQL per PHP:

```
# apt-get install php7.0-mysql
```

## 3. Configuració Apache

Cal canviar la següent directiva de l'arxiu de configuració /etc/apache2/apache.conf

```;
<Directory /var/www/>
  AllowOverride All
</Directory>
```

I activar el mòdul en qüestió:

```
# a2enmod rewrite
```

Cal donar els permisos necessaris a l'usuari d'Apache al directori web perquè hi pugui escriure:
  chown -R www-data:www-data /var/www/
  chmod -R 766 /var/www/

Cal tenir en compte que si fos un hosting compartit amb d'altres llocs s'haurien de canviar els permisos per cada un dels llocs perquè l'usuari d'un lloc web no pugués accedir al de l'altre.

## 4. Configuració MySQL

MySQL ja ve configurat per defecte però per tal de millorar la seguretat podem executar el següent programa

```;
# mysql_secure_installation
```

El programa ens guiarà per definir un password per l'usuari root, no permetre fer login a usuaris anònims, desactivar el login remot i eliminar la base de dades de test.

També ens caldrà un usuari especific per la base de dades, per tal de que Wordpress hi pugui fer-hi canvis. Cal entrar al client de mysql:

```;
# mysql
> CREATE DATABASE wordpress;
> GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost' IDENTIFIED BY 'seaxdbpassword';
> FLUSH PRIVILEGES;
> EXIT
```

## 5. Instal·lació Wordpress

Abans cal descarregar Wordpress de la pàgina web oficial i descomprimir:
  $ wget https://wordpress.org/latest.tar.gz
  $ tar -xzvf latest.tar.gz

Editar el fitxer wp-config.php que conté les variables de configuració. Cal especificar els detalls de connexió amb la base de dades i les claus secrets per generar-les. Està entre els fitxers adjunts.

Cal copiar tots els fitxer al directori web arrel on apunta apache:
```
# cp -a wordpress/. /var/www/html/
```

Ara podem entrar des del nostre host, amb qualsevol navegador, a seax.org/wp-admin/install.php per començar la configuració. Simplement cal anar seguint els passos que pregunten el nom del lloc, el nom de l'usuari administrador.

## 6. Personalització Wordpress

Hem canviat el tema per defecte un que s'anomena Hestia, en l'apartat d'aparença.

Per poder tenir un fòrum de debat s'ha instal·lat el plugin bbPress, que permet crear diversos fòrums i establir diferents permisos.

Per poder fer l'agenda s'ha instal·lat el plugin The Events Calendar, que incorpora un gestor d'esdeveniments.

Perquè els usuaris es pugui gestionar el seu perfil també s'ha instal·lat BuddyPress, que afegeix les caraterístiques d'una comunitat.

Pel repositori de docuements s'ha instal·lat Download Manager que és un gestor de documents. Permet agrupar-los, protegir-los i fer un seguiment de les baixades.

Finalment, per tal de poder contactar, s'ha instal·lat el plugin de Pirate Forms.

## 7. Seguretat Wordpress

S'han instal·lat els plugins Wordfence Security i Security Ninja que fan auditories de seguretat a la instal·lació.

Per exemple l'auditoria de Security Ninja avisa de perills com:

- Plugins i temes desactivvats però encara instal·lats
- La versió de MySQL i els permisos de l'usuari
- El prefix de les taules de la bbdd
- Revisa els permisos del fitxer wp-config.php que conté informació sensible (440)

Les contrasenyes han estat generades aleatòriament.

Per tal de securitzar l'àrea restringida, només per a usuaris, s'ha inserit aquest troç de codi a l'arxiu functions.php del tema activat:

```;
  add_action( 'template_redirect', function() {
    if ( is_user_logged_in() ) return;
    $restricted = array( 64, 0 );
    if ( in_array( get_queried_object_id(), $restricted ) ) {
      wp_redirect( site_url( '/wp-login.php' ) );
    exit();
    }
  });
```

El que fa és descartar que l'usuari estigui logat, i revisar si la pàgina a la que es vol accedir és o la 0 o la 64. En aquest cas les 0 són el fòrum i l'agenda i el 64 el repositori.

Per validar-ho hem accedit amb una finestra de navegació oculta (sense usuari logat) i podem comprovar com ens redirigeix cada cop a la pàgina de login o registre si no es té usuari. Si ens loguem amb un usuari, com el creat com exemple joan12, podrem veure el contingut privat.

La gestió d'usuaris (accés, recordatori de contrassenya) es fa amb la solució nativa de Wordpress i el registre amb BuddyPress perquè està activada l'opció de perfil estès.

## 8. Opcional: certificat SSL

Crearem un certificat SSL propi per tal de poder navegar amb el trànsit encriptat. Com que serà un certificat autosignat el navegador el detectarà com a no vàlid però la comunicació entre el servidor i el navegador serà encriptada. Una autoritat hauria de donar-nos un certificat per un lloc web que tinguem a internet amb domini associat (com per exemple letsecrypt.org).

Primer creem el certificat amb OpenSSL:

```
# openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt
```

Amb req -x509 diem que volem un certificat autosignat amb aquest estàndard. Serà vàlid per un any i serà de 2048 bits. Ens preguntarà detalls del nostre lloc web i de l'organització.

Ara generem un certificat de Diffie-Hellman usat en la negociació:
```
# openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
```
Insertarem el fitxer ssl-parms.conf (adjunt) a /etc/apache2/conf-available/ perquè el sevidor Apache agafi la configuració.

Ara modificarem l'arxiu SSL del host virutal:
```
# nano /etc/apache2/sites-available/default-ssl.conf
```
I afegirem el domini del servidor i la ruta on es troben els certificats que hem creat abans.

Per activar els canvis al servidor cal activar els següents mòduls:

```
# a2enmod ssl
# a2enmod headers
# a2enconf ssl-params
```

Podem testejar la configuració:
```
# apache2ctl configtest
```
Si tot és correcte reiniciar el servidor:
```
# service apache2 restart
```

Ara ja es pot provar d'anar a l'adreça https://seax.org i veurem el missatge de que el navegador detecta que l'autoritat de certificació és invàlida. Tot i això podem Avançar i procedir al lloc web.

En la captura de xarxa adjunta podem veure que si accedim per HTTP tota la conexió és per HTTP sobre TCP pel port 80 i es pot veure tot el detall del trànsit i les respostes. En canvi quan canviem a HTTPS canviem a TLS (sockets segurs) i port 443 sense poder veure quin és el contingut.


## Referència
- https://codex.wordpress.org/Installing_WordPress
- https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-apache-in-ubuntu-16-04
