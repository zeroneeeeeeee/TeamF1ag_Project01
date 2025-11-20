#!/bin/bash

set -e
source "$(dirname "$0")/config.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Step 1: S3 Bucket Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Region: $REGION"
echo "   Bucket: $S3_BUCKET"
echo "   Note: Bucket name includes Account ID for global uniqueness"
echo ""

if aws s3 ls "s3://$S3_BUCKET" --region $REGION &>/dev/null 2>&1; then
    echo "✅ S3 bucket already exists"
else
    echo "📦 Creating S3 bucket..."
    aws s3 mb "s3://$S3_BUCKET" --region $REGION
    
    aws s3api put-public-access-block \
        --bucket $S3_BUCKET \
        --public-access-block-configuration \
            BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true \
        --region $REGION
    
    echo "✅ S3 bucket created and configured"
fi

echo ""
echo "📋 S3 Bucket: s3://$S3_BUCKET"
echo ""

