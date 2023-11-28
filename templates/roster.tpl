
%{ for nginx-server in nginx-servers ~}
${ nginx-server["name"] }:
  host: ${ nginx-server.network_interface[0].nat_ip_address }
  user: cloud-user
  priv: /root/.ssh/id_rsa
  sudo: True
  
%{ endfor ~}