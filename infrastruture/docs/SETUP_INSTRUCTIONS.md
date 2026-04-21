# Infrastructure Setup Instructions

## Quick Start

### Prerequisites Setup (5 minutes)

```bash
# 1. Install required tools
brew install awscli terraform kubectl kustomize  # macOS
# or apt-get for Linux, or Download binaries for Windows

# 2. Configure AWS credentials
aws configure
# Enter your AWS Access Key ID, Secret Access Key, default region (us-east-1)

# 3. Clone/prepare the repository
cd food-delivery-k8s
```

### Deploy EKS Cluster (15-20 minutes)

```bash
cd terraform/aws

# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Deploy
terraform apply
# This creates: VPC, Subnets, EKS Cluster, Node Groups, etc.

# Get kubeconfig
aws eks update-kubeconfig --region us-east-1 --name food-delivery-prod

# Verify cluster
kubectl cluster-info
kubectl get nodes
```

### Deploy Applications (10-15 minutes)

```bash
# 1. Install NGINX Ingress (required for Ingress resources)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace

# 2. Install Cert-Manager (required for SSL/TLS)
helm repo add jetstack https://charts.jetstack.io
helm repo update
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.crds.yaml
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace

# 3. Push Docker images to ECR
# First, build and push your images to AWS ECR
# Then update the image registry in k8s/overlays/prod/kustomization.yaml

# 4. Deploy with Kustomize
kubectl apply -k k8s/overlays/prod

# 5. Verify deployments
kubectl get pods -n food-delivery
kubectl get svc -n food-delivery
```

### Install ArgoCD (5 minutes)

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for it to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
# Visit https://localhost:8080

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Deploy applications via ArgoCD
kubectl apply -f argocd/applications.yaml
```

---

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Cloud                                │
├─────────────────────────────────────────────────────────────┤
│  VPC (10.0.0.0/16)                                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  EKS Cluster (food-delivery-prod)                   │   │
│  │                                                      │   │
│  │  Namespaces:                                        │   │
│  │  ├─ food-delivery (6 services + frontend + gateway) │   │
│  │  ├─ infrastructure (RabbitMQ, MongoDB, Redis)       │   │
│  │  ├─ monitoring (Prometheus, Grafana)                │   │
│  │  ├─ observability (ELK Stack, Jaeger)               │   │
│  │  └─ argocd (GitOps deployment)                      │   │
│  │                                                      │   │
│  │  Load Balancers (AWS NLB):                          │   │
│  │  ├─ API Gateway (8081)                              │   │
│  │  ├─ Frontend (3000)                                 │   │
│  │  ├─ Grafana (3000)                                  │   │
│  │  ├─ Kibana (5601)                                   │   │
│  │  └─ Jaeger (16686)                                  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Components

### Services Deployed

| Service     | Port | Replicas | Resources  | HA  |
| ----------- | ---- | -------- | ---------- | --- |
| Auth        | 5000 | 3 (prod) | 500m/1Gi   | Yes |
| Restaurant  | 5001 | 3 (prod) | 500m/1Gi   | Yes |
| Utils       | 5002 | 3 (prod) | 500m/1Gi   | Yes |
| Realtime    | 5004 | 3 (prod) | 500m/1Gi   | Yes |
| Rider       | 5005 | 3 (prod) | 500m/1Gi   | Yes |
| Admin       | 5006 | 2 (prod) | 500m/1Gi   | Yes |
| Frontend    | 3000 | 3 (prod) | 250m/512Mi | Yes |
| API Gateway | 8081 | 3 (prod) | 250m/256Mi | Yes |

### Infrastructure Components

| Component | Type        | Replicas | Storage   |
| --------- | ----------- | -------- | --------- |
| MongoDB   | StatefulSet | 3        | 20Gi each |
| RabbitMQ  | StatefulSet | 3        | 10Gi each |
| Redis     | Deployment  | 1        | ephemeral |

### Monitoring Stack

| Component     | Port       | Type         |
| ------------- | ---------- | ------------ |
| Prometheus    | 9090       | ClusterIP    |
| Grafana       | 3000       | LoadBalancer |
| Elasticsearch | 9200       | ClusterIP    |
| Logstash      | 5000, 8080 | ClusterIP    |
| Kibana        | 5601       | LoadBalancer |
| Jaeger        | 16686      | LoadBalancer |

---

## Environment-Specific Deployment

### Development

```bash
kubectl apply -k k8s/overlays/dev
# Minimal resources, 1 replica each, no monitoring
```

### Staging

```bash
kubectl apply -k k8s/overlays/staging
# Medium resources, 2 replicas, minimal monitoring
```

### Production

```bash
kubectl apply -k k8s/overlays/prod
# Full resources, 3 replicas, full monitoring, auto-scaling
```

---

## Important Configurations

### Update Docker Registry

Edit `k8s/overlays/prod/kustomization.yaml`:

```yaml
images:
  - name: YOUR_ECR_REGISTRY/auth-service
    newTag: v1.0.0
  # Update for all services
```

### Configure Secrets

```bash
# Update database connection
kubectl patch secret mongodb-connection -n food-delivery \
  --type merge -p '{"data":{"uri":"YOUR_MONGODB_URI_BASE64"}}'

# Update RabbitMQ connection
kubectl patch secret rabbitmq-connection -n food-delivery \
  --type merge -p '{"data":{"uri":"YOUR_RABBITMQ_URI_BASE64"}}'

# Update auth secrets
kubectl patch secret auth-secrets -n food-delivery \
  --type merge -p '{"data":{"jwt-secret":"YOUR_JWT_SECRET_BASE64"}}'

# Update payment secrets
kubectl patch secret payment-secrets -n food-delivery \
  --type merge -p '{"data":{"razorpay-key-id":"YOUR_KEY_BASE64"}}'
```

### Ingress Configuration

Update domain names in `k8s/base/infrastructure/ingress.yaml`:

```yaml
spec:
  tls:
    - hosts:
        - api.YOUR_DOMAIN.com
        - YOUR_DOMAIN.com
      secretName: food-delivery-tls
```

---

## Networking & Security

### Network Policies

- Deny all by default
- Allow traffic within namespace
- Allow traffic from Ingress
- Allow traffic from monitoring
- Allow DNS queries

### RBAC

- Service account per namespace
- Role-based access control
- Pod security policies enforced

### Security Groups

- Control Plane: Only HTTPS from VPC
- Nodes: Allow communication between nodes
- Egress: All outbound allowed

---

## Monitoring Access

```bash
# Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# http://localhost:9090

# Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000
# http://localhost:3000 (admin/admin@123)

# Elasticsearch
kubectl port-forward -n observability svc/elasticsearch 9200:9200
# http://localhost:9200

# Kibana
kubectl port-forward -n observability svc/kibana 5601:5601
# http://localhost:5601

# Jaeger
kubectl port-forward -n observability svc/jaeger 16686:16686
# http://localhost:16686

# RabbitMQ Management
kubectl port-forward -n infrastructure svc/rabbitmq-management 15672:15672
# http://localhost:15672 (admin/admin@123)

# MongoDB
kubectl port-forward -n infrastructure svc/mongodb 27017:27017
# mongodb://admin:password@localhost:27017/admin
```

---

## Useful Commands

```bash
# Get cluster info
kubectl cluster-info
kubectl get nodes
kubectl describe nodes

# Get resources
kubectl get pods -n food-delivery
kubectl get svc -n food-delivery
kubectl get ingress -n food-delivery

# Check logs
kubectl logs -f deployment/auth-service -n food-delivery
kubectl logs -f statefulset/mongodb -n infrastructure

# Port forwarding
kubectl port-forward svc/SERVICE_NAME PORT:PORT -n NAMESPACE

# Debugging
kubectl describe pod POD_NAME -n food-delivery
kubectl exec -it POD_NAME -n food-delivery -- /bin/sh
kubectl events -n food-delivery --sort-by='.lastTimestamp'

# Scaling
kubectl scale deployment auth-service --replicas=5 -n food-delivery
kubectl autoscale deployment auth-service --min=2 --max=10 -n food-delivery

# Apply configurations
kubectl apply -k k8s/overlays/prod
kustomize build k8s/overlays/prod | kubectl apply -f -

# ArgoCD
argocd app list
argocd app sync APPNAME
argocd app history APPNAME
```

---

## Troubleshooting Quick Reference

| Issue              | Command                                                            |
| ------------------ | ------------------------------------------------------------------ |
| Pod won't start    | `kubectl describe pod POD_NAME -n NS`                              |
| Connection refused | `kubectl logs POD_NAME -n NS`                                      |
| Out of memory      | `kubectl top pods -n NS`                                           |
| Database down      | `kubectl get statefulset -n infrastructure`                        |
| Network issue      | `kubectl run -it --rm debug --image=busybox --restart=Never -- sh` |

---

## Cost Optimization Tips

1. Use spot instances for non-critical workloads
2. Set resource limits to avoid waste
3. Use auto-scaling based on metrics
4. Delete unused resources regularly
5. Monitor AWS costs via CloudWatch

---

## Next Steps

1. **Build and push images** to ECR
2. **Update secrets** with real values
3. **Configure DNS** to point to LoadBalancer IPs
4. **Set up alerts** in Grafana/Prometheus
5. **Configure backup** for stateful resources
6. **Test disaster recovery** procedures
7. **Document runbooks** for operations team
