variable "name" {
  type        = string
  default     = null
  sensitive   = false
  description = "Cluster Name"
}

variable "bastion" {
  type        = any
  default     = {}
  sensitive   = false
  description = "Cluster Bastion"
}

variable "public_key" {
  type        = string
  default     = null
  sensitive   = false
  description = "Cluster Public Key"
}

variable "private_key" {
  type        = string
  default     = null
  sensitive   = false
  description = "Cluster Private Key"
}

variable "groups" {
  type = map(object({
    name        = optional(string)
    zone        = optional(string)
    description = optional(string)
  }))
  default     = {}
  sensitive   = false
  description = "Cluster Groups"
}

variable "volumes" {
  type = map(object({
    name                      = optional(string)
    type                      = optional(string)
    size                      = optional(number)
    zone                      = optional(string)
    labels                    = optional(map(string), {})
    licenses                  = optional(list(string), [])
    description               = optional(string)
    access_mode               = optional(string)
    storage_pool              = optional(string)
    architecture              = optional(string)
    provisioned_iops          = optional(number)
    provisioned_throughput    = optional(number)
    physical_block_size_bytes = optional(number)
    protection                = optional(bool)
  }))
  default     = {}
  sensitive   = false
  description = "Cluster Volumes"
}

variable "servers" {
  type = map(object({
    name        = optional(string)
    zone        = optional(string)
    type        = optional(string)
    size        = optional(number)
    image       = optional(string)
    description = optional(string)
    protection  = optional(bool)
    labels      = optional(map(string), {})
    tags        = optional(list(string), [])
    volumes     = optional(list(string), [])
    groups      = optional(list(string), [])

    public_ipv4 = optional(bool, null)
    public_ipv6 = optional(bool, null)
    private_ip  = optional(list(any))
  }))
  default     = {}
  sensitive   = false
  description = "Cluster Servers"
}

variable "balancers" {
  type = map(object({
    name   = optional(string)
    scope  = optional(string)
    region = optional(string)
    scheme = optional(string)
    groups = optional(list(string), [])
    mappings = optional(map(object({
      iap_policy       = optional(any)
      cdn_policy       = optional(any)
      security_policy  = optional(string)
      ssl_certificates = optional(list(string), [])
    })), {})

    private_ip = optional(list(any))
  }))
  default     = {}
  sensitive   = false
  description = "Cluster Balancers"
}
