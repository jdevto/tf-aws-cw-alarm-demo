# CloudWatch High-Resolution Metric Alarm Demo

A simple Terraform demo that creates a Lambda function, CloudWatch custom metric, and alarm that triggers automatically every minute.

## 🎯 Objective

See a CloudWatch alarm automatically flip to ALARM state every minute, then auto-clear in the next evaluation period - all without manual intervention.

## 🏗️ Architecture

```plaintext
EventBridge (1 min) → Lambda Function → PutMetricData → CloudWatch 1-second metric → Alarm → Dashboard
```

## 📋 Components

- **EventBridge Rule**: Triggers Lambda every minute automatically
- **Lambda Function**: `demo-metric-producer` - puts custom metric data
- **CloudWatch Metric**: Namespace `Demo/App`, Metric `trigger_count`
- **Alarm**: 10-second period, triggers when Sum >= 1
- **Dashboard**: Real-time metric and alarm status visualization

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Node.js and npm (for building Lambda)

### 1. Build Lambda Function

```bash
chmod +x build.sh
./build.sh
```

### 2. Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

### 3. Watch the Demo

The demo runs automatically! Simply:

- Open the CloudWatch dashboard URL from the outputs
- Watch the alarm flip to ALARM state every minute
- See it auto-clear within 10-20 seconds

## 📊 How It Works

1. **Deploy**: Terraform creates EventBridge rule, Lambda, IAM role, CloudWatch alarm, and dashboard
2. **Automatic Trigger**: EventBridge invokes Lambda every minute
3. **Metric Creation**: Lambda puts a custom metric with `StorageResolution=1` (high-res)
4. **Alarm Trigger**: Alarm evaluates every 10 seconds, enters ALARM state when Sum >= 1
5. **Auto-Clear**: No new data in next period → alarm returns to OK state
6. **Repeat**: Process repeats every minute automatically

## 🔧 Configuration

### EventBridge Rule

- **Schedule**: `rate(1 minute)` - triggers every minute
- **Target**: Lambda function invocation
- **Automatic**: No manual intervention required

### Lambda Function

- Runtime: Node.js 18.x
- Memory: 128 MB
- Timeout: 30 seconds
- Environment variables for metric namespace and name
- **Auto-triggered**: Runs every minute via EventBridge

### CloudWatch Alarm

- Period: 10 seconds
- Evaluation Periods: 1
- Statistic: Sum
- Threshold: >= 1
- Treat Missing Data: notBreaching

### Metric

- Namespace: `Demo/App`
- Metric Name: `trigger_count`
- Storage Resolution: 1 second (high-resolution)
- Unit: Count

## 📈 Expected Timeline

- **Every 60s**: EventBridge triggers Lambda
- **+1-5s**: Metric appears in CloudWatch
- **+10-20s**: Alarm enters ALARM state
- **+20-30s**: Alarm returns to OK state (no new data)
- **+60s**: Cycle repeats automatically

## 🧹 Cleanup

```bash
terraform destroy
```

## 💡 Use Cases

This demo pattern can be easily adapted for:

- Real-time application monitoring
- API rate limiting alerts
- Error rate monitoring
- Custom business metrics
- Performance monitoring
- Automated health checks

## 🔍 Monitoring

- **CloudWatch Console**: View metrics and alarm history
- **Dashboard**: Real-time visualization at the provided URL
- **Lambda Logs**: Check CloudWatch Logs for function execution details
- **EventBridge**: Monitor rule execution in CloudWatch Events

## 📝 Notes

- **Fully automated** - runs every minute without manual intervention
- High-resolution metrics (1-second) incur higher costs than standard metrics
- Alarm evaluation happens every 10 seconds for immediate feedback
- No email notifications configured (demo purposes only)
- Lambda function is stateless and can be invoked multiple times
- EventBridge rule ensures consistent metric generation for testing
