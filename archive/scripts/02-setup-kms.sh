#!/bin/bash

set -e
source "$(dirname "$0")/config.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 Step 2: KMS Key Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Alias: $KMS_ALIAS"
echo "   Region: $REGION"
echo ""

if aws kms describe-key --key-id $KMS_ALIAS --region $REGION &>/dev/null 2>&1; then
    echo "✅ KMS key already exists"
    KMS_KEY_ARN=$(aws kms describe-key \
        --key-id $KMS_ALIAS \
        --region $REGION \
        --query 'KeyMetadata.Arn' \
        --output text)
    KMS_KEY_ID=$(aws kms describe-key \
        --key-id $KMS_ALIAS \
        --region $REGION \
        --query 'KeyMetadata.KeyId' \
        --output text)
else
    echo "🔐 Creating KMS key..."
    
    KMS_KEY_ID=$(aws kms create-key \
        --description "Infrastructure encryption key for ${ENV} environment (CloudWatch Logs, RDS, Secrets Manager)" \
        --region $REGION \
        --query 'KeyMetadata.KeyId' \
        --output text)
    
    aws kms create-alias \
        --alias-name $KMS_ALIAS \
        --target-key-id $KMS_KEY_ID \
        --region $REGION
    
    aws kms enable-key-rotation \
        --key-id $KMS_KEY_ID \
        --region $REGION
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

cat > /tmp/kms-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${ACCOUNT_ID}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow CloudWatch Logs",
      "Effect": "Allow",
      "Principal": {
        "Service": "logs.${REGION}.amazonaws.com"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:CreateGrant"
      ],
      "Resource": "*",
      "Condition": {
        "ArnLike": {
          "kms:EncryptionContext:aws:logs:arn": "arn:aws:logs:${REGION}:${ACCOUNT_ID}:log-group:/ecs/${ENV}/*"
        }
      }
    },
    {
      "Sid": "Allow CloudWatch Logs DescribeKey",
      "Effect": "Allow",
      "Principal": {
        "Service": "logs.${REGION}.amazonaws.com"
      },
      "Action": [
        "kms:DescribeKey"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Allow RDS",
      "Effect": "Allow",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:CreateGrant"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Allow Secrets Manager",
      "Effect": "Allow",
      "Principal": {
        "Service": "secretsmanager.amazonaws.com"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:CreateGrant"
      ],
      "Resource": "*"
    }
  ]
}
EOF


aws kms put-key-policy \
    --key-id $KMS_KEY_ID \
    --policy-name default \
    --policy file:///tmp/kms-policy.json \
    --region $REGION

rm /tmp/kms-policy.json

KMS_KEY_ARN=$(aws kms describe-key \
    --key-id $KMS_ALIAS \
    --region $REGION \
    --query 'KeyMetadata.Arn' \
    --output text)

echo "✅ KMS key configured/updated (policy re-applied)"

echo ""
echo "📋 KMS Key ARN: $KMS_KEY_ARN"
echo ""

