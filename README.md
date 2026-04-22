# Food Delivery Platform - Complete Production Setup

[![CI/CD Pipeline](https://github.com/yourorg/food-delivery-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/yourorg/food-delivery-platform/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Kubernetes: 1.28+](https://img.shields.io/badge/Kubernetes-1.28%2B-blue)](https://kubernetes.io)
[![Terraform: 1.5+](https://img.shields.io/badge/Terraform-1.5%2B-purple)](https://www.terraform.io)

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Project Structure](#project-structure)
- [Technology Stack](#technology-stack)
- [Features](#features)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [Support](#support)

## Overview

The **Food Delivery Platform** is a production-grade microservices application built with modern cloud-native technologies. It features:

✅ **Microservices Architecture** - 6 independent services with clear responsibilities
✅ **Kubernetes Deployment** - Self-managed K8s on AWS EC2 (not EKS)
✅ **Service Mesh** - Istio for advanced traffic management & security
✅ **Observability** - Complete stack with OpenTelemetry, Prometheus, Grafana, Jaeger
✅ **Infrastructure as Code** - Terraform with modular design
✅ **Configuration Management** - Ansible playbooks for automated setup
✅ **CI/CD Pipeline** - GitHub Actions with Docker Hub registry
✅ **High Availability** - Multi-AZ, auto-scaling, load balancing
✅ **Security** - TLS encryption, mTLS, RBAC, network policies
✅ **Multi-Environment** - Development, Staging, Production

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Internet Users                            │
└────────────────────────┬────────────────────────────────────┘
                         │
                    ┌────▼────┐
                    │   ALB   │ (Application Load Balancer)
                    └────┬────┘
                         │
        ┌────────────────┼────────────────┐
        │                                 │
    ┌───▼────┐                      ┌────▼─────┐
    │ Istio  │ Service Mesh         │ Ingress  │
    │ Gateway│                      │ Gateway  │
    └───┬────┘                      └────┬─────┘
        │                                │
        └────────────────┬───────────────┘
                         │
            ┌────────────▼────────────┐
            │  Kubernetes Cluster     │
            │  ┌────────────────────┐ │
            │  │ Master Nodes (3)   │ │
            │  │ Worker Nodes (5+)  │ │
            │  └────────────────────┘ │
            │         │               │
            │    ┌────▼────────┐      │
            │    │ Microservices
            │    │ ┌─────────┐ │      │
            │    │ │Frontend │ │      │
            │    │ ├─────────┤ │      │
            │    │ │Auth     │ │      │
            │    │ ├─────────┤ │      │
            │    │ │Admin    │ │      │
            │    │ ├─────────┤ │      │
            │    │ │Order    │ │      │
            │    │ ├─────────┤ │      │
            │    │ │Rider    │ │      │
            │    │ ├─────────┤ │      │
            │    │ │Restaurant
            │    │ └─────────┘ │      │
            │    └────┬────────┘      │
            │         │               │
            │    ┌────▼───────┐       │
            │    │ Observability      │
            │    │ ├─ OpenTelemetry  │
            │    │ ├─ Prometheus     │
            │    │ ├─ Jaeger         │
            │    │ └─ Loki           │
            │    └─────────────┘      │
            └──────────────────────────┘
                    │
        ┌───────────┼───────────┐
        │           │           │
    ┌───▼───┐ ┌────▼────┐ ┌───▼────┐
    │  RDS  │ │ElastiCache  │ │Other
    │  DB   │ │  Redis  │ │Services│
    └───────┘ └─────────┘ └────────┘
```

### Technology Stack

| Component     | Technology     | Version   |
| ------------- | -------------- | --------- |
| Orchestration | Kubernetes     | 1.28+     |
| Compute       | AWS EC2        | t3 family |
| Database      | PostgreSQL     | 15        |
| Cache         | Redis          | 7.0       |
| Service Mesh  | Istio          | 1.18+     |
| Observability | OpenTelemetry  | 0.85+     |
| Metrics       | Prometheus     | 2.45+     |
| Visualization | Grafana        | 10.0+     |
| Tracing       | Jaeger         | 1.38+     |
| Logs          | Loki           | 2.9+      |
| IaC           | Terraform      | 1.5+      |
| Configuration | Ansible        | 2.14+     |
| CI/CD         | GitHub Actions | latest    |
| Registry      | Docker Hub     | latest    |

### Microservices

| Service            | Port | Purpose                        | Stack                     |
| ------------------ | ---- | ------------------------------ | ------------------------- |
| Frontend           | 3000 | User Interface                 | React + TypeScript + Vite |
| Auth Service       | 3100 | Authentication & Authorization | Node.js + Express         |
| Admin Service      | 3101 | Administrative Operations      | Node.js + Express         |
| Restaurant Service | 3102 | Restaurant Management          | Node.js + Express         |
| Order Service      | 3103 | Order Processing               | Node.js + Express         |
| Rider Service      | 3104 | Rider Management               | Node.js + Express         |
| Realtime Service   | 3105 | WebSocket Communications       | Node.js + Socket.io       |

## Quick Start

### Prerequisites

```bash
# Check versions
terraform --version          # >= 1.5
aws --version               # >= 2.0
kubectl version --client    # >= 1.28
helm version               # >= 3.12
ansible --version          # >= 2.14
docker --version           # >= 20.0
```

### 1️⃣ Clone Repository

```bash
git clone https://github.com/yourorg/food-delivery-platform.git
cd food-delivery-platform
```

### 2️⃣ Configure AWS Credentials

```bash
aws configure
# Enter:
# AWS Access Key ID: [your-key]
# AWS Secret Access Key: [your-secret]
# Default region name: us-east-1
# Default output format: json
```

### 3️⃣ Deploy Infrastructure (5-10 minutes)

```bash
cd infrastruture/terraform/environments/prod

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
aws_region                = "us-east-1"
certificate_arn           = "arn:aws:acm:us-east-1:ACCOUNT:certificate/ID"
db_username               = "foodadmin"
db_password               = "SecurePassword123!@#"
EOF

# Deploy
terraform init
terraform plan
terraform apply
```

### 4️⃣ Setup Kubernetes Cluster (10-15 minutes)

```bash
cd ../../ansible

# Update inventory with EC2 IPs from Terraform output
nano inventory/prod.ini

# Run Ansible
ansible-playbook -i inventory/prod.ini playbooks/setup-kubernetes-cluster.yml
```

### 5️⃣ Deploy Services (5 minutes)

```bash
# Get kubeconfig
kubectl config use-context food-delivery-prod

# Create namespace
kubectl create namespace production
kubectl label namespace production istio-injection=enabled

# Deploy applications
kubectl apply -f ../k8s/services/ -n production
kubectl apply -f ../k8s/istio/ -n production
```

### 6️⃣ Access Services

```bash
# Get ALB DNS
ALB_DNS=$(terraform output -json | jq -r '.cluster_info.value.alb_dns_name')

# Access services
curl https://$ALB_DNS/health
curl https://$ALB_DNS/api/v1/restaurants

# Access monitoring
# Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Jaeger: kubectl port-forward -n observability svc/jaeger 16686:16686
```

## Project Structure

```
food-delivery-platform/
│
├── app/                                    # Application code
│   ├── frontend/                          # React frontend
│   │   ├── src/
│   │   ├── public/
│   │   ├── package.json
│   │   └── Dockerfile
│   │
│   └── services/                          # Microservices
│       ├── auth-service/
│       ├── admin-service/
│       ├── restaurant-service/
│       ├── order-service/
│       ├── rider-service/
│       └── realtime-service/
│
├── infrastruture/                         # Infrastructure & DevOps
│   ├── terraform/
│   │   ├── modules/                      # Reusable modules
│   │   │   ├── vpc/
│   │   │   ├── security_group/
│   │   │   ├── ec2/
│   │   │   ├── rds/
│   │   │   ├── elasticache/
│   │   │   └── alb/
│   │   │
│   │   └── environments/                  # Environment configs
│   │       ├── dev/
│   │       ├── staging/
│   │       └── prod/
│   │
│   ├── ansible/
│   │   ├── inventory/
│   │   │   ├── dev.ini
│   │   │   ├── staging.ini
│   │   │   └── prod.ini
│   │   │
│   │   ├── playbooks/
│   │   │   └── setup-kubernetes-cluster.yml
│   │   │
│   │   └── roles/
│   │       ├── system-setup/
│   │       ├── container-runtime/
│   │       ├── kubernetes-setup/
│   │       ├── networking/
│   │       ├── bootstrap-cluster/
│   │       ├── join-cluster/
│   │       ├── istio-setup/
│   │       ├── opentelemetry-setup/
│   │       └── monitoring-setup/
│   │
│   ├── k8s/
│   │   ├── base/                        # Base K8s manifests
│   │   ├── observability/               # OpenTelemetry
│   │   ├── istio/                       # Istio configs
│   │   ├── monitoring/                  # Prometheus/Grafana
│   │   └── services/                    # App deployments
│   │
│   └── docs/
│       ├── INFRASTRUCTURE_SETUP_COMPLETE.md
│       ├── PRODUCTION_DEPLOYMENT_COMPLETE.md
│       ├── SYSTEM_ANALYSIS_RECOMMENDATIONS.md
│       └── FILE_INDEX.md
│
├── .github/
│   └── workflows/
│       └── ci.yml                       # Complete CI/CD pipeline
│
├── README.md                            # This file
├── LICENSE.md
├── SECURITY.md
└── docker-compose.yml
```

## Features

### Security

- TLS/SSL encryption in transit
- mTLS between services (Istio)
- RBAC for Kubernetes access
- Network policies for pod-to-pod communication
- Secrets management with Kubernetes Secrets
- Container image scanning with Trivy
- SAST with SonarQube

### Observability

- Distributed tracing with Jaeger
- Metrics collection with Prometheus
- Log aggregation with Loki
- Visualization with Grafana
- Application instrumentation with OpenTelemetry
- Health checks and readiness probes

### Deployment & Operations

- GitOps-ready with ArgoCD (optional)
- Blue-green deployments supported
- Canary deployments via Istio
- Automatic rollbacks on failure
- Pod disruption budgets for safety
- Horizontal Pod Autoscaling (HPA)
- Backup and disaster recovery

### Cost Optimization

- Spot instances for worker nodes
- Reserved instances for master nodes
- Auto-scaling based on metrics
- Resource quotas per namespace
- Network cost optimization

## Documentation

### Core Documentation

- [Infrastructure Setup Guide](infrastruture/docs/INFRASTRUCTURE_SETUP_COMPLETE.md) - Complete infrastructure setup
- [Production Deployment Guide](infrastruture/docs/PRODUCTION_DEPLOYMENT_COMPLETE.md) - Step-by-step deployment
- [System Analysis](infrastruture/docs/SYSTEM_ANALYSIS_RECOMMENDATIONS.md) - Architecture decisions

### Quick References

- [Terraform Modules](infrastruture/terraform/modules) - Infrastructure modules
- [Ansible Playbooks](infrastruture/ansible/playbooks) - Automation scripts
- [Kubernetes Manifests](infrastruture/k8s) - K8s configurations
- [CI/CD Pipeline](.github/workflows/ci.yml) - GitHub Actions workflow

### External Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Istio Documentation](https://istio.io/latest/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Ansible Documentation](https://docs.ansible.com/)
- [Docker Hub](https://hub.docker.com/)

## CI/CD Pipeline

### GitHub Actions Workflow

The pipeline automatically:

1. **Build** - Compiles code and creates Docker images
2. **Test** - Runs unit tests and integration tests
3. **Scan** - Performs security scans (SAST, dependency check, container scanning)
4. **Deploy Staging** - Auto-deploys to staging on `develop` branch
5. **Deploy Production** - Auto-deploys to production on `main` branch

### Secrets Configuration

Required GitHub secrets:

```
DOCKERHUB_USERNAME      - Docker Hub username
DOCKERHUB_TOKEN         - Docker Hub access token
AWS_ACCESS_KEY_ID       - AWS credentials
AWS_SECRET_ACCESS_KEY   - AWS credentials
SONAR_TOKEN             - SonarQube token
SLACK_WEBHOOK_URL       - Slack notifications
```

## Development Workflow

### Local Development

```bash
# Start development environment
docker-compose up

# Services available at:
# Frontend: http://localhost:3000
# Backend APIs: http://localhost:8080
# Database: localhost:5432
# Redis: localhost:6379
```

### Testing

```bash
# Run tests
npm test --prefix app/frontend
npm test --prefix app/services/auth-service

# Run linting
npm run lint --prefix app/frontend

# Run OWASP dependency check
npm audit
```

### Building & Pushing

```bash
# Build locally
docker build -t username/frontend:latest ./app/frontend

# Push to Docker Hub
docker push username/frontend:latest
```

## Monitoring & Alerting

### Access Monitoring Dashboards

```bash
# Grafana (Metrics & Dashboards)
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# http://localhost:3000 (admin/admin)

# Prometheus (Metrics)
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# http://localhost:9090

# Jaeger (Tracing)
kubectl port-forward -n observability svc/jaeger 16686:16686
# http://localhost:16686

# Loki (Logs)
kubectl port-forward -n monitoring svc/loki 3100:3100
# http://localhost:3100
```

### Alerting Rules

Configure alerting rules in:

- `infrastruture/k8s/monitoring/prometheus-rules.yaml`
- Slack, PagerDuty, or email notifications

## Troubleshooting

### Common Issues

```bash
# Pod not starting
kubectl describe pod POD_NAME -n NAMESPACE
kubectl logs POD_NAME -n NAMESPACE

# Service connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  wget -O- http://service-name:port/

# Kubernetes issues
kubectl cluster-info
kubectl get events -n NAMESPACE
kubectl get nodes -o wide

# Terraform issues
terraform plan
terraform show
terraform state list
```

### Getting Help

1. Check the logs: `kubectl logs -f <pod>`
2. Review documentation in `infrastruture/docs/`
3. Check status in monitoring dashboards
4. Open an issue on GitHub

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests and linting
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

This project is licensed under the MIT License - see [LICENSE.md](LICENSE.md) for details.

## Security

Please see [SECURITY.md](SECURITY.md) for security reporting procedures.

## Support

- **Documentation**: See `infrastruture/docs/` for detailed guides
- **Issues**: Open an issue on GitHub
- **Email**: support@example.com
- **Slack**: #food-delivery-platform

## Roadmap

- [ ] ArgoCD integration
- [ ] GitOps workflows
- [ ] Cost optimization automation
- [ ] Multi-region deployment
- [ ] AI-powered demand forecasting
- [ ] Enhanced analytics
- [ ] Mobile app backend
- [ ] Payment gateway integration

## Status

- ✅ Infrastructure: Production Ready
- ✅ CI/CD: Production Ready
- ✅ Kubernetes: Production Ready
- ✅ Service Mesh: Production Ready
- ✅ Observability: Production Ready
- Application Services: In Development
- Frontend: In Development

---

**Maintained by**: Surya Parua
