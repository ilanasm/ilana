provider "aws" {
  region = var.aws_region
}

# ECS Cluster
resource "aws_ecs_cluster" "flask_cluster" {
  name = "flask-api-cluster"
}

# ECR Repository
data "aws_ecr_repository" "flask_api_repo" {
  name = "ilanas-flask-api"
}

# Application Load Balancer (ALB)
resource "aws_lb" "flask_lb" {
  name               = "flask-api-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = ["sg-0c43d7031899a4d19"]
}

# Target Group for ALB
resource "aws_lb_target_group" "flask_target_group" {
  name     = "flask-api-target-group"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = "vpc-00cca0426394bdde3"

  health_check {
    path                = "/v1/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Listener for ALB
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.flask_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flask_target_group.arn
  }
}

# IAM Roles and Policies for ECS

# Execution Role
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecsExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "ecs_execution_policy" {
  name       = "ecsExecutionPolicyAttachment"
  roles      = [aws_iam_role.ecs_execution_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "flask_distribution" {
  enabled             = true
  default_root_object = "index.html"

  # Origin for ECS (via ALB)
  origin {
    domain_name = aws_lb.flask_lb.dns_name
    origin_id   = "flask-api-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Default Cache Behavior
  default_cache_behavior {
    target_origin_id       = "flask-api-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # Viewer Certificate
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}
