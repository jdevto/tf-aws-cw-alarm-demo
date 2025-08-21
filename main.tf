terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

data "aws_region" "current" {}

# CloudWatch Log Group for Lambda (explicitly managed)
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/demo-metric-producer"
  retention_in_days = 1
  tags = {
    Name    = "demo-lambda-logs"
    Purpose = "demo"
  }
}

# Lambda function that puts custom metric data
resource "aws_lambda_function" "metric_producer" {
  filename      = "lambda_function.zip"
  function_name = "demo-metric-producer"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 30
  memory_size   = 128

  environment {
    variables = {
      NAMESPACE   = "Demo/App"
      METRIC_NAME = "trigger_count"
    }
  }

  tags = {
    Name    = "demo-metric-producer"
    Purpose = "demo"
  }

  depends_on = [aws_cloudwatch_log_group.lambda_logs]
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "demo-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Lambda to put CloudWatch metrics and be invoked by EventBridge
resource "aws_iam_role_policy" "lambda_cloudwatch_policy" {
  name = "lambda-cloudwatch-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# EventBridge rule to trigger Lambda every minute
resource "aws_cloudwatch_event_rule" "lambda_trigger" {
  name                = "demo-lambda-trigger"
  description         = "Triggers Lambda function every minute to put metric data"
  schedule_expression = "cron(0 * * * ? *)"

  tags = {
    Name    = "demo-lambda-trigger"
    Purpose = "demo"
  }
}

# EventBridge target to invoke Lambda
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.lambda_trigger.name
  target_id = "DemoLambdaTarget"
  arn       = aws_lambda_function.metric_producer.arn
}

# Lambda permission to allow EventBridge to invoke it
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.metric_producer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_trigger.arn
}

# CloudWatch Alarm
resource "aws_cloudwatch_metric_alarm" "demo_alarm" {
  alarm_name          = "demo-trigger-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "trigger_count"
  namespace           = "Demo/App"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_description   = "Demo alarm that triggers when Lambda puts metric data"

  tags = {
    Name    = "demo-trigger-alarm"
    Purpose = "demo"
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "demo_dashboard" {
  dashboard_name = "Demo-Metric-Dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["Demo/App", "trigger_count"]
          ]
          period = 10
          stat   = "Sum"
          region = data.aws_region.current.region
          title  = "Demo Trigger Count"
        }
      },
      {
        type   = "alarm"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          alarms = [
            aws_cloudwatch_metric_alarm.demo_alarm.arn
          ]
          title = "Demo Alarm Status"
        }
      }
    ]
  })
}

# Outputs
output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.metric_producer.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.metric_producer.arn
}

output "alarm_arn" {
  description = "ARN of the CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.demo_alarm.arn
}

output "dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://${data.aws_region.current.region}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.region}#dashboards:name=Demo-Metric-Dashboard"
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule that triggers Lambda"
  value       = aws_cloudwatch_event_rule.lambda_trigger.arn
}
