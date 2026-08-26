#!/bin/bash
# ============================================================
# 松美洛贤教育科技 - GitHub 推送脚本
# 使用方法:
#   1. 开启 VPN/代理
#   2. 打开终端 (Terminal)
#   3. 运行: bash push-to-github.sh
# ============================================================

cd "$(dirname "$0")"

echo "============================================"
echo "  推送正确的文件结构到 GitHub"
echo "============================================"
echo ""

# 确保在正确的目录
echo "当前目录: $(pwd)"
echo "文件列表:"
ls -la
echo ""

# 检查是否有 functions 和 public 目录
if [ ! -d "functions" ] || [ ! -d "public" ]; then
  echo "错误: functions/ 或 public/ 目录不存在!"
  echo "请确保在 cloudflare-deploy 目录中运行此脚本"
  exit 1
fi

echo "✓ functions/ 目录存在"
echo "✓ public/ 目录存在"
echo ""

# 确保 remote 已设置
if ! git remote get-url origin &>/dev/null; then
  git remote add origin https://github.com/joycehocc/matsumi-rakuken.git
  echo "✓ 已添加 GitHub remote"
else
  git remote set-url origin https://github.com/joycehocc/matsumi-rakuken.git
  echo "✓ 已更新 GitHub remote"
fi

echo ""
echo "准备推送到 https://github.com/joycehocc/matsumi-rakuken"
echo ""
echo "如果提示输入:"
echo "  Username: joycehocc"
echo "  Password: 你的 GitHub Personal Access Token"
echo "  (不是登录密码! 在 GitHub → Settings → Developer settings → Personal access tokens 生成)"
echo ""

# 强制推送（替换 GitHub 上的错误文件）
git push --force origin main

if [ $? -eq 0 ]; then
  echo ""
  echo "============================================"
  echo "  ✓ 推送成功!"
  echo "============================================"
  echo ""
  echo "  现在去 Cloudflare Pages 重新部署:"
  echo "  1. Cloudflare Dashboard → Workers & Pages → 你的项目"
  echo "  2. Settings → Builds & deployments"
  echo "  3. Root directory: 留空"
  echo "  4. Build output directory: public"
  echo "  5. Save → Deployments → Retry deployment"
  echo ""
else
  echo ""
  echo "============================================"
  echo "  ✗ 推送失败"
  echo "============================================"
  echo ""
  echo "  请检查:"
  echo "  1. VPN/代理是否已开启"
  echo "  2. GitHub 用户名和 Token 是否正确"
  echo "  3. Token 是否有 repo 权限"
fi
