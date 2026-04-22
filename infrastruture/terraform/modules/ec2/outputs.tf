output "master_instance_ids" {
  description = "Master node instance IDs"
  value       = aws_instance.master[*].id
}

output "master_private_ips" {
  description = "Master node private IPs"
  value       = aws_instance.master[*].private_ip
}

output "worker_instance_ids" {
  description = "Worker node instance IDs"
  value       = aws_instance.worker[*].id
}

output "worker_private_ips" {
  description = "Worker node private IPs"
  value       = aws_instance.worker[*].private_ip
}

output "iam_role_arn" {
  description = "IAM role ARN for Kubernetes nodes"
  value       = aws_iam_role.kubernetes_node.arn
}

output "bastion_security_group_id" {
  description = "Bastion security group ID"
  value       = try(aws_security_group.bastion[0].id, null)
}
