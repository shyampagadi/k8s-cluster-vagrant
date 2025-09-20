# Problem 34: Career Preparation - Outputs

output "portfolio_website_url" {
  description = "URL of the portfolio website"
  value       = aws_cloudfront_distribution.portfolio.domain_name
}

output "portfolio_s3_bucket" {
  description = "S3 bucket hosting the portfolio website"
  value       = aws_s3_bucket.portfolio.bucket
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.portfolio.id
}

output "monitoring_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.portfolio.dashboard_name}"
}

output "demo_infrastructure_endpoints" {
  description = "Endpoints for demo infrastructure"
  value = {
    api_gateway = aws_api_gateway_rest_api.demo.execution_arn
    lambda_function = aws_lambda_function.demo.function_name
    rds_endpoint = aws_db_instance.demo.endpoint
  }
}

output "skills_demonstration" {
  description = "Links to skills demonstration resources"
  value = {
    terraform_state_bucket = aws_s3_bucket.terraform_state.bucket
    monitoring_dashboard = aws_cloudwatch_dashboard.portfolio.dashboard_name
    security_compliance = aws_config_configuration_recorder.portfolio.name
    cost_optimization = aws_budgets_budget.portfolio.name
  }
}

output "certification_resources" {
  description = "Resources created for certification preparation"
  value = {
    practice_vpc = aws_vpc.practice.id
    practice_subnets = aws_subnet.practice[*].id
    practice_security_groups = aws_security_group.practice[*].id
    practice_instances = aws_instance.practice[*].id
  }
}

output "project_documentation" {
  description = "Documentation and guides created"
  value = {
    architecture_diagrams = "s3://${aws_s3_bucket.portfolio.bucket}/diagrams/"
    deployment_guides = "s3://${aws_s3_bucket.portfolio.bucket}/guides/"
    troubleshooting_docs = "s3://${aws_s3_bucket.portfolio.bucket}/troubleshooting/"
  }
}

output "contact_information" {
  description = "Professional contact information"
  value = {
    portfolio_website = "https://${aws_cloudfront_distribution.portfolio.domain_name}"
    github_profile = var.github_username != "" ? "https://github.com/${var.github_username}" : ""
    linkedin_profile = var.linkedin_profile
    contact_email = var.contact_email
  }
}

output "aws_resources_created" {
  description = "Summary of AWS resources created for portfolio"
  value = {
    compute = {
      ec2_instances = length(aws_instance.practice)
      lambda_functions = 1
    }
    storage = {
      s3_buckets = 2
      ebs_volumes = length(aws_instance.practice)
    }
    networking = {
      vpcs = 1
      subnets = length(aws_subnet.practice)
      security_groups = length(aws_security_group.practice)
    }
    database = {
      rds_instances = 1
    }
    monitoring = {
      cloudwatch_dashboards = 1
      cloudwatch_alarms = length(aws_cloudwatch_metric_alarm.portfolio)
    }
    security = {
      iam_roles = length(aws_iam_role.portfolio)
      config_rules = 1
    }
  }
}
