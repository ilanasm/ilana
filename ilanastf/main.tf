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
  target_type = "ip"
  vpc_id   = "vpc-00cca0426394bdde3"

  health_check {
    path                = "/v1/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

#Listener for ALB
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

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# S3 Bucket for Static Content
data "aws_s3_bucket" "flask_index" {
  bucket = "terraform-state-ilanas"
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "s3_identity" {
  comment = "Allow CloudFront to access the S3 bucket"

  lifecycle {
    prevent_destroy = true
  }
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
  } # Closing the origin block properly

  # Origin for S3 Bucket
  origin {
    domain_name = data.aws_s3_bucket.flask_index.bucket_regional_domain_name
    origin_id   = "flask-s3-origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3_identity.cloudfront_access_identity_path
    }
  }

  # Default Cache Behavior
  default_cache_behavior {
    target_origin_id       = "flask-s3-origin"
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
} # Closing the aws_cloudfront_distribution block

# ECS Task Definition
resource "aws_ecs_task_definition" "flask_task" {
  family                   = "flask-api-task"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # Task-level CPU
  memory                   = "512" # Task-level Memory

  container_definitions = jsonencode([
    {
      name      = "flask-api"
      image     = data.aws_ecr_repository.flask_api_repo.repository_url
      cpu       = 256
      memory    = 512
      essential = true

      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
          protocol      = "tcp"
        }
      ]
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "flask_service" {
  name            = "flask-api-service"
  cluster         = aws_ecs_cluster.flask_cluster.id
  task_definition = aws_ecs_task_definition.flask_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnets
    security_groups  = ["sg-0c43d7031899a4d19"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.flask_target_group.arn
    container_name   = "flask-api"
    container_port   = 5000
  }
}
