# Food Delivery Platform - Kubernetes Production Infrastructure

Complete production-ready Kubernetes infrastructure for a food delivery platform with microservices, monitoring, observability, and GitOps.

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                     Food Delivery Platform                       │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Frontend Layer:                                                 │
│  ├─ React.js Frontend (3000)                                    │
│  └─ Nginx API Gateway (8081)                                    │
│                                                                  │
│  Microservices (Node.js/Express):                               │
│  ├─ Auth Service (5000) - Google OAuth, JWT                     │
│  ├─ Restaurant Service (5001) - Menu, Orders, Cart              │
│  ├─ Utils Service (5002) - Payments, Image Upload               │
│  ├─ Realtime Service (5004) - WebSocket                         │
│  ├─ Rider Service (5005) - GPS, Orders                          │
│  └─ Admin Service (5006) - Admin Operations                     │
│                                                                  │
│  Data Layer:                                                     │
│  ├─ MongoDB (Replica Set, 3 nodes)                             │
│  ├─ RabbitMQ (Cluster, 3 nodes)                                │
│  └─ Redis (Single instance)                                     │
│                                                                  │
│  Monitoring & Observability:                                     │
│  ├─ Prometheus (Metrics)                                        │
│  ├─ Grafana (Visualization)                                     │
│  ├─ ELK Stack (Logging)                                         │
│  └─ Jaeger (Distributed Tracing)                                │
│                                                                  │
│  GitOps:                                                         │
│  └─ ArgoCD (Continuous Deployment)                              │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

## Quick Start (30 minutes)

### Prerequisites

```bash
# Install required tools
aws cli, terraform, kubectl, kustomize, helm

# Configure AWS
aws configure
```

### Deploy

```bash
# 1. Create EKS cluster
cd terraform/aws
terraform init && terraform apply

# 2. Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name food-delivery-prod

# 3. Install prerequisites
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace

helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace -f cert-manager-values.yaml

# 4. Deploy applications
kubectl apply -k k8s/overlays/prod

# 5. Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f argocd/applications.yaml
```

## Repository Structure

```
food-delivery-k8s/
├── terraform/
│   └── aws/
│       ├── main.tf          # EKS cluster, VPC, networking
│       └── variables.tf      # Configuration variables
│
├── k8s/
│   ├── base/                # Base configurations
│   │   ├── namespace/       # Namespaces & quotas
│   │   ├── security/        # RBAC & network policies
│   │   ├── services/        # Microservices deployments
│   │   ├── infrastructure/  # RabbitMQ, MongoDB, Ingress
│   │   ├── monitoring/      # Prometheus, Grafana
│   │   └── observability/   # ELK, Jaeger
│   │
│   └── overlays/            # Environment-specific configs
│       ├── dev/             # Development
│       ├── staging/         # Staging
│       └── prod/            # Production
│
├── argocd/
│   └── applications.yaml    # ArgoCD app definitions
│
├── SETUP_INSTRUCTIONS.md    # Quick setup guide
├── PRODUCTION_DEPLOYMENT_GUIDE.md  # Detailed guide
└── README.md                # This file
```

## Features

### High Availability

- ✅ Multi-replica deployments
- ✅ Pod Disruption Budgets
- ✅ Auto-scaling (HPA)
- ✅ Database clustering (MongoDB, RabbitMQ)
- ✅ Affinity rules (pod anti-affinity)

### Security

- ✅ RBAC role-based access control
- ✅ Network policies (deny by default)
- ✅ Pod security policies
- ✅ Secrets encryption
- ✅ TLS/SSL certificates
- ✅ Non-root containers

### Monitoring & Observability

- ✅ Prometheus metrics collection
- ✅ Grafana dashboards
- ✅ ELK stack for logging
- ✅ Jaeger distributed tracing
- ✅ OpenTelemetry instrumentation
- ✅ Alerting rules

### GitOps

- ✅ ArgoCD for continuous deployment
- ✅ Infrastructure as Code (Terraform)
- ✅ Kustomize for environment management
- ✅ Automated rollbacks

### Production-Ready

- ✅ Resource limits & requests
- ✅ Health checks (liveness & readiness)
- ✅ Rolling updates
- ✅ Database backups
- ✅ Disaster recovery procedures

## Component Details

### Services & Replicas

| Service     | Replicas | Memory | CPU  | Auto-scale |
| ----------- | -------- | ------ | ---- | ---------- |
| Auth        | 3        | 512Mi  | 500m | 2-10       |
| Restaurant  | 3        | 1Gi    | 500m | 2-10       |
| Utils       | 3        | 512Mi  | 500m | 2-8        |
| Realtime    | 3        | 512Mi  | 500m | 2-15       |
| Rider       | 3        | 512Mi  | 500m | 2-10       |
| Admin       | 2        | 512Mi  | 500m | 1-5        |
| Frontend    | 3        | 256Mi  | 250m | 2-5        |
| API Gateway | 3        | 256Mi  | 250m | 2-15       |

### Infrastructure

| Component | Type        | Replicas | Storage   | HA  |
| --------- | ----------- | -------- | --------- | --- |
| MongoDB   | StatefulSet | 3        | 20Gi each | Yes |
| RabbitMQ  | StatefulSet | 3        | 10Gi each | Yes |
| Redis     | Deployment  | 1        | Ephemeral | No  |

### Monitoring

| Tool          | Port  | Access       | Purpose             |
| ------------- | ----- | ------------ | ------------------- |
| Prometheus    | 9090  | ClusterIP    | Metrics collection  |
| Grafana       | 3000  | LoadBalancer | Visualization       |
| Elasticsearch | 9200  | ClusterIP    | Log storage         |
| Kibana        | 5601  | LoadBalancer | Log analysis        |
| Jaeger        | 16686 | LoadBalancer | Trace visualization |

## Security Features

### Network Policies

```yaml
- Deny all by default
- Allow traffic within namespace
- Allow traffic from ingress
- Allow traffic from monitoring
- Allow DNS queries
```

### RBAC

```yaml
- Service account per namespace
- Role-based access control
- Restricted API access
```

### Pod Security

```yaml
- Non-root containers
- Drop all capabilities
- Read-only root filesystem (where possible)
- No privilege escalation
```

## Monitoring Access

```bash
# Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000
# Login: admin/admin@123

# Elasticsearch
kubectl port-forward -n observability svc/elasticsearch 9200:9200

# Kibana
kubectl port-forward -n observability svc/kibana 5601:5601

# Jaeger
kubectl port-forward -n observability svc/jaeger 16686:16686
```

## Deployment Environments

### Development

```bash
kubectl apply -k k8s/overlays/dev
# Minimal resources, 1 replica, no monitoring
```

### Staging

```bash
kubectl apply -k k8s/overlays/staging
# Medium resources, 2 replicas, minimal monitoring
```

### Production

```bash
kubectl apply -k k8s/overlays/prod
# Full resources, 3+ replicas, full monitoring
```

## GitOps Workflow with ArgoCD

### Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Deploy Applications

```bash
kubectl apply -f argocd/applications.yaml
```

### Access ArgoCD UI

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# https://localhost:8080
# Username: admin
# Password: (get from secret)
```

## Useful Commands

```bash
# Check cluster
kubectl get nodes
kubectl get pods -A

# Get services
kubectl get svc -n food-delivery
kubectl get svc -n monitoring

# Check logs
kubectl logs -f deployment/auth-service -n food-delivery

# Port forward
kubectl port-forward svc/prometheus -n monitoring 9090:9090

# Scale deployment
kubectl scale deployment auth-service --replicas=5 -n food-delivery

# Apply config
kubectl apply -k k8s/overlays/prod

# Check events
kubectl get events -n food-delivery --sort-by='.lastTimestamp'
```

## Production Checklist

- [ ] VPC & Networking configured
- [ ] EKS cluster deployed with 3+ nodes
- [ ] RBAC & security policies applied
- [ ] Network policies enforced
- [ ] Secrets configured (MongoDB, RabbitMQ, auth)
- [ ] Docker images built & pushed to ECR
- [ ] Ingress configured with SSL/TLS
- [ ] Prometheus collecting metrics
- [ ] Grafana dashboards created
- [ ] ELK stack collecting logs
- [ ] Jaeger tracing enabled
- [ ] ArgoCD deployed & synced
- [ ] Pod disruption budgets applied
- [ ] Auto-scaling configured
- [ ] Monitoring alerts configured
- [ ] Backup procedures tested
- [ ] Disaster recovery plan documented

## Configuration Updates

### Update Docker Registry

Edit `k8s/overlays/prod/kustomization.yaml`:

```yaml
images:
  - name: YOUR_ECR_REGISTRY/auth-service
    newTag: v1.0.0
```

### Update Secrets

```bash
kubectl patch secret mongodb-connection -n food-delivery \
  --type merge -p '{"data":{"uri":"BASE64_ENCODED_URI"}}'
```

### Update Domain Names

Edit `k8s/base/infrastructure/ingress.yaml`:

```yaml
hosts:
  - api.yourdomain.com
  - yourdomain.com
```

## Documentation

- **Setup**: See [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md)
- **Production**: See [PRODUCTION_DEPLOYMENT_GUIDE.md](PRODUCTION_DEPLOYMENT_GUIDE.md)
- **Terraform**: See [terraform/aws/README.md](terraform/aws/README.md)

## Troubleshooting

### Pods not starting

```bash
kubectl describe pod <pod-name> -n food-delivery
kubectl logs <pod-name> -n food-delivery
```

### Connection issues

```bash
# Test connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  nc -zv mongodb.infrastructure.svc.cluster.local 27017
```

### Check resource usage

```bash
kubectl top nodes
kubectl top pods -n food-delivery
```

## 🔗 Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform AWS EKS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster)
- [ArgoCD Documentation](https://argoproj.github.io/argo-cd/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [ELK Stack](https://www.elastic.co/guide/)
- [Jaeger](https://www.jaegertracing.io/)

## Support

For issues:

1. Check logs: `kubectl logs <pod-name>`
2. Check events: `kubectl get events -n <namespace>`
3. Check monitoring: Visit Grafana dashboard
4. Review runbooks in documentation

## License

This infrastructure code is provided as-is for the Food Delivery Platform project.

## Contributing

To contribute:

1. Create a feature branch
2. Make changes
3. Test in dev/staging
4. Submit PR for production deployment
5. Use ArgoCD for GitOps workflow

---

**Created**: 2026
**Maintained by**: Surya Parua
**Last Updated**: 2026
