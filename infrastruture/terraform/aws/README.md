# Terraform AWS EKS Setup

This directory contains Terraform code to deploy a production-ready EKS (Elastic Kubernetes Service) cluster on AWS.

## What Gets Deployed

### Network Infrastructure

- **VPC** with configurable CIDR block
- **Public Subnets** (3 across AZs) for NAT Gateways and Load Balancers
- **Private Subnets** (3 across AZs) for EKS nodes
- **Internet Gateway** for public internet access
- **NAT Gateways** (3) for private subnet outbound access
- **Route Tables** with proper routing

### EKS Cluster

- **EKS Control Plane** with encryption
- **Node Groups** with auto-scaling
- **EBS CSI Driver** add-on
- **VPC CNI** add-on for networking
- **CoreDNS** add-on for service discovery
- **kube-proxy** add-on

### Security Groups

- **Control Plane SG** - Only HTTPS from VPC
- **Node SG** - Internal communication, Ingress ports

### IAM

- **Cluster Role** with required policies
- **Node Role** with worker policies
- **IRSA** (IAM Roles for Service Accounts) support
- **EBS CSI Driver Role** for storage

## Prerequisites

```bash
# Install Terraform
curl https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Configure AWS credentials
aws configure

# Verify AWS access
aws ec2 describe-regions
```

## Configuration

### Create Backend for Terraform State

```bash
# Create S3 bucket
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

### Create terraform.tfvars

```bash
cat > terraform.tfvars << 'EOF'
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

## Deployment

### Step 1: Initialize Terraform

```bash
terraform init
```

This will:

- Download provider plugins
- Configure the S3 backend
- Create .terraform directory

### Step 2: Validate Configuration

```bash
terraform validate
terraform fmt -check
```

### Step 3: Plan Deployment

```bash
terraform plan -out=tfplan
```

Review the output to ensure all resources are correct.

### Step 4: Apply Configuration

```bash
terraform apply tfplan
```

This will take 15-20 minutes to complete.

### Step 5: Configure kubectl

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name food-delivery-prod

# Verify
kubectl cluster-info
kubectl get nodes
```

## Outputs

After deployment, Terraform outputs:

```bash
cluster_id = "food-delivery-prod"
cluster_arn = "arn:aws:eks:us-east-1:..."
cluster_endpoint = "https://..."
cluster_version = "1.28"
```

## Customization

### Change Cluster Size

Edit `terraform.tfvars`:

```hcl
desired_size = 5    # Increase desired nodes
max_size     = 15   # Increase max nodes
```

Then apply:

```bash
terraform apply
```

### Change Instance Types

Edit `terraform.tfvars`:

```hcl
instance_types = ["t3.xlarge", "t3.2xlarge"]
```

### Change Kubernetes Version

Edit `terraform.tfvars`:

```hcl
kubernetes_version = "1.29"
```

### Add Availability Zones

Edit `terraform.tfvars`:

```hcl
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
private_subnets    = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24", "10.0.14.0/24"]
```

## Maintenance

### Update Cluster

```bash
# Update Kubernetes version in terraform.tfvars
# Plan changes
terraform plan

# Apply
terraform apply
```

### Scale Nodes

```bash
# In terraform.tfvars
desired_size = 5

# Apply
terraform apply
```

### Add/Remove Subnets

```bash
# Modify availability_zones, public_subnets, private_subnets in terraform.tfvars
# Plan and apply
terraform plan
terraform apply
```

## Monitoring

### Check Cluster Status

```bash
# Cluster info
kubectl cluster-info

# Node status
kubectl get nodes
kubectl describe nodes

# Pod status
kubectl get pods -A
```

### CloudWatch Logs

```bash
# Enable cluster logging
aws eks describe-cluster --name food-delivery-prod --query 'cluster.logging'

# View logs in CloudWatch
aws logs describe-log-groups | grep food-delivery-prod
```

## Destroy

⚠️ **CAUTION**: This will delete all resources!

```bash
# List all resources
terraform state list

# Destroy
terraform destroy

# Confirm
# Type: yes
```

## Troubleshooting

### "Access Denied" Error

Verify AWS credentials:

```bash
aws sts get-caller-identity
```

Ensure user has necessary permissions:

- eks:\*
- ec2:\*
- iam:\*
- dynamodb:\*

### "Timeout" During Deployment

The EKS cluster can take 15-20 minutes to create. You can monitor progress in AWS Console:

- EC2 > Auto Scaling Groups
- CloudFormation
- EKS Clusters

### Cannot Reach Nodes

Check security groups:

```bash
aws ec2 describe-security-groups --filters Name=group-name,Values=food-delivery-prod-eks-nodes-sg
```

### Node Not Ready

Check node logs:

```bash
kubectl describe node <node-name>
kubectl logs <pod-name> -n kube-system
```

## Costs

**Estimated Monthly Costs** (us-east-1):

| Component         | Count  | Cost/month      |
| ----------------- | ------ | --------------- |
| EKS Control Plane | 1      | $73             |
| EC2 t3.large      | 3      | ~$200           |
| EBS Volumes       | 3x50GB | ~$30            |
| NAT Gateways      | 3      | ~$33            |
| Load Balancers    | 2-3    | ~$20            |
| **Total**         |        | **~$356/month** |

To reduce costs:

- Use spot instances for non-critical workloads
- Reduce desired node count
- Use smaller instance types
- Delete unused resources

## Security Best Practices

### Network Security

- ✅ Private subnets for nodes
- ✅ NAT Gateways for outbound
- ✅ Security groups restrict access
- ✅ Network ACLs configured

### Cluster Security

- ✅ RBAC enabled
- ✅ API server endpoint private
- ✅ Encryption at rest enabled
- ✅ IAM roles for service accounts

### Monitoring

- ✅ CloudWatch logs enabled
- ✅ CloudTrail audit logging
- ✅ VPC Flow Logs

## References

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

## Support

For issues:

1. Check AWS CloudFormation events
2. Review CloudWatch logs
3. Check IAM permissions
4. Review security groups

## License

This Terraform code is provided as-is.
