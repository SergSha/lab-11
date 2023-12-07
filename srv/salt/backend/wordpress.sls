---
/etc/php.ini:
  file.line:
    - name: /etc/php.ini
    - mode: ensure
    - after: ;cgi.fix_pathinfo.*
    - content: cgi.fix_pathinfo=0

download_wordpress:
  file.managed:
    - name: /tmp/wordpress.tar.gz
    - source: https://wordpress.org/latest.tar.gz

extract_wordpress:
  archive.extracted:
    - name: /var/www/wordpress
    - source: /tmp/wordpress.tar.gz
    - user: nginx
    - group: nginx

configure_wordpress:
  file.managed:
    - name: /var/www/wordpress/wp-config.php
    - source: salt://backend/files/wordpress/wp-config.php.jinja
    - template: jinja
    - user: nginx
    - group: nginx
