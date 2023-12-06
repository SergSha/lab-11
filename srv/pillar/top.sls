base:
   '*':
     - selinux

mine_functions:
  network.ip_addrs: 
    - interface: eth0
    - cidr: 10.10.10.0/24