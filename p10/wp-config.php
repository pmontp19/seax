<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the
 * installation. You don't have to use the web site, you can
 * copy this file to "wp-config.php" and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * MySQL settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://codex.wordpress.org/Editing_wp-config.php
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', 'wordpress');

/** MySQL database username */
define('DB_USER', 'wordpress');

/** MySQL database password */
define('DB_PASSWORD', 'seaxdbpassword');

/** MySQL hostname */
define('DB_HOST', 'localhost');

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8');

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
 define('AUTH_KEY',         '@[}:rKfPGD@ 843v{lw=AsoyEyZVKN|j5|F/f_-g/^uHH_B>|O/yK-xbJ4Mo$:xI');
 define('SECURE_AUTH_KEY',  'ACEW,HngMmz=w1u&inGD6tl@m|Z9o$;+J(^F^$P1ILceWzpXozK<-+TOTRwx@M89');
 define('LOGGED_IN_KEY',    'Cfi8<|i3n04H0!agfKJA<}qv(JBzCZZ8iKXcn-+iZb+iv[O{8LL_)kA@{&7|_tP;');
 define('NONCE_KEY',        '}|4-#el*bFy-Z@9)nvY`Eyn^;&,L.V?@pnMLDBX|pp+.e+=|pRr{/*|jecFaY:y5');
 define('AUTH_SALT',        'n4{drL-31>+&c|[@OvTt<7HZ+diY.5`JOX&%`x<l=h?cJC[Tt=ZvP+eH89R[k2wO');
 define('SECURE_AUTH_SALT', 'd)X3tXx!/ym3~{A~.S]uZh>}7F7l+jm04<Zc%zJT( 8Z-Sk9u/Uc0i9{2b(0J{sa');
 define('LOGGED_IN_SALT',   'A?;;nL$Qqr6C7VXF^2(+vv2y78G~Owf+Gc<|.&R.$3-t|ATK|~7(U=Q(>eM`voZV');
 define('NONCE_SALT',       '0<CvTKo rn!+YhmDu@qAV~b5e}4|[[&LEesr?EfT5A;p)^A9rvDNb5>g1`iesa!=');
/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix  = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the Codex.
 *
 * @link https://codex.wordpress.org/Debugging_in_WordPress
 */
define('WP_DEBUG', false);

/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');
