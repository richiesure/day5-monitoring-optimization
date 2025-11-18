# Day 5: Monitoring, Alerting & Optimization

## Project Description
Complete observability infrastructure with CloudWatch Dashboards, automated alerting, log analysis, cost optimization, and security auditing for all DevOps infrastructure (Days 1-4).

## What Was Built

### 1. CloudWatch Dashboard
- **EC2 Metrics**: CPU utilization, network I/O
- **Lambda Metrics**: Invocations, errors, duration
- **ECS Metrics**: Container CPU/memory usage
- **Log Insights**: Real-time error tracking
- **Custom Metrics**: Application-level monitoring

### 2. Automated Alerting (5 Alarms)
- ✅ EC2 High CPU (>80% for 10 minutes)
- ✅ Lambda Errors (any execution failure)
- ✅ ECS Unhealthy Tasks (<1 healthy container)
- ✅ High AWS Costs (>$50/month)
- ✅ Application Error Spike (>10 errors/5min)

### 3. Log Aggregation & Analysis
- CloudWatch Logs Insights queries
- Automated error detection
- Performance statistics tracking
- Custom log metric filters

### 4. Cost Optimization
- Daily/monthly cost tracking
- Service-level cost breakdown
- Cost forecasting
- Unused resource detection

### 5. Security Audit
- IAM security assessment
- Security group analysis
- EBS encryption check
- Secrets management review
- CloudTrail verification

## Architecture
```
┌─────────────────────────────────────────────────────┐
│                  CloudWatch                         │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────┐ │
│  │  Dashboard   │  │   Alarms     │  │   Logs    │ │
│  └──────┬───────┘  └──────┬───────┘  └─────┬─────┘ │
│         │                 │                 │       │
└─────────┼─────────────────┼─────────────────┼───────┘
          │                 │                 │
          ▼                 ▼                 ▼
    ┌─────────┐        ┌────────┐       ┌─────────┐
    │   EC2   │        │  SNS   │       │ Lambda  │
    │ Lambda  │───────▶│ Topic  │◀──────│  ECS    │
    │   ECS   │        └────┬───┘       └─────────┘
    └─────────┘             │
                            ▼
                       📧 Email Alerts
```

## Files Structure
```
.
├── main.tf                    # CloudWatch infrastructure
├── variables.tf               # Input variables
├── outputs.tf                 # Dashboard/alarm outputs
├── log-insights-queries.sh    # Log analysis queries
├── cost-analysis.sh           # Cost optimization tool
├── security-audit.sh          # Security assessment
├── test-alerts.sh             # Alert system testing
└── README.md                  # This file
```

## Deployment

### Prerequisites
- Day 1-4 infrastructure deployed
- Terraform installed
- AWS CLI configured

### Deploy Monitoring
```bash
# Initialize and deploy
terraform init
terraform plan
terraform apply

# Confirm SNS subscription via email
# Check your inbox for AWS notification
```

### Access Dashboard

**URL**: https://eu-west-2.console.aws.amazon.com/cloudwatch/home?region=eu-west-2#dashboards:name=DevOps-Infrastructure-Dashboard

Or via CLI:
```bash
aws cloudwatch list-dashboards --region eu-west-2
```

## Usage

### View Real-Time Metrics
```bash
# Check alarm states
aws cloudwatch describe-alarms \
  --region eu-west-2 \
  --query 'MetricAlarms[*].[AlarmName,StateValue]' \
  --output table

# Get EC2 CPU utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average \
  --region eu-west-2
```

### Run Log Analysis
```bash
# Execute predefined queries
./log-insights-queries.sh

# Custom query
aws logs start-query \
  --log-group-name /aws/lambda/ec2-automated-backup \
  --start-time $(date -d '24 hours ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, @message | sort @timestamp desc' \
  --region eu-west-2
```

### Cost Analysis
```bash
# Full cost report
./cost-analysis.sh

# Quick cost check
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '7 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics UnblendedCost \
  --region us-east-1
```

### Security Audit
```bash
# Run full audit
./security-audit.sh

# Quick checks
aws iam get-account-summary
aws ec2 describe-security-groups --query 'SecurityGroups[?IpPermissions[?IpRanges[?CidrIp==`0.0.0.0/0`]]]'
```

### Test Alerts
```bash
# Send test notification
./test-alerts.sh

# Manually trigger EC2 CPU alert
ssh ec2-user@<EC2_IP>
sudo apt-get install stress
stress --cpu 4 --timeout 600
```

## Monitoring Dashboards Explained

### EC2 CPU Utilization Widget
- **What**: Tracks CPU usage percentage
- **Why**: Detects performance issues or runaway processes
- **Threshold**: Alert at >80%

### Lambda Metrics Widget
- **Invocations**: How many times Lambda ran
- **Errors**: Failed executions
- **Duration**: Execution time (optimization opportunity)

### ECS Resource Usage Widget
- **CPU Utilization**: Container compute usage
- **Memory Utilization**: Container memory consumption
- **Why**: Right-size container resources

### Lambda Error Rate Widget
- **Formula**: (Errors / Invocations) × 100
- **Why**: Track reliability over time
- **Threshold**: >5% needs investigation

### Recent Lambda Errors Widget
- **Type**: Log Insights query
- **Shows**: Last 20 ERROR entries
- **Use**: Quick troubleshooting

## Alert Response Playbook

### EC2 High CPU Alert

**Triggered**: CPU >80% for 10 minutes

**Response**:
1. SSH into instance: `ssh ec2-user@<IP>`
2. Check processes: `top`
3. Identify culprit: `ps aux --sort=-%cpu | head`
4. Action: Kill process or scale up instance

### Lambda Error Alert

**Triggered**: Any Lambda execution error

**Response**:
1. Check logs: `aws logs tail /aws/lambda/ec2-automated-backup --region eu-west-2`
2. Identify error type
3. Common causes:
   - IAM permission denied → Fix policy
   - Timeout → Increase timeout
   - Out of memory → Increase memory

### ECS Unhealthy Tasks

**Triggered**: <1 healthy container

**Response**:
1. Check service: `aws ecs describe-services --cluster devops-day3-cluster --services devops-day3-service --region eu-west-2`
2. Check task logs: CloudWatch Logs
3. Common causes:
   - Health check failing → Fix app
   - Out of memory → Increase task memory
   - Image pull error → Check ECR

### High Costs Alert

**Triggered**: Monthly costs >$50

**Response**:
1. Run cost analysis: `./cost-analysis.sh`
2. Identify top services
3. Actions:
   - Scale down ECS
   - Delete old snapshots
   - Stop unused EC2 instances

## Cost Breakdown (Current Setup)
```
Service              | Cost/Month | Notes
---------------------|------------|---------------------------
EC2 t3.micro         | $0.00      | Free tier (750 hrs)
Lambda               | $0.40      | Snapshot storage
ECS Fargate (0 tasks)| $0.00      | Scaled to 0
ECS Fargate (1 task) | $25.00     | If running 24/7
CloudWatch           | $0.50      | Logs + metrics
SNS                  | $0.00      | Free tier
Total (scaled down)  | $0.90/mo   | ✅ Minimal cost
Total (1 ECS task)   | $25.90/mo  | Production-like
```

## Security Findings & Remediation

### Current Security Score: 65/100

**Issues Found:**

**1. Unencrypted EBS Volumes (-15 points)**
```bash
# Encrypt existing volumes
aws ec2 create-snapshot --volume-id vol-xxx --description "Before encryption"
aws ec2 copy-snapshot --source-snapshot-id snap-xxx --encrypted
aws ec2 create-volume --snapshot-id snap-encrypted --encrypted
```

**2. CloudTrail Not Enabled (-20 points)**
```bash
# Enable CloudTrail
aws cloudtrail create-trail \
  --name devops-audit-trail \
  --s3-bucket-name my-cloudtrail-bucket
aws cloudtrail start-logging --name devops-audit-trail
```

**3. Root Account No MFA (Critical)**
- Go to IAM → Dashboard → Security Status
- Enable MFA for root account

**4. Open Security Groups (0.0.0.0/0)**
- Review and restrict to specific IPs
- Use VPN or bastion host for SSH

## Best Practices Implemented

✅ **Observability**
- Comprehensive dashboards
- Multi-layer alerting
- Centralized logging

✅ **Cost Management**
- Automated cost tracking
- Budget alerts
- Resource optimization

✅ **Security**
- Regular audits
- Automated checks
- Compliance monitoring

✅ **Incident Response**
- Alert playbooks
- Automated notifications
- Log aggregation

## SRE Metrics

### Service Level Indicators (SLIs)
- **Lambda Success Rate**: >99%
- **EC2 Uptime**: >99.9%
- **ECS Task Health**: 100% (when running)

### Service Level Objectives (SLOs)
- **Alert Response Time**: <5 minutes
- **Backup Success Rate**: 100%
- **Dashboard Load Time**: <3 seconds

### Error Budget
- **Monthly downtime allowed**: 43 minutes (99.9% uptime)
- **Failed backups allowed**: 0 per month

## Cleanup
```bash
# Destroy monitoring infrastructure
terraform destroy

# Keep alarms if continuing Day 6
```

## Production Enhancements

For real production:

1. **PagerDuty Integration**: On-call rotation
2. **Slack Notifications**: Team alerts
3. **Synthetic Monitoring**: Proactive checks
4. **Custom Metrics**: Business KPIs
5. **Anomaly Detection**: ML-based alerts
6. **Multi-Region Dashboards**: Global view
7. **SLA Tracking**: Contractual commitments

## Troubleshooting

### Dashboard Not Showing Data
- Check metric namespaces match
- Verify resources exist in same region
- Wait 5-10 minutes for metrics to populate

### Alarms Stuck in INSUFFICIENT_DATA
- Normal for new alarms (no data yet)
- Wait for one evaluation period
- Check metric is being published

### Not Receiving Email Alerts
- Confirm SNS subscription in email
- Check spam folder
- Verify email in terraform.tfvars

## Learning Objectives

✅ CloudWatch Dashboards creation
✅ Multi-service monitoring
✅ Automated alerting strategies
✅ Log aggregation with Insights
✅ Cost optimization techniques
✅ Security audit procedures
✅ Incident response planning
✅ SRE principles (SLIs, SLOs)

---

**Author:** DevOps Learning Journey - Day 5

**Dashboard URL**: https://eu-west-2.console.aws.amazon.com/cloudwatch/home?region=eu-west-2#dashboards:name=DevOps-Infrastructure-Dashboard

**Security Score**: 65/100 (Fair - improvements needed)
**Monthly Cost**: ~$25-30 (optimized setup)
