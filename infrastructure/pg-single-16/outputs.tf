output "id" {
  description = "Database instance ID (dbms_id)."
  value       = vkcs_db_instance.this.id
}

output "name" {
  description = "Instance name."
  value       = vkcs_db_instance.this.name
}

output "ips" {
  description = "List of IP addresses assigned to the instance."
  value       = vkcs_db_instance.this.ip
}

output "ip_address" {
  description = "Primary IP address of the instance (first entry), or null if not yet assigned."
  value       = try(vkcs_db_instance.this.ip[0], null)
}

output "port" {
  description = "PostgreSQL TCP port."
  value       = 5432
}

output "datastore_version" {
  description = "PostgreSQL major version of the instance."
  value       = var.postgresql_version
}

output "config_group_id" {
  description = "ID of the config group created by this module, or null."
  value       = local.create_config_group ? vkcs_db_config_group.this[0].id : null
}

output "root_password" {
  description = "Root password (only meaningful when root_enabled = true). Sensitive."
  value       = var.root_enabled ? vkcs_db_instance.this.root_password : null
  sensitive   = true
}

output "database_names" {
  description = "Names of the databases created by this module."
  value       = [for d in vkcs_db_database.this : d.name]
}

output "user_names" {
  description = "Names of the users created by this module."
  value       = [for u in vkcs_db_user.this : u.name]
}
