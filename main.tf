/*
  VPC: dedicated per environment/region.
*/
resource "digitalocean_vpc" "vpc" {
  name     = "${var.cluster_name}-vpc"
  region   = var.region
  ip_range = var.vpc_cidr

  #  tags = var.tags
}

/*
  Discover available Kubernetes versions.
  We'll select either an exact version (if provided) or the latest stable
  patch that matches the minor prefix.
*/
data "digitalocean_kubernetes_versions" "available" {}

locals {
  stable_versions = [
    for v in data.digitalocean_kubernetes_versions.available.valid_versions :
    v if v.stable == true
  ]

  stable_version_strings = [for v in local.stable_versions : v.slug]

  minor_pattern = var.kubernetes_minor_prefix

  minor_versions = [
    for s in local.stable_version_strings :
    s if can(regex(local.minor_pattern, s))
  ]

  effective_k8s_version = (
    var.kubernetes_version != "" ? var.kubernetes_version :
    length(local.minor_versions) > 0 ? local.minor_versions[0] :
    length(local.stable_version_strings) > 0 ? local.stable_version_strings[0] :
    ""
  )
}

/*
  Kubernetes Cluster (DOKS)
*/
resource "digitalocean_kubernetes_cluster" "doks" {
  name     = var.cluster_name
  region   = var.region
  version  = local.effective_k8s_version
  vpc_uuid = digitalocean_vpc.vpc.id

  surge_upgrade = true
  auto_upgrade  = false

  maintenance_policy {
    day        = var.maintenance_day
    start_time = var.maintenance_start_time_utc
  }

  node_pool {
    name       = "sysnp"
    size       = var.node_size
    node_count = var.node_count
    tags       = concat(var.tags, ["role:system"])

    auto_scale = var.enable_autoscale
    min_nodes  = var.enable_autoscale ? var.min_nodes : null
    max_nodes  = var.enable_autoscale ? var.max_nodes : null
  }

  tags = var.tags

  depends_on = [digitalocean_vpc.vpc]
}

/*
  Optional: DigitalOcean firewall to restrict inbound traffic to nodes.
*/
resource "digitalocean_firewall" "nodes" {
  count = var.enable_firewall ? 1 : 0

  name = "${var.cluster_name}-nodes-fw"

  droplet_ids = [
    for np in digitalocean_kubernetes_cluster.doks.node_pool :
    np.nodes[*].droplet_id
  ][0]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.allowed_source_addresses
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = var.allowed_source_addresses
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = var.allowed_source_addresses
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  tags = var.tags
}
