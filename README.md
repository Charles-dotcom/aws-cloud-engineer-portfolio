# ☁️ Cloud Engineer Portfolio

**Charles Mphahlele** | Senior Cloud / DevOps Engineer  
AWS Certified Solutions Architect – Associate | AWS Certified Developer – Associate | AWS Certified Cloud Practitioner  
Johannesburg, South Africa

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?logo=linkedin)](https://linkedin.com/in/charles-mphahlele-b029791b4)
[![Email](https://img.shields.io/badge/Email-charlesmphahlele5@gmail.com-red?logo=gmail)](mailto:charlesmphahlele5@gmail.com)
[![Phone](https://img.shields.io/badge/Phone-+27%2060%20117%202101-green?logo=whatsapp)](tel:+27601172101)

---

## 🎯 About Me

Results-driven **Cloud Infrastructure Engineer** with 5+ years of hands-on experience designing, automating, and operating secure, scalable, and cost-efficient cloud platforms on **AWS** (primary) with exposure to Azure and GCP concepts.

I specialize in:
- **Infrastructure as Code (IaC)** at scale using Terraform
- Building production-grade **CI/CD pipelines** with GitHub Actions
- Containerization and orchestration (Docker, Kubernetes/EKS with Karpenter)
- Multi-account AWS architectures, Landing Zones, and zero-trust security
- Cost optimization, observability, and compliance automation (POPIA, ISO, SOC2 patterns)

**Key Achievements**
- Architected greenfield AWS infrastructure (EKS + Karpenter) achieving **99.99% uptime** and **40% faster** environment provisioning
- Reduced cloud spend by **up to 30%** through rightsizing, Reserved Instances, and automation
- Led monolith-to-microservices migration and SQLite-to-PostgreSQL RDS cutover with zero-downtime strategies
- Enforced multi-account governance with SCPs resulting in **25% reduction** in security vulnerabilities

I build **repeatable, auditable, and self-documenting** cloud infrastructure that teams can trust.

---

## 🛠️ Technical Skills

| Category              | Technologies & Tools |
|-----------------------|----------------------|
| **IaC & Automation**  | Terraform, Terragrunt, CloudFormation, Ansible, Crossplane |
| **Cloud Platforms**   | AWS (EKS, ECS, Lambda, RDS, S3, CloudFront, IAM, EventBridge, ECR, Route53, CloudWatch, Security Hub, GuardDuty, Cost Explorer), Azure (AKS, VMs), GCP concepts |
| **Containers & Orchestration** | Docker (multi-stage), Kubernetes (EKS/AKS), Helm, ArgoCD, Karpenter, Cluster Autoscaler |
| **CI/CD & GitOps**    | GitHub Actions, GitLab CI, ArgoCD, blue-green / canary / rolling deployments |
| **Security & Compliance** | IAM (least privilege, OIDC, Identity Center), SCPs, KMS, Secrets Manager, WAF, GuardDuty, AWS Config, POPIA/SOC2/HIPAA patterns |
| **Observability**     | Prometheus + Grafana, CloudWatch, X-Ray, ELK/EFK, OpenTelemetry |
| **Languages & Scripting** | Python, Bash, HCL, YAML, JSON, SQL |
| **Other**             | Linux (Ubuntu/Debian deep troubleshooting), Git, Backstage (internal developer platforms) |

---

## 🚀 Featured Projects

### 1. Reusable AWS VPC Module (Production-Grade Networking)
**Location:** `terraform/modules/aws-vpc/`

A battle-tested, reusable Terraform module that provisions a secure, highly available VPC following AWS best practices:

- Public + private subnets across 3 AZs
- NAT Gateways (highly available)
- VPC Endpoints (S3, DynamoDB, SSM, ECR, etc.) for private connectivity
- Custom route tables, NACLs, and security group baselines
- IPv6 support optional
- Tagging strategy for cost allocation and compliance

**Why it matters:** Every serious cloud workload starts with solid networking. This module is designed to be dropped into any Landing Zone or workload account.

**Usage:**
```hcl
module "vpc" {
  source  = "./terraform/modules/aws-vpc"
  # ... variables
}
```

---

### 2. Static Website Hosting with S3 + CloudFront + Terraform
**Location:** `terraform/examples/static-website/`

End-to-end Infrastructure as Code example that deploys a secure, globally distributed static website:

- S3 bucket with versioning, encryption (SSE-KMS), and bucket policy
- CloudFront distribution with OAC (Origin Access Control)
- Custom error pages, caching behaviors, and security headers
- Optional Route 53 alias record + ACM certificate
- Terraform state backend with S3 + DynamoDB locking

**Live Demo Pattern:** Perfect for company marketing sites, documentation portals, or resume sites. Zero ongoing server costs.

**GitHub Actions Integration:** See workflows below — `terraform-plan` runs on every PR, `terraform-apply` on merge to `main`.

---

### 3. Dockerized Application + CI/CD Workflow (GitHub Actions + ECR)
**Location:** `apps/sample-cloud-app/` + `.github/workflows/docker-ci.yml`

Complete containerization and CI pipeline example:

- **Multi-stage Dockerfile** (small final image, security hardened)
- `.dockerignore` for clean context
- GitHub Actions workflow that:
  - Runs on push/PR to `main`
  - Lints Dockerfile
  - Builds image
  - (Optional) Scans with Trivy or Dockle
  - Pushes to **Amazon ECR** using OIDC (no long-lived AWS keys)
  - Outputs image URI + tag for downstream deployment jobs

**How to extend:** Pair this with the ECS/Fargate example or your own Kubernetes deployment step.

---

### 4. GitHub Actions + Terraform CI/CD Templates (Reusable Workflows)
**Location:** `.github/workflows/`

Production-ready, secure workflows following 2025+ best practices:

- **`terraform-plan.yml`** — Runs `terraform fmt`, `validate`, `plan` on every Pull Request. Comments plan output on PR. Uses OIDC to AWS.
- **`terraform-apply.yml`** — Runs only on merge to `main` (or protected branch). Applies changes with proper locking.
- **`docker-ci.yml`** — Builds, scans, and publishes Docker images to ECR.

**Security highlights:**
- AWS authentication via **OIDC** (short-lived credentials, no secrets in repo)
- Terraform state in S3 with DynamoDB locking
- Plan output posted back to PR for review
- Optional integration with `tfsec`, `checkov`, or `terraform-compliance`

These workflows are designed to be copied into any infrastructure repository.

---

### 5. Multi-Container Application Deployment
**Location:** `apps/multi-container-app/`

Production-style **multi-container** example using Docker Compose:

- **Nginx** reverse proxy in front of a **Flask backend API**
- Proper healthchecks, restart policies, and networking
- Ready to extend to Amazon ECS Fargate (multi-container task definition) or Kubernetes
- Shows you understand real-world application architecture (not just single-container demos)

This is a strong signal that you can design and operate microservices-style workloads.

---

### 6. Landing Zone SCP Governance Pipeline
**Location:** `terraform/examples/landing-zone-scp/`

**Governance as Code** example — managing AWS Service Control Policies (SCPs) via Terraform + GitHub Actions.

- Version-controlled restrictive SCPs (deny root actions, prevent leaving org, protect GuardDuty, etc.)
- Terraform to create and attach SCPs to Organizational Units
- Designed to run with **manual approval gates** in CI/CD (critical for Landing Zone safety)
- Shows deep understanding of AWS Organizations, multi-account strategy, and compliance guardrails

This is highly valued in enterprise environments and Landing Zone / Platform Engineering roles.

---

### 7. SRE Observability & Reliability Stack
**Location:** `apps/observability-stack/` + `terraform/examples/sre-observability/` + `docs/sre/`

**Industry-standard observability** using both open-source and AWS-native tools:

- **Prometheus + Grafana** full stack (Docker Compose) — the de facto industry standard
- Pre-provisioned Grafana dashboards and Prometheus scrape config
- CloudWatch alarms + SNS + example dashboard (Terraform)
- Sample **SLOs**, error budget thinking, and a real incident **runbook**

This shows you are fluent in **Prometheus + Grafana** (not just AWS CloudWatch) and can operate in both cloud-managed and open-source observability environments. Strong signal for SRE, Platform, and modern DevOps roles.

---

## ☁️ Multi-Cloud Capability (AWS + Azure)

To demonstrate I am not locked into a single cloud provider, this portfolio also includes **equivalent Azure examples** using Terraform:

### Azure Virtual Network Module
**Location:** `terraform/modules/azure-vnet/` + `terraform/examples/azure-basic-network/`

Production-grade Azure Virtual Network with:
- Resource Group
- VNet + multiple subnets
- Network Security Group (baseline rules)
- Subnet associations

Mirrors the AWS VPC module and shows clean multi-cloud networking patterns.

### Azure Static Website
**Location:** `terraform/examples/azure-static-website/`

Azure equivalent of the AWS S3 + CloudFront example:
- Storage Account with Static Website hosting
- Optional Azure CDN for global distribution
- Clean Terraform structure ready for production use

These examples prove you can deliver consistent Infrastructure as Code across **AWS and Azure**.

---

## 📁 Repository Structure

```
cloud-engineer-portfolio/
├── README.md
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml
│       ├── terraform-apply.yml
│       └── docker-ci.yml
├── terraform/
│   ├── modules/
│   │   ├── aws-vpc/
│   │   └── azure-vnet/           # Multi-cloud networking
│   └── examples/
│       ├── basic-vpc/
│       ├── static-website/
│       ├── azure-basic-network/
│       └── azure-static-website/
├── apps/
│   ├── sample-cloud-app/
│   │   ├── Dockerfile
│   │   ├── app.py
│   │   ├── requirements.txt
│   │   └── .dockerignore
│   ├── multi-container-app/
│   └── observability-stack/          # Prometheus + Grafana (industry standard)
├── docs/
│   ├── github-actions-setup.md
│   ├── oidc-aws-setup.md
│   └── terraform-best-practices.md
└── LICENSE
```

---

## 🔧 How to Use This Portfolio

### 1. Clone & Explore
```bash
git clone https://github.com/yourusername/cloud-engineer-portfolio.git
cd cloud-engineer-portfolio
```

### 2. Run Terraform Examples Locally
```bash
cd terraform/examples/static-website
cp terraform.tfvars.example terraform.tfvars
# edit variables (bucket name, region, etc.)
terraform init
terraform plan
terraform apply
```

### 3. Trigger GitHub Actions (Recommended)
1. Fork this repo
2. Set up **OIDC between GitHub and your AWS account** (see `docs/oidc-aws-setup.md`)
3. Create an S3 bucket + DynamoDB table for Terraform state (or use the example in `docs/`)
4. Push to `main` or open a PR — watch the magic happen!

### 4. Customize for Your Workloads
- Copy the `aws-vpc` module into your real infrastructure repos
- Adapt the Docker workflow for your microservices
- Extend the static website example with your own frontend (Next.js, Hugo, etc.)

---

## 📜 Certifications & Continuous Learning

- AWS Certified Solutions Architect – Associate (2024)
- AWS Certified Developer – Associate
- AWS Certified Cloud Practitioner
- Actively building expertise in **Agentic AI platforms**, Amazon Bedrock, RAG architectures, and LLM-powered automation on AWS

---

## 🤝 Let's Connect

I'm always open to discussing cloud architecture, Terraform patterns, cost optimization wins, or opportunities to build secure and scalable platforms.

- **Email:** charlesmphahlele5@gmail.com
- **LinkedIn:** [linkedin.com/in/charles-mphahlele-b029791b4](https://linkedin.com/in/charles-mphahlele-b029791b4)
- **Phone:** +27 60 117 2101
- **Location:** Johannesburg / Randburg, Gauteng, South Africa

---

*This portfolio demonstrates real, production-oriented patterns I use daily as a Cloud Engineer. All examples are designed to be secure, maintainable, and easy to extend.*

**Built with ❤️ for reliable cloud infrastructure.**
