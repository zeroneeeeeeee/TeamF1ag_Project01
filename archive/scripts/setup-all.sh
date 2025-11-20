#!/bin/bash

set -e

SCRIPT_DIR="$(dirname "$0")"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 CloudFormation Prerequisites Setup - All"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ROLE_OUTPUT=$("$SCRIPT_DIR/00-setup-github-oidc.sh" | tee /dev/tty | grep "IAM Role ARN:" | cut -d: -f2- | xargs)

"$SCRIPT_DIR/01-setup-s3.sh"

KMS_OUTPUT=$("$SCRIPT_DIR/02-setup-kms.sh" | tee /dev/tty | grep "KMS Key ARN:" | cut -d: -f2- | xargs)


echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All Prerequisites Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

source "$SCRIPT_DIR/config.sh"

echo "📋 Summary:"
echo "   - IAM Role ARN: $ROLE_OUTPUT (OIDC)"
echo "   - S3 Bucket: $S3_BUCKET"
echo "   - KMS Key ARN: $KMS_OUTPUT"
echo ""
echo "📝 Next Steps:"
echo ""
echo "1️⃣ Update .github/workflows/deploy.yml:"
echo "   - Replace REPLACE_WITH_ACCOUNT_ID with your actual Account ID"
echo "   - Or use Role ARN: $ROLE_OUTPUT"
echo ""
echo "2️⃣ GitHub Actions가 자동으로 처리:"
echo "   - config.sh 로드 → 파라미터 자동 생성"
echo "   - KMS Key ARN: AWS에서 자동 조회"
echo "   - Image URI: config.sh에서 가져옴 (퍼블릭 레지스트리)"
echo "   - params 파일 불필요!"
echo ""
echo "3️⃣ Commit and push to GitHub:"
echo "   git add ."
echo "   git commit -m 'Setup infrastructure with OIDC'"
echo "   git push origin main"
echo ""
echo ""
echo "4️⃣ Docker 이미지:"
echo "   - 퍼블릭 레지스트리 사용: ghcr.io/ctfd/ctfd:latest"
echo "   - config.sh의 IMAGE_URI에 설정되어 있음"
echo "   - 별도 빌드/푸시 불필요"
echo ""

