resource "google_compute_address" "ipv4" {
  for_each = { for key, val in var.servers : key => val if val.public_ipv4 == true }

  name         = "${coalesce(each.value.name, "${var.name}-${each.key}")}-ipv4"
  region       = join("-", slice(split("-", each.value.zone), 0, 2))
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}

resource "google_compute_address" "ipv6" {
  for_each = { for key, val in var.servers : key => val if val.public_ipv6 == true }

  name               = "${coalesce(each.value.name, "${var.name}-${each.key}")}-ipv6"
  region             = join("-", slice(split("-", each.value.zone), 0, 2))
  subnetwork         = try(each.value.private_ip[1], null)
  ip_version         = "IPV6"
  address_type       = "EXTERNAL"
  ipv6_endpoint_type = "VM"
}

resource "google_compute_instance" "this" {
  for_each = var.servers

  name                = coalesce(each.value.name, "${var.name}-${each.key}")
  zone                = each.value.zone
  machine_type        = each.value.type
  description         = each.value.description
  deletion_protection = each.value.protection
  can_ip_forward      = (each.value.public_ipv4 != false || each.value.public_ipv6 != false) && each.value.private_ip != null
  metadata            = { ssh-keys = "terraform:${var.public_key}" }
  labels              = each.value.labels
  tags                = each.value.tags

  boot_disk {
    initialize_params {
      size  = each.value.size
      image = each.value.image
    }
  }

  dynamic "attached_disk" {
    for_each = { for volume in each.value.volumes : volume => split(":", volume) }
    content {
      source = try(google_compute_disk.this[attached_disk.value[0]].self_link, attached_disk.value[0])
      mode   = try(attached_disk.value[1], "READ_WRITE")
    }
  }

  network_interface {
    network    = try(each.value.private_ip[0], null)
    subnetwork = try(each.value.private_ip[1], null)
    stack_type = each.value.public_ipv6 != false ? "IPV4_IPV6" : "IPV4_ONLY"

    dynamic "access_config" {
      for_each = each.value.public_ipv4 != false ? { "1" = "1" } : {}
      content {
        network_tier = "PREMIUM"
        nat_ip       = try(google_compute_address.ipv4[each.key].address, null)
      }
    }

    dynamic "ipv6_access_config" {
      for_each = each.value.public_ipv6 != false ? { "1" = "1" } : {}
      content {
        network_tier  = "PREMIUM"
        external_ipv6 = try(google_compute_address.ipv6[each.key].address, null)
      }
    }
  }

  connection {
    type                = "ssh"
    host                = try(self.network_interface[0].access_config[0].nat_ip, self.network_interface[0].network_ip)
    port                = "22"
    user                = "terraform"
    private_key         = var.private_key
    bastion_host        = try(var.bastion.host, null)
    bastion_port        = try(var.bastion.port, null)
    bastion_user        = try(var.bastion.user, null)
    bastion_private_key = try(var.bastion.private_key, null)
  }

  provisioner "remote-exec" {
    inline = ["cloud-init status --wait || true"]
  }
}

resource "google_compute_instance_group" "this" {
  for_each = var.groups

  name        = coalesce(each.value.name, "${var.name}-${each.key}")
  zone        = each.value.zone
  description = each.value.description

  instances = [
    for key, val in var.servers : google_compute_instance.this[key].self_link
    if contains(val.groups, each.key)
  ]

  dynamic "named_port" {
    for_each = {
      for item in flatten([
        for key, val in var.balancers : [
          for mapping, _ in val.mappings : {
            key   = "${key}_${split(":", mapping)[2]}"
            value = split(":", mapping)[2]
          }
        ] if contains(val.groups, each.key)
      ]) : item.key => item.value
    }

    content {
      name = "port-${named_port.value}"
      port = named_port.value
    }
  }
}
