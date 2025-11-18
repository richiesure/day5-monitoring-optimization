# main.tf - Monitoring and Alerting Infrastructure

provider "aws" {
  region = var.aws_region
}

# Get current account ID
data "aws_caller_identity" "current" {}

# SNS Topic for All Alerts
resource "aws_sns_topic" "devops_alerts" {
  name = "devops-day5-alerts"

  tags = {
    Name        = "DevOps-Alerts"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# SNS Email Subscription
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.devops_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "DevOps-Infrastructure-Dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # EC2 CPU Utilization
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average", period = 300 }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "EC2 CPU Utilization"
          period  = 300
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
        width  = 12
        height = 6
        x      = 0
        y      = 0
      },
      # Lambda Invocations
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", period = 3600 }],
            [".", "Errors", { stat = "Sum", period = 3600 }],
            [".", "Duration", { stat = "Average", period = 3600 }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Lambda Metrics (Hourly)"
          period  = 3600
        }
        width  = 12
        height = 6
        x      = 12
        y      = 0
      },
      # ECS Service Metrics
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", { stat = "Average", period = 300 }],
            [".", "MemoryUtilization", { stat = "Average", period = 300 }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ECS Container Resource Usage"
          period  = 300
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
        width  = 12
        height = 6
        x      = 0
        y      = 6
      },
      # Lambda Error Rate
      {
        type = "metric"
        properties = {
          metrics = [
            [{ expression = "m2/m1*100", label = "Error Rate %", id = "e1" }],
            ["AWS/Lambda", "Invocations", { id = "m1", visible = false }],
            [".", "Errors", { id = "m2", visible = false }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Lambda Error Rate"
          period  = 300
          yAxis = {
            left = {
              min = 0
            }
          }
        }
        width  = 12
        height = 6
        x      = 12
        y      = 6
      },
      # Log Insights Query Widget
      {
        type = "log"
        properties = {
          query   = "SOURCE '/aws/lambda/ec2-automated-backup'\n| fields @timestamp, @message\n| filter @message like /ERROR/\n| sort @timestamp desc\n| limit 20"
          region  = var.aws_region
          title   = "Recent Lambda Errors"
          stacked = false
        }
        width  = 24
        height = 6
        x      = 0
        y      = 12
      }
    ]
  })
}

# CloudWatch Alarm: EC2 High CPU
resource "aws_cloudwatch_metric_alarm" "ec2_high_cpu" {
  alarm_name          = "ec2-high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when EC2 CPU exceeds 80% for 10 minutes"
  alarm_actions       = [aws_sns_topic.devops_alerts.arn]
  ok_actions          = [aws_sns_topic.devops_alerts.arn]

  dimensions = {
    InstanceId = var.ec2_instance_id
  }

  tags = {
    Name        = "EC2-High-CPU"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# CloudWatch Alarm: Lambda Errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "lambda-backup-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alert when Lambda backup function fails"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.devops_alerts.arn]
  ok_actions          = [aws_sns_topic.devops_alerts.arn]

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  tags = {
    Name        = "Lambda-Backup-Errors"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# CloudWatch Alarm: ECS Service Unhealthy
resource "aws_cloudwatch_metric_alarm" "ecs_unhealthy" {
  alarm_name          = "ecs-service-unhealthy-tasks"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthyTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Alert when ECS has less than 1 healthy task"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.devops_alerts.arn]
  ok_actions          = [aws_sns_topic.devops_alerts.arn]

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  tags = {
    Name        = "ECS-Unhealthy-Tasks"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# CloudWatch Alarm: High AWS Costs
resource "aws_cloudwatch_metric_alarm" "high_costs" {
  alarm_name          = "high-aws-costs"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 21600
  statistic           = "Maximum"
  threshold           = 50
  alarm_description   = "Alert when estimated monthly charges exceed $50"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.devops_alerts.arn]

  dimensions = {
    Currency = "USD"
  }

  tags = {
    Name        = "High-AWS-Costs"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# CloudWatch Log Metric Filter: Application Errors
resource "aws_cloudwatch_log_metric_filter" "app_errors" {
  name           = "ApplicationErrors"
  pattern        = "[time, request_id, event_type = ERROR*, ...]"
  log_group_name = "/ecs/devops-day3-app"

  metric_transformation {
    name      = "ApplicationErrorCount"
    namespace = "CustomMetrics"
    value     = "1"
  }
}

# Alarm for Application Errors
resource "aws_cloudwatch_metric_alarm" "app_errors" {
  alarm_name          = "application-error-spike"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApplicationErrorCount"
  namespace           = "CustomMetrics"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alert when application logs 10+ errors in 5 minutes"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.devops_alerts.arn]

  tags = {
    Name        = "Application-Error-Spike"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
