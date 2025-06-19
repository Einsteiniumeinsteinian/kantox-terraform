# modules/eks-node-groups/variables.tf

variable "cluster" {
  description = "EKS cluster configuration"
  type = object({
    name                       = string
    endpoint                   = string
    certificate_authority_data = string
    version                    = optional(string, "1.32")
  })
}

variable "network" {
  description = "Network settings for the node group"
  type = object({
    vpc_id                 = string
    subnet_ids             = list(string)
    security_groups_ids = optional(list(string), [])
  })
}

variable "node_groups" {
  description = "Map of node group configurations"
  type = map(object({
    desired_capacity = number
    max_capacity     = number
    min_capacity     = number
    instance_types   = list(string)
    capacity_type    = string
    disk_size        = number
    disk_type        = string
    disk_iops        = optional(number)
    disk_throughput  = optional(number)
    k8s_labels       = optional(map(string), {})
    k8s_taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
    ami_type                      = optional(string, "AL2_x86_64")
    remote_access_enabled         = optional(bool, false)
    ec2_ssh_key                   = optional(string)
    source_security_groups        = optional(list(string), [])
    max_unavailable               = optional(number, 1)
    max_unavailable_percentage    = optional(number)
    force_update_version          = optional(bool, false)
    user_data                     = optional(string, "")
    pre_bootstrap_user_data       = optional(string, "")
    post_bootstrap_user_data      = optional(string, "")
    bootstrap_extra_args          = optional(string, "")
    subnet_ids                    = optional(list(string))
    additional_security_group_ids = optional(list(string), [])
  }))

  validation {
    condition = alltrue([
      for k, v in var.node_groups : contains(["ON_DEMAND", "SPOT"], v.capacity_type)
    ])
    error_message = "capacity_type must be either 'ON_DEMAND' or 'SPOT'."
  }

  validation {
    condition = alltrue([
      for k, v in var.node_groups : contains(["gp3", "gp2", "io1", "io2"], v.disk_type)
    ])
    error_message = "disk_type must be one of: gp3, gp2, io1, io2."
  }
}

variable "settings" {
  description = "General configuration and tags"
  type = object({
    enable_monitoring = optional(bool, true)
    enable_imdsv2     = optional(bool, true)
    name_prefix       = optional(string, "")
    name_suffix       = optional(string, "")
  })
}

variable "general_tags" {
  description = "General tags including Environment and Project"
  type = object({
    Environment = string
    Owner       = string
    Project     = string
    Team        = string
    ManagedBy   = optional(string, "terraform")
  })
}

variable "optional_tags" {
  description = "Optional tags per resource type"
  type = object({
    launch_template = optional(map(string), {})
  })
  default = {}
}
