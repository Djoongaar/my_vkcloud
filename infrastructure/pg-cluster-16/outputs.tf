output "id" {
  description = "Cluster ID (dbms_id)."
  value       = vkcs_db_cluster.this.id
}

output "name" {
  description = "Cluster name."
  value       = vkcs_db_cluster.this.name
}

output "loadbalancer_id" {
  description = "ID of the built-in load balancer in front of the cluster."
  value       = vkcs_db_cluster.this.loadbalancer_id
}

output "instances" {
  description = "List of cluster instances with their IDs, IPs and roles."
  value       = vkcs_db_cluster.this.instances
}

output "port" {
  description = "PostgreSQL TCP port."
  value       = 5432
}

output "config_group_id" {
  description = "ID of the config group created by this module, or null."
  value       = local.create_config_group ? vkcs_db_config_group.this[0].id : null
}

output "root_password" {
  description = "Root password (only meaningful when root_enabled = true). Sensitive."
  value       = var.root_enabled ? vkcs_db_cluster.this.root_password : null
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

output "user_passwords" {
  description = "Map of user name => password (explicitly set or auto-generated). Sensitive; retrieve with `terraform output -json user_passwords`."
  value       = local.user_passwords
  sensitive   = true
}
