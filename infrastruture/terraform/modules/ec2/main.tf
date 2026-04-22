terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data source for latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for EC2 instances
resource "aws_iam_role" "kubernetes_node" {
  name_prefix = "${var.project_name}-k8s-node-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-k8s-node-role-${var.environment}"
    }
  )
}

# IAM Policy for EC2 instances
resource "aws_iam_role_policy" "kubernetes_node" {
  name_prefix = "${var.project_name}-k8s-node-policy-"
  role        = aws_iam_role.kubernetes_node.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeTags",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeInstanceAttribute"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags"
        ]
        Resource = [
          "arn:aws:ec2:*:*:instance/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "kubernetes_node" {
  name_prefix = "${var.project_name}-k8s-node-profile-"
  role        = aws_iam_role.kubernetes_node.name
}

# Master Nodes
resource "aws_instance" "master" {
  count                   = var.master_node_count
  ami                     = data.aws_ami.ubuntu.id
  instance_type           = var.master_instance_type
  iam_instance_profile    = aws_iam_instance_profile.kubernetes_node.name
  vpc_security_group_ids  = [var.master_security_group_id]
  subnet_id               = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  associate_public_ip_address = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.master_root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_type           = "gp3"
    volume_size           = var.master_data_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    role : "master",
    cluster_name : var.cluster_name,
    kubernetes_version : var.kubernetes_version
  }))

  monitoring = true

  tags = merge(
    var.common_tags,
    {
      Name                                           = "${var.project_name}-master-${count.index + 1}-${var.environment}"
      "kubernetes.io/cluster/${var.cluster_name}"  = "owned"
      "karpenter.sh/capacity-type"                 = "on-demand"
    }
  )

  depends_on = [aws_iam_instance_profile.kubernetes_node]
}

# Worker Nodes
resource "aws_instance" "worker" {
  count                  = var.worker_node_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.worker_instance_type
  iam_instance_profile   = aws_iam_instance_profile.kubernetes_node.name
  vpc_security_group_ids = [var.worker_security_group_id]
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.worker_root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_type           = "gp3"
    volume_size           = var.worker_data_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    role : "worker",
    cluster_name : var.cluster_name,
    kubernetes_version : var.kubernetes_version
  }))

  monitoring = true

  tags = merge(
    var.common_tags,
    {
      Name                                           = "${var.project_name}-worker-${count.index + 1}-${var.environment}"
      "kubernetes.io/cluster/${var.cluster_name}"  = "owned"
      "karpenter.sh/capacity-type"                 = "spot"
    }
  )

  depends_on = [aws_iam_instance_profile.kubernetes_node]
}

# Security group for SSH access (optional, for admin access)
resource "aws_security_group" "bastion" {
  count       = var.enable_bastion ? 1 : 0
  name_prefix = "${var.project_name}-bastion-sg-"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_allowed_cidrs
    description = "SSH from allowed CIDRs"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-bastion-sg-${var.environment}"
    }
  )
}
