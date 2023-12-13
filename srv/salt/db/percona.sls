---
{% set mysql_root_user = pillar['mysql_root_user'] %}
{% set mysql_root_password = pillar['mysql_root_password'] %}
{% set wp_db_name = pillar['wp_db_name'] %}
{% set wp_db_user = pillar['wp_db_user'] %}
{% set wp_db_pass = pillar['wp_db_pass'] %}

percona-key:
  cmd.run:
    - name: rpm --import https://www.percona.com/downloads/RPM-GPG-KEY-percona

percona-release:
  pkg.installed:
    - sources:
      - percona-release: https://repo.percona.com/yum/percona-release-latest.noarch.rpm

setup_ps80:
  cmd.run:
    - name: echo 'y' | percona-release setup ps80
    - require:
      - pkg: percona-release

#install_packages:
#  pkg.installed:
#    pkgs:
#      - percona-server-server
#      - python3-PyMySQL

percona-server-server:
  pkg.installed

python3-PyMySQL:
  pkg.installed

mysql:
  service.running:
    - watch:
      - file: '/etc/my.cnf.d/my.cnf'
    - enable: true
    - require:
      - pkg: percona-server-server

/etc/my.cnf.d/my.cnf:
  file.managed:
    - source: salt://db/files/percona/my.cnf.jinja
    - template: jinja

{% set temp_root_pass = salt['cmd.shell']('grep \'temporary password\' /var/log/mysqld.log | awk \'{print $NF}\' | tail -n 1') %}

create_my_cnf:
  file.append:
    - name: /root/.my.cnf
    - template: jinja
    - text: |
        [client]
        user={{ mysql_root_user }}
        password={{ temp_root_pass }}
    - require:
      - service: mysql

#set_root_pass:
#  cmd.run:
#    - name: mysql --connect-expired-password -e "ALTER USER '{{ mysql_root_user.stdout }}'@'localhost' IDENTIFIED WITH mysql_native_password BY '{{ mysql_root_password }}';"

change_root_pass:
  mysql_user.present:
    - name: {{ mysql_root_user }}
    - host: '10.10.0.0/255.255.0.0'
    - password: {{ mysql_root_password }}
    - connection_host: localhost
    - connection_user: {{ mysql_root_user }}
    - connection_pass: {{ temp_root_pass }}

/root/.my.cnf:
  file.line:
    - name: /root/.my.cnf
    - mode: replace
    - match: password=.*
    - content: password={{ mysql_root_password }}

create_fnv1a_64_fnv_64_murmur_hash:
  cmd.run:
    - names:
      - /usr/bin/mysql -e "CREATE FUNCTION fnv1a_64 RETURNS INTEGER SONAME 'libfnv1a_udf.so'"
      - /usr/bin/mysql -e "CREATE FUNCTION fnv_64 RETURNS INTEGER SONAME 'libfnv_udf.so'"
      - /usr/bin/mysql -e "CREATE FUNCTION murmur_hash RETURNS INTEGER SONAME 'libmurmur_udf.so'"

create_mysql_database:
  mysql_database.present:
    - name: {{ wp_db_name }}
    - connection_user: {{ mysql_root_user }}
    - connection_pass: {{ mysql_root_password }}
    - require:
      - service: mysql


create_mysql_user:
  mysql_user.present:
    - name: {{ wp_db_user }}
    - host: '10.10.0.0/255.255.0.0'
    - password: {{ wp_db_pass }}
    - connection_host: '%'
    - connection_user: {{ mysql_root_user }}
    - connection_pass: {{ mysql_root_password }}
    - connection_charset: utf8
...


