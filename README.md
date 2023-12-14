# lab-11
otus | saltstack

### Домашнее задание
Управление конфигурацией на несколько серверов

#### Цель:
настроить управление конфигурацией проекта ( предыдущее ДЗ) через salt

#### Описание/Пошаговая инструкция выполнения домашнего задания:
добавить в проект salt server;
добавить на конечные ноды миньоны солта;
настроить управление конфигурацией nginx и iptables.

#### Критерии оценки:
Статус "Принято" ставится при выполнении перечисленных требований.


### Выполнение домашнего задания

#### Создание стенда

Стенд будем разворачивать с помощью Terraform на Proxmox, настройку серверов будем выполнять с помощью Saltstack.

Необходимые файлы размещены в репозитории GitHub по ссылке:
```
https://github.com/SergSha/lab-11.git
```

Схема:

<img src="pics/infra.png" alt="infra.png" />

Для начала получаем OAUTH токен:
```
https://cloud.yandex.ru/docs/iam/concepts/authorization/oauth-token
```

Настраиваем аутентификации в консоли:
```
export YC_TOKEN=$(yc iam create-token)
export TF_VAR_yc_token=$YC_TOKEN
```

Скачиваем проект с гитхаба:
```
git clone https://github.com/SergSha/lab-11.git && cd ./lab-11
```

В файле provider.tf нужно вставить свой 'cloud_id':
```
cloud_id  = "..."
```

При необходимости в файле main.tf вставить нужные 'ssh_public_key' и 'ssh_private_key', так как по умолчанию соответсвенно id_rsa.pub и id_rsa:
```
ssh_public_key  = "~/.ssh/id_rsa.pub"
ssh_private_key = "~/.ssh/id_rsa"
```

Для того чтобы развернуть стенд, нужно выполнить следующую команду:
```
terraform init && terraform apply -auto-approve
```

По завершению команды получим данные outputs:
```
Outputs:

bes-info = {
  "be-01" = {
    "ip_address" = tolist([
      "10.10.10.7",
    ])
    "nat_ip_address" = tolist([
      "51.250.110.54",
    ])
  }
  "be-02" = {
    "ip_address" = tolist([
      "10.10.10.5",
    ])
    "nat_ip_address" = tolist([
      "158.160.27.141",
    ])
  }
}
dbs-info = {
  "db-01" = {
    "ip_address" = tolist([
      "10.10.10.19",
    ])
    "nat_ip_address" = tolist([
      "158.160.20.238",
    ])
  }
}
lbs-info = {
  "lb-01" = {
    "ip_address" = tolist([
      "10.10.10.23",
    ])
    "nat_ip_address" = tolist([
      "51.250.107.199",
    ])
  }
}
masters-info = {
  "master-01" = {
    "ip_address" = tolist([
      "10.10.10.3",
    ])
    "nat_ip_address" = tolist([
      "51.250.22.169",
    ])
  }
}
```

Затем подклю

На всех серверах будут установлены ОС Almalinux 9, настроены смнхронизация времени Chrony, система принудительного контроля доступа SELinux, в качестве firewall будет использоваться NFTables.

Стенд был взят из лабораторной работы 5 https://github.com/SergSha/lab-05. Стенд состоит из salt-мастера master-01 и salt-миньонов: балансировщик lb-01, бэкендов be-01 и be-02, сервер хранения базы данных db-01.


Consul-server развернём на кластере из трёх нод consul-01, consul-02, consul-03. На балансировщиках (nginx-01 и nginx-02) и бэкендах (backend-01 и backend-02) будут установлены клиентские версии Consul. На баланcировщиках также будут установлены и настроены сервис consul-template, которые будут динамически подменять конфигурационные файлы Nginx. На бэкендах будут установлены wordpress. Проверка (check) на доступность сервисов на клиентских серверах будет осуществляться по http.

Так как на YandexCloud ограничено количество выделяемых публичных IP адресов, в качестве JumpHost, через который будем подключаться по SSH (в частности для Ansible) к другим серверам той же подсети будем использовать сервер nginx-01.

Список виртуальных машин после запуска стенда:

<img src="pics/screen-001.png" alt="screen-001.png" />

Для проверки работы стенда воспользуемся установленным на бэкендах Wordpress:

<img src="pics/screen-002.png" alt="screen-002.png" />

Значение IP адреса сайта можно получить от балансировщика lb-01:

<img src="pics/screen-003.png" alt="screen-003.png" />





```
[root@jump-01 ~]# salt '*' saltutil.refresh_pillar
jump-01:
    True
nginx-01:
    True
db-01:
    True
backend-01:
    True
[root@jump-01 ~]# salt '*' mine.update
db-01:
    True
nginx-01:
    True
jump-01:
    True
backend-01:
    True
[root@jump-01 ~]# 
```

```
[root@jump-01 ~]# salt '*' mine.get '*' network.ip_addrs
db-01:
    ----------
    backend-01:
        - 10.10.10.17
    db-01:
        - 10.10.10.36
    jump-01:
        - 10.10.10.21
    nginx-01:
        - 10.10.10.26
jump-01:
    ----------
    backend-01:
        - 10.10.10.17
    db-01:
        - 10.10.10.36
    jump-01:
        - 10.10.10.21
    nginx-01:
        - 10.10.10.26
nginx-01:
    ----------
    backend-01:
        - 10.10.10.17
    db-01:
        - 10.10.10.36
    jump-01:
        - 10.10.10.21
    nginx-01:
        - 10.10.10.26
backend-01:
    ----------
    backend-01:
        - 10.10.10.17
    db-01:
        - 10.10.10.36
    jump-01:
        - 10.10.10.21
    nginx-01:
        - 10.10.10.26
[root@jump-01 ~]# 
```


```
[root@rocky user]# salt-ssh -i --priv=/home/user/.ssh/otus --sudo almalinux@51.250.22.169 cmd.run "salt-key -L"
51.250.22.169:
    Accepted Keys:
    be-01
    be-02
    db-01
    lb-01
    master-01
    Denied Keys:
    Unaccepted Keys:
    Rejected Keys:
```

```
[root@jump-01 ~]# salt '*' state.apply
```

```
salt-ssh -i --priv=/home/user/.ssh/otus --sudo almalinux@51.250.22.169 cmd.run "salt \* state.apply test=true"
```


```
[root@master-01 ~]# salt 'db-01' cmd.run 'nft list ruleset'
db-01:
    table ip filter {
    	chain MYSQL_INP {
    		ip saddr 10.10.10.13 tcp dport 3306 ct state new counter packets 2 bytes 120 accept
    	}
    
    	chain INPUT {
    		type filter hook input priority filter; policy drop;
    		ct state invalid counter packets 0 bytes 0 drop
    		iifname "lo" counter packets 0 bytes 0 accept
    		udp dport 323 counter packets 0 bytes 0 accept
    		ct state established,related counter packets 9532 bytes 87220025 accept
    		counter packets 253 bytes 17459 jump MYSQL_INP
    	}
    
    	chain FORWARD {
    		type filter hook forward priority filter; policy drop;
    	}
    
    	chain OUTPUT {
    		type filter hook output priority filter; policy drop;
    		ct state established,related,new counter packets 6362 bytes 394066 accept
    	}
    }
[root@master-01 ~]# 
```


```
salt 'db-01' cmd.run 'ss -tulpn'
```


```
salt 'db-01' cmd.run 'systemctl status sshd'
```



