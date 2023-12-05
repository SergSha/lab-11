locals {
  vm_user         = "cloud-user"
  ssh_public_key  = "~/.ssh/otus.pub"
  ssh_private_key = "~/.ssh/otus"
  #vm_name         = "instance"
  vpc_name        = "my_vpc_network"

  folders = {
    "lab-folder" = {}
    #"loadbalancer-folder" = {}
    #"nginx_folder" = {}
    #"backend_folder" = {}
  }

  subnets = {
    "lab-subnet" = {
      v4_cidr_blocks = ["10.10.10.0/24"]
    }
    /*
    "loadbalancer-subnet" = {
      v4_cidr_blocks = ["10.10.10.0/24"]
    }
    "nginx-subnet" = {
      v4_cidr_blocks = ["10.10.20.0/24"]
    }
    "backend-subnet" = {
      v4_cidr_blocks = ["10.10.30.0/24"]
    }
    */
  }

  #subnet_cidrs  = ["10.10.50.0/24"]
  #subnet_name   = "my_vpc_subnet"
  jump_count     = "1"
  db_count       = "0"
  iscsi_count    = "0"
  backend_count  = "0"
  nginx_count    = "1"
  /*
  disk = {
    "web" = {
      "size" = "1"
    }
  }
  */
}
/*
resource "yandex_resourcemanager_folder" "folders" {
  for_each = local.folders
  name     = each.key
  cloud_id = var.cloud_id
}
*/
#data "yandex_resourcemanager_folder" "folders" {
#  for_each   = yandex_resourcemanager_folder.folders
#  name       = each.value["name"]
#  depends_on = [yandex_resourcemanager_folder.folders]
#}

resource "yandex_vpc_network" "vpc" {
  #folder_id = yandex_resourcemanager_folder.folders["lab-folder"].id
  name      = local.vpc_name
}

data "yandex_vpc_network" "vpc" {
  #folder_id = yandex_resourcemanager_folder.folders["lab-folder"].id
  name      = yandex_vpc_network.vpc.name
}

#resource "yandex_vpc_subnet" "subnet" {
#  count          = length(local.subnet_cidrs)
#  #folder_id      = yandex_resourcemanager_folder.folders["lab-folder"].id
#  v4_cidr_blocks = local.subnet_cidrs
#  zone           = var.zone
#  name           = "${local.subnet_name}${format("%1d", count.index + 1)}"
#  network_id     = yandex_vpc_network.vpc.id
#}

resource "yandex_vpc_subnet" "subnets" {
  for_each = local.subnets
  name           = each.key
  #folder_id      = yandex_resourcemanager_folder.folders["lab-folder"].id
  v4_cidr_blocks = each.value["v4_cidr_blocks"]
  zone           = var.zone
  network_id     = data.yandex_vpc_network.vpc.id
  route_table_id = yandex_vpc_route_table.rt.id
}

#data "yandex_vpc_subnet" "subnets" {
#  for_each   = yandex_vpc_subnet.subnets
#  name       = each.value["name"]
#  #folder_id      = yandex_resourcemanager_folder.folders["lab-folder"].id
#  depends_on = [yandex_vpc_subnet.subnets]
#}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "test-gateway"
  #folder_id = yandex_resourcemanager_folder.folders["lab-folder"].id
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "rt" {
  name       = "test-route-table"
  #folder_id  = yandex_resourcemanager_folder.folders["lab-folder"].id
  network_id = yandex_vpc_network.vpc.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
    #next_hop_address   = yandex_compute_instance.nat-instance.network_interface.0.ip_address
    #next_hop_address = data.yandex_lb_network_load_balancer.keepalived.internal_address_spec.0.address
  }
}

module "jump-servers" {
  source         = "./modules/instances"
  count          = local.jump_count
  vm_name        = "jump-${format("%02d", count.index + 1)}"
  core_fraction  = 50
  vpc_name       = local.vpc_name
  #folder_id      = yandex_resourcemanager_folder.folders["lab-folder"].id
  network_interface = {
    for subnet in yandex_vpc_subnet.subnets :
    subnet.name => {
      subnet_id = subnet.id
      nat       = true
    }
    if subnet.name == "lab-subnet"
  }
  #subnet_cidrs   = yandex_vpc_subnet.subnet.v4_cidr_blocks
  #subnet_name    = yandex_vpc_subnet.subnet.name
  #subnet_id      = yandex_vpc_subnet.subnet.id
  vm_user        = local.vm_user
  ssh_public_key = local.ssh_public_key
  #user-data = "#cloud-config\n${file("cloud-init-salt-master.yml")}"
  user-data = "#cloud-config\nwrite_files:\n- content: ${base64encode("master:\n- 127.0.0.1\nid: jump-${format("%02d", count.index + 1)}")}\n  encoding: b64\n  path: /etc/salt/minion.d/minion.conf\n${file("cloud-init-salt-master.yml")}"
  # \nruncmd:\n- [ systemctl, start, salt-master ]
  secondary_disk = {}
  #depends_on     = [yandex_compute_disk.disks]
}

data "yandex_compute_instance" "jump-servers" {
  count      = length(module.jump-servers)
  name       = module.jump-servers[count.index].vm_name
  #folder_id  = yandex_resourcemanager_folder.folders["lab-folder"].id
  depends_on = [module.jump-servers]
}
/*
module "db-servers" {
  source         = "./modules/instances"
  count          = local.db_count
  vm_name        = "db-${format("%02d", count.index + 1)}"
  vpc_name       = local.vpc_name
  #folder_id      = yandex_resourcemanager_folder.folders["lab-folder"].id
  network_interface = {
    for subnet in yandex_vpc_subnet.subnets :
    subnet.name => {
      subnet_id = subnet.id
      #nat       = true
    }
    if subnet.name == "lab-subnet"
  }
  #subnet_cidrs   = yandex_vpc_subnet.subnet.v4_cidr_blocks
  #subnet_name    = yandex_vpc_subnet.subnet.name
  #subnet_id      = yandex_vpc_subnet.subnet.id
  vm_user        = local.vm_user
  ssh_public_key = local.ssh_public_key
  secondary_disk = {}
  depends_on     = [yandex_compute_disk.disks]
}

data "yandex_compute_instance" "db-servers" {
  count      = length(module.db-servers)
  name       = module.db-servers[count.index].vm_name
  #folder_id  = yandex_resourcemanager_folder.folders["lab-folder"].id
  depends_on = [module.db-servers]
}

module "iscsi-servers" {
  source         = "./modules/instances"
  count          = local.iscsi_count
  vm_name        = "iscsi-${format("%02d", count.index + 1)}"
  vpc_name       = local.vpc_name
  #folder_id      = yandex_resourcemanager_folder.folders["lab-folder"].id
  network_interface = {
    for subnet in yandex_vpc_subnet.subnets :
    subnet.name => {
      subnet_id = subnet.id
      #nat       = true
    }
    if subnet.name == "lab-subnet" #|| subnet.name == "backend-subnet"
  }
  #subnet_cidrs   = yandex_vpc_subnet.subnet.v4_cidr_blocks
  #subnet_name    = yandex_vpc_subnet.subnet.name
  #subnet_id      = yandex_vpc_subnet.subnet.id
  vm_user        = local.vm_user
  ssh_public_key = local.ssh_public_key
  secondary_disk = {
    for disk in yandex_compute_disk.disks :
    disk.name => {
      disk_id = disk.id
      #"auto_delete" = true
      #"mode"        = "READ_WRITE"
    }
    if disk.name == "web-${format("%02d", count.index + 1)}"
  }
  depends_on = [yandex_compute_disk.disks]
}

data "yandex_compute_instance" "iscsi-servers" {
  count      = length(module.iscsi-servers)
  name       = module.iscsi-servers[count.index].vm_name
  #folder_id  = yandex_resourcemanager_folder.folders["lab-folder"].id
  depends_on = [module.iscsi-servers]
}

module "backend-servers" {
  source         = "./modules/instances"
  count          = local.backend_count
  vm_name        = "backend-${format("%02d", count.index + 1)}"
  vpc_name       = local.vpc_name
  #folder_id      = yandex_resourcemanager_folder.folders["lab-folder"].id
  network_interface = {
    for subnet in yandex_vpc_subnet.subnets :
    subnet.name => {
      subnet_id = subnet.id
      #nat       = true
    }
    if subnet.name == "lab-subnet" #|| subnet.name == "backend-subnet"
  }
  #subnet_cidrs   = yandex_vpc_subnet.subnet.v4_cidr_blocks
  #subnet_name    = yandex_vpc_subnet.subnet.name
  #subnet_id      = yandex_vpc_subnet.subnet.id
  vm_user        = local.vm_user
  ssh_public_key = local.ssh_public_key
  secondary_disk = {}
  depends_on = [yandex_compute_disk.disks]
}

data "yandex_compute_instance" "backend-servers" {
  count      = length(module.backend-servers)
  name       = module.backend-servers[count.index].vm_name
  #folder_id  = yandex_resourcemanager_folder.folders["lab-folder"].id
  depends_on = [module.backend-servers]
}
*/
module "nginx-servers" {
  source         = "./modules/instances"
  count          = local.nginx_count
  vm_name        = "nginx-${format("%02d", count.index + 1)}"
  core_fraction  = 50
  vpc_name       = local.vpc_name
  #folder_id      = yandex_resourcemanager_folder.folders["lab-folder"].id
  network_interface = {
    for subnet in yandex_vpc_subnet.subnets :
    subnet.name => {
      subnet_id = subnet.id
      nat       = true
    }
    if subnet.name == "lab-subnet" #|| subnet.name == "nginx-subnet"
  }
  #subnet_cidrs   = yandex_vpc_subnet.subnet.v4_cidr_blocks
  #subnet_name    = yandex_vpc_subnet.subnet.name
  #subnet_id      = yandex_vpc_subnet.subnet.id
  vm_user        = local.vm_user
  ssh_public_key = local.ssh_public_key
  #user-data = "#cloud-config\n${file("cloud-init-salt-minion.yml")}"
  user-data = "#cloud-config\nwrite_files:\n- content: ${base64encode("master:\n- ${data.yandex_compute_instance.jump-servers[0].network_interface[0].ip_address}\nid: nginx-${format("%02d", count.index + 1)}")}\n  encoding: b64\n  path: /etc/salt/minion.d/minion.conf\n${file("cloud-init-salt-minion.yml")}"
  #user-data = "#cloud-config\nruncmd:\n  - rpm --import https://repo.saltproject.io/salt/py3/redhat/8/x86_64/SALT-PROJECT-GPG-PUBKEY-2023.pub\n  - curl -fsSL https://repo.saltproject.io/salt/py3/redhat/8/x86_64/latest.repo | tee /etc/yum.repos.d/salt.repo\n  - dnf install salt-minion -y\nsalt_minion:\n  pkg_name: 'salt-minion'\n  service_name: 'salt-minion'\n  config_dir: '/etc/salt'\n  conf:\n    master: ${data.yandex_compute_instance.jump-servers[0].network_interface[0].ip_address}"
  #user-data = "#cloud-config\n${file("cloud-init-salt-minion.yml")}\n  - echo -e master:\n- ${data.yandex_compute_instance.jump-servers[0].network_interface[0].ip_address} > /etc/salt/minion\n  - systemctl enable --now salt-minion"
  # \nwrite_files:\n- content: ${base64encode("master:\n- ${data.yandex_compute_instance.jump-servers[0].network_interface[0].ip_address}")}\n  encoding: b64\n  path: /etc/salt/minion\nbootcmd:\n- systemctl start salt-minion"
  # \nruncmd:\n- [ systemctl, start, salt-minion ]
  secondary_disk = {}
  #depends_on     = [yandex_compute_disk.disks]
  depends_on     = [data.yandex_compute_instance.jump-servers]
}

data "yandex_compute_instance" "nginx-servers" {
  count      = length(module.nginx-servers)
  name       = module.nginx-servers[count.index].vm_name
  #folder_id  = yandex_resourcemanager_folder.folders["lab-folder"].id
  depends_on = [module.nginx-servers]
}

resource "local_file" "inventory_file" {
  content = templatefile("${path.module}/templates/inventory.tpl",
    {
      jump-servers    = data.yandex_compute_instance.jump-servers
      #db-servers      = data.yandex_compute_instance.db-servers
      #iscsi-servers   = data.yandex_compute_instance.iscsi-servers
      #backend-servers = data.yandex_compute_instance.backend-servers
      nginx-servers   = data.yandex_compute_instance.nginx-servers
      remote_user     = local.vm_user
    }
  )
  filename = "${path.module}/inventory.ini"
}

resource "local_file" "roster_file" {
  content = templatefile("${path.module}/templates/roster.tpl",
    {
      jump-servers    = data.yandex_compute_instance.jump-servers
      #db-servers      = data.yandex_compute_instance.db-servers
      #iscsi-servers   = data.yandex_compute_instance.iscsi-servers
      #backend-servers = data.yandex_compute_instance.backend-servers
      nginx-servers   = data.yandex_compute_instance.nginx-servers
      remote_user     = local.vm_user
    }
  )
  filename = "${path.module}/srv/salt/roster"
}
#resource "yandex_compute_disk" "disks" {
#  for_each  = local.disks
#  name      = each.key
#  #folder_id = yandex_resourcemanager_folder.folders["lab-folder"].id
#  size      = each.value["size"]
#  zone      = var.zone
#}
/*
resource "yandex_compute_disk" "disks" {
  count     = local.iscsi_count
  name      = "web-${format("%02d", count.index + 1)}"
  #folder_id = yandex_resourcemanager_folder.folders["lab-folder"].id
  size      = "1"
  zone      = var.zone
}
*/
#data "yandex_compute_disk" "disks" {
#  for_each   = yandex_compute_disk.disks
#  name       = each.value["name"]
#  #folder_id  = yandex_resourcemanager_folder.folders["lab-folder"].id
#  depends_on = [yandex_compute_disk.disks]
#}
/*
resource "null_resource" "nginx-servers" {

  count = length(module.nginx-servers)

  # Changes to the instance will cause the null_resource to be re-executed
  triggers = {
    name = module.nginx-servers[count.index].vm_name
  }

  
  # Running the remote provisioner like this ensures that ssh is up and running
  # before running the local provisioner

  provisioner "remote-exec" {
    inline = ["echo 'Wait until SSH is ready'"]
  }

  connection {
    type        = "ssh"
    user        = local.vm_user
    private_key = file(local.ssh_private_key)
    host        = "${module.nginx-servers[count.index].instance_external_ip_address}"
  }

  # Note that the -i flag expects a comma separated list, so the trailing comma is essential!

  provisioner "local-exec" {
    command = "ansible-playbook -u '${local.vm_user}' --private-key '${local.ssh_private_key}' --become -i ./inventory.ini -l '${module.nginx-servers[count.index].instance_external_ip_address},' provision.yml"
    #command = "ansible-playbook provision.yml -u '${local.vm_user}' --private-key '${local.ssh_private_key}' --become -i '${element(module.nginx-servers.nat_ip_address, 0)},' "
  }
  
}
*/
/*
resource "null_resource" "jump-servers" {

  count = length(module.jump-servers)

  # Changes to the instance will cause the null_resource to be re-executed
  triggers = {
    name = "${module.jump-servers[count.index].vm_name}"
  }

  # Running the remote provisioner like this ensures that ssh is up and running
  # before running the local provisioner

  provisioner "remote-exec" {
    inline = ["sudo rpm --import https://repo.saltproject.io/salt/py3/redhat/8/x86_64/SALT-PROJECT-GPG-PUBKEY-2023.pub",
    "curl -fsSL https://repo.saltproject.io/salt/py3/redhat/8/x86_64/latest.repo | sudo tee /etc/yum.repos.d/salt.repo",
    "sudo dnf install salt-minion -y",
    "sudo echo -e 'master:\n  - ${data.yandex_compute_instance.jump-servers[count.index].network_interface[0].ip_address}' > /etc/salt/minion"]
  }
  
  connection {
    type        = "ssh"
    user        = local.vm_user
    private_key = file(local.ssh_private_key)
    host        = data.yandex_compute_instance.jump-servers[count.index].network_interface[0].ip_address
  }
  
  # Note that the -i flag expects a comma separated list, so the trailing comma is essential!

  provisioner "local-exec" {
    command = "ansible-playbook -u '${local.vm_user}' --private-key '${local.ssh_private_key}' --become -i '${module.backend-servers[count.index].instance_external_ip_address},' provision.yml"
    #command = "ansible-playbook provision.yml -u '${local.vm_user}' --private-key '${local.ssh_private_key}' --become -i '${element(module.backend-servers.nat_ip_address, 0)},' "
  }
  
}
*/
