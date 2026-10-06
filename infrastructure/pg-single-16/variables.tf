variable "name" {
  type        = string
  description = "Name of the managed PostgreSQL instance."
  default     = "PostgreSQL-16"

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 64
    error_message = "Instance name must be between 1 and 64 characters."
  }
}

variable "flavor_id" {
  type        = string
  description = "Compute flavor ID for the database node. PostgreSQL requires at least 2 vCPU / 8 GB RAM."
  default     = "2d9866a9-e955-4986-b00a-340ca54b2cac"

  validation {
    condition     = length(var.flavor_id) > 0
    error_message = "flavor_id must not be empty."
  }
}

variable "size" {
  type        = number
  description = "Data volume size in GB."
  default     = 100

  validation {
    condition     = var.size >= 10
    error_message = "size must be at least 10 GB."
  }
}

variable "volume_type" {
  type        = string
  description = "Data volume type."
  default     = "high-iops"

  validation {
    condition     = contains(["ceph-ssd", "ceph-hdd", "high-iops", "high-iops-ha", "ef-nvme"], var.volume_type)
    error_message = "volume_type must be one of: ceph-ssd, ceph-hdd, high-iops, high-iops-ha, ef-nvme."
  }
}

variable "datastore_type" {
  type        = string
  description = "PostgreSQL datastore flavour: postgresql or postgresql_high_performance."
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
    condition     = contains(["10", "11", "12", "13", "14", "15", "16", "17"], var.postgresql_version)
    error_message = "postgresql_version must be one of 10..17."
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
  description = "Set of security group IDs applied to the instance port."
  default     = []
}

variable "fixed_ip" {
  type        = string
  description = "Fixed IPv4 address inside the subnet. null means automatic allocation."
  default     = null
}

variable "availability_zone" {
  type        = string
  description = "Availability zone for the instance (e.g. GZ1, ME1, MS1, PA2)."
  default     = "PA2"
}

variable "floating_ip_enabled" {
  type        = bool
  description = "Attach a public floating IP to the instance. Requires the network to have internet access."
  default     = false
}

variable "keypair" {
  type        = string
  description = "Name of the SSH key pair injected into the database node."
  default     = null
}

variable "root_enabled" {
  type        = bool
  description = "Enable the root (superuser) account. If root_password is null, VKCS generates one (see the root_password output)."
  default     = false
}

variable "root_password" {
  type        = string
  description = "Explicit root password. Only used when root_enabled = true. null means auto-generated."
  default     = null
  sensitive   = true
}

variable "cloud_monitoring_enabled" {
  type        = bool
  description = "Enable VK Cloud monitoring agent on the instance."
  default     = false
}

variable "configuration_id" {
  type        = string
  description = "ID of an existing config group to attach. Ignored when config_group_values is set (this module then creates and attaches its own)."
  default     = null
}

variable "config_group_name" {
  type        = string
  description = "Name for the config group created from config_group_values. Defaults to \"<name>-config\"."
  default     = null
}

variable "config_group_description" {
  type        = string
  description = "Description for the created config group."
  default     = null
}

variable "config_group_values" {
  type        = map(string)
  description = "PostgreSQL parameters (postgresql.conf style). When non-empty, the module creates a vkcs_db_config_group and attaches it."
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
  description = "Automatically grow the data volume up to max_disk_size GB when it fills up."
  default     = {"enabled": true, "max_disk_size": 1024}
}

variable "wal_volume" {
  type = object({
    size        = number
    volume_type = string
  })
  description = "Dedicated WAL volume. null keeps WAL on the data volume."
  default     = {"size": 10, "volume_type": "high-iops"}
}

variable "backup_schedule" {
  type = object({
    name           = string
    interval_hours = number
    keep_count     = number
    start_hours    = number
    start_minutes  = optional(number, 0)
  })
  description = "Automatic backup schedule. null disables scheduled backups."
  default     = null
}

variable "databases" {
  type = list(object({
    name    = string
    charset = optional(string)
    collate = optional(string)
  }))
  description = "Databases to create inside the instance."
  default     = [
    {"name": "demo_0"},
    {"name": "demo_1"},
    {"name": "demo_2"},
    {"name": "demo_3"},
    {"name": "demo_4"},
    {"name": "demo_5"},
    {"name": "demo_6"},
    {"name": "demo_7"},
    {"name": "demo_8"},
    ]

  validation {
    condition     = alltrue([for d in var.databases : length(d.name) > 0])
    error_message = "Every database must have a non-empty name."
  }
}

variable "users" {
  type = list(object({
    name      = string
    password  = string
    host      = optional(string)
    databases = optional(list(string))
  }))
  description = "Database users to create. Each password must be at least 8 characters."
  default     = [
    {"name": "demo_user_0", "password": "3o=9FqbY3846n2f2e", "databases": ["demo_0"]},
    {"name": "demo_user_1", "password": "Huovfi*hv=SiuB384", "databases": ["demo_1"]},
    {"name": "demo_user_2", "password": "q9Y4Fb3=6o8n32f2e", "databases": ["demo_2"]},
    {"name": "demo_user_3", "password": "8S3u4iBvo=H*hfviu", "databases": ["demo_3"]},
    {"name": "demo_user_4", "password": "2en8f63o4=q9Y45Fb", "databases": ["demo_4"]},
    {"name": "demo_user_5", "password": "Biu*3S48vH=foivhu", "databases": ["demo_5"]},
    {"name": "demo_user_6", "password": "YbF=3o9q62n86f4e2", "databases": ["demo_6"]},
    {"name": "demo_user_7", "password": "vfo4H8uS*=Bihiuv3", "databases": ["demo_7"]},
    {"name": "demo_user_8", "password": "6f2e2n8o3=9Fq3bY4", "databases": ["demo_8"]},
    ]

  validation {
    condition     = alltrue([for u in var.users : length(u.password) >= 8])
    error_message = "Every user password must be at least 8 characters long."
  }
}
