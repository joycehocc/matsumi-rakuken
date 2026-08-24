# 松美洛贤教育科技 - Cloudflare 部署指南

## 项目结构

```
cloudflare-deploy/
├── functions/              ← API (Pages Functions)
│   └── api/
│       ├── submit.js       ← POST /api/submit (提交留言)
│       ├── login.js        ← POST /api/login (管理员登录)
│       ├── export.js       ← GET /api/export (导出CSV)
│       └── submissions/
│           ├── index.js    ← GET/DELETE /api/submissions
│           └── [id].js     ← DELETE /api/submissions/:id
├── public/                 ← 静态文件
│   ├── index.html          ← 公司网站
│   ├── admin.html          ← 管理后台
│   └── _redirects          ← 路由规则 (/admin → /admin.html)
├── schema.sql              ← D1 数据库表结构
├── wrangler.toml           ← Cloudflare 配置
├── package.json
└── .gitignore
```

## 部署步骤

### 第一步：注册账号

1. **GitHub**: 注册 github.com（代码托管）
2. **Cloudflare**: 注册 dash.cloudflare.com（部署 + 数据库 + 域名）

### 第二步：推送到 GitHub

1. 在 GitHub 创建仓库，命名为 `matsumi-rakuken`（或任意名称）
2. 在本地执行：

```bash
cd cloudflare-deploy
git init
git add .
git commit -m "Initial commit - Cloudflare Pages deploy"
git branch -M main
git remote add origin https://github.com/你的用户名/matsumi-rakuken.git
git push -u origin main
```

### 第三步：创建 Cloudflare D1 数据库

**方法 A：网页操作（推荐新手）**

1. 登录 Cloudflare Dashboard
2. 左侧菜单 → Workers & Pages → D1
3. 点击 Create Database
4. 数据库名称输入 `matsumi-db`
5. 创建后，点击进入数据库
6. 点击 Console 标签
7. 粘贴 schema.sql 的内容并执行：

```sql
CREATE TABLE IF NOT EXISTS submissions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  phone TEXT,
  email TEXT,
  service TEXT,
  message TEXT,
  time TEXT,
  ip TEXT
);
```
8. 记下 Database ID（在数据库概览页面可以看到）

**方法 B：命令行操作**

```bash
# 安装 wrangler
npm install -g wrangler

# 登录 Cloudflare
wrangler login

# 创建数据库
wrangler d1 create matsumi-db

# 输出会显示 database_id，复制它

# 执行 schema
wrangler d1 execute matsumi-db --file=schema.sql
```

### 第四步：在 Cloudflare 创建 Pages 项目

**方法 A：通过 GitHub 连接（推荐，自动部署）**

1. Cloudflare Dashboard → Workers & Pages → Create
2. 选择 Pages → Connect to Git
3. 授权并选择你的 GitHub 仓库 `matsumi-rakuken`
4. 构建设置：
   - Framework preset: None
   - Build command: 留空
   - Build output directory: `public`
5. 展开 Environment Variables，添加：

   | 变量名 | 值 | 说明 |
   |--------|-----|------|
   | `ADMIN_PASSWORD` | 你的管理密码 | 登录后台用，如 `matsumi2026` |

6. 点击 Save and Deploy
7. 部署完成后会得到 `https://matsumi-rakuken.pages.dev` 这样的网址

**方法 B：通过命令行部署**

1. 编辑 `wrangler.toml`，填入你的 database_id
2. 执行：

```bash
npm install
wrangler pages deploy public --project-name=matsumi-rakuken
```

### 第五步：绑定 D1 数据库

1. Cloudflare Dashboard → Workers & Pages → 你的 Pages 项目
2. Settings → Functions → D1 database bindings
3. 添加绑定：
   - Variable name: `DB`
   - D1 database: 选择 `matsumi-db`
4. 保存后重新部署（在 Deployments 中点击 Retry deployment）

### 第六步：设置自定义域名

1. 确保你的域名已添加到 Cloudflare（在 Cloudflare Dashboard → Websites 中添加）
   - 如果域名注册商不是 Cloudflare，需要将域名的 DNS 服务器改为 Cloudflare 提供的 NS 记录
   - Cloudflare 会自动处理 DNS 和 SSL 证书

2. 回到 Pages 项目 → Custom domains → Set up a custom domain
3. 输入你的域名，例如 `www.matsumi.com` 或 `matsumi.com`
4. Cloudflare 会自动添加 CNAME 记录
5. 等待 DNS 生效（通常几分钟到几小时）
6. SSL 证书会自动签发（免费）

**如果域名不在 Cloudflare 管理：**
1. 在你的域名注册商处，添加 CNAME 记录：
   - 名称: `www`（或 `@`）
   - 目标: `matsumi-rakuken.pages.dev`
2. 等待 DNS 生效
3. 在 Pages → Custom domains 中添加域名
4. Cloudflare 会自动签发 SSL 证书

### 第七步：验证部署

1. 访问 `https://你的域名` — 应看到公司网站
2. 访问 `https://你的域名/admin` — 应看到管理后台登录页
3. 输入管理密码登录 — 应看到留言数据管理页面
4. 在网站上提交一条留言 — 在后台应能看到该留言

## 常见问题

### Q: 后台显示"无法连接服务器"？
A: 检查 D1 数据库绑定是否配置正确（Variable name 必须是 `DB`），并确保已重新部署。

### Q: 自定义域名显示不安全？
A: 等待几分钟让 SSL 证书自动签发。如果域名 DNS 不在 Cloudflare 管理，确保 CNAME 记录正确指向 `xxx.pages.dev`。

### Q: 每次推送代码后会自动部署吗？
A: 是的，通过 GitHub 连接的 Pages 项目会在每次 push 到 main 分支时自动部署。

### Q: 如何修改管理密码？
A: 在 Cloudflare Dashboard → Pages 项目 → Settings → Environment Variables 中修改 `ADMIN_PASSWORD` 的值，然后重新部署。

### Q: 数据存储在哪里？
A: 存储在 Cloudflare D1 数据库中（SQLite），免费额度：500MB 存储、500万行读取/天、10万行写入/天。
