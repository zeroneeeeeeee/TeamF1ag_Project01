#!/bin/bash

set -e
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/config.sh"

KMS_KEY_ARN="${KMS_KEY_ARN:-REPLACE_WITH_KMS_KEY_ARN}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Generating params files from config.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   ENV: ${ENV}"
echo "   APP_NAME: ${APP_NAME}"
echo "   APP_PORT: ${APP_PORT}"
echo ""

mkdir -p params

cat > params/dev-running.json <<EOF
[
  {
    "ParameterKey": "Env",
    "ParameterValue": "${ENV}"
  },
  {
    "ParameterKey": "KmsKeyArn",
    "ParameterValue": "${KMS_KEY_ARN}"
  },
  {
    "ParameterKey": "ImageUri",
    "ParameterValue": "${IMAGE_URI}"
  },
  {
    "ParameterKey": "AppName",
    "ParameterValue": "${APP_NAME}"
  },
  {
    "ParameterKey": "AppPort",
    "ParameterValue": "${APP_PORT}"
  },
  {
    "ParameterKey": "DesiredCount",
    "ParameterValue": "${DESIRED_COUNT_START:-2}"
  },
  {
    "ParameterKey": "Cpu",
    "ParameterValue": "${CPU}"
  },
  {
    "ParameterKey": "Memory",
    "ParameterValue": "${MEMORY}"
  },
  {
    "ParameterKey": "AcmCertificateArn",
    "ParameterValue": ""
  }
]
EOF

cat > params/dev-stopped.json <<EOF
[
  {
    "ParameterKey": "Env",
    "ParameterValue": "${ENV}"
  },
  {
    "ParameterKey": "KmsKeyArn",
    "ParameterValue": "${KMS_KEY_ARN}"
  },
  {
    "ParameterKey": "ImageUri",
    "ParameterValue": "${IMAGE_URI}"
  },
  {
    "ParameterKey": "AppName",
    "ParameterValue": "${APP_NAME}"
  },
  {
    "ParameterKey": "AppPort",
    "ParameterValue": "${APP_PORT}"
  },
  {
    "ParameterKey": "DesiredCount",
    "ParameterValue": "${DESIRED_COUNT_STOP:-0}"
  },
  {
    "ParameterKey": "Cpu",
    "ParameterValue": "${CPU}"
  },
  {
    "ParameterKey": "Memory",
    "ParameterValue": "${MEMORY}"
  },
  {
    "ParameterKey": "AcmCertificateArn",
    "ParameterValue": ""
  }
]
EOF

echo "✅ Generated params/dev-running.json"
echo "✅ Generated params/dev-stopped.json"
echo ""
echo "⚠️  Remember to update:"
echo "   - KmsKeyArn: ${KMS_KEY_ARN}"
echo "   - ImageUri: ${IMAGE_URI} (from config.sh)"
echo "   (Run ./scripts/setup-all.sh to get KMS Key ARN)"

