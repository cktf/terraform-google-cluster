# TODO: Implement GLOBAL-INTERNAL forwarding rules
# https://cloud.google.com/load-balancing/docs/l7-internal#components

locals {
  rules = {
    for item in flatten([
      for key, val in var.balancers : [
        for mapping, config in val.mappings : {
          key = "${key}_${replace(mapping, ":", "_")}"
          value = {
            key              = key
            name             = "${coalesce(val.name, "${var.name}-${key}")}-${replace(mapping, ":", "-")}"
            scope            = val.scope
            region           = val.region
            scheme           = val.scheme
            groups           = { for group in val.groups : group => group }
            protocol         = lower(split(":", mapping)[0])
            source_port      = tonumber(split(":", mapping)[1])
            target_port      = tonumber(split(":", mapping)[2])
            iap_policy       = try(config.iap_policy, null)
            cdn_policy       = try(config.cdn_policy, null)
            security_policy  = try(config.security_policy, null)
            ssl_certificates = try(config.ssl_certificates, null)
          }
        }
      ]
    ]) : item.key => item.value
  }
}

resource "google_compute_health_check" "this" {
  for_each = {
    for key, val in local.rules : key => val
    if val.scope == "GLOBAL"
  }

  name = each.value.name

  dynamic "grpc_health_check" {
    for_each = each.value.protocol == "grpc" ? { "1" = "1" } : {}
    content {
      port = each.value.target_port
    }
  }

  dynamic "http2_health_check" {
    for_each = each.value.protocol == "http2" ? { "1" = "1" } : {}
    content {
      port = each.value.target_port
    }
  }

  dynamic "https_health_check" {
    for_each = each.value.protocol == "https" ? { "1" = "1" } : {}
    content {
      port = each.value.target_port
    }
  }

  dynamic "http_health_check" {
    for_each = each.value.protocol == "http" ? { "1" = "1" } : {}
    content {
      port = each.value.target_port
    }
  }

  dynamic "ssl_health_check" {
    for_each = each.value.protocol == "ssl" ? { "1" = "1" } : {}
    content {
      port = each.value.target_port
    }
  }

  dynamic "tcp_health_check" {
    for_each = each.value.protocol == "tcp" ? { "1" = "1" } : {}
    content {
      port = each.value.target_port
    }
  }
}

resource "google_compute_region_health_check" "this" {
  for_each = {
    for key, val in local.rules : key => val
    if val.scope == "REGIONAL"
  }

  name   = each.value.name
  region = each.value.region

  dynamic "grpc_health_check" {
    for_each = each.value.protocol == "grpc" ? { "1" = "1" } : {}
    content {
      port = each.value.target_port
    }
  }

  dynamic "http2_health_check" {
    for_each = each.value.protocol == "http2" ? { "1" = "1" } : {}
    content {
      port = each.value.target_port
    }
  }

  dynamic "https_health_check" {
    for_each = each.value.protocol == "https" ? { "1" = "1" } : {}
    content {
      port = each.value.target_port
    }
  }

  dynamic "http_health_check" {
    for_each = each.value.protocol == "http" ? { "1" = "1" } : {}
    content {
      port = each.value.target_port
    }
  }

  dynamic "ssl_health_check" {
    for_each = each.value.protocol == "ssl" ? { "1" = "1" } : {}
    content {
      port = each.value.target_port
    }
  }

  dynamic "tcp_health_check" {
    for_each = each.value.protocol == "tcp" ? { "1" = "1" } : {}
    content {
      port = each.value.target_port
    }
  }
}

resource "google_compute_backend_service" "this" {
  for_each = {
    for key, val in local.rules : key => val
    if val.scope == "GLOBAL"
  }

  name                  = each.value.name
  load_balancing_scheme = each.value.scheme
  protocol              = upper(each.value.protocol)
  health_checks         = [google_compute_health_check.this[each.key].self_link]
  security_policy       = each.value.security_policy

  dynamic "backend" {
    for_each = each.value.groups
    content {
      group = google_compute_instance_group.this[backend.value].self_link
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
    for key, val in local.rules : key => val
    if val.scope == "REGIONAL"
  }

  name                  = each.value.name
  region                = each.value.region
  load_balancing_scheme = each.value.scheme
  protocol              = upper(each.value.protocol)
  health_checks         = [google_compute_health_check.this[each.key].self_link]

  dynamic "backend" {
    for_each = each.value.groups
    content {
      group = google_compute_instance_group.this[backend.value].self_link
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
    for key, val in local.rules : key => val
    if contains(["grpc", "http2", "https", "http"], val.protocol)
  }

  name            = each.value.name
  default_service = each.value.scope == "GLOBAL" ? google_compute_backend_service.this[each.key].self_link : google_compute_region_backend_service.this[each.key].self_link
}

resource "google_compute_target_grpc_proxy" "this" {
  for_each = {
    for key, val in local.rules : key => val
    if contains(["grpc"], val.protocol)
  }

  name    = each.value.name
  url_map = google_compute_url_map.this[each.key].self_link
}

resource "google_compute_target_https_proxy" "this" {
  for_each = {
    for key, val in local.rules : key => val
    if contains(["http2", "https"], val.protocol)
  }

  name             = each.value.name
  url_map          = google_compute_url_map.this[each.key].self_link
  ssl_certificates = each.value.ssl_certificates
}

resource "google_compute_target_http_proxy" "this" {
  for_each = {
    for key, val in local.rules : key => val
    if contains(["http"], val.protocol)
  }

  name    = each.value.name
  url_map = google_compute_url_map.this[each.key].self_link
}

resource "google_compute_target_ssl_proxy" "this" {
  for_each = {
    for key, val in local.rules : key => val
    if contains(["ssl"], val.protocol)
  }

  name             = each.value.name
  backend_service  = each.value.scope == "GLOBAL" ? google_compute_backend_service.this[each.key].self_link : google_compute_region_backend_service.this[each.key].self_link
  ssl_certificates = each.value.ssl_certificates
}

resource "google_compute_target_tcp_proxy" "this" {
  for_each = {
    for key, val in local.rules : key => val
    if contains(["tcp"], val.protocol)
  }

  name            = each.value.name
  backend_service = each.value.scope == "GLOBAL" ? google_compute_backend_service.this[each.key].self_link : google_compute_region_backend_service.this[each.key].self_link
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
    for key, val in local.rules : key => val
    if val.scope == "GLOBAL"
  }

  name                  = each.value.name
  load_balancing_scheme = each.value.scheme
  port_range            = each.value.source_port
  ip_address            = google_compute_global_address.this[each.value.key].self_link

  target = {
    grpc  = try(google_compute_target_grpc_proxy.this[each.key].self_link, null)
    http2 = try(google_compute_target_https_proxy.this[each.key].self_link, null)
    https = try(google_compute_target_https_proxy.this[each.key].self_link, null)
    http  = try(google_compute_target_http_proxy.this[each.key].self_link, null)
    ssl   = try(google_compute_target_ssl_proxy.this[each.key].self_link, null)
    tcp   = try(google_compute_target_tcp_proxy.this[each.key].self_link, null)
  }[each.value.protocol]
}

resource "google_compute_forwarding_rule" "this" {
  for_each = {
    for key, val in local.rules : key => val
    if val.scope == "REGIONAL"
  }

  name                  = each.value.name
  region                = each.value.region
  load_balancing_scheme = each.value.scheme
  port_range            = each.value.source_port
  ip_address            = google_compute_address.this[each.value.key].self_link

  target = {
    grpc  = try(google_compute_target_grpc_proxy.this[each.key].self_link, null)
    http2 = try(google_compute_target_https_proxy.this[each.key].self_link, null)
    https = try(google_compute_target_https_proxy.this[each.key].self_link, null)
    http  = try(google_compute_target_http_proxy.this[each.key].self_link, null)
    ssl   = try(google_compute_target_ssl_proxy.this[each.key].self_link, null)
    tcp   = try(google_compute_target_tcp_proxy.this[each.key].self_link, null)
  }[each.value.protocol]
}
