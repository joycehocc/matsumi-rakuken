#!/bin/bash
# ============================================================
# 松美洛贤教育科技 - Cloudflare 一键部署脚本
# 使用方法: bash deploy.sh
# ============================================================

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_NAME="matsumi-rakuken"
DB_NAME="matsumi-db"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() { echo ""; echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${GREEN}▶ $1${NC}"; echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }
print_ok()   { echo -e "${GREEN}  ✓ $1${NC}"; }
print_warn() { echo -e "${YELLOW}  ⚠ $1${NC}"; }
print_err()  { echo -e "${RED}  ✗ $1${NC}"; }
print_info() { echo -e "${BLUE}  ℹ $1${NC}"; }

echo ""
echo "============================================"
echo "  松美洛贤教育科技 - Cloudflare 部署脚本"
echo "============================================"
echo ""
echo "  项目目录: $PROJECT_DIR"
echo "  项目名称: $PROJECT_NAME"
echo "  数据库名称: $DB_NAME"
echo ""

# ============================================================
# 步骤 1: 检查并安装 Node.js
# ============================================================
print_step "步骤 1/7: 检查 Node.js 环境"

NODE_OK=false

# 尝试找到可用的 node
for node_path in /usr/local/bin/node /opt/homebrew/bin/node $(command -v node 2>/dev/null); do
  if [ -x "$node_path" ]; then
    if "$node_path" -v >/dev/null 2>&1; then
      NODE_VERSION=$("$node_path" -v)
      print_ok "找到 Node.js: $node_path ($NODE_VERSION)"
      export PATH="$(dirname "$node_path"):$PATH"
      NODE_OK=true
      break
    fi
  fi
done

if [ "$NODE_OK" = false ]; then
  print_warn "未找到可用的 Node.js，开始安装 Homebrew + Node.js..."

  # 检查 Homebrew
  BREW_PATH=""
  for brew_path in /usr/local/bin/brew /opt/homebrew/bin/brew /opt/homebrew/bin/brew; do
    if [ -x "$brew_path" ]; then
      BREW_PATH="$brew_path"
      break
    fi
  done

  if [ -z "$BREW_PATH" ]; then
    print_info "安装 Homebrew（可能需要几分钟）..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # 重新检测
    for brew_path in /usr/local/bin/brew /opt/homebrew/bin/brew; do
      if [ -x "$brew_path" ]; then
        BREW_PATH="$brew_path"
        break
      fi
    done
  fi

  if [ -n "$BREW_PATH" ]; then
    print_ok "Homebrew 已安装: $BREW_PATH"
    eval "$("$BREW_PATH" shellenv)"
    print_info "安装 Node.js（可能需要几分钟）..."
    brew install node
    print_ok "Node.js 安装完成: $(node -v)"
  else
    print_err "Homebrew 安装失败"
    echo ""
    echo "请手动安装 Node.js："
    echo "  1. 打开 https://nodejs.org"
    echo "  2. 下载 LTS 版本（.pkg 安装包）"
    echo "  3. 双击安装"
    echo "  4. 重新运行此脚本: bash deploy.sh"
    exit 1
  fi
fi

# ============================================================
# 步骤 2: 安装 Wrangler
# ============================================================
print_step "步骤 2/7: 安装 Cloudflare Wrangler CLI"

if npx wrangler --version >/dev/null 2>&1; then
  print_ok "Wrangler 已安装: $(npx wrangler --version)"
else
  print_info "安装 Wrangler..."
  npm install -g wrangler
  print_ok "Wrangler 安装完成: $(wrangler --version)"
fi

# ============================================================
# 步骤 3: 登录 Cloudflare
# ============================================================
print_step "步骤 3/7: 登录 Cloudflare"

if wrangler whoami >/dev/null 2>&1; then
  print_ok "已登录 Cloudflare: $(wrangler whoami 2>&1 | grep -o 'authenticated.*' || echo '已认证')"
else
  print_info "即将打开浏览器进行 Cloudflare 授权..."
  print_info "请在浏览器中点击 Allow 授权"
  echo ""
  read -p "按回车键继续..." _
  wrangler login
  if wrangler whoami >/dev/null 2>&1; then
    print_ok "Cloudflare 登录成功"
  else
    print_err "登录失败，请重试"
    exit 1
  fi
fi

# ============================================================
# 步骤 4: 创建 D1 数据库
# ============================================================
print_step "步骤 4/7: 创建 D1 数据库"

DB_EXISTS=$(wrangler d1 list 2>&1 | grep "$DB_NAME" || true)

if [ -n "$DB_EXISTS" ]; then
  print_ok "数据库 $DB_NAME 已存在"
else
  print_info "创建数据库 $DB_NAME..."
  DB_OUTPUT=$(wrangler d1 create "$DB_NAME" 2>&1)
  echo "$DB_OUTPUT"
  print_ok "数据库创建成功"
fi

# 获取 database_id
print_info "获取数据库 ID..."
DB_ID=$(wrangler d1 list 2>&1 | grep "$DB_NAME" | awk '{print $1}' || true)

if [ -n "$DB_ID" ]; then
  print_ok "数据库 ID: $DB_ID"

  # 更新 wrangler.toml
  if grep -q "在下面部署步骤中获取" "$PROJECT_DIR/wrangler.toml"; then
    sed -i.bak "s/在下面部署步骤中获取/$DB_ID/" "$PROJECT_DIR/wrangler.toml"
    rm -f "$PROJECT_DIR/wrangler.toml.bak"
    print_ok "已更新 wrangler.toml 中的 database_id"
  fi
else
  print_warn "无法自动获取数据库 ID"
  print_info "请手动查找数据库 ID 并填入 wrangler.toml"
  echo "  运行: wrangler d1 list"
  echo "  找到 $DB_NAME 对应的 ID，填入 wrangler.toml"
fi

# ============================================================
# 步骤 5: 初始化数据库表结构
# ============================================================
print_step "步骤 5/7: 初始化数据库表结构"

print_info "执行 schema.sql..."
wrangler d1 execute "$DB_NAME" --remote --file="$PROJECT_DIR/schema.sql" 2>&1 || {
  print_warn "远程执行失败，尝试本地执行..."
  wrangler d1 execute "$DB_NAME" --local --file="$PROJECT_DIR/schema.sql" 2>&1
}
print_ok "数据库表结构已创建"

# ============================================================
# 步骤 6: 设置管理密码
# ============================================================
print_step "步骤 6/7: 设置管理密码"

read -p "请输入管理后台密码（默认 matsumi2026，直接回车使用默认值）: " ADMIN_PWD
ADMIN_PWD=${ADMIN_PWD:-matsumi2026}

# 保存到 .dev.vars 文件（本地开发用）
cat > "$PROJECT_DIR/.dev.vars" << EOF
ADMIN_PASSWORD="$ADMIN_PWD"
ADMIN_SECRET="matsumi-rakuken-$(date +%s)"
EOF
print_ok "密码已保存到 .dev.vars"

print_warn "注意：部署后还需在 Cloudflare 网页后台设置环境变量"
echo "  路径: Pages 项目 → Settings → Environment Variables"
echo "  变量名: ADMIN_PASSWORD"
echo "  值: $ADMIN_PWD"

# ============================================================
# 步骤 7: 部署到 Cloudflare Pages
# ============================================================
print_step "步骤 7/7: 部署到 Cloudflare Pages"

print_info "开始部署..."
echo ""

wrangler pages deploy "$PROJECT_DIR/public" --project-name="$PROJECT_NAME" 2>&1 || {
  print_err "部署失败"
  echo ""
  echo "常见问题："
  echo "  1. 如果提示项目不存在，请先在 Cloudflare Dashboard 创建 Pages 项目"
  echo "     路径: Workers & Pages → Create → Pages → Upload assets"
  echo "  2. 如果提示权限不足，请确认 wrangler login 已成功"
  echo ""
  echo "也可以尝试手动上传："
  echo "  1. 打开 https://dash.cloudflare.com → Workers & Pages → Create"
  echo "  2. 选择 Pages → Upload assets"
  echo "  3. 项目名称: $PROJECT_NAME"
  echo "  4. 上传 $PROJECT_DIR/public 目录下的所有文件"
  exit 1
}

# ============================================================
# 部署完成
# ============================================================
echo ""
echo "============================================================"
echo -e "${GREEN}  ✓ 部署完成！${NC}"
echo "============================================================"
echo ""
echo "  你的网站: https://$PROJECT_NAME.pages.dev"
echo "  管理后台: https://$PROJECT_NAME.pages.dev/admin"
echo "  管理密码: $ADMIN_PWD"
echo ""
echo "  接下来需要完成的操作（在浏览器中）："
echo ""
echo "  1. 绑定 D1 数据库："
echo "     Cloudflare Dashboard → Pages → $PROJECT_NAME"
echo "     → Settings → Functions → D1 database bindings"
echo "     → 变量名: DB → 选择: $DB_NAME"
echo ""
echo "  2. 设置环境变量："
echo "     → Settings → Environment Variables"
echo "     → 添加: ADMIN_PASSWORD = $ADMIN_PWD"
echo ""
echo "  3. 重新部署："
echo "     → Deployments → Retry deployment"
echo ""
echo "  4. 绑定自定义域名："
echo "     → Custom domains → Set up a custom domain"
echo "     → 输入你的域名 → 自动配置 HTTPS"
echo ""
echo "  详细指南: $PROJECT_DIR/README.md"
echo "============================================================"
echo ""
