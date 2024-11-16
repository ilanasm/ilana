resource "aws_ecs_cluster" "flask_cluster" {
  name = "flask-api-cluster"
}

resource "aws_ecr_repository" "flask_api_repo" {
  name = "ilanas-flask-api"
}

resource "aws_lb" "flask_lb" {
  name = "flask-api-alb"
}

resource "aws_cloudfront_distribution" "flask_distribution" {
  origin {
    domain_name = aws_lb.flask_lb.dns_name
    origin_id   = "flask-api-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
    }
  }

  enabled = true
}

