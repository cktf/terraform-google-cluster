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
        for mapping, config in val.mappings : {
          key = "${key}_${mapping}"
          value = {
            name            = "${coalesce(val.name, "${var.name}-${key}")}-backend-service-${mapping}"
            scheme          = val.scheme
            protocol        = upper(split(":", mapping)[0])
            health_checks   = [google_compute_health_check.this["${key}_${mapping}"].self_link]
            backends        = { for group in val.group : group => google_compute_instance_group.this[group].self_link }
            iap_policy      = config.iap_policy
            cdn_policy      = config.cdn_policy
            security_policy = config.security_policy
          }
        }
      ] if val.scope == "GLOBAL"
    ]) : item.key => item.value
  }

  name                  = each.value.name
  load_balancing_scheme = each.value.scheme
  protocol              = each.value.protocol
  health_checks         = each.value.health_checks
  security_policy       = each.value.security_policy

  dynamic "backend" {
    for_each = each.value.backends
    content {
      group = backend.value
    }
  }

  dynamic "iap" {
    for_each = each.value.iap_policy != null ? { "1" = "1" } : {}
    content {
      enabled              = true
      oauth2_client_id     = try(iap.value.iap_policy.client_id, null)
      oauth2_client_secret = try(iap.value.iap_policy.client_secret, null)
    }
  }

  enable_cdn = each.value.cdn_policy != null
  dynamic "cdn_policy" {
    for_each = each.value.cdn_policy != null ? { "1" = "1" } : {}
    content {
      cache_mode                   = try(each.value.cdn_policy.cache_mode, null)
      max_ttl                      = try(each.value.cdn_policy.max_ttl, null)
      client_ttl                   = try(each.value.cdn_policy.client_ttl, null)
      default_ttl                  = try(each.value.cdn_policy.default_ttl, null)
      negative_caching             = try(each.value.cdn_policy.negative_caching, null)
      serve_while_stale            = try(each.value.cdn_policy.serve_while_stale, null)
      request_coalescing           = try(each.value.cdn_policy.request_coalescing, null)
      signed_url_cache_max_age_sec = try(each.value.cdn_policy.signed_url_cache_max_age, null)

      dynamic "cache_key_policy" {
        for_each = try(each.value.cdn_policy.cache_key_policies, {})
        content {
          include_host           = try(cache_key_policy.value.include_host, null)
          include_protocol       = try(cache_key_policy.value.include_protocol, null)
          include_http_headers   = try(cache_key_policy.value.include_http_headers, null)
          include_query_string   = try(cache_key_policy.value.include_query_string, null)
          include_named_cookies  = try(cache_key_policy.value.include_named_cookies, null)
          query_string_whitelist = try(cache_key_policy.value.query_string_whitelist, null)
          query_string_blacklist = try(cache_key_policy.value.query_string_blacklist, null)
        }
      }

      dynamic "negative_caching_policy" {
        for_each = try(each.value.cdn_policy.negative_caching_policies, {})
        content {
          ttl  = try(negative_caching_policy.value.ttl, null)
          code = try(negative_caching_policy.value.code, null)
        }
      }

      dynamic "bypass_cache_on_request_headers" {
        for_each = try(each.value.cdn_policy.bypass_cache_on_request_headers, {})
        content {
          header_name = bypass_cache_on_request_headers.value.header_name
        }
      }
    }
  }
}

resource "google_compute_region_backend_service" "this" {
  for_each = {
    for item in flatten([
      for key, val in var.balancers : [
        for mapping, config in val.mappings : {
          key = "${key}_${mapping}"
          value = {
            name            = "${coalesce(val.name, "${var.name}-${key}")}-backend-service-${mapping}"
            region          = val.region
            scheme          = val.scheme
            protocol        = upper(split(":", mapping)[0])
            health_checks   = [google_compute_region_health_check.this["${key}_${mapping}"].self_link]
            backends        = { for group in val.group : group => google_compute_instance_group.this[group].self_link }
            iap_policy      = config.iap_policy
            cdn_policy      = config.cdn_policy
            security_policy = config.security_policy
          }
        }
      ] if val.scope == "REGIONAL"
    ]) : item.key => item.value
  }

  name                  = each.value.name
  region                = each.value.region
  load_balancing_scheme = each.value.scheme
  protocol              = each.value.protocol
  health_checks         = each.value.health_checks

  dynamic "backend" {
    for_each = each.value.backends
    content {
      group = backend.value
    }
  }

  dynamic "iap" {
    for_each = each.value.iap_policy != null ? { "1" = "1" } : {}
    content {
      enabled              = true
      oauth2_client_id     = try(iap.value.iap_policy.client_id, null)
      oauth2_client_secret = try(iap.value.iap_policy.client_secret, null)
    }
  }

  enable_cdn = each.value.cdn_policy != null
  dynamic "cdn_policy" {
    for_each = each.value.cdn_policy != null ? { "1" = "1" } : {}
    content {
      cache_mode                   = try(each.value.cdn_policy.cache_mode, null)
      max_ttl                      = try(each.value.cdn_policy.max_ttl, null)
      client_ttl                   = try(each.value.cdn_policy.client_ttl, null)
      default_ttl                  = try(each.value.cdn_policy.default_ttl, null)
      negative_caching             = try(each.value.cdn_policy.negative_caching, null)
      serve_while_stale            = try(each.value.cdn_policy.serve_while_stale, null)
      signed_url_cache_max_age_sec = try(each.value.cdn_policy.signed_url_cache_max_age, null)

      dynamic "cache_key_policy" {
        for_each = try(each.value.cdn_policy.cache_key_policies, {})
        content {
          include_host           = try(cache_key_policy.value.include_host, null)
          include_protocol       = try(cache_key_policy.value.include_protocol, null)
          include_query_string   = try(cache_key_policy.value.include_query_string, null)
          include_named_cookies  = try(cache_key_policy.value.include_named_cookies, null)
          query_string_whitelist = try(cache_key_policy.value.query_string_whitelist, null)
          query_string_blacklist = try(cache_key_policy.value.query_string_blacklist, null)
        }
      }

      dynamic "negative_caching_policy" {
        for_each = try(each.value.cdn_policy.negative_caching_policies, {})
        content {
          code = try(negative_caching_policy.value.code, null)
        }
      }
    }
  }
}

resource "google_compute_url_map" "this" {
  for_each = {
    for item in flatten([
      for key, val in var.balancers : [
        for mapping, _ in val.mappings : {
          key = "${key}_${mapping}"
          value = {
            name = "${coalesce(val.name, "${var.name}-${key}")}-url-map-${mapping}"
            service = {
              GLOBAL   = google_compute_backend_service.this["${key}_${mapping}"].self_link
              REGIONAL = google_compute_region_backend_service.this["${key}_${mapping}"].self_link
            }[val.scope]
          }
        } if contains(["grpc", "http2", "https", "http"], mapping)
      ]
    ]) : item.key => item.value
  }

  name            = each.value.name
  default_service = each.value.service
}

resource "google_compute_target_grpc_proxy" "this" {
  for_each = {
    for item in flatten([
      for key, val in var.balancers : [
        for mapping, _ in val.mappings : {
          key = "${key}_${mapping}"
          value = {
            name    = "${coalesce(val.name, "${var.name}-${key}")}-target-proxy-${mapping}"
            url_map = google_compute_url_map.this["${key}_${mapping}"].self_link
          }
        } if contains(["grpc"], mapping)
      ]
    ]) : item.key => item.value
  }

  name    = each.value.name
  url_map = each.value.url_map
}

resource "google_compute_target_https_proxy" "this" {
  for_each = {
    for item in flatten([
      for key, val in var.balancers : [
        for mapping, config in val.mappings : {
          key = "${key}_${mapping}"
          value = {
            name             = "${coalesce(val.name, "${var.name}-${key}")}-target-proxy-${mapping}"
            url_map          = google_compute_url_map.this["${key}_${mapping}"].self_link
            ssl_certificates = config.ssl_certificates
          }
        } if contains(["http2", "https"], mapping)
      ]
    ]) : item.key => item.value
  }

  name             = each.value.name
  url_map          = each.value.url_map
  ssl_certificates = each.value.ssl_certificates
}

resource "google_compute_target_http_proxy" "this" {
  for_each = {
    for item in flatten([
      for key, val in var.balancers : [
        for mapping, _ in val.mappings : {
          key = "${key}_${mapping}"
          value = {
            name    = "${coalesce(val.name, "${var.name}-${key}")}-target-proxy-${mapping}"
            url_map = google_compute_url_map.this["${key}_${mapping}"].self_link
          }
        } if contains(["http"], mapping)
      ]
    ]) : item.key => item.value
  }

  name    = each.value.name
  url_map = each.value.url_map
}

resource "google_compute_target_ssl_proxy" "this" {
  for_each = {
    for item in flatten([
      for key, val in var.balancers : [
        for mapping, config in val.mappings : {
          key = "${key}_${mapping}"
          value = {
            name = "${coalesce(val.name, "${var.name}-${key}")}-target-proxy-${mapping}"
            service = {
              GLOBAL   = google_compute_backend_service.this["${key}_${mapping}"].self_link
              REGIONAL = google_compute_region_backend_service.this["${key}_${mapping}"].self_link
            }[val.scope]
            ssl_certificates = config.ssl_certificates
          }
        } if contains(["ssl"], mapping)
      ]
    ]) : item.key => item.value
  }

  name             = each.value.name
  backend_service  = each.value.service
  ssl_certificates = each.value.ssl_certificates
}

resource "google_compute_target_tcp_proxy" "this" {
  for_each = {
    for item in flatten([
      for key, val in var.balancers : [
        for mapping, _ in val.mappings : {
          key = "${key}_${mapping}"
          value = {
            name = "${coalesce(val.name, "${var.name}-${key}")}-target-proxy-${mapping}"
            service = {
              GLOBAL   = google_compute_backend_service.this["${key}_${mapping}"].self_link
              REGIONAL = google_compute_region_backend_service.this["${key}_${mapping}"].self_link
            }[val.scope]
          }
        } if contains(["tcp"], mapping)
      ]
    ]) : item.key => item.value
  }

  name            = each.value.name
  backend_service = each.value.service
}

resource "google_compute_global_address" "this" {
  for_each = {
    for key, val in var.balancers : key => val
    if val.scope == "GLOBAL"
  }

  name         = coalesce(each.value.name, "${var.name}-${each.key}")
  address_type = each.value.scheme
  ip_version   = "IPV4"
}

resource "google_compute_address" "this" {
  for_each = {
    for key, val in var.balancers : key => val
    if val.scope == "REGIONAL"
  }

  name         = coalesce(each.value.name, "${var.name}-${each.key}")
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

# TODO: Implement global, internal forwarding rules
# https://cloud.google.com/load-balancing/docs/l7-internal#components
