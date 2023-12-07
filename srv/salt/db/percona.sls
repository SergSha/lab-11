---
{% set mysql_root_user = salt['pillar.get']('mysql_root_user') %}
{% set mysql_root_password = salt['pillar.get']('mysql_root_password') %}
{% set wp_db_name = salt['pillar.get']('wp_db_name') %}
{% set wp_db_user = salt['pillar.get']('wp_db_user') %}
{% set wp_db_pass = salt['pillar.get']('wp_db_pass') %}

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

install_packages:
  pkgs.installee:
    pkgs:
      - percona-server-server
      - python3-PyMySQL

mysql:
  service.running:
    - watch:
        - file: 
          - /etc/my.cnf.d/my.cnf
          - /root/.my.cnf
        - pkg:
          - mysql
    - enable: true

/etc/my.cnf.d/my.cnf:
  file.managed:
    - source: salt://db/files/percona/my.cnf.jinja
    - template: jinja

/root/.my.cnf:
  file.managed:
    - source: salt://db/files/percona/root-my.cnf.jinja
    - template: jinja

#get_temp_root_pass:
#  cmd.run:
#    - name: grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}' | tail -n 1 > /tmp/temp_root_pass

{% set temp_root_pass = salt['cmd.run']('grep \'temporary password\' /var/log/mysqld.log | awk \'{print $NF}\' | tail -n 1') %}
/root/.my.cnf:
  file.line:
    - name: /root/.my.cnf
    - mode: replace
    - match: password=.*
    - content: password={{ temp_root_pass }}

set_root_pass:
  cmd.run:
    - name: mysql --connect-expired-password -e "ALTER USER '{{ mysql_root_user }}'@'localhost' IDENTIFIED WITH mysql_native_password BY '{{ mysql_root_password }}';"

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

mysql_database:
  mysql_database.present:
    - name: {{ wp_db_name }}

mysql_user:
  mysql_user.present:
    - name: {{ wp_db_user }}
    - host: '10.10.0.0/255.255.0.0'
    - password: {{ wp_db_pass }}
    #- connection_host: {{ mysql_host }}
    - connection_user: {{ mysql_root_user }}
    - connection_pass: {{ mysql_root_password }}
    - connection_charset: utf8




#- name: DB | Create Database for Wordpress
#  community.mysql.mysql_db:
#    name: "{{ wp_db_name }}"
#    login_user: "{{ mysql_root_user }}"
#    login_password: "{{ mysql_root_password }}"
#    #login_unix_socket: /run/mysqld/mysqld.sock
#
#- name: DB | Create database user using hashed password with all database privileges
#  community.mysql.mysql_user:
#    name: "{{ wp_db_user }}"
#    host: "10.10.0.0/255.255.0.0"
#    password: "{{ wp_db_pass }}"
#    priv: "{{ wp_db_name }}.*:ALL"
#    state: present
#    login_user: "{{ mysql_root_user }}"
#    login_password: "{{ mysql_root_password }}"
#    #login_unix_socket: /run/mysqld/mysqld.sock


