variable "region" {
  description = <<-EOT
    DigitalOcean region slug (e.g., nyc3, sfo3, ams3, fra1, sgp1, blr1, tor1).
  EOT
  type        = string
}

variable "vpc_cidr" {
  description = <<-EOT
    VPC IPv4 CIDR block for the environment (e.g., 10.10.0.0/16).
  EOT
  type        = string
  default     = "10.10.0.0/16"
}

variable "cluster_name" {
  description = "Kubernetes cluster name."
  type        = string
}

variable "kubernetes_version" {
  description = <<-EOT
    Exact Kubernetes version string (e.g., 1.30.2-do.0).
    If left empty (""), the latest stable patch of the minor prefix below will be selected.
  EOT
  type        = string
  default     = ""
}

variable "kubernetes_minor_prefix" {
  description = <<-EOT
    Minor prefix to select the latest stable patch (e.g., "1.30").
    Used only when kubernetes_version == "".
  EOT
  type        = string
  default     = "1.30"
}

variable "node_size" {
  description = <<-EOT
    Droplet size for the default node pool (e.g., s-2vcpu-4gb, s-4vcpu-8gb, c-2).
  EOT
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "node_count" {
  description = "Number of nodes in the default node pool."
  type        = number
  default     = 3
}

variable "enable_autoscale" {
  description = "Enable autoscaling for the default node pool."
  type        = bool
  default     = false
}

variable "min_nodes" {
  description = "Minimum nodes for autoscaling (used when enable_autoscale = true)."
  type        = number
  default     = 2
}

variable "max_nodes" {
  description = "Maximum nodes for autoscaling (used when enable_autoscale = true)."
  type        = number
  default     = 6
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = list(string)
  default     = ["project:doks-demo", "env:lab", "owner:julio"]
}

variable "enable_firewall" {
  description = <<-EOT
    Whether to create a basic DigitalOcean firewall to limit inbound traffic to nodes.
    If true, you must set allowed_source_addresses accordingly.
  EOT
  type        = bool
  default     = false
}

variable "allowed_source_addresses" {
  description = <<-EOT
    List of CIDRs or IPs allowed to access node SSH and typical app ports (demo firewall).
    Only used when enable_firewall = true.
  EOT
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "maintenance_day" {
  description = "Weekly maintenance day for automatic upgrades (monday..sunday)."
  type        = string
  default     = "sunday"
}

variable "maintenance_start_time_utc" {
  description = "Start time (UTC, HH:MM) for maintenance window, e.g., 00:00."
  type        = string
  default     = "00:00"
}
