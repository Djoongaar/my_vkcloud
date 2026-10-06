locals {
  create_config_group = length(var.config_group_values) > 0

  user_passwords = {
    for u in var.users : u.name => u.password != null ? u.password : random_password.user[u.name].result
  }
}

# Generated for every user (not only password-less ones): filtering by
# u.password would derive the for_each keys from a potentially sensitive
# value, which Terraform rejects. Unused results cost nothing in the cloud.
resource "random_password" "user" {
  for_each = toset([for u in var.users : u.name])

  length           = var.generated_password_length
  special          = true
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!#%*()-_=+"
}

resource "vkcs_db_config_group" "this" {
  count = local.create_config_group ? 1 : 0

  name   = coalesce(var.config_group_name, "${var.name}-config")
  values = var.config_group_values

  datastore {
    type    = var.datastore_type
    version = var.postgresql_version
  }
}

resource "vkcs_db_cluster" "this" {
  name                     = var.name
  flavor_id                = var.flavor_id
  cluster_size             = var.cluster_size
  volume_size              = var.volume_size
  volume_type              = var.volume_type
  availability_zones       = var.availability_zones
  floating_ip_enabled      = var.floating_ip_enabled
  keypair                  = var.keypair
  root_enabled             = var.root_enabled
  root_password            = var.root_enabled ? var.root_password : null
  cloud_monitoring_enabled = var.cloud_monitoring_enabled
  configuration_id         = local.create_config_group ? vkcs_db_config_group.this[0].id : var.configuration_id

  datastore {
    type    = var.datastore_type
    version = var.postgresql_version
  }

  network {
    uuid            = var.network_id
    subnet_id       = var.subnet_id
    security_groups = var.security_group_ids
  }

  dynamic "disk_autoexpand" {
    for_each = var.disk_autoexpand.enabled ? [1] : []
    content {
      autoexpand    = true
      max_disk_size = var.disk_autoexpand.max_disk_size
    }
  }

  dynamic "wal_volume" {
    for_each = var.wal_volume == null ? [] : [var.wal_volume]
    content {
      size        = wal_volume.value.size
      volume_type = wal_volume.value.volume_type
    }
  }

  # VK provisions a default backup schedule; ignore it to keep re-apply plans
  # clean. Removing it on update also crashes provider 0.17.0 (panic in
  # extractDatabaseBackupSchedule).
  lifecycle {
    ignore_changes = [backup_schedule]
  }
}

resource "vkcs_db_database" "this" {
  for_each = { for d in var.databases : d.name => d }

  name    = each.value.name
  dbms_id = vkcs_db_cluster.this.id
  charset = each.value.charset
  collate = each.value.collate
}

resource "vkcs_db_user" "this" {
  for_each = { for u in var.users : u.name => u }

  name      = each.value.name
  password  = local.user_passwords[each.value.name]
  dbms_id   = vkcs_db_cluster.this.id
  databases = each.value.databases
  host      = each.value.host

  depends_on = [vkcs_db_database.this]
}
