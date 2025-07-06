resource "google_compute_disk" "this" {
  for_each = var.volumes

  name                           = coalesce(each.value.name, "${var.name}-${each.key}")
  type                           = each.value.type
  size                           = each.value.size
  zone                           = each.value.zone
  labels                         = each.value.labels
  licenses                       = each.value.licenses
  description                    = each.value.description
  access_mode                    = each.value.access_mode
  storage_pool                   = each.value.storage_pool
  architecture                   = each.value.architecture
  provisioned_iops               = each.value.provisioned_iops
  provisioned_throughput         = each.value.provisioned_throughput
  physical_block_size_bytes      = each.value.physical_block_size_bytes
  create_snapshot_before_destroy = each.value.protection
}
