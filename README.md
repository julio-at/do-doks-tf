# DigitalOcean Kubernetes (DOKS) with Terraform — Clone & Run

This repository provisions a **DigitalOcean VPC** and a **DOKS cluster** using **Terraform only**. No shell scripts are required, and the files are written for clarity (no one‑liners in `.tf`).

> TL;DR: **Clone → export `DIGITALOCEAN_TOKEN` → edit `terraform.tfvars` → `terraform init/plan/apply` → write kubeconfig → `kubectl get nodes`.


## 1) Clone this repo

```bash
git clone <YOUR_REPO_URL>.git
cd do-doks-tf
```

Project layout:
```
do-doks-tf/
├─ versions.tf
├─ providers.tf
├─ variables.tf
├─ main.tf
├─ outputs.tf
├─ terraform.tfvars.example
├─ .gitignore
└─ README.md
```


## 2) Prerequisites

- **DigitalOcean account** with billing enabled.
- **Personal Access Token** with Read/Write for Kubernetes, VPC, Firewalls (and Registry if you plan to use it).
- **Tools**:
  - Terraform ≥ 1.8.0
  - kubectl (optional, for validation)

Export your token:
```bash
export DIGITALOCEAN_TOKEN="<your_do_token>"
```


## 3) Configure `terraform.tfvars`

Copy the example and edit real values:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Key settings:
- `region` — e.g., `nyc3`, `sfo3`, `ams3`, `fra1`.
- `vpc_cidr` — VPC CIDR (default `10.10.0.0/16`).
- `cluster_name` — cluster name (e.g., `doks-demo`).
- `kubernetes_version` — **exact** version (e.g., `1.30.2-do.0`) **or** leave empty to auto‑select latest patch of `kubernetes_minor_prefix` (default `1.30`).
- `node_size` / `node_count` — default node pool shape.
- `enable_autoscale`, `min_nodes`, `max_nodes` — enable and set bounds for autoscaling (optional).
- `enable_firewall` — if `true`, a basic DO firewall will be created to restrict inbound SSH/HTTP/HTTPS to `allowed_source_addresses`.
- `tags` — list of tags applied to resources.

> Check available versions/sizes for your region in the DigitalOcean docs/UI. If a size is unavailable, choose a nearby size (`s-2vcpu-4gb`, `s-4vcpu-8gb`, `c-2`, etc.).


## 4) Initialize, validate, plan, and apply

```bash
terraform init -upgrade
terraform fmt
terraform validate
terraform plan -out tfplan
terraform apply -auto-approve tfplan
```

What gets created:
- VPC (per region) with your CIDR.
- DOKS cluster with a **system node pool** (`sysnp`).
- (Optional) A **DigitalOcean firewall** to limit inbound traffic to nodes.


## 5) Use `kubectl` (no doctl required)

Write the kubeconfig to a file and validate:
```bash
terraform output -raw kubeconfig > kubeconfig
export KUBECONFIG="$PWD/kubeconfig"

kubectl cluster-info
kubectl get nodes -o wide
```

> The kubeconfig output is **sensitive** — keep it private and never commit it.


## 6) Troubleshooting (quick)

- **401/403 Unauthorized**  
  Ensure `DIGITALOCEAN_TOKEN` is exported and has required scopes.

- **Node size not available**  
  Pick a different `node_size` or target another region.

- **Version mismatch**  
  If `kubernetes_version` is empty and the `kubernetes_minor_prefix` doesn’t exist in your region yet, set an **exact** version from the UI/API or adjust the minor prefix.

- **Firewall rules**  
  The included firewall is a **demo** rule set; harden for production (limit sources, ports, and add egress rules as needed).


## 7) Next steps (optional)

- Add a dedicated **workload node pool** with taints/labels, leaving `sysnp` for critical add‑ons.
- Configure **autoscaler** appropriately and tune surge upgrades.
- Add **Ingress** (Nginx/Traefik) with a single `LoadBalancer` service to reduce cost.
- Add **monitoring/logging** stack and **HPA/VPA** for workloads.
- Use **DigitalOcean Container Registry** and set up image pull secrets.

## 8) Clean up

```bash
terraform destroy -auto-approve
```

> This removes the cluster and VPC created by this project.
