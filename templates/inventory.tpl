
[all]
%{ for jump-server in jump-servers ~}
${ jump-server["name"] } ansible_host=${ jump-server.network_interface[0].ip_address } ip=${ jump-server.network_interface[0].ip_address } public_ip=${ jump-server.network_interface[0].nat_ip_address }
%{ endfor ~}
%{ for backend-server in backend-servers ~}
${ backend-server["name"] } ansible_host=${ backend-server.network_interface[0].ip_address } ip=${ backend-server.network_interface[0].ip_address } public_ip=${ backend-server.network_interface[0].nat_ip_address }
%{ endfor ~}
%{ for nginx-server in nginx-servers ~}
${ nginx-server["name"] } ansible_host=${ nginx-server.network_interface[0].ip_address } ip=${ nginx-server.network_interface[0].ip_address } public_ip=${ nginx-server.network_interface[0].nat_ip_address }
%{ endfor ~}

[jump_servers]
%{ for jump-server in jump-servers ~}
${ jump-server["name"] }
%{ endfor ~}

[backend_servers]
%{ for backend-server in backend-servers ~}
${ backend-server["name"] }
%{ endfor ~}

[nginx_servers]
%{ for nginx-server in nginx-servers ~}
${ nginx-server["name"] }
%{ endfor ~}

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyJump="${ remote_user }@${ jump-servers[0].network_interface[0].nat_ip_address }"'
#ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyCommand="ssh -p 22 -W %h:%p -q ${ remote_user }@${ jump-servers[0].network_interface[0].nat_ip_address }"'
