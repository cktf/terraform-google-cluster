data "google_compute_image" "this" {
  project = "ubuntu-os-cloud"
  family  = "ubuntu-2504-amd64"
}

# resource "google_compute_disk" "this" {
#   name = "${var.name}-disk"
#   type = "hyperdisk-balanced"
#   zone = "us-central1-c"
#   size = 10
# }

# resource "google_compute_instance" "bastion" {
#   name         = "${var.name}-bastion"
#   zone         = "us-central1-c"
#   machine_type = "e2-small"

#   tags = ["swarm"]

#   boot_disk {
#     initialize_params {
#       image = data.google_compute_image.this.self_link
#     }
#   }

#   network_interface {
#     network    = google_compute_network.this.name
#     subnetwork = google_compute_subnetwork.this.name

#     # access_config {
#     #   // Ephemeral public IP
#     # }
#   }

#   metadata = {
#     startup-script = <<-EOT
#       #!/bin/bash
#       sudo apt update -y && sudo apt install -y nginx
#       EOT
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# # Health check for the backend instances
# resource "google_compute_health_check" "tcp_health_check" {
#   name               = "${var.name}-tcp-health-check"
#   timeout_sec        = 1
#   check_interval_sec = 1

#   tcp_health_check {
#     port = "80" # Change this to the port your application is listening on
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# # Instance group
# resource "google_compute_instance_group" "swarm_group" {
#   name    = "${var.name}-instance-group"
#   zone    = "us-central1-c"
#   network = google_compute_network.this.self_link

#   instances = [
#     google_compute_instance.bastion.self_link
#   ]

#   named_port {
#     name = "http"
#     port = 80 # Change this to match your application port
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# # Backend service that uses instance group
# # Tip: BackendService, TargetProxy, ForwardingRule must recreate on protocol change (resource key, name contains the protocol)
# # Tip: Address or GlobalAddress must not be recreated !!!
# resource "google_compute_backend_service" "tcp" {
#   name          = "${var.name}-backend-service-tcp"
#   protocol      = "TCP"
#   timeout_sec   = 10
#   health_checks = [google_compute_health_check.tcp_health_check.id]

#   backend {
#     group = google_compute_instance_group.swarm_group.self_link
#   }
# }

# ########################
# # 0. Disk + Address
# ########################
# # resource "google_compute_disk" "this" {...}
# # resource "google_compute_address" "this" {...}

# ########################
# # 1. Instance + Group + HealthCheck + BackendService(Global/Regional ???)
# ########################
# # resource "google_compute_instance" "this" {...}
# # resource "google_compute_health_check" "this" {...} (Only ALB)
# # resource "google_compute_instance_group" "this" {...}
# # resource "google_compute_backend_service" "this" {instanceGroup + healthCheck} (global)
# # resource "google_compute_region_backend_service" "this" {instanceGroup + healthCheck} (regional) 

# ########################
# # 2. Application Load Balancer (HTTP/HTTPS/GRPC)
# ########################
# # resource "google_compute_url_map" "this" {backendService[]}
# # resource "google_compute_target_https_proxy" "this" {urlMap}
# # resource "google_compute_target_http_proxy" "this" {urlMap}
# # resource "google_compute_target_grpc_proxy" "this" {urlMap}

# ########################
# # 2. Network Load Balancer (TCP/SSL)
# ########################
# # resource "google_compute_target_ssl_proxy" "this" {backendService}
# # resource "google_compute_target_tcp_proxy" "this" {backendService}

# ########################
# # 2. Legacy Load Balancer (Instance)
# ########################
# # resource "google_compute_target_instance" "this" {instance}
# # resource "google_compute_target_pool" "this" {instance[] + healthCheck}

# ########################
# # 3. Regional Forwarding Rule
# ########################
# # resource "google_compute_address" "this" {}
# # resource "google_compute_forwarding_rule" "this" {target + portRange}

# ########################
# # 3. Global Forwarding Rule
# ########################
# # resource "google_compute_global_address" "this" {}
# # resource "google_compute_global_forwarding_rule" "this" {target + portRange}

# ########################
# # ?. SSL/TLS Certificate, Network Endpoint Group, Backend Bucket
# ########################

# # 1. Target HTTP Proxy
# # resource "google_compute_url_map" "this" {
# #   name            = "${var.name}-url-map"
# #   default_service = google_compute_backend_service.http.self_link

# #   lifecycle {
# #     create_before_destroy = true
# #   }
# # }
# # resource "google_compute_target_http_proxy" "this" {
# #   name    = "${var.name}-http-proxy"
# #   url_map = google_compute_url_map.this.self_link

# #   lifecycle {
# #     create_before_destroy = true
# #   }
# # }

# # 2. Target TCP Proxy
# resource "google_compute_target_tcp_proxy" "this" {
#   name            = "${var.name}-tcp-proxy"
#   backend_service = google_compute_backend_service.tcp.self_link
# }

# # Global forwarding rule for HTTP traffic
# resource "google_compute_global_forwarding_rule" "tcp" {
#   name                  = "${var.name}-tcp-forwarding-rule"
#   target                = google_compute_target_tcp_proxy.this.id
#   port_range            = "80"
#   load_balancing_scheme = "EXTERNAL"
#   ip_address            = google_compute_global_address.this.address
# }
# resource "google_compute_global_address" "this" {
#   name = "${var.name}-static-ip"
# }

# # Firewall rule to allow health checks
# resource "google_compute_firewall" "health_check" {
#   name    = "${var.name}-allow-health-check"
#   network = google_compute_network.this.id

#   allow {
#     protocol = "tcp"
#     ports    = ["80"] # Change this to match your application port
#   }

#   source_ranges = ["130.211.0.0/22", "35.191.0.0/16"] # Google health check ranges
#   target_tags   = ["swarm"]
# }

# # Firewall rule to allow external traffic to the load balancer
# resource "google_compute_firewall" "lb_traffic" {
#   name    = "${var.name}-allow-lb-traffic"
#   network = google_compute_network.this.id

#   allow {
#     protocol = "tcp"
#     ports    = ["80"] # Change this to match your application port
#   }

#   source_ranges = ["${google_compute_global_address.this.address}/32"]
#   target_tags   = ["swarm"]
# }

# module "bastion" {
#   source  = "cktf/cluster/hcloud"
#   version = "2.0.0"

#   name        = var.name
#   public_key  = tls_private_key.this.public_key_openssh
#   private_key = tls_private_key.this.private_key_openssh

#   servers = {
#     bastion = {
#       type       = "cx22"
#       image      = data.hcloud_image.this.id
#       attach     = true
#       network    = module.network.id
#       gateway    = local.cidr
#       location   = values(var.groups)[0].location
#       protection = true
#     }
#   }
# }

# module "bastion_config" {
#   source = "../config"

#   name    = var.name
#   servers = module.bastion.servers
# }

# module "bastion_hosts" {
#   source     = "../ansible"
#   depends_on = [module.swarm]

#   servers  = merge(module.bastion.servers, module.cluster.servers)
#   playbook = "../swarm/ansible/hosts.yml"
# }
