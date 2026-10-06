locals {
  create_config_group = length(var.config_group_values) > 0
}

resource "vkcs_db_config_group" "this" {
  count = local.create_config_group ? 1 : 0

  name        = coalesce(var.config_group_name, "${var.name}-config")
  description = var.config_group_description
  values      = var.config_group_values

  datastore {
    type    = var.datastore_type
    version = var.postgresql_version
  }
}

resource "vkcs_db_instance" "this" {
  name                     = var.name
  flavor_id                = var.flavor_id
  size                     = var.size
  volume_type              = var.volume_type
  availability_zone        = var.availability_zone
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
    fixed_ip_v4     = var.fixed_ip
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

  dynamic "backup_schedule" {
    for_each = var.backup_schedule == null ? [] : [var.backup_schedule]
    content {
      name           = backup_schedule.value.name
      interval_hours = backup_schedule.value.interval_hours
      keep_count     = backup_schedule.value.keep_count
      start_hours    = backup_schedule.value.start_hours
      start_minutes  = backup_schedule.value.start_minutes
    }
  }
/*
  capabilities {
    name = "postgres_extensions"
    settings = {
      "hstore" = "true"
    }
  }
*/
}

resource "vkcs_db_database" "this" {
  for_each = { for d in var.databases : d.name => d }

  name    = each.value.name
  dbms_id = vkcs_db_instance.this.id
  charset = each.value.charset
  collate = each.value.collate
}

resource "vkcs_db_user" "this" {
  for_each = { for u in var.users : u.name => u }

  name      = each.value.name
  password  = each.value.password
  dbms_id   = vkcs_db_instance.this.id
  databases = each.value.databases
  host      = each.value.host

  depends_on = [vkcs_db_database.this]
}
