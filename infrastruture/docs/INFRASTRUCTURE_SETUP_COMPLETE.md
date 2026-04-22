# Food Delivery Platform - Infrastructure Setup Guide

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [AWS Infrastructure Setup](#aws-infrastructure-setup)
5. [Kubernetes Cluster Setup](#kubernetes-cluster-setup)
6. [Service Mesh & Observability](#service-mesh--observability)
7. [CI/CD Pipeline](#cicd-pipeline)
8. [Operations](#operations)

## Overview

The Food Delivery Platform uses a production-grade, highly available infrastructure deployed on AWS EC2 with Kubernetes. This setup provides:

- **Infrastructure as Code**: Terraform modules for consistent, reproducible deployments
- **Multi-Environment Support**: Development, Staging, and Production environments
- **Service Mesh**: Istio for advanced traffic management and security
- **Observability**: OpenTelemetry, Prometheus, Grafana, and Jaeger
- **Configuration Management**: Ansible for cluster setup and management
- **CI/CD Pipeline**: GitHub Actions with Docker Hub registry
- **High Availability**: Multi-AZ deployments with auto-scaling

## Architecture

### Infrastructure Layers

```
┌─────────────────────────────────────────┐
│     Application Layer (Services)         │
│  ┌──────────────────────────────────┐   │
│  │ Istio Service Mesh & Ingress     │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│  Kubernetes Cluster (EC2 Instances)      │
│  ┌──────────────────────────────────┐   │
│  │ Master Nodes: 3 (t3.xlarge)      │   │
│  │ Worker Nodes: 5+ (t3.2xlarge)    │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│    AWS Managed Services                  │
│  ┌──────────────────────────────────┐   │
│  │ RDS PostgreSQL (Multi-AZ)        │   │
│  │ ElastiCache Redis                │   │
│  │ ALB (Application Load Balancer)  │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│    AWS VPC & Network                     │
│  ┌──────────────────────────────────┐   │
│  │ Public Subnets (3 AZs)           │   │
│  │ Private Subnets (3 AZs)          │   │
│  │ NAT Gateways & Security Groups   │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### Folder Structure

```
infrastruture/
├── terraform/
│   ├── modules/                     # Reusable Terraform modules
│   │   ├── vpc/                    # VPC, Subnets, NAT
│   │   ├── security_group/         # Security groups
│   │   ├── ec2/                    # EC2 instances
│   │   ├── rds/                    # PostgreSQL database
│   │   ├── elasticache/            # Redis cache
│   │   └── alb/                    # Application Load Balancer
│   └── environments/                # Environment-specific configs
│       ├── dev/
│       ├── staging/
│       └── prod/
├── ansible/
│   ├── inventory/                   # Inventory files (dev, staging, prod)
│   ├── playbooks/
│   │   └── setup-kubernetes-cluster.yml
│   └── roles/                       # Ansible roles
│       ├── system-setup/
│       ├── container-runtime/
│       ├── kubernetes-setup/
│       ├── networking/
│       ├── bootstrap-cluster/
│       ├── join-cluster/
│       ├── istio-setup/
│       ├── opentelemetry-setup/
│       └── monitoring-setup/
├── k8s/
│   ├── base/                        # Base K8s configs
│   ├── observability/               # OpenTelemetry configs
│   ├── istio/                       # Istio configs
│   ├── monitoring/                  # Prometheus/Grafana
│   └── services/                    # Application services
└── docs/                            # Documentation
    ├── SETUP_INSTRUCTIONS.md
    ├── DEPLOYMENT_SUMMARY.md
    ├── PRODUCTION_DEPLOYMENT_GUIDE.md
    └── SYSTEM_ANALYSIS_RECOMMENDATIONS.md
```

## Prerequisites

### Required Tools

```bash
# Infrastructure & Deployment
- Terraform >= 1.5
- AWS CLI v2
- kubectl >= 1.28
- Helm >= 3.12
- Ansible >= 2.14

# Local Development
- Docker & Docker Compose
- Node.js 18+
- Git

# Cloud Resources
- AWS Account with appropriate IAM permissions
- GitHub account with repository access
```

### AWS Permissions Required

Minimum IAM permissions needed:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "rds:*",
        "elasticache:*",
        "elasticloadbalancing:*",
        "iam:*",
        "s3:*",
        "cloudwatch:*",
        "logs:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## AWS Infrastructure Setup

### Step 1: Initialize Terraform Backend

```bash
# Create S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket food-delivery-terraform-state \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket food-delivery-terraform-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locks
aws dynamodb create-table \
  --table-name terraform-state-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```

### Step 2: Deploy VPC Infrastructure

```bash
cd infrastruture/terraform/environments/prod

# Initialize Terraform
terraform init -backend-config="bucket=food-delivery-terraform-state" \
              -backend-config="key=prod/terraform.tfstate" \
              -backend-config="region=us-east-1" \
              -backend-config="dynamodb_table=terraform-state-locks"

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
aws_region = "us-east-1"
project_name = "food-delivery"
certificate_arn = "arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/ID"
db_username = "admin"
db_password = "StrongPassword123!"
EOF

# Plan and apply
terraform plan
terraform apply
```

### Step 3: Verify AWS Resources

```bash
# Check VPC
aws ec2 describe-vpcs --query 'Vpcs[?Tags[?Key==`Project`].Value==`food-delivery`]'

# Check EC2 instances
aws ec2 describe-instances --filters "Name=tag:Project,Values=food-delivery"

# Check RDS instance
aws rds describe-db-instances --query 'DBInstances[?DBInstanceIdentifier==`food-delivery-db-prod`]'

# Check ElastiCache
aws elasticache describe-cache-clusters --query 'CacheClusters[?CacheNodeType]'
```

## Kubernetes Cluster Setup

### Step 1: Prepare EC2 Instances

```bash
# Get instance IPs from Terraform output
terraform output -json | jq '.cluster_info.value'

# Create Ansible inventory from Terraform output
# Update infrastruture/ansible/inventory/prod.ini with actual IPs
```

### Step 2: Setup Kubernetes Cluster

```bash
cd infrastruture/ansible

# Run Ansible playbook
ansible-playbook -i inventory/prod.ini playbooks/setup-kubernetes-cluster.yml

# Verify cluster
ansible -i inventory/prod.ini masters -m shell -a "kubectl get nodes"
```

### Step 3: Configure kubeconfig

```bash
# Get kubeconfig from master node
ssh -i ~/.ssh/kubernetes-key.pem ubuntu@MASTER_IP "cat ~/.kube/config" > ~/.kube/food-delivery-prod

# Set as default
export KUBECONFIG=~/.kube/food-delivery-prod

# Verify
kubectl cluster-info
kubectl get nodes
kubectl get pods -A
```

### Step 4: Verify Network & DNS

```bash
# Check Flannel CNI
kubectl get pods -n kube-flannel

# Check kube-proxy
kubectl get pods -n kube-system

# Test DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default
```

## Service Mesh & Observability

### Deploy Istio Service Mesh

```bash
# Install Istio using the playbook
ansible-playbook -i inventory/prod.ini playbooks/setup-kubernetes-cluster.yml \
  --tags istio

# Verify Istio installation
kubectl get pods -n istio-system
kubectl get svc -n istio-system

# Check Istio version
istioctl version
```

### Configure Application Services

```bash
# Apply Istio configurations
kubectl apply -f infrastruture/k8s/istio/

# Verify VirtualServices
kubectl get virtualservices
kubectl get destinationrules

# Verify Gateway
kubectl get gateway -n istio-system
```

### Deploy OpenTelemetry

```bash
# Deploy OpenTelemetry Collector
kubectl apply -f infrastruture/k8s/observability/otel-collector-config.yaml
kubectl apply -f infrastruture/k8s/observability/otel-collector-deployment.yaml
kubectl apply -f infrastruture/k8s/observability/otel-sdk-config.yaml

# Verify deployment
kubectl get pods -n observability
kubectl get svc -n observability
```

### Deploy Monitoring Stack

```bash
# Install Prometheus & Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  -f infrastruture/k8s/monitoring/values.yaml

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Open http://localhost:3000
# Default credentials: admin/admin
```

### Deploy Jaeger Tracing

```bash
# Install Jaeger
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo update

helm install jaeger jaegertracing/jaeger \
  -n observability --create-namespace

# Access Jaeger UI
kubectl port-forward -n observability svc/jaeger 16686:16686
# Open http://localhost:16686
```

## CI/CD Pipeline

### GitHub Secrets Configuration

Set the following secrets in GitHub repository settings:

```
DOCKERHUB_USERNAME=<your_dockerhub_username>
DOCKERHUB_TOKEN=<your_dockerhub_token>
AWS_ACCESS_KEY_ID=<aws_access_key>
AWS_SECRET_ACCESS_KEY=<aws_secret_key>
SONAR_TOKEN=<sonarqube_token>
SLACK_WEBHOOK_URL=<slack_webhook_for_notifications>
```

### Pipeline Execution

The CI/CD pipeline automatically:

1. **Build**: Builds Docker images for all services
2. **Test**: Runs code quality checks and security scans
3. **Security Scan**: Scans container images with Trivy
4. **Deploy Staging**: Auto-deploys to staging on `develop` branch
5. **Deploy Production**: Auto-deploys to production on `main` branch

### Manual Deployment

```bash
# Deploy specific environment
cd infrastruture/terraform/environments/prod
terraform apply

# Update Docker images in Kubernetes
kubectl set image deployment/frontend \
  frontend=DOCKERHUB_USERNAME/frontend:VERSION \
  -n production

# Check rollout status
kubectl rollout status deployment/frontend -n production
```

## Operations

### Monitoring & Logs

```bash
# View logs
kubectl logs -f deployment/restaurant-service -n default

# Check pod status
kubectl get pods -n default
kubectl describe pod POD_NAME -n default

# View metrics
kubectl top pods -n default
kubectl top nodes

# Access Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

### Troubleshooting

```bash
# Get cluster info
kubectl cluster-info
kubectl get nodes -o wide

# Debug pod networking
kubectl exec -it POD_NAME -- /bin/bash
ping SERVICE_NAME

# Check DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup SERVICE_NAME

# View events
kubectl get events -n default

# Describe problematic resource
kubectl describe node NODE_NAME
kubectl describe pod POD_NAME -n NAMESPACE
```

### Backup & Recovery

```bash
# Backup etcd
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-backup.db

# Backup database
mysqldump -h RDS_ENDPOINT -u admin -p fooddelivery > backup.sql

# Backup Redis
redis-cli -h REDIS_ENDPOINT BGSAVE
```

### Scaling

```bash
# Scale deployment
kubectl scale deployment restaurant-service --replicas=5 -n default

# Auto-scaling with HPA
kubectl apply -f infrastruture/k8s/base/services/hpa.yaml

# Check HPA status
kubectl get hpa -n default
```

## Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs)
- [Istio Documentation](https://istio.io/latest/docs)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs)
- [Ansible Documentation](https://docs.ansible.com)

## Support & Troubleshooting

For issues and support:

1. Check the logs: `kubectl logs -f <pod>`
2. Review Terraform state: `terraform state show`
3. Run diagnostics: `kubectl diagnostic`
4. Consult documentation above
