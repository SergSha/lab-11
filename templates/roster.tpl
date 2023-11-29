%{ for jump-server in jump-servers ~}
${ jump-server["name"] }:
  host: ${ jump-server.network_interface[0].nat_ip_address }
  user: cloud-user
  priv: /home/user/.ssh/id_rsa
  sudo: True
  
%{ endfor ~}
%{ for nginx-server in nginx-servers ~}
${ nginx-server["name"] }:
  host: ${ nginx-server.network_interface[0].nat_ip_address }
  user: cloud-user
  priv: /home/user/.ssh/id_rsa
  sudo: True
  
%{ endfor ~}