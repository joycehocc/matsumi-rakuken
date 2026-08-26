#!/bin/bash
# ============================================================
# 推送脚本 - 使用 Token 方式（避免粘贴问题）
# 使用方法:
#   1. 开启 VPN
#   2. 打开 Terminal
#   3. 运行: bash push-token.sh 你的GitHubToken
#   例如: bash push-token.sh ghp_xxxxxxxxxxxxxxxxxxxx
# ============================================================

cd "$(dirname "$0")"

TOKEN="$1"

if [ -z "$TOKEN" ]; then
  echo "============================================"
  echo "  请提供你的 GitHub Personal Access Token"
  echo "============================================"
  echo ""
  echo "  使用方法:"
  echo "  bash push-token.sh 你的Token"
  echo ""
  echo "  例如:"
  echo "  bash push-token.sh ghp_abc123def456ghi789"
  echo ""
  echo "  Token 获取方式:"
  echo "  GitHub → Settings → Developer settings"
  echo "  → Personal access tokens → Generate new token"
  echo "  → 勾选 repo 权限 → 复制 Token"
  exit 1
fi

echo ""
echo "正在推送到 GitHub..."
echo ""

# 使用 Token 直接推送（不需要交互式输入密码）
git push --force "https://joycehocc:${TOKEN}@github.com/joycehocc/matsumi-rakuken.git" main

if [ $? -eq 0 ]; then
  echo ""
  echo "============================================"
  echo "  ✓ 推送成功!"
  echo "============================================"
  echo ""
  echo "  接下来在 Cloudflare 操作:"
  echo "  1. Settings → Builds & deployments"
  echo "  2. Root directory: 留空"
  echo "  3. Build output directory: public"
  echo "  4. Save → Deployments → Retry deployment"
else
  echo ""
  echo "============================================"
  echo "  ✗ 推送失败"
  echo "============================================"
  echo ""
  echo "  请检查:"
  echo "  1. VPN 是否已开启"
  echo "  2. Token 是否正确"
  echo "  3. Token 是否有 repo 权限"
fi
