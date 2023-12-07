mysql_port: 3306
wp_db_name: wordpress
wp_db_user: wordpress
wp_db_pass: wordpresspassword

{% set addrs = salt['mine.get']('db-01', 'network.ip_addrs', tgt_type='glob').values() %}
wp_db_host: {{ addrs[0] }}
