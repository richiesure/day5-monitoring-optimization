#!/bin/bash
# log-insights-queries.sh - Common CloudWatch Logs Insights queries

AWS_REGION="eu-west-2"
LAMBDA_LOG_GROUP="/aws/lambda/ec2-automated-backup"
ECS_LOG_GROUP="/ecs/devops-day3-app"

echo "=== CloudWatch Logs Insights Queries ==="
echo ""

# Query 1: Lambda execution summary (last 24 hours)
echo "1. Lambda Backup Execution Summary (Last 24 Hours)"
echo "---------------------------------------------------"
aws logs start-query \
  --log-group-name "$LAMBDA_LOG_GROUP" \
  --start-time $(date -d '24 hours ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, @message
| filter @message like /Total snapshots created/
| sort @timestamp desc
| limit 20' \
  --region "$AWS_REGION" \
  --query 'queryId' \
  --output text > /tmp/query1.txt

QUERY_ID=$(cat /tmp/query1.txt)
echo "Query ID: $QUERY_ID"
echo "Waiting for results..."
sleep 5

aws logs get-query-results \
  --query-id "$QUERY_ID" \
  --region "$AWS_REGION" \
  --output table

echo ""
echo "---------------------------------------------------"
echo ""

# Query 2: All errors in last hour
echo "2. All Errors (Last Hour)"
echo "---------------------------------------------------"
aws logs start-query \
  --log-group-name "$LAMBDA_LOG_GROUP" \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 50' \
  --region "$AWS_REGION" \
  --query 'queryId' \
  --output text > /tmp/query2.txt

QUERY_ID=$(cat /tmp/query2.txt)
echo "Query ID: $QUERY_ID"
echo "Waiting for results..."
sleep 5

aws logs get-query-results \
  --query-id "$QUERY_ID" \
  --region "$AWS_REGION" \
  --output table

echo ""
echo "---------------------------------------------------"
echo ""

# Query 3: ECS container logs (if service is running)
echo "3. ECS Application Logs (Last Hour)"
echo "---------------------------------------------------"
aws logs start-query \
  --log-group-name "$ECS_LOG_GROUP" \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, @message
| sort @timestamp desc
| limit 20' \
  --region "$AWS_REGION" \
  --query 'queryId' \
  --output text > /tmp/query3.txt 2>/dev/null

if [ -s /tmp/query3.txt ]; then
  QUERY_ID=$(cat /tmp/query3.txt)
  echo "Query ID: $QUERY_ID"
  echo "Waiting for results..."
  sleep 5
  
  aws logs get-query-results \
    --query-id "$QUERY_ID" \
    --region "$AWS_REGION" \
    --output table
else
  echo "No ECS logs found (service might be scaled to 0)"
fi

echo ""
echo "---------------------------------------------------"
echo ""

# Query 4: Lambda performance stats
echo "4. Lambda Performance Statistics"
echo "---------------------------------------------------"
aws logs start-query \
  --log-group-name "$LAMBDA_LOG_GROUP" \
  --start-time $(date -d '7 days ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp
| filter @type = "REPORT"
| stats avg(@duration), max(@duration), min(@duration), count(*) by bin(5m)' \
  --region "$AWS_REGION" \
  --query 'queryId' \
  --output text > /tmp/query4.txt

QUERY_ID=$(cat /tmp/query4.txt)
echo "Query ID: $QUERY_ID"
echo "Waiting for results..."
sleep 5

aws logs get-query-results \
  --query-id "$QUERY_ID" \
  --region "$AWS_REGION" \
  --output table

echo ""
echo "=== Queries Complete ==="
