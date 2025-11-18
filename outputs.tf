# outputs.tf - Output values after deployment

output "dashboard_name" {
  description = "Name of the CloudWatch Dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_url" {
  description = "URL to view the CloudWatch Dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.devops_alerts.arn
}

output "alarms_configured" {
  description = "List of configured CloudWatch alarms"
  value = [
    aws_cloudwatch_metric_alarm.ec2_high_cpu.alarm_name,
    aws_cloudwatch_metric_alarm.lambda_errors.alarm_name,
    aws_cloudwatch_metric_alarm.ecs_unhealthy.alarm_name,
    aws_cloudwatch_metric_alarm.high_costs.alarm_name,
    aws_cloudwatch_metric_alarm.app_errors.alarm_name
  ]
}

output "next_steps" {
  description = "What to do next"
  value       = <<-EOT
    ✅ Monitoring infrastructure deployed successfully!
    
    📊 View Dashboard:
    ${aws_cloudwatch_dashboard.main.dashboard_name}
    URL: https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}
    
    🚨 Configured Alarms:
    - EC2 High CPU (>80%)
    - Lambda Errors
    - ECS Unhealthy Tasks
    - High AWS Costs (>$${var.cost_alert_threshold})
    - Application Error Spike (>10 errors/5min)
    
    📧 Email Alerts: ${var.alert_email}
    ⚠️  IMPORTANT: Check your email and confirm SNS subscription!
    
    📈 View Alarms:
    aws cloudwatch describe-alarms --region ${var.aws_region} --query 'MetricAlarms[*].[AlarmName,StateValue]' --output table
    
    📊 Test Alert (trigger high CPU):
    # SSH into EC2 and run: stress --cpu 4 --timeout 600
    
    💡 View Logs with Insights:
    aws logs start-query \
      --log-group-name /aws/lambda/ec2-automated-backup \
      --start-time $(date -d '1 hour ago' +%s) \
      --end-time $(date +%s) \
      --query-string 'fields @timestamp, @message | sort @timestamp desc | limit 20'
  EOT
}
