# Food Delivery K8s Production Deployment Guide

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Terraform Setup (EKS)](#terraform-setup)
4. [Kubernetes Deployment](#kubernetes-deployment)
5. [ArgoCD Setup](#argocd-setup)
6. [Monitoring & Observability](#monitoring--observability)
7. [Production Checklist](#production-checklist)
8. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### System Components

**Frontend & API Gateway:**

- React frontend (port 3000)
- Nginx API Gateway (port 8081) with load balancing

**Microservices (Node.js/Express):**

- Auth Service (5000) - User authentication & Google OAuth
- Restaurant Service (5001) - Menu, orders, cart management
- Utils Service (5002) - Payments (Razorpay, Stripe), Cloudinary uploads
- Realtime Service (5004) - WebSocket for real-time updates
- Rider Service (5005) - Rider management & GPS tracking
- Admin Service (5006) - Admin operations

**Data Layer:**

- MongoDB (StatefulSet, 3 replicas) - Primary data store
- RabbitMQ (StatefulSet, 3 replicas) - Message queue
- Redis (Deployment) - Caching & sessions

**Monitoring & Observability:**

- Prometheus - Metrics collection
- Grafana - Visualization
- ELK Stack - Log aggregation (Elasticsearch, Logstash, Kibana)
- Jaeger - Distributed tracing
- OpenTelemetry - Instrumentation

**GitOps:**

- ArgoCD - Continuous deployment

---

## Prerequisites

### Local Tools Required

```bash
# AWS CLI
aws --version

# Terraform
terraform version

# kubectl
kubectl version --client

# kustomize
kustomize version

# Helm (optional, for ArgoCD)
helm version
```

### AWS Requirements

1. AWS Account with appropriate permissions
2. VPC with internet access
3. S3 bucket for Terraform state
4. DynamoDB table for Terraform locks
5. ECR registry for container images

### Infrastructure Sizing

**Recommended for Production:**

- EKS Cluster: 3+ nodes (t3.large minimum)
- Node Type: EC2 t3.large or larger
- Storage: 30GB+ per MongoDB/Elasticsearch PV
- RabbitMQ: 3 replicas for HA
- PostgreSQL/MongoDB: 3 replicas for HA

---

## Terraform Setup

### Step 1: Initialize S3 Backend

```bash
cd terraform/aws

# Create S3 bucket for state
aws s3api create-bucket \
  --bucket food-delivery-tf-state \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket food-delivery-tf-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for locks
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```

### Step 2: Configure Terraform Variables

```bash
# Create terraform.tfvars
cat > terraform/aws/terraform.tfvars << EOF
aws_region           = "us-east-1"
cluster_name         = "food-delivery-prod"
environment          = "production"
kubernetes_version   = "1.28"
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnets       = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnets      = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
desired_size         = 3
min_size             = 3
max_size             = 10
instance_types       = ["t3.large"]
disk_size            = 50
EOF
```

### Step 3: Deploy EKS Cluster

```bash
# Initialize Terraform
terraform init

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Get kubeconfig
aws eks update-kubeconfig \
  --region us-east-1 \
  --name food-delivery-prod

# Verify cluster
kubectl get nodes
```

---

## Kubernetes Deployment

### Step 1: Install NGINX Ingress Controller

```bash
# Add Helm repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --values - <<EOF
controller:
  replicas: 3
  resources:
    requests:
      cpu: 200m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi
  service:
    type: LoadBalancer
EOF
```

### Step 2: Install Cert-Manager

```bash
# Add Helm repo
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Install CRDs
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.crds.yaml

# Install cert-manager
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace
```

### Step 3: Build and Push Docker Images

```bash
# Set ECR registry
ECR_REGISTRY="YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com"

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY

# Build and push each service
for service in auth-service restaurant-service utils-service realtime-service rider-service admin-service frontend; do
  cd ../Food-Delivery-Platform/backend/$service
  docker build -t $ECR_REGISTRY/$service:v1.0.0 .
  docker push $ECR_REGISTRY/$service:v1.0.0
  cd -
done
```

### Step 4: Update Image Registry in Kustomize

Edit `k8s/overlays/prod/kustomization.yaml`:

```yaml
images:
  - name: YOUR_ECR_REGISTRY/auth-service
    newTag: v1.0.0
  # ... update for all services
```

### Step 5: Deploy with Kustomize

```bash
# Deploy production environment
kustomize build k8s/overlays/prod | kubectl apply -f -

# Or deploy with kubectl + kustomize
kubectl apply -k k8s/overlays/prod

# Verify deployments
kubectl get deployments -n food-delivery
kubectl get pods -n food-delivery
kubectl logs -n food-delivery deployment/auth-service
```

### Step 6: Configure Secrets

```bash
# Update secrets with actual values
kubectl patch secret mongodb-connection -n food-delivery -p \
  '{"data":{"uri":"'"$(echo -n 'mongodb://...' | base64)"'"}}'

kubectl patch secret rabbitmq-connection -n food-delivery -p \
  '{"data":{"uri":"'"$(echo -n 'amqp://...' | base64)"'"}}'

kubectl patch secret auth-secrets -n food-delivery -p \
  '{"data":{"jwt-secret":"'"$(echo -n 'your-secret' | base64)"'"}}'

kubectl patch secret payment-secrets -n food-delivery -p \
  '{"data":{"razorpay-key-id":"'"$(echo -n 'key' | base64)"'"}}'
```

---

## ArgoCD Setup

### Step 1: Install ArgoCD

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for deployment
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Step 2: Connect Git Repository

```bash
# Get ArgoCD CLI
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd

# Login to ArgoCD
argocd login localhost:8080 --insecure

# Add Git repository
argocd repo add https://github.com/YOUR_USERNAME/food-delivery-k8s \
  --username YOUR_USERNAME \
  --password YOUR_TOKEN \
  --insecure-skip-server-verification
```

### Step 3: Deploy Applications via ArgoCD

```bash
# Apply ArgoCD applications
kubectl apply -f argocd/applications.yaml

# Monitor sync status
argocd app list
argocd app sync food-delivery-app
argocd app sync monitoring-stack
argocd app sync observability-stack
argocd app sync infrastructure-stack
```

---

## Monitoring & Observability

### Prometheus

**Access:**

```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Visit: http://localhost:9090
```

**Key Metrics:**

- `container_memory_usage_bytes` - Memory usage
- `rate(container_cpu_usage_seconds_total[5m])` - CPU usage
- `http_request_duration_seconds` - API latency
- `http_requests_total` - Request count

### Grafana

**Access:**

```bash
kubectl port-forward -n monitoring svc/grafana 3000:3000
# Username: admin
# Password: admin@123
# Visit: http://localhost:3000
```

**Dashboards to Create:**

1. Kubernetes Cluster Monitoring
2. Application Performance
3. Infrastructure Health
4. Business Metrics

### ELK Stack

**Access Kibana:**

```bash
kubectl port-forward -n observability svc/kibana 5601:5601
# Visit: http://localhost:5601
```

**Configure Index Patterns:**

1. logs-\* (time series)
2. View dashboards and create alerts

### Jaeger

**Access:**

```bash
kubectl port-forward -n observability svc/jaeger 16686:16686
# Visit: http://localhost:16686
```

**Instrumentation:**
Add to your Node.js services:

```javascript
const jaeger = require("jaeger-client");
const initTracer = require("jaeger-client").initTracer;

const initJaegerTracer = (serviceName) => {
  return initTracer({
    serviceName,
    sampler: {
      type: "const",
      param: 1,
    },
    reporter: {
      logSpans: true,
      agentHost: "jaeger-agent.observability.svc.cluster.local",
      agentPort: 6831,
    },
  });
};
```

---

## Production Checklist

- [ ] **Networking**
  - [ ] VPC configured with public/private subnets
  - [ ] NAT Gateway for private subnet egress
  - [ ] Network policies applied
  - [ ] Ingress controller running
  - [ ] SSL/TLS certificates configured

- [ ] **Security**
  - [ ] RBAC roles configured
  - [ ] Pod Security Policies enabled
  - [ ] Network policies enforced
  - [ ] Secrets encrypted at rest
  - [ ] Regular security scans
  - [ ] Audit logging enabled

- [ ] **Monitoring & Observability**
  - [ ] Prometheus scraping metrics
  - [ ] Grafana dashboards created
  - [ ] ELK stack collecting logs
  - [ ] Jaeger tracing enabled
  - [ ] Alerts configured in Prometheus
  - [ ] Alertmanager routing configured

- [ ] **High Availability**
  - [ ] Multiple replicas for all services
  - [ ] Pod disruption budgets set
  - [ ] Database replication enabled
  - [ ] RabbitMQ clustering configured
  - [ ] Auto-scaling policies defined

- [ ] **Backup & Disaster Recovery**
  - [ ] Database backups configured
  - [ ] Backup retention policy set
  - [ ] Disaster recovery tested
  - [ ] RTO/RPO targets defined

- [ ] **Performance**
  - [ ] HPA (Horizontal Pod Autoscaler) configured
  - [ ] Resource limits set
  - [ ] Caching enabled
  - [ ] CDN configured for frontend

- [ ] **Deployment**
  - [ ] GitOps workflow with ArgoCD
  - [ ] Blue-green or canary deployments configured
  - [ ] Automated rollbacks enabled

- [ ] **Documentation**
  - [ ] Runbooks created
  - [ ] On-call procedures documented
  - [ ] Architecture diagrams maintained

---

## Troubleshooting

### Common Issues & Solutions

#### Pods not starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n food-delivery

# Check logs
kubectl logs <pod-name> -n food-delivery
kubectl logs <pod-name> -n food-delivery --previous

# Check events
kubectl get events -n food-delivery --sort-by='.lastTimestamp'
```

#### Database connection issues

```bash
# Test connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  nc -zv mongodb.infrastructure.svc.cluster.local 27017

# Check MongoDB service
kubectl get svc -n infrastructure
kubectl get pods -n infrastructure
```

#### RabbitMQ queue issues

```bash
# Port forward to management UI
kubectl port-forward -n infrastructure svc/rabbitmq-management 15672:15672

# Check RabbitMQ logs
kubectl logs -n infrastructure statefulset/rabbitmq
```

#### High memory/CPU usage

```bash
# Check resource usage
kubectl top nodes
kubectl top pods -n food-delivery

# Update resource limits in kustomize patches
# Edit k8s/overlays/prod/deployment-resources-prod.yaml
kubectl apply -k k8s/overlays/prod
```

#### Network Policy issues

```bash
# Check network policies
kubectl get networkpolicy -n food-delivery

# Test connectivity between pods
kubectl exec -it <pod-name> -n food-delivery -- sh
# Inside pod: wget http://auth-service:5000/health
```

---

## Maintenance

### Regular Tasks

**Daily:**

- Check pod health: `kubectl get pods -n food-delivery`
- Monitor error rates in Grafana
- Review Jaeger traces for anomalies

**Weekly:**

- Review resource utilization
- Check backup status
- Review security logs

**Monthly:**

- Patch Kubernetes nodes
- Update dependencies
- Review and rotate secrets
- Capacity planning

### Scaling

```bash
# Manual scaling
kubectl scale deployment auth-service -n food-delivery --replicas=5

# Horizontal Pod Autoscaler
kubectl autoscale deployment auth-service -n food-delivery --min=2 --max=10

# Cluster autoscaling (via Terraform)
# Update min_size, max_size, desired_size in terraform.tfvars
```

---

## Support & Resources

- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **ArgoCD Documentation**: https://argoproj.github.io/argo-cd/
- **Prometheus Documentation**: https://prometheus.io/docs/
- **ELK Stack**: https://www.elastic.co/guide/
- **Jaeger Documentation**: https://www.jaegertracing.io/docs/

---

## Contact & Support

For issues or questions:

1. Check logs: `kubectl logs`
2. Check events: `kubectl get events`
3. Review monitoring dashboards
4. Consult runbooks
5. Escalate to SRE team
