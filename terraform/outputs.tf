output "instance_id" {
  description = "ID of the monitored EC2 instance"
  value       = aws_instance.monitoring_ec2.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.monitoring_ec2.public_ip
}

output "sns_topic_arn" {
  description = "ARN of the SNS alert topic"
  value       = aws_sns_topic.alerts.arn
}

output "high_cpu_alarm_name" {
  description = "Name of the high CPU CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.high_cpu.alarm_name
}

output "system_recovery_alarm_name" {
  description = "Name of the system recovery CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.system_recovery.alarm_name
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}
