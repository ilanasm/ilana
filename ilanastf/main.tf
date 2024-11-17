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

# CloudFront Setup with Logging and S3 Integration

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "s3_identity" {
  comment = "Allow CloudFront to access the S3 bucket"
}

# S3 Bucket for Logs
resource "aws_s3_bucket" "logs" {
  bucket = "ilanas-logs"
}

resource "aws_s3_bucket_policy" "logs_policy" {
  bucket = aws_s3_bucket.logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontLogging"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.logs.arn}/*"
      }
    ]
  })
}

# Reference Existing S3 Bucket for Static Content
data "aws_s3_bucket" "flask_index" {
  bucket = "terraform-state-ilanas" 
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

  # Origin for S3 Bucket
  origin {
    domain_name = data.aws_s3_bucket.flask_index.bucket_regional_domain_name
    origin_id   = "flask-s3-origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3_identity.cloudfront_access_identity_path
    }
  }

  # Default Cache Behavior for S3 Bucket
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

  # Cache Behavior for API (/v1/*)


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

  # Logging
  logging_config {
    bucket = aws_s3_bucket.logs.bucket_domain_name
    prefix = "cloudfront/"
  }
}
