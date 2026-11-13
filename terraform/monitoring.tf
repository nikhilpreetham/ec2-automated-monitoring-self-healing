# SNS topic for monitoring notifications
resource "aws_sns_topic" "alerts" {
  name = "ec2-monitoring-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Alerts when the instance has sustained high CPU use.
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "ec2-monitoring-high-cpu"
  alarm_description   = "Alert when EC2 CPU utilization stays above 70 percent."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    InstanceId = aws_instance.monitoring_ec2.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  treat_missing_data = "notBreaching"
}

# Recovers the instance after two failed system status checks.
resource "aws_cloudwatch_metric_alarm" "system_recovery" {
  alarm_name          = "ec2-monitoring-system-recovery"
  alarm_description   = "Recover EC2 after two system-status-check failures."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Minimum"
  threshold           = 1

  dimensions = {
    InstanceId = aws_instance.monitoring_ec2.id
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn,
    "arn:aws:automate:${var.aws_region}:ec2:recover"
  ]

  treat_missing_data = "missing"
}

# CloudWatch dashboard for instance health and performance.
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "ec2-monitoring-dashboard"

  dashboard_body = jsonencode({
    start          = "-PT6H"
    periodOverride = "inherit"

    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "EC2 CPU Utilization"
          region = var.aws_region
          view   = "timeSeries"
          period = 300
          stat   = "Average"

          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.monitoring_ec2.id]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "System Status Checks"
          region = var.aws_region
          view   = "timeSeries"
          period = 300
          stat   = "Maximum"

          metrics = [
            ["AWS/EC2", "StatusCheckFailed_System", "InstanceId", aws_instance.monitoring_ec2.id]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "Network Traffic"
          region = var.aws_region
          view   = "timeSeries"
          period = 300
          stat   = "Average"

          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", aws_instance.monitoring_ec2.id],
            ["AWS/EC2", "NetworkOut", "InstanceId", aws_instance.monitoring_ec2.id]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "T3 CPU Credit Balance"
          region = var.aws_region
          view   = "timeSeries"
          period = 300
          stat   = "Average"

          metrics = [
            ["AWS/EC2", "CPUCreditBalance", "InstanceId", aws_instance.monitoring_ec2.id]
          ]
        }
      },
      {
        type   = "alarm"
        x      = 0
        y      = 12
        width  = 24
        height = 4

        properties = {
          title = "Monitoring Alarm Status"

          alarms = [
            aws_cloudwatch_metric_alarm.high_cpu.arn,
            aws_cloudwatch_metric_alarm.system_recovery.arn
          ]
        }
      }
    ]
  })
}