#!/bin/bash
# test-alerts.sh - Test CloudWatch alerts

echo "==================================================="
echo "ALERT TESTING - Triggering Test Notifications"
echo "==================================================="
echo ""

# Test 1: Manually trigger SNS notification
echo "1. Testing SNS Email Notification"
echo "---------------------------------------------------"
aws sns publish \
  --topic-arn arn:aws:sns:eu-west-2:494376414941:devops-day5-alerts \
  --subject "🧪 Test Alert - DevOps Monitoring System" \
  --message "This is a test alert from your DevOps monitoring system.

✅ If you receive this email, your alert system is working correctly!

Dashboard: https://eu-west-2.console.aws.amazon.com/cloudwatch/home?region=eu-west-2

Triggered at: $(date)

This is an automated test - no action required." \
  --region eu-west-2

echo "✅ Test notification sent! Check your email: richieprograms@gmail.com"
echo ""
echo "---------------------------------------------------"
echo ""

# Test 2: Check current alarm states
echo "2. Current Alarm States"
echo "---------------------------------------------------"
aws cloudwatch describe-alarms \
  --region eu-west-2 \
  --query 'MetricAlarms[*].[AlarmName,StateValue,StateUpdatedTimestamp]' \
  --output table

echo ""
echo "---------------------------------------------------"
echo ""

# Test 3: Simulate Lambda error (safe - won't actually break anything)
echo "3. How to Trigger Test Alarms (Manual Steps)"
echo "---------------------------------------------------"
echo ""
echo "🔴 EC2 High CPU Alert:"
echo "   SSH into EC2 and run: stress --cpu 4 --timeout 600"
echo "   (Requires: sudo apt-get install stress)"
echo "   Alert triggers when CPU > 80% for 10 minutes"
echo ""
echo "🔴 Lambda Error Alert:"
echo "   Temporarily break Lambda code and invoke it"
echo "   Alert triggers on any Lambda error"
echo ""
echo "🔴 ECS Unhealthy Alert:"
echo "   Scale ECS to 1, then manually stop the task"
echo "   Alert triggers when healthy tasks < 1"
echo ""
echo "🔴 Cost Alert:"
echo "   This would trigger if monthly costs exceed \$50"
echo "   (Not recommended to test in real environment!)"
echo ""
echo "==================================================="
echo ""

echo "✅ Alert system is configured and ready!"
echo "📧 Check your email for the test notification"
echo "📊 View real-time alerts in CloudWatch console"
