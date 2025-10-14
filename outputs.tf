output "region" {
  description = "DigitalOcean region used."
  value       = var.region
}

output "vpc_id" {
  description = "VPC UUID."
  value       = digitalocean_vpc.vpc.id
}

output "cluster_id" {
  description = "DOKS cluster ID."
  value       = digitalocean_kubernetes_cluster.doks.id
}

output "cluster_name" {
  description = "DOKS cluster name."
  value       = digitalocean_kubernetes_cluster.doks.name
}

output "kubernetes_version_effective" {
  description = "Effective Kubernetes version deployed."
  value       = digitalocean_kubernetes_cluster.doks.version
}

output "kubeconfig" {
  description = "Kubeconfig (raw) to access the cluster."
  value       = digitalocean_kubernetes_cluster.doks.kube_config[0].raw_config
  sensitive   = true
}
