# Deployment Guide - Production Deployment

## Overview

This guide covers end-to-end deployment of the Food Delivery Platform to production environments on AWS EC2 with Kubernetes.

## Pre-Deployment Checklist

- [ ] AWS Account ready with appropriate permissions
- [ ] Terraform backend configured (S3 + DynamoDB)
- [ ] SSL/TLS certificate available (ACM)
- [ ] GitHub secrets configured
- [ ] Docker Hub credentials ready
- [ ] Ansible inventory updated with correct IPs
- [ ] SSH keys configured for EC2 access

## Phase 1: Infrastructure Deployment (Terraform)

### 1. Initialize Terraform Backend

```bash
# Create S3 state bucket
aws s3api create-bucket \
  --bucket food-delivery-terraform-state-prod \
  --region us-east-1

# Enable encryption & versioning
aws s3api put-bucket-encryption \
  --bucket food-delivery-terraform-state-prod \
  --server-side-encryption-configuration '{...}'

aws s3api put-bucket-versioning \
  --bucket food-delivery-terraform-state-prod \
  --versioning-configuration Status=Enabled

# Create DynamoDB for locks
aws dynamodb create-table \
  --table-name terraform-locks-prod \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```

### 2. Deploy Production Infrastructure

```bash
cd infrastruture/terraform/environments/prod

# Configure AWS credentials
export AWS_REGION=us-east-1
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret

# Initialize Terraform
terraform init

# Create tfvars file
cat > terraform.tfvars <<'EOF'
aws_region                = "us-east-1"
project_name              = "food-delivery"
certificate_arn           = "arn:aws:acm:us-east-1:123456789:certificate/abc123"
db_username               = "foodadmin"
db_password               = "SecurePassword123!@#"

# Production resource sizing
prod_master_node_count    = 3
prod_worker_node_count    = 5
prod_master_instance_type = "t3.xlarge"
prod_worker_instance_type = "t3.2xlarge"

prod_db_allocated_storage = 500
prod_db_instance_class    = "db.r5.xlarge"
prod_backup_retention_period = 30

prod_redis_node_type      = "cache.r5.large"
prod_redis_num_cache_nodes = 3
prod_redis_automatic_failover = true
EOF

# Plan deployment
terraform plan -out=tfplan

# Review and apply
terraform apply tfplan

# Save outputs
terraform output -json > infrastructure-output.json
```

### 3. Verify Infrastructure

```bash
# Check all resources created
terraform show | grep resource

# Get ALB endpoint
terraform output -json | jq '.cluster_info.value.alb_dns_name'

# Verify EC2 instances
aws ec2 describe-instances \
  --query 'Reservations[].Instances[?Tags[?Key==`Project`].Value==`food-delivery`].[InstanceId,PrivateIpAddress,State.Name]' \
  --output table

# Check RDS status
aws rds describe-db-instances \
  --query 'DBInstances[?DBInstanceIdentifier==`food-delivery-db-prod`].[DBInstanceStatus,Engine,DBInstanceClass]' \
  --output table

# Check ElastiCache
aws elasticache describe-cache-clusters \
  --query 'CacheClusters[?CacheClusterId==`food-delivery-redis-prod`].[CacheClusterStatus,CacheNodeType]' \
  --output table
```

## Phase 2: Kubernetes Cluster Bootstrap (Ansible)

### 1. Update Ansible Inventory

```bash
# Get EC2 private IPs from Terraform
terraform output -json | jq '.cluster_info.value | {masters: .master_private_ips, workers: .worker_private_ips}'

# Update inventory with actual IPs
cd infrastruture/ansible
nano inventory/prod.ini
```

### 2. Configure SSH Access

```bash
# Setup SSH key
chmod 600 ~/.ssh/kubernetes-key.pem

# Test SSH connectivity
for master in 10.2.10.1 10.2.11.1 10.2.12.1; do
  ssh -i ~/.ssh/kubernetes-key.pem ubuntu@$master "echo 'SSH OK: $master'"
done

for worker in 10.2.10.2 10.2.11.2 10.2.12.2; do
  ssh -i ~/.ssh/kubernetes-key.pem ubuntu@$worker "echo 'SSH OK: $worker'"
done
```

### 3. Run Ansible Playbook

```bash
cd infrastruture/ansible

# Dry run first
ansible-playbook -i inventory/prod.ini playbooks/setup-kubernetes-cluster.yml --check

# Full deployment
ansible-playbook -i inventory/prod.ini playbooks/setup-kubernetes-cluster.yml -v

# Follow logs
tail -f /var/log/ansible.log
```

### 4. Verify Kubernetes Cluster

```bash
# SSH into master node
ssh -i ~/.ssh/kubernetes-key.pem ubuntu@10.2.10.1

# Check cluster status
kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods -A

# Verify network
kubectl run test-pod --image=busybox --rm -it -- ping kubernetes.default
```

## Phase 3: Service Mesh & Observability Setup

### 1. Deploy Istio

```bash
# SSH into master
ssh -i ~/.ssh/kubernetes-key.pem ubuntu@10.2.10.1

# Copy KUBECONFIG
export KUBECONFIG=/etc/kubernetes/admin.conf

# Install Istio
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.18.0 sh -
cd istio-1.18.0
./bin/istioctl install --set profile=production

# Verify
kubectl get pods -n istio-system
kubectl get svc -n istio-system
```

### 2. Deploy OpenTelemetry

```bash
# Create observability namespace
kubectl create namespace observability

# Deploy OpenTelemetry Collector
kubectl apply -f /home/ubuntu/food-delivery-platform/infrastruture/k8s/observability/

# Verify
kubectl get pods -n observability
kubectl get svc -n observability
```

### 3. Deploy Monitoring Stack

```bash
# Add Helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus Stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  --set prometheus.prometheusSpec.storageSpec.accessModes[0]=ReadWriteOnce \
  --set prometheus.prometheusSpec.storageSpec.resources.requests.storage=10Gi

# Verify
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

## Phase 4: Application Deployment

### 1. Create Namespaces

```bash
kubectl create namespace production
kubectl label namespace production istio-injection=enabled
```

### 2. Create Secrets

```bash
# Database credentials
kubectl create secret generic db-credentials \
  --from-literal=username=foodadmin \
  --from-literal=password=SecurePassword123!@# \
  -n production

# Registry credentials
kubectl create secret docker-registry dockerhub \
  --docker-server=docker.io \
  --docker-username=DOCKERHUB_USERNAME \
  --docker-password=DOCKERHUB_TOKEN \
  -n production
```

### 3. Deploy Applications

```bash
# Apply service definitions
kubectl apply -f infrastruture/k8s/services/ -n production

# Apply Istio configs
kubectl apply -f infrastruture/k8s/istio/ -n production

# Verify deployments
kubectl get deployments -n production
kubectl get pods -n production
```

### 4. Configure Ingress

```bash
# Create TLS secret
kubectl create secret tls food-delivery-tls \
  --cert=path/to/cert.pem \
  --key=path/to/key.pem \
  -n istio-system

# Apply Gateway config
kubectl apply -f infrastruture/k8s/istio/gateway.yaml

# Verify
kubectl get gateway -n istio-system
kubectl get virtualservices -n production
```

## Phase 5: Verification & Testing

### 1. Health Checks

```bash
# Pod health
kubectl get pods -n production -o wide
kubectl describe pod POD_NAME -n production

# Service connectivity
kubectl get svc -n production
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  wget -O- http://restaurant-service:3000/health

# Database connectivity
psql -h RDS_ENDPOINT -U foodadmin -d fooddelivery \
  -c "SELECT version();"

# Redis connectivity
redis-cli -h REDIS_ENDPOINT ping
```

### 2. Smoke Tests

```bash
# Test API endpoints through ALB
curl -k https://ALB_ENDPOINT/health
curl -k https://ALB_ENDPOINT/api/v1/restaurants
curl -k https://ALB_ENDPOINT/api/v1/riders

# Check response times
ab -n 100 -c 10 https://ALB_ENDPOINT/api/v1/restaurants

# Check SSL/TLS
openssl s_client -connect ALB_ENDPOINT:443
```

### 3. Monitoring & Logs

```bash
# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Open http://localhost:3000 (admin/admin)

# Access Jaeger
kubectl port-forward -n observability svc/jaeger 16686:16686
# Open http://localhost:16686

# View application logs
kubectl logs -f deployment/restaurant-service -n production
kubectl logs -f deployment/rider-service -n production
kubectl logs -f deployment/order-service -n production
```

## Phase 6: Post-Deployment

### 1. Update DNS

```bash
# Point your domain to ALB
ALB_DNS=$(terraform output -json | jq -r '.cluster_info.value.alb_dns_name')

# Update Route53 (if using AWS Route53)
aws route53 change-resource-record-sets \
  --hosted-zone-id ZONE_ID \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "food-delivery.example.com",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [{"Value": "'$ALB_DNS'"}]
      }
    }]
  }'
```

### 2. Enable Auto-Scaling

```bash
# Apply HPA
kubectl apply -f infrastruture/k8s/base/services/hpa.yaml

# Verify HPA
kubectl get hpa -n production
kubectl describe hpa restaurant-service-hpa -n production
```

### 3. Setup Backup

```bash
# Database backup
aws rds create-db-snapshot \
  --db-instance-identifier food-delivery-db-prod \
  --db-snapshot-identifier food-delivery-db-backup-$(date +%Y%m%d)

# Enable automated backups (already done in Terraform)
# Verify
aws rds describe-db-instances \
  --db-instance-identifier food-delivery-db-prod \
  --query 'DBInstances[0].BackupRetentionPeriod'
```

### 4. Documentation Update

- Update deployment runbook with actual URLs/IPs
- Document emergency procedures
- Create operational dashboards
- Setup alerting rules

## Rollback Procedures

### If Deployment Fails

```bash
# Check rollout history
kubectl rollout history deployment/restaurant-service -n production

# Rollback to previous version
kubectl rollout undo deployment/restaurant-service -n production

# Check status
kubectl rollout status deployment/restaurant-service -n production
```

### If Infrastructure Deployment Fails

```bash
cd infrastruture/terraform/environments/prod

# Check state
terraform state list
terraform show

# Destroy problematic resources
terraform destroy -target=module.ec2.aws_instance.worker[0]

# Re-apply
terraform apply
```

## Maintenance Schedule

- **Daily**: Monitor dashboards, check logs
- **Weekly**: Review performance metrics, test backups
- **Monthly**: Security patches, dependency updates
- **Quarterly**: Disaster recovery drills, capacity planning

## Support Contacts

- **Infrastructure Team**: infrastructure@example.com
- **DevOps Team**: devops@example.com
- **Emergency**: on-call@example.com

---

_Last Updated: 2024_
_Maintained by: Infrastructure Team_
