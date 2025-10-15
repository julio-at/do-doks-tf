# DigitalOcean Kubernetes (DOKS) with Terraform — Clone & Run

This repository provisions a **DigitalOcean VPC** and a **DOKS cluster** using **Terraform only**. No shell scripts are required, and the files are written for clarity (no one‑liners in `.tf`).

> TL;DR: **Clone → export `DIGITALOCEAN_TOKEN` → edit `terraform.tfvars` → `terraform init/plan/apply` → write kubeconfig → `kubectl get nodes`.

---

## 1) Clone this repo

```bash
git clone https://github.com/julio-at/do-doks-tf.git
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

---

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

### (Optional) Discover slugs with `doctl`

```bash
doctl auth init
doctl account get

# Regions (slugs like nyc3, sfo3, ams3, fra1)
doctl compute region list

# Droplet sizes (slugs like s-2vcpu-4gb, s-4vcpu-8gb, c-2)
doctl compute size list

# DOKS versions (slugs like 1.30.2-do.0)
doctl kubernetes options versions

# Regions supported by DOKS
doctl kubernetes options regions

# Sizes supported by DOKS
doctl kubernetes options sizes
```

---

## 3) Where each slug goes

| What | Examples | Variable in `terraform.tfvars` |
|---|---|---|
| **Region** | `nyc3`, `sfo3`, `ams3`, `fra1` | `region = "nyc3"` |
| **Node size** | `s-2vcpu-4gb`, `s-4vcpu-8gb`, `c-2` | `node_size = "s-2vcpu-4gb"` |
| **Exact DOKS version** | `1.30.2-do.0` | `kubernetes_version = "1.30.2-do.0"` |
| **Minor prefix (auto-latest)** | `1.30` | `kubernetes_minor_prefix = "1.30"` *(used only if `kubernetes_version` is empty)* |

**Kubernetes versioning**
- **Option A (exact pin):** set `kubernetes_version = "1.30.x-do.0"` to avoid drift.
- **Option B (auto latest of minor):** leave `kubernetes_version = ""` and set `kubernetes_minor_prefix = "1.30"`. Terraform will select the `latest_version` of that minor automatically.

---

## 4) Configure `terraform.tfvars`

Copy the example and edit real values:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Example (both options included):
```hcl
region                   = "nyc3"
vpc_cidr                 = "10.10.0.0/16"

cluster_name             = "doks-demo"

# Option A: exact version (recommended for prod)
# kubernetes_version       = "1.30.2-do.0"
# kubernetes_minor_prefix  = "1.30"  # ignored if exact is set

# Option B: latest patch of the minor
kubernetes_version       = ""
kubernetes_minor_prefix  = "1.30"

node_size                = "s-2vcpu-4gb"
node_count               = 3

enable_autoscale         = false
min_nodes                = 2
max_nodes                = 6

# Leave this off for the MVP; enable later and restrict sources
enable_firewall          = false
allowed_source_addresses = ["0.0.0.0/0"]

tags = ["project:doks-demo", "env:lab", "owner:julio"]
```

**Notes**
- `digitalocean_vpc` **does not** support `tags`. Don’t add them there.
- If you enable the sample `digitalocean_firewall`, prefer associating by **tags** (e.g., `k8s`, `k8s:worker`) rather than `droplet_ids` to cover current and future workers.

---

## 5) Initialize, validate, plan, and apply

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
- (Optional) A **DigitalOcean firewall** to limit inbound traffic to nodes (off by default).

---

## 6) Use `kubectl` (no doctl required)

Write the kubeconfig to a file and validate:
```bash
terraform output -raw kubeconfig > kubeconfig
export KUBECONFIG="$PWD/kubeconfig"

kubectl cluster-info
kubectl get nodes -o wide
```

> The kubeconfig output is **sensitive** — keep it private and never commit it.

---

## 7) Troubleshooting (quick)

- **401/403 Unauthorized**  
  Ensure `DIGITALOCEAN_TOKEN` is exported and has required scopes.

- **Node size not available**  
  Pick a different `node_size` or target another region.

- **Version mismatch**  
  If `kubernetes_version` is empty and the `kubernetes_minor_prefix` isn’t available in your region yet, set an **exact** version or adjust the minor prefix.

- **VPC tags error**  
  `digitalocean_vpc` doesn’t support `tags`. Remove that attribute from the resource if present.

- **Firewall rules**  
  The included firewall is a **demo** rule set; harden for production (limit sources/ports and tighten egress as needed).

---

## 8) Next steps (optional)

- Add a dedicated **workload node pool** with taints/labels, leaving `sysnp` for critical add-ons.
- Configure **autoscaler** appropriately and tune surge upgrades.
- Add **Ingress** (Nginx/Traefik) with a single `LoadBalancer` service to reduce cost.
- Add **monitoring/logging** stack and **HPA/VPA** for workloads.
- Use **DigitalOcean Container Registry** and set up image pull secrets.

---

## 9) Clean up

```bash
terraform destroy -auto-approve
```

> This removes the cluster and VPC created by this project.
