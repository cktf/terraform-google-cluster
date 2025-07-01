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

variable "servers" {
  type = map(object({
    name       = optional(string)
    type       = optional(string)
    image      = optional(number)
    attach     = optional(bool, false)
    subnet     = optional(string)
    network    = optional(number)
    gateway    = optional(string, "")
    location   = optional(string)
    datacenter = optional(string)
    protection = optional(bool)
    firewalls  = optional(list(number), [])
    ssh_keys   = optional(list(string), [])
    labels     = optional(map(string), {})
    groups     = optional(list(string), ["default"])

    volumes = optional(map(object({
      size      = number
      format    = optional(string)
      protected = optional(bool)
    })), {})
  }))
  default     = {}
  sensitive   = false
  description = "Cluster Servers"
}

variable "load_balancers" {
  type = map(object({
    name      = optional(string)
    type      = optional(string)
    zone      = optional(string)
    attach    = optional(bool, false)
    subnet    = optional(string)
    network   = optional(number)
    location  = optional(string)
    algorithm = optional(string)
    labels    = optional(map(string), {})
    groups    = optional(list(string), ["default"])

    mapping = map(number)
  }))
  default     = {}
  sensitive   = false
  description = "Cluster Load Balancers"
}
