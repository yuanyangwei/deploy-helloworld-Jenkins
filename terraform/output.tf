output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.repo.repository_url
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "The name of the ECS service"
  value       = aws_ecs_service.main.name
}

# If you decide to add a Load Balancer later, you would add its DNS here
output "public_ip_warning" {
  description = "Reminder for Fargate public IP"
  value       = "Note: Service is running with a Public IP. In a full production setup, use an ALB."
}
