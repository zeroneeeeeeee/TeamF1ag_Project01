#!/bin/bash

set -e
source "$(dirname "$0")/config.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 Step 0: GitHub Actions OIDC Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Region: $REGION"
echo ""

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "📋 AWS Account ID: $ACCOUNT_ID"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Step 1: OIDC Provider"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

OIDC_PROVIDER_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"

if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_PROVIDER_ARN" &>/dev/null 2>&1; then
    echo "✅ OIDC Provider already exists"
else
    echo "🔐 Creating OIDC Provider..."
    aws iam create-open-id-connect-provider \
        --url https://token.actions.githubusercontent.com \
        --client-id-list sts.amazonaws.com
    echo "✅ OIDC Provider created"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "👤 Step 2: IAM Role"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ROLE_NAME="GitHubActionsDeployRole"

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
        --description "GitHub Actions role for CloudFormation deployment"

    rm /tmp/trust-policy.json

    ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

    echo "✅ IAM Role created"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔑 Step 3: Permissions Policy"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

POLICY_NAME="GitHubActionsDeployPolicy"

if aws iam get-role-policy --role-name "$ROLE_NAME" --policy-name "$POLICY_NAME" &>/dev/null 2>&1; then
    echo "📝 Permissions Policy already exists - updating to latest version..."
else
    echo "🔑 Creating Permissions Policy..."
fi

cat > /tmp/permissions-policy.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudformation:*",
        "s3:*",
        "ec2:*",
        "ecs:*",
        "elasticloadbalancing:*",
        "logs:*",
        "rds:*",
        "elasticache:*",
        "secretsmanager:*",
        "kms:DescribeKey",
        "iam:GetRole",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRolePolicy"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowPassRoleToECS",
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": [
        "arn:aws:iam::*:role/*-ecs-task-execution-role",
        "arn:aws:iam::*:role/*-ecs-task-role"
      ],
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": "ecs-tasks.amazonaws.com"
        }
      }
    },
    {
      "Sid": "AllowCreateServiceLinkedRole",
      "Effect": "Allow",
      "Action": "iam:CreateServiceLinkedRole",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "iam:AWSServiceName": [
            "ecs.amazonaws.com",
            "elasticloadbalancing.amazonaws.com",
            "rds.amazonaws.com",
            "elasticache.amazonaws.com"
          ]
        }
      }
    }
  ]
}
EOF

aws iam put-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-name "$POLICY_NAME" \
    --policy-document file:///tmp/permissions-policy.json

rm /tmp/permissions-policy.json
echo "✅ Permissions Policy updated"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ GitHub Actions OIDC Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Summary:"
echo "   - OIDC Provider: arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
echo "   - IAM Role ARN: $ROLE_ARN"
echo "   - GitHub Repo: $GITHUB_REPO"
echo ""
echo "📝 Next Steps:"
echo ""
echo "1️⃣ Update .github/workflows/deploy.yml:"
echo ""
echo "   permissions:"
echo "     id-token: write"
echo "     contents: read"
echo ""
echo "   steps:"
echo "     - name: Configure AWS Credentials"
echo "       uses: aws-actions/configure-aws-credentials@v5.1.0"
echo "       with:"
echo "         role-to-assume: $ROLE_ARN"
echo "         aws-region: $REGION"
echo ""
echo "2️⃣ Remove from deploy.yml:"
echo "   - aws-access-key-id"
echo "   - aws-secret-access-key"
echo ""
echo "3️⃣ Delete GitHub Secrets (optional):"
echo "   GitHub Repo → Settings → Secrets → Actions"
echo "   - Delete: AWS_ACCESS_KEY_ID"
echo "   - Delete: AWS_SECRET_ACCESS_KEY"
echo ""
echo "4️⃣ Test workflow:"
echo "   git add .github/workflows/deploy.yml"
echo "   git commit -m 'Switch to OIDC authentication'"
echo "   git push origin main"
echo ""
echo "📖 Reference:"
echo "   https://github.com/aws-actions/configure-aws-credentials"
echo "   https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services"
echo "   https://docs.aws.amazon.com/cli/latest/reference/"
echo ""

