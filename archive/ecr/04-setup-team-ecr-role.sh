#!/bin/bash

set -e
source "$(dirname "$0")/../scripts/config.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "👤 Step 4: Team ECR Push Role Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Region: $REGION"
echo ""

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "📋 AWS Account ID: $ACCOUNT_ID"
echo ""

if [ -z "$GITHUB_REPO" ]; then
    echo "⚠️  GITHUB_REPO not set in config.sh"
    read -p "Enter GitHub Repository (format: username/repo): " GITHUB_REPO
    if [ -z "$GITHUB_REPO" ]; then
        echo "❌ Error: GitHub Repository is required"
        exit 1
    fi
fi

echo "   GitHub Repo: $GITHUB_REPO"
echo ""

ECR_REPOSITORY_NAME="${ECR_REPOSITORY_NAME:-teamf1ag-ecr}"

ROLE_NAME="TeamECRPushRole"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "👤 Step 1: IAM Role"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if aws iam get-role --role-name "$ROLE_NAME" &>/dev/null 2>&1; then
    echo "✅ IAM Role already exists"
    ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)
else
    echo "👤 Creating IAM Role..."
    cat > /tmp/trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_REPO}:ref:refs/heads/main"
        }
      }
    }
  ]
}
EOF

    aws iam create-role \
        --role-name "$ROLE_NAME" \
        --assume-role-policy-document file:///tmp/trust-policy.json \
        --description "GitHub Actions role for ECR image push"

    rm /tmp/trust-policy.json

    ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

    echo "✅ IAM Role created"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔑 Step 2: ECR Permissions Policy"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

POLICY_NAME="TeamECRPushPolicy"

if aws iam get-role-policy --role-name "$ROLE_NAME" --policy-name "$POLICY_NAME" &>/dev/null 2>&1; then
    echo "📝 Permissions Policy already exists - updating to latest version..."
else
    echo "🔑 Creating Permissions Policy..."
fi

cat > /tmp/ecr-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "arn:aws:ecr:${REGION}:${ACCOUNT_ID}:repository/${ECR_REPOSITORY_NAME}"
    }
  ]
}
EOF

aws iam put-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-name "$POLICY_NAME" \
    --policy-document file:///tmp/ecr-policy.json

rm /tmp/ecr-policy.json
echo "✅ ECR Permissions Policy updated"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Team ECR Push Role Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Summary:"
echo "   - IAM Role ARN: $ROLE_ARN"
echo "   - ECR Repository: $ECR_REPOSITORY_NAME"
echo "   - GitHub Repo: $GITHUB_REPO"
echo ""
echo "📝 Next Steps:"
echo ""
echo "1️⃣ Update .github/workflows/push-to-ecr-example.yml:"
echo ""
echo "   env:"
echo "     AWS_ROLE_ARN: $ROLE_ARN"
echo "     ECR_REPOSITORY_NAME: $ECR_REPOSITORY_NAME"
echo ""
echo "2️⃣ Enable workflow in .github/workflows/push-to-ecr-example.yml"
echo "   (Remove # comments)"
echo ""
echo "3️⃣ Test workflow:"
echo "   git add .github/workflows/push-to-ecr-example.yml"
echo "   git commit -m 'Enable ECR push workflow'"
echo "   git push origin main"
echo ""
