output "ecs_cluster_id" {
  description = "ECS Cluster ID"
  value       = aws_ecs_cluster.flask_cluster.id
}

output "ecr_repository_url" {
  description = "ECR Repository URL"
  value       = data.aws_ecr_repository.flask_api_repo.repository_url
}

output "alb_dns_name" {
  description = "DNS name of the application load balancer"
  value       = aws_lb.flask_lb.dns_name
}

#output "cloudfront_domain_name" {
  #description = "CloudFront distribution domain name"
  #value       = aws_cloudfront_distribution.flask_distribution.domain_name
#}
