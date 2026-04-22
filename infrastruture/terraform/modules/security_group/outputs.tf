output "master_security_group_id" {
  description = "Master node security group ID"
  value       = aws_security_group.master.id
}

output "worker_security_group_id" {
  description = "Worker node security group ID"
  value       = aws_security_group.worker.id
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

output "elasticache_security_group_id" {
  description = "ElastiCache security group ID"
  value       = aws_security_group.elasticache.id
}
