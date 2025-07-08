########################
# 3. ForwardingRule + Address
########################
# resource "google_compute_address" "this" {} (regional)
# resource "google_compute_forwarding_rule" "this" {target + portRange} (regional) (per-mapping)
# resource "google_compute_global_address" "this" {} (global)
# resource "google_compute_global_forwarding_rule" "this" {target + portRange} (global) (per-mapping)

resource "google_compute_health_check" "this" {
  for_each = {
    for item in flatten([
      for key, val in var.balancers : [
        for mapping, _ in val.mappings : {
          key = "${key}_${mapping}"
          value = {
            name     = "${coalesce(val.name, "${var.name}-${key}")}-health-check-${mapping}"
            protocol = split(":", mapping)[0]
            port     = tonumber(split(":", mapping)[2])
          }
        }
      ] if val.scope == "GLOBAL"
    ]) : item.key => item.value
  }

  name = each.value.name

  dynamic "grpc_health_check" {
    for_each = each.value.protocol == "grpc" ? { "1" = "1" } : {}
    content {
      port = each.value.port
    }
  }

  dynamic "http2_health_check" {
    for_each = each.value.protocol == "http2" ? { "1" = "1" } : {}
    content {
      port = each.value
    }
  }

  dynamic "https_health_check" {
    for_each = each.value.protocol == "https" ? { "1" = "1" } : {}
    content {
      port = each.value.port
    }
  }

  dynamic "http_health_check" {
    for_each = each.value.protocol == "http" ? { "1" = "1" } : {}
    content {
      port = each.value.port
    }
  }

  dynamic "ssl_health_check" {
    for_each = each.value.protocol == "ssl" ? { "1" = "1" } : {}
    content {
      port = each.value.port
    }
  }

  dynamic "tcp_health_check" {
    for_each = each.value.protocol == "tcp" ? { "1" = "1" } : {}
    content {
      port = each.value.port
    }
  }
}

resource "google_compute_region_health_check" "this" {
  for_each = {
    for item in flatten([
      for key, val in var.balancers : [
        for mapping, _ in val.mappings : {
          key = "${key}_${mapping}"
          value = {
            name     = "${coalesce(val.name, "${var.name}-${key}")}-health-check-${mapping}"
            region   = val.region
            protocol = split(":", mapping)[0]
            port     = tonumber(split(":", mapping)[2])
          }
        }
      ] if val.scope == "REGIONAL"
    ]) : item.key => item.value
  }

  name   = each.value.name
  region = each.value.region

  dynamic "grpc_health_check" {
    for_each = each.value.protocol == "grpc" ? { "1" = "1" } : {}
    content {
      port = each.value.port
    }
  }

  dynamic "http2_health_check" {
    for_each = each.value.protocol == "http2" ? { "1" = "1" } : {}
    content {
      port = each.value
    }
  }

  dynamic "https_health_check" {
    for_each = each.value.protocol == "https" ? { "1" = "1" } : {}
    content {
      port = each.value.port
    }
  }

  dynamic "http_health_check" {
    for_each = each.value.protocol == "http" ? { "1" = "1" } : {}
    content {
      port = each.value.port
    }
  }

  dynamic "ssl_health_check" {
    for_each = each.value.protocol == "ssl" ? { "1" = "1" } : {}
    content {
      port = each.value.port
    }
  }

  dynamic "tcp_health_check" {
    for_each = each.value.protocol == "tcp" ? { "1" = "1" } : {}
    content {
      port = each.value.port
    }
  }
}

resource "google_compute_backend_service" "this" {
  for_each = {
    for item in flatten([
      for key, val in var.balancers : [
        for mapping, _ in val.mappings : {
          key = "${key}_${mapping}"
          value = {
            name     = "${coalesce(val.name, "${var.name}-${key}")}-backend-service-${mapping}"
            protocol = upper(split(":", mapping)[0])
            groups   = { for group in val.group : group => "" }
          }
        }
      ] if val.scope == "GLOBAL"
    ]) : item.key => item.value
  }

  name          = each.value.name
  protocol      = each.value.protocol
  health_checks = [google_compute_health_check.this[each.key].id]

  dynamic "backend" {
    for_each = each.value.groups
    content {
      group = google_compute_instance_group.this[backend.key].self_link
    }
  }

  # TODO: CDN policies
  # TODO: WAF policies
  # TODO: IAP policies
}

resource "google_compute_region_backend_service" "this" {
  for_each = {
    for item in flatten([
      for key, val in var.balancers : [
        for mapping, _ in val.mappings : {
          key = "${key}_${mapping}"
          value = {
            name     = "${coalesce(val.name, "${var.name}-${key}")}-backend-service-${mapping}"
            region   = val.region
            protocol = upper(split(":", mapping)[0])
            groups   = { for group in val.group : group => "" }
          }
        }
      ] if val.scope == "REGIONAL"
    ]) : item.key => item.value
  }

  name          = each.value.name
  region        = each.value.region
  protocol      = each.value.protocol
  health_checks = [google_compute_health_check.this[each.key].id]

  dynamic "backend" {
    for_each = each.value.groups
    content {
      group = google_compute_instance_group.this[backend.key].self_link
    }
  }

  # TODO: CDN policies
  # TODO: WAF policies
  # TODO: IAP policies
}

resource "google_compute_url_map" "this" {
  for_each = {
    for item in flatten([
      for key, val in var.balancers : [
        for mapping, _ in val.mappings : {
          key = "${key}_${mapping}"
          value = {
            name  = "${coalesce(val.name, "${var.name}-${key}")}-url-map-${mapping}"
            scope = val.scope
          }
        } if contains(["grpc", "http2", "https", "http"], mapping)
      ]
    ]) : item.key => item.value
  }

  name            = each.value.name
  default_service = each.value.scope == "GLOBAL" ? google_compute_backend_service.this[each.key].self_link : google_compute_region_backend_service.this[each.key].self_link
}

resource "google_compute_target_grpc_proxy" "this" {
  for_each = {
    for item in flatten([
      for key, val in var.balancers : [
        for mapping, _ in val.mappings : {
          key = "${key}_${mapping}"
          value = {
            name  = "${coalesce(val.name, "${var.name}-${key}")}-target-proxy-${mapping}"
            scope = val.scope
          }
        } if contains(["grpc"], mapping)
      ]
    ]) : item.key => item.value
  }

  name    = each.value.name
  url_map = google_compute_url_map.this[each.key].self_link
}

resource "google_compute_target_https_proxy" "this" {
  for_each = {
    for item in flatten([
      for key, val in var.balancers : [
        for mapping, _ in val.mappings : {
          key = "${key}_${mapping}"
          value = {
            name  = "${coalesce(val.name, "${var.name}-${key}")}-target-proxy-${mapping}"
            scope = val.scope
          }
        } if contains(["https"], mapping)
      ]
    ]) : item.key => item.value
  }

  name    = each.value.name
  url_map = google_compute_url_map.this[each.key].self_link
  # TODO: SSL certificates
  # TODO: Support HTTP2
}

resource "google_compute_target_http_proxy" "this" {
  for_each = {
    for item in flatten([
      for key, val in var.balancers : [
        for mapping, _ in val.mappings : {
          key = "${key}_${mapping}"
          value = {
            name  = "${coalesce(val.name, "${var.name}-${key}")}-target-proxy-${mapping}"
            scope = val.scope
          }
        } if contains(["http"], mapping)
      ]
    ]) : item.key => item.value
  }

  name    = each.value.name
  url_map = google_compute_url_map.this[each.key].self_link
}

resource "google_compute_target_ssl_proxy" "this" {
  for_each = {
    for item in flatten([
      for key, val in var.balancers : [
        for mapping, _ in val.mappings : {
          key = "${key}_${mapping}"
          value = {
            name  = "${coalesce(val.name, "${var.name}-${key}")}-target-proxy-${mapping}"
            scope = val.scope
          }
        } if contains(["ssl"], mapping)
      ]
    ]) : item.key => item.value
  }

  name            = each.value.name
  backend_service = each.value.scope == "GLOBAL" ? google_compute_backend_service.this[each.key].self_link : google_compute_region_backend_service.this[each.key].self_link
  # TODO: SSL certificates
}

resource "google_compute_target_tcp_proxy" "this" {
  for_each = {
    for item in flatten([
      for key, val in var.balancers : [
        for mapping, _ in val.mappings : {
          key = "${key}_${mapping}"
          value = {
            name  = "${coalesce(val.name, "${var.name}-${key}")}-target-proxy-${mapping}"
            scope = val.scope
          }
        } if contains(["tcp"], mapping)
      ]
    ]) : item.key => item.value
  }

  name            = each.value.name
  backend_service = each.value.scope == "GLOBAL" ? google_compute_backend_service.this[each.key].self_link : google_compute_region_backend_service.this[each.key].self_link
}

resource "google_compute_global_address" "this" {
  for_each = {
    for key, val in var.var.balancers : key => val
    if val.type == "GLOBAL"
  }

  name         = coalesce(val.name, "${var.name}-${key}")
  address_type = each.value.scheme
  ip_version   = "IPV4"
}

resource "google_compute_address" "this" {
  for_each = {
    for key, val in var.var.balancers : key => val
    if val.type == "REGIONAL"
  }

  name         = coalesce(val.name, "${var.name}-${key}")
  region       = each.value.region
  address_type = each.value.scheme
  ip_version   = "IPV4"
}

resource "google_compute_global_forwarding_rule" "this" {
  for_each = {
    for item in flatten([
      for key, val in var.balancers : [
        for mapping, _ in val.mappings : {
          key = "${key}_${mapping}"
          value = {
            name   = "${coalesce(val.name, "${var.name}-${key}")}-forwarding-rule-${mapping}"
            scheme = val.scheme
            target = {
              grpc  = google_compute_target_grpc_proxy.this["${key}_${mapping}"].self_link
              http2 = google_compute_target_https_proxy.this["${key}_${mapping}"].self_link
              https = google_compute_target_https_proxy.this["${key}_${mapping}"].self_link
              http  = google_compute_target_http_proxy.this["${key}_${mapping}"].self_link
              ssl   = google_compute_target_ssl_proxy.this["${key}_${mapping}"].self_link
              tcp   = google_compute_target_tcp_proxy.this["${key}_${mapping}"].self_link
            }[split(":", mapping)[0]]
            port_range = split(":", mapping)[1]
            ip_address = google_compute_global_address.this[key].self_link
          }
        }
      ] if val.scope == "GLOBAL"
    ]) : item.key => item.value
  }

  name                  = each.value.name
  load_balancing_scheme = each.value.scheme
  target                = each.value.target
  port_range            = each.value.port_range
  ip_address            = each.value.ip_address
}

resource "google_compute_forwarding_rule" "this" {
  for_each = {
    for item in flatten([
      for key, val in var.balancers : [
        for mapping, _ in val.mappings : {
          key = "${key}_${mapping}"
          value = {
            name   = "${coalesce(val.name, "${var.name}-${key}")}-forwarding-rule-${mapping}"
            region = val.region
            scheme = val.scheme
            target = {
              grpc  = google_compute_target_grpc_proxy.this["${key}_${mapping}"].self_link
              http2 = google_compute_target_https_proxy.this["${key}_${mapping}"].self_link
              https = google_compute_target_https_proxy.this["${key}_${mapping}"].self_link
              http  = google_compute_target_http_proxy.this["${key}_${mapping}"].self_link
              ssl   = google_compute_target_ssl_proxy.this["${key}_${mapping}"].self_link
              tcp   = google_compute_target_tcp_proxy.this["${key}_${mapping}"].self_link
            }[split(":", mapping)[0]]
            port_range = split(":", mapping)[1]
            ip_address = google_compute_address.this[key].self_link
          }
        }
      ] if val.scope == "REGIONAL"
    ]) : item.key => item.value
  }

  name                  = each.value.name
  region                = each.value.region
  load_balancing_scheme = each.value.scheme
  target                = each.value.target
  port_range            = each.value.port_range
  ip_address            = each.value.ip_address
}
