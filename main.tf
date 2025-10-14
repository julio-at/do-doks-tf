/*
  VPC dedicada por entorno/región.
  IMPORTANTE: digitalocean_vpc NO soporta 'tags'.
*/
resource "digitalocean_vpc" "vpc" {
  name     = "${var.cluster_name}-vpc"
  region   = var.region
  ip_range = var.vpc_cidr
}

/*
  Selección de versión DOKS:
  - Si kubernetes_version == "": usar latest patch del minor (version_prefix).
  - Si kubernetes_version != "": usar pin exacto.
*/
data "digitalocean_kubernetes_versions" "minor" {
  version_prefix = "${var.kubernetes_minor_prefix}."
}

locals {
  effective_k8s_version = (
    var.kubernetes_version != "" ?
    var.kubernetes_version :
    data.digitalocean_kubernetes_versions.minor.latest_version
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

  # Upgrades
  surge_upgrade = true
  auto_upgrade  = false

  maintenance_policy {
    day        = var.maintenance_day
    start_time = var.maintenance_start_time_utc
  }

  # Node pool “sistema”
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
  (Opcional) Firewall por tags — deja enable_firewall = false para el MVP.
  Si lo activas, limita orígenes en 'allowed_source_addresses'.
*/
resource "digitalocean_firewall" "nodes" {
  count = var.enable_firewall ? 1 : 0

  name = "${var.cluster_name}-nodes-fw"

  # Asociar por tags (los workers de DOKS llevan tags 'k8s' y 'k8s:worker')
  tags = [
    "k8s",
    "k8s:worker"
  ]

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
}

