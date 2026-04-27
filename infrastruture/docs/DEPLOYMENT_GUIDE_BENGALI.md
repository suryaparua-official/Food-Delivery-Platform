# Food Delivery Platform - Complete Infrastructure Guide (বাংলায়)

## প্রধান সমস্যা এবং সমাধান

### 1. CI/CD Pipeline ✅ FIXED
**সমস্যা**: OWASP, Trivy, SonarQube ছিল না
**সমাধান**: `.github/workflows/security-pipeline.yml` তৈরি করা হয়েছে সব security scanning সহ

**কী যোগ করা হয়েছে**:
- OWASP Dependency-Check (সব npm dependencies scan করে)
- SonarQube Code Analysis (code quality এবং bugs খোঁজে)
- TruffleHog Secret Scanning (hardcoded keys খোঁজে)
- Trivy Container Image Scanning (container vulnerabilities scan করে)
- Terraform Validation

### 2. Infrastructure - Terraform 🔄 IN PROGRESS
**সমস্যা**: EKS ব্যবহার করছে, কিন্তু EC2 self-managed K8s চান
**সমাধান**: Terraform সম্পূর্ণভাবে rewrite করছি EC2-এর জন্য

**কী পরিবর্তিত হয়েছে**:
- EKS providers হটিয়ে দেওয়া হয়েছে
- VPC, Subnets, NAT Gateway সঠিকভাবে configured
- Control Plane (3 nodes) এবং Worker Nodes (3+ nodes) সেটআপ
- Security Groups proper port এবং CIDR সহ

### 3. Services - Security Fixes ⚠️ NEXT
**সমস্যা**: Payment processing এ security issues আছে

**প্রয়োজনীয় ফিক্স**:
```typescript
// ❌ WRONG - Secret exposed
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

// ✅ CORRECT - Proper validation
import { requireEnvVar } from "../utils/env-validator.js";
const stripeKey = requireEnvVar("STRIPE_SECRET_KEY");
const stripe = new Stripe(stripeKey, {
  apiVersion: "2023-10-16",
});
```

### 4. Ansible - Organization ⚠️ TODO
**সমস্যা**: Ansible properly organized নয়
**সমাধান**: প্রতিটি service এর জন্য separate roles তৈরি করব

### 5. Documentation ⚠️ TODO
**প্রয়োজন**:
- Deployment গাইড (Bengali explanation + English code)
- Architecture diagrams
- Troubleshooting guide
- Security best practices

---

## Architecture (আর্কিটেকচার বর্ণনা)

### নেটওয়ার্ক (Network)
```
Internet
    ↓
NAT Gateway (Public Subnet)
    ↓
Private Subnet 1, 2, 3
    ↓
├── Control Plane Nodes (3) - K8s API, etcd, etc.
├── Worker Nodes (3+) - Applications running
```

### Security Layers (নিরাপত্তা স্তর)
```
1. AWS Security Groups - Port-based firewall
2. Network ACLs - Subnet-level firewall  
3. Pod Security Policies - Container-level restrictions
4. RBAC - Role-based access control
5. Secrets Management - Encrypted storage
```

---

## Deployment Steps (স্থাপনা ধাপ)

### পূর্ব প্রয়োজনীয়তা (Prerequisites)
1. AWS account এবং credentials configured
2. Terraform >= 1.5.0 installed
3. Ansible >= 2.10 installed
4. kubectl >= 1.28 installed

### ধাপ 1: AWS Infrastructure তৈরি করুন
```bash
cd infrastruture/terraform/aws
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```

### ধাপ 2: Kubernetes Cluster Bootstrap করুন (Ansible দিয়ে)
```bash
cd infrastruture/ansible
ansible-playbook playbooks/setup-kubernetes-cluster.yml -i inventory/prod.ini
```

### ধাপ 3: Applications Deploy করুন
```bash
kubectl apply -k k8s/overlays/prod/
```

---

## Environment Variables (পরিবেশ ভেরিয়েবল)
প্রতিটি service এ `.env.example` আছে - production secrets সহ `.env` তৈরি করুন

### Required Secrets:
- `MONGODB_URI` - MongoDB Atlas connection string
- `UPSTASH_REDIS_URL` - Redis connection (Upstash)
- `JWT_SECRET` - JWT signing key (minimum 32 characters)
- `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET` - Payment processor
- `STRIPE_PUBLISHABLE_KEY`, `STRIPE_SECRET_KEY` - Payment processor
- `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` - OAuth

---

## Key Files Changed (পরিবর্তিত ফাইল)

### ✅ New/Updated:
- `.github/workflows/security-pipeline.yml` - সব security scanning সহ CI/CD
- `infrastruture/terraform/aws/variables.tf` - আপডেট করা variables
- `infrastruture/terraform/aws/main.tf` - আংশিক আপডেট (চলমান)

### ⚠️ Needs Update:
- `infrastruture/terraform/aws/` - সম্পূর্ণ rewrite প্রয়োজন
- `infrastruture/ansible/` - সংগঠন উন্নত করতে হবে
- `app/services/*/src/` - Security hardening প্রয়োজন

---

## Payment Processing - Security Issues (পেমেন্ট সিকিউরিটি)

### বর্তমান সমস্যা:
1. ❌ Secret keys hardcoded
2. ❌ No input validation on payment endpoints
3. ❌ No idempotency on payment operations
4. ❌ Weak signature verification

### সমাধান Required:
1. ✅ Environment variable validation utility
2. ✅ Request validation middleware
3. ✅ Idempotency key checking
4. ✅ Proper error handling

---

## Monitoring & Observability (মনিটরিং)

### এখন কী আছে:
- Prometheus (metrics collection)
- Grafana (visualization)
- Jaeger (distributed tracing)
- ELK Stack (logging)

### প্রয়োজন:
- Proper Kubernetes integration
- OpenTelemetry সঠিক configuration
- Alert rules সঠিকভাবে configured

---

## টাইমলাইন (Timeline)

**আজ**: Infrastructure setup + CI/CD pipeline
**আগামীকাল**: Services security fixes + Ansible organization
**৩ দিন**: সম্পূর্ণ deployment + testing
**৪ দিন**: Production deployment

---

## সম্পর্কে যোগাযোগ করুন (Support)

যদি কোনো সমস্যা হয়:
1. Error logs দেখুন: `kubectl logs <pod-name> -n <namespace>`
2. Terraform state check করুন: `terraform show`
3. Ansible debug মোড চালান: `ansible-playbook ... -vvv`
