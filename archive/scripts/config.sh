#!/bin/bash

export REGION="ap-northeast-2"
export ENV="test"  # dev, test 또는 prod

export APP_NAME="ctfd"
export APP_PORT="8000"
export IMAGE_URI="ghcr.io/ctfd/ctfd:latest"  # 퍼블릭 레지스트리 사용 (ECR 사용 안 함)
export CPU="512"  # CTFd 최소 요구사항: 0.5 vCPU
export MEMORY="1024"  # CTFd 최소 요구사항: 1GB

export DESIRED_COUNT_START="2"  # Task 시작 시 개수
export DESIRED_COUNT_STOP="0"   # Task 중지 시 개수

export STACK_NAME="${ENV}-root"

export S3_BUCKET_BASE="my-cfn-artifacts"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
if [ -z "$ACCOUNT_ID" ]; then
    echo "❌ Error: Could not get AWS Account ID. Account ID is required for S3 bucket name uniqueness."
    echo "   Please ensure AWS CLI is configured: aws configure"
    exit 1
else
    export ACCOUNT_ID  # GitHub Actions에서 Role ARN 구성에 사용
    export S3_BUCKET="my-cfn-artifacts-${ENV}-${ACCOUNT_ID}"
    echo "✅ Account ID detected: ${ACCOUNT_ID}"
fi

export KMS_ALIAS="alias/${ENV}-infra"  # 인프라 전반 암호화용 (CloudWatch Logs, RDS, Secrets Manager)

if [ "${ENV}" = "dev" ]; then
    export EXISTING_UPLOAD_BUCKET_NAME="dev-ctfd-uploads-${ACCOUNT_ID}"  # dev: 기존 버킷 재사용
elif [ "${ENV}" = "prod" ]; then
    export EXISTING_UPLOAD_BUCKET_NAME="prod-ctfd-uploads-${ACCOUNT_ID}"  # prod: 기존 버킷 재사용
else
    export EXISTING_UPLOAD_BUCKET_NAME=""  # test: 새 버킷 생성
fi


export GITHUB_REPO="zeroneeeeeeee/TeamF1ag_Project01"

