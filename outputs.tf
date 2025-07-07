output "volumes" {
  value = {
    for key, val in google_compute_disk.this : key => {
      link = val.self_link
      disk = val.disk_id
    }
  }
  sensitive   = false
  description = "Cluster Volumes"
}

output "servers" {
  value = {
    for key, val in google_compute_instance.this : key => {
      groups = var.servers[key].groups
      connection = {
        type                = "ssh"
        host                = try(val.network_interface[0].access_config[0].nat_ip, val.network_interface[0].network_ip)
        port                = "22"
        user                = "terraform"
        private_key         = var.private_key
        private_host        = try(val.network_interface[0].network_ip, null)
        bastion_host        = try(var.bastion.host, null)
        bastion_port        = try(var.bastion.port, null)
        bastion_user        = try(var.bastion.user, null)
        bastion_private_key = try(var.bastion.private_key, null)
      }
    }
  }
  sensitive   = false
  description = "Cluster Servers"
}
