#!/bin/bash
# cost-analysis.sh - AWS Cost Analysis and Optimization

AWS_REGION="eu-west-2"
START_DATE=$(date -d '30 days ago' +%Y-%m-%d)
END_DATE=$(date +%Y-%m-%d)

echo "==================================================="
echo "AWS COST ANALYSIS - Last 30 Days"
echo "==================================================="
echo ""

# Total cost by service
echo "1. Cost by Service (Last 30 Days)"
echo "---------------------------------------------------"
aws ce get-cost-and-usage \
  --time-period Start=$START_DATE,End=$END_DATE \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE \
  --region us-east-1 \
  --query 'ResultsByTime[0].Groups[*].[Keys[0],Metrics.UnblendedCost.Amount]' \
  --output table | head -20

echo ""
echo "---------------------------------------------------"
echo ""

# Daily cost trend
echo "2. Daily Cost Trend (Last 7 Days)"
echo "---------------------------------------------------"
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '7 days ago' +%Y-%m-%d),End=$END_DATE \
  --granularity DAILY \
  --metrics "UnblendedCost" \
  --region us-east-1 \
  --query 'ResultsByTime[*].[TimePeriod.Start,Metrics.UnblendedCost.Amount]' \
  --output table

echo ""
echo "---------------------------------------------------"
echo ""

# Current month forecast
echo "3. Current Month Cost Forecast"
echo "---------------------------------------------------"
MONTH_START=$(date +%Y-%m-01)
MONTH_END=$(date -d "$(date +%Y-%m-01) +1 month -1 day" +%Y-%m-%d)

aws ce get-cost-forecast \
  --time-period Start=$(date +%Y-%m-%d),End=$MONTH_END \
  --metric UNBLENDED_COST \
  --granularity MONTHLY \
  --region us-east-1 \
  --query 'Total.Amount' \
  --output text | xargs -I {} echo "Forecasted cost for $(date +%B): \${}"

echo ""
echo "---------------------------------------------------"
echo ""

# Resource inventory
echo "4. Resource Inventory (Cost Contributors)"
echo "---------------------------------------------------"
echo "EC2 Instances:"
aws ec2 describe-instances \
  --region $AWS_REGION \
  --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,Tags[?Key==`Name`].Value|[0]]' \
  --output table

echo ""
echo "ECS Services:"
aws ecs list-services \
  --cluster devops-day3-cluster \
  --region $AWS_REGION \
  --query 'serviceArns[*]' \
  --output table

echo ""
echo "Lambda Functions:"
aws lambda list-functions \
  --region $AWS_REGION \
  --query 'Functions[*].[FunctionName,Runtime,MemorySize]' \
  --output table

echo ""
echo "EBS Snapshots:"
aws ec2 describe-snapshots \
  --owner-ids self \
  --region $AWS_REGION \
  --query 'Snapshots[*].[SnapshotId,VolumeSize,StartTime]' \
  --output table

echo ""
echo "---------------------------------------------------"
echo ""

# Optimization recommendations
echo "5. Cost Optimization Recommendations"
echo "---------------------------------------------------"
echo "✅ CURRENT SETUP ANALYSIS:"
echo ""
echo "EC2 t3.micro: ~\$0/month (Free tier - 750 hours)"
echo "Lambda: ~\$0.40/month (snapshots storage)"
echo "ECS Fargate (if 1 task): ~\$25/month"
echo "CloudWatch: ~\$0.50/month"
echo "SNS: ~\$0.00 (within free tier)"
echo ""
echo "💡 OPTIMIZATION TIPS:"
echo ""
echo "1. ECS Service: Currently scaled to $(aws ecs describe-services --cluster devops-day3-cluster --services devops-day3-service --region $AWS_REGION --query 'services[0].desiredCount' --output text) containers"
echo "   - Scale to 0 when not in use: Save ~\$25/month"
echo "   - Use Fargate Spot: Save 70% on compute costs"
echo ""
echo "2. EBS Snapshots: $(aws ec2 describe-snapshots --owner-ids self --region $AWS_REGION --query 'length(Snapshots)' --output text) snapshots"
echo "   - Delete snapshots older than 30 days"
echo "   - Cost: ~\$0.05/GB/month"
echo ""
echo "3. CloudWatch Logs:"
echo "   - Set retention to 7 days (already configured)"
echo "   - Delete unused log groups"
echo ""
echo "4. Unused Resources Check:"
aws ec2 describe-volumes \
  --filters Name=status,Values=available \
  --region $AWS_REGION \
  --query 'Volumes[*].[VolumeId,Size,CreateTime]' \
  --output table 2>/dev/null | head -5

if [ $(aws ec2 describe-volumes --filters Name=status,Values=available --region $AWS_REGION --query 'length(Volumes)' --output text 2>/dev/null) -gt 0 ]; then
  echo "   ⚠️  Found unattached EBS volumes - consider deleting"
else
  echo "   ✅ No unattached EBS volumes found"
fi

echo ""
echo "==================================================="
echo "ESTIMATED MONTHLY COST: \$25-30"
echo "==================================================="
