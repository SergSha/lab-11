
[all]
%{ for nginx-server in nginx-servers ~}
${ nginx-server["name"] } ansible_host=${ nginx-server.network_interface[0].ip_address } ip=${ nginx-server.network_interface[0].ip_address } public_ip=${ nginx-server.network_interface[0].nat_ip_address }
%{ endfor ~}

[nginx_servers]
%{ for nginx-server in nginx-servers ~}
${ nginx-server["name"] }
%{ endfor ~}

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyJump="${ remote_user }@${ nginx-servers[0].network_interface[0].nat_ip_address }"'
#ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyCommand="ssh -p 22 -W %h:%p -q ${ remote_user }@${ nginx-servers[0].network_interface[0].nat_ip_address }"'
