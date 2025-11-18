#!/bin/bash
# security-audit.sh - Security best practices audit

AWS_REGION="eu-west-2"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

echo "==================================================="
echo "SECURITY AUDIT - DevOps Infrastructure"
echo "==================================================="
echo ""
echo "Account ID: $ACCOUNT_ID"
echo "Region: $AWS_REGION"
echo ""

# 1. IAM Security
echo "1. IAM Security Checks"
echo "---------------------------------------------------"

echo "Root Account MFA:"
aws iam get-account-summary --query 'SummaryMap.AccountMFAEnabled' --output text | \
  xargs -I {} echo "  Status: {}"

echo ""
echo "IAM Users without MFA:"
aws iam list-users --query 'Users[*].UserName' --output text | \
  while read user; do
    MFA=$(aws iam list-mfa-devices --user-name $user --query 'length(MFADevices)' --output text)
    if [ "$MFA" -eq "0" ]; then
      echo "  ⚠️  $user - No MFA enabled"
    fi
  done

echo ""
echo "Active Access Keys (should rotate every 90 days):"
aws iam list-users --query 'Users[*].UserName' --output text | \
  while read user; do
    aws iam list-access-keys --user-name $user --query 'AccessKeyMetadata[*].[AccessKeyId,CreateDate,Status]' --output text | \
      while read key date status; do
        AGE_DAYS=$(( ( $(date +%s) - $(date -d "$date" +%s) ) / 86400 ))
        if [ $AGE_DAYS -gt 90 ]; then
          echo "  ⚠️  $user: Key $key is $AGE_DAYS days old (rotate recommended)"
        else
          echo "  ✅ $user: Key $key is $AGE_DAYS days old"
        fi
      done
  done

echo ""
echo "---------------------------------------------------"
echo ""

# 2. Security Groups
echo "2. Security Group Analysis"
echo "---------------------------------------------------"

echo "Security Groups with unrestricted access (0.0.0.0/0):"
aws ec2 describe-security-groups \
  --region $AWS_REGION \
  --query 'SecurityGroups[?IpPermissions[?IpRanges[?CidrIp==`0.0.0.0/0`]]].{ID:GroupId,Name:GroupName,VPC:VpcId}' \
  --output table

echo ""
echo "Open ports check:"
aws ec2 describe-security-groups \
  --region $AWS_REGION \
  --query 'SecurityGroups[*].{Group:GroupName,Ingress:IpPermissions[?IpRanges[?CidrIp==`0.0.0.0/0`]].[FromPort,ToPort]}' | \
  grep -v "null" | head -20

echo ""
echo "---------------------------------------------------"
echo ""

# 3. EBS Encryption
echo "3. EBS Volume Encryption Status"
echo "---------------------------------------------------"
aws ec2 describe-volumes \
  --region $AWS_REGION \
  --query 'Volumes[*].[VolumeId,Encrypted,State]' \
  --output table | \
  while read vol encrypted state; do
    if [ "$encrypted" = "False" ]; then
      echo "  ⚠️  Volume $vol is NOT encrypted"
    fi
  done

UNENCRYPTED=$(aws ec2 describe-volumes --region $AWS_REGION --query 'Volumes[?Encrypted==`false`] | length(@)' --output text)
if [ "$UNENCRYPTED" -eq "0" ]; then
  echo "  ✅ All EBS volumes are encrypted"
else
  echo "  ⚠️  Found $UNENCRYPTED unencrypted volumes"
fi

echo ""
echo "---------------------------------------------------"
echo ""

# 4. S3 Bucket Security (if any exist)
echo "4. S3 Bucket Security"
echo "---------------------------------------------------"
aws s3api list-buckets --query 'Buckets[*].Name' --output text 2>/dev/null | \
  while read bucket; do
    PUBLIC=$(aws s3api get-bucket-acl --bucket $bucket --query 'Grants[?Grantee.URI==`http://acs.amazonaws.com/groups/global/AllUsers`]' --output text 2>/dev/null)
    if [ -n "$PUBLIC" ]; then
      echo "  ⚠️  Bucket $bucket has public access"
    else
      echo "  ✅ Bucket $bucket is private"
    fi
  done

echo ""
echo "---------------------------------------------------"
echo ""

# 5. CloudTrail
echo "5. CloudTrail Logging"
echo "---------------------------------------------------"
TRAILS=$(aws cloudtrail describe-trails --region $AWS_REGION --query 'length(trailList)' --output text)
if [ "$TRAILS" -gt "0" ]; then
  echo "  ✅ CloudTrail enabled ($TRAILS trails)"
  aws cloudtrail describe-trails --region $AWS_REGION --query 'trailList[*].[Name,IsMultiRegionTrail]' --output table
else
  echo "  ⚠️  CloudTrail NOT enabled - consider enabling for audit logs"
fi

echo ""
echo "---------------------------------------------------"
echo ""

# 6. Secrets in Environment Variables
echo "6. Secrets Management Check"
echo "---------------------------------------------------"
echo "Lambda function environment variables (checking for hardcoded secrets):"
aws lambda list-functions --region $AWS_REGION --query 'Functions[*].FunctionName' --output text | \
  while read func; do
    VARS=$(aws lambda get-function-configuration --function-name $func --region $AWS_REGION --query 'Environment.Variables' --output json 2>/dev/null)
    if echo "$VARS" | grep -iq "password\|secret\|key"; then
      echo "  ⚠️  $func may have secrets in environment variables"
    else
      echo "  ✅ $func looks good"
    fi
  done

echo ""
echo "---------------------------------------------------"
echo ""

# Summary
echo "7. Security Score Summary"
echo "---------------------------------------------------"
SCORE=100
ISSUES=0

# Check for issues
[ "$UNENCRYPTED" -gt "0" ] && SCORE=$((SCORE-15)) && ISSUES=$((ISSUES+1)) && echo "  ⚠️  Unencrypted EBS volumes (-15 points)"
[ "$TRAILS" -eq "0" ] && SCORE=$((SCORE-20)) && ISSUES=$((ISSUES+1)) && echo "  ⚠️  CloudTrail not enabled (-20 points)"

echo ""
echo "Security Score: $SCORE/100"
echo "Issues Found: $ISSUES"

if [ $SCORE -eq 100 ]; then
  echo "✅ Excellent security posture!"
elif [ $SCORE -ge 80 ]; then
  echo "✅ Good security, minor improvements needed"
elif [ $SCORE -ge 60 ]; then
  echo "⚠️  Fair security, several improvements needed"
else
  echo "❌ Poor security, immediate action required"
fi

echo ""
echo "==================================================="
