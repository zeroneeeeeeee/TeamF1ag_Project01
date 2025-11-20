#!/bin/bash

set -e
source "$(dirname "$0")/../scripts/config.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Step 3: ECR Repository Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Region: $REGION"
echo ""

ECR_REPOSITORY_NAME="${ECR_REPOSITORY_NAME:-teamf1ag-ecr}"

echo "📋 ECR Repository Name: $ECR_REPOSITORY_NAME"
echo ""

if aws ecr describe-repositories --repository-names "$ECR_REPOSITORY_NAME" --region $REGION &>/dev/null 2>&1; then
    echo "✅ ECR Repository already exists"
    ECR_REPOSITORY_URI=$(aws ecr describe-repositories \
        --repository-names "$ECR_REPOSITORY_NAME" \
        --region $REGION \
        --query 'repositories[0].repositoryUri' \
        --output text)
else
    echo "📦 Creating ECR Repository..."

    aws ecr create-repository \
        --repository-name "$ECR_REPOSITORY_NAME" \
        --region $REGION \
        --image-scanning-configuration scanOnPush=true \
        --image-tag-mutability MUTABLE

    cat > /tmp/lifecycle-policy.json <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 10 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF

    aws ecr put-lifecycle-policy \
        --repository-name "$ECR_REPOSITORY_NAME" \
        --lifecycle-policy-text file:///tmp/lifecycle-policy.json \
        --region $REGION

    rm /tmp/lifecycle-policy.json

    ECR_REPOSITORY_URI=$(aws ecr describe-repositories \
        --repository-names "$ECR_REPOSITORY_NAME" \
        --region $REGION \
        --query 'repositories[0].repositoryUri' \
        --output text)

    echo "✅ ECR Repository created"
fi

echo ""
echo "📋 ECR Repository URI: $ECR_REPOSITORY_URI"
echo ""
echo "📝 Next Steps:"
echo ""
echo "1️⃣ Update config.sh (optional):"
echo "   export ECR_REPOSITORY_NAME=\"$ECR_REPOSITORY_NAME\""
echo ""
echo "2️⃣ Docker 이미지 빌드 및 푸시:"
echo "   aws ecr get-login-password --region $REGION | \\"
echo "     docker login --username AWS --password-stdin $ECR_REPOSITORY_URI"
echo ""
echo "   docker build -t $ECR_REPOSITORY_NAME:latest ."
echo "   docker tag $ECR_REPOSITORY_NAME:latest $ECR_REPOSITORY_URI:latest"
echo "   docker push $ECR_REPOSITORY_URI:latest"
echo ""
echo "3️⃣ Update CloudFormation parameters:"
echo "   ImageUri: $ECR_REPOSITORY_URI:latest"
echo ""

