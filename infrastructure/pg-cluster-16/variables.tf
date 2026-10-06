variable "name" {
  type        = string
  description = "Name of the PostgreSQL HA cluster."
  default     = "PostgreSQL-HA-16"

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 64
    error_message = "Cluster name must be between 1 and 64 characters."
  }
}

variable "flavor_id" {
  type        = string
  description = "Compute flavor ID for each cluster node (min 2 vCPU / 8 GB RAM)."
  default     = "72e08e66-77a8-457f-b86e-6dea452fd301"
}

variable "cluster_size" {
  type        = number
  description = "Number of nodes in the cluster (1 primary + replicas)."
  default     = 3

  validation {
    condition     = var.cluster_size >= 3 && var.cluster_size <= 7
    error_message = "cluster_size must be between 3 and 7 for a PostgreSQL HA cluster."
  }
}

variable "volume_size" {
  type        = number
  description = "Data volume size in GB per node."
  default     = 40

  validation {
    condition     = var.volume_size >= 10
    error_message = "volume_size must be at least 10 GB."
  }
}

variable "volume_type" {
  type        = string
  description = "Data volume type per node."
  default     = "high-iops"

  validation {
    condition     = contains(["ceph-ssd", "ceph-hdd", "high-iops", "high-iops-ha", "ef-nvme"], var.volume_type)
    error_message = "volume_type must be one of: ceph-ssd, ceph-hdd, high-iops, high-iops-ha, ef-nvme."
  }
}

variable "datastore_type" {
  type        = string
  description = "PostgreSQL datastore flavour for the cluster."
  default     = "postgresql"

  validation {
    condition     = contains(["postgresql", "postgresql_high_performance"], var.datastore_type)
    error_message = "datastore_type must be postgresql or postgresql_high_performance."
  }
}

variable "postgresql_version" {
  type        = string
  description = "PostgreSQL major version."
  default     = "16"

  validation {
    condition     = contains(["12", "13", "14", "15", "16", "17"], var.postgresql_version)
    error_message = "postgresql_version must be one of 12..17."
  }
}

variable "network_id" {
  type        = string
  description = "Network ID the instance is attached to."
  default     = "ef76ebb7-dfc5-403e-b090-9c00babc58e1"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID inside the network. null lets VKCS choose."
  default     = "3fd0eac7-1731-4744-9ecc-17042cf8f6cc"
}

variable "security_group_ids" {
  type        = set(string)
  description = "Set of security group IDs applied to the cluster node ports."
  default     = []
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for the cluster nodes. Length should match cluster_size for a spread placement."
  default     = ["MS1", "ME1", "PA2"]
}

variable "floating_ip_enabled" {
  type        = bool
  description = "Attach a public floating IP to the cluster."
  default     = false
}

variable "keypair" {
  type        = string
  description = "SSH key pair name injected into the nodes."
  default     = null
}

variable "root_enabled" {
  type        = bool
  description = "Enable the root (superuser) account."
  default     = false
}

variable "root_password" {
  type        = string
  description = "Explicit root password. null means auto-generated when root_enabled = true."
  default     = null
  sensitive   = true
}

variable "cloud_monitoring_enabled" {
  type        = bool
  description = "Enable VK Cloud monitoring agent."
  default     = false
}

variable "configuration_id" {
  type        = string
  description = "ID of an existing config group to attach. Ignored when config_group_values is set."
  default     = null
}

variable "config_group_name" {
  type        = string
  description = "Name for the config group created from config_group_values. Defaults to \"<name>-config\"."
  default     = null
}

variable "config_group_values" {
  type        = map(string)
  description = "PostgreSQL parameters. When non-empty, the module creates a vkcs_db_config_group and attaches it."
  default     = {
    "work_mem": 16384,
    "checkpoint_timeout": 1800,
    "temp_buffers": 2048,
    "commit_delay": 1000,
    "random_page_cost": "1.1",
    "effective_io_concurrency": 600,
    "bgwriter_delay": "10ms",
    "bgwriter_lru_multiplier": 6,
    "bgwriter_lru_maxpages": 4000,
    "max_files_per_process": 10000
  }
}

variable "disk_autoexpand" {
  type = object({
    enabled       = optional(bool, false)
    max_disk_size = optional(number, 1000)
  })
  description = "Automatically grow the data volume up to max_disk_size GB."
  default     = {"enabled": true, "max_disk_size": 1024}
}

variable "wal_volume" {
  type = object({
    size        = number
    volume_type = string
  })
  description = "Dedicated WAL volume per node. null keeps WAL on the data volume."
  default     = {"size": 10, "volume_type": "high-iops"}
}

variable "databases" {
  type = list(object({
    name    = string
    charset = optional(string)
    collate = optional(string)
  }))
  description = "Databases to create inside the cluster."
  default     = []
}

variable "users" {
  type = list(object({
    name      = string
    password  = optional(string)
    host      = optional(string)
    databases = optional(list(string))
  }))
  description = "Database users to create. When a user's password is omitted, a strong one is generated and exposed through the user_passwords output. The cluster API requires passwords to contain a special character."
  default     = []

  validation {
    condition     = alltrue([for u in var.users : u.password == null ? true : length(u.password) >= 8])
    error_message = "Every explicitly set user password must be at least 8 characters long. Omit the password to auto-generate one."
  }

  validation {
    condition     = length(distinct([for u in var.users : u.name])) == length(var.users)
    error_message = "User names must be unique."
  }
}

variable "generated_password_length" {
  type        = number
  description = "Length of auto-generated user passwords (used when a user's password is omitted)."
  default     = 16

  validation {
    condition     = var.generated_password_length >= 8 && var.generated_password_length <= 128
    error_message = "generated_password_length must be between 8 and 128."
  }
}
