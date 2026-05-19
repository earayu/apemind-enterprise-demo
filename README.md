# APeMind Enterprise — Docker Compose 部署指南

本仓库包含 APeMind Enterprise 知识库系统的 Docker Compose 部署配置，适用于 POC 验证和私有化交付。

---

## 环境要求

| 组件 | 最低要求 |
|------|---------|
| Docker | ≥ 20.10 |
| docker compose | V2（`docker compose version`） |
| 磁盘空间 | ≥ 30 GB |
| 内存 | ≥ 8 GB |

**检查命令：**

```bash
docker --version
docker compose version
df -h .
```

> **如果 `docker compose` 命令不可用**（Ubuntu）：
> ```bash
> sudo apt-get update && sudo apt-get install -y docker.io docker-compose-plugin
> sudo systemctl enable --now docker
> sudo usermod -aG docker $USER  # 需重新登录生效
> ```

---

## 第一步：克隆仓库

```bash
git clone https://github.com/earayu/apemind-enterprise-demo.git
cd apemind-enterprise-demo
```

---

## 第二步：配置环境变量

**2.1 复制配置模板**

```bash
cp envs/env.template .env
```

**2.2 编辑 `.env`，填写必填项**

```bash
# JWT 密钥（必填，生成命令：openssl rand -hex 32）
JWT_SECRET=

# 阿里云百炼 API Key（用于 embedding）
DASHSCOPE_API_KEY=sk-xxxx

# OpenRouter API Key（用于 LLM 对话）
OPENROUTER_API_KEY=sk-or-v1-xxxx
```

> ⚠️ `.env` 文件包含密钥，请勿提交到任何代码仓库。

**2.3 代理环境配置（可选）**

如果服务器配置了 HTTP/HTTPS 代理，取消注释 `.env` 末尾的 `NO_PROXY` 行：

```bash
NO_PROXY=localhost,127.0.0.1,::1
no_proxy=localhost,127.0.0.1,::1
```

否则容器内组件（Qdrant、Redis、ES 等）会尝试通过代理访问本地地址，导致连接失败。

**2.4 指定版本（可选）**

默认使用 `v2.1.28`。如需切换版本，在启动命令前设置：

```bash
export VERSION=v2.1.28
```

---

## 第三步：拉取镜像并启动

```bash
# 拉取所有镜像（约 5-10 分钟，取决于网速）
docker compose pull

# 启动所有服务
docker compose up -d
```

---

## 第四步：确认服务状态

```bash
docker compose ps
```

正常状态（启动约 2-3 分钟后）：

```
aperag-api               Up X minutes (healthy)
aperag-frontend          Up X minutes
aperag-nginx             Up X minutes
aperag-indexing-worker   Up X minutes
aperag-postgres          Up X minutes (healthy)
aperag-redis             Up X minutes (healthy)
aperag-qdrant            Up X minutes (healthy)
aperag-es                Up X minutes (healthy)
```

---

## 第五步：初始化系统（⚠️ 仅首次部署执行一次）

```bash
# 安装依赖
pip3 install requests

# 加载环境变量
set -a && source .env && set +a

# 设置管理员密码
export APERAG_ADMIN_PASSWORD=自定义管理员密码

# 运行初始化脚本
python3 scripts/init-local-demo.py
```

脚本将自动创建管理员账号、AI 模型配置（dashscope + openrouter）。

---

## 第六步：访问系统

| 地址 | 说明 |
|------|------|
| `http://服务器IP:3000` | 系统前端 |
| `http://服务器IP:8000/docs` | API 文档 |

**查看服务器 IP：**

```bash
hostname -I
```

**登录：**
- 用户名：`admin`
- 密码：第五步设置的 `APERAG_ADMIN_PASSWORD`

---

## 日常运维

```bash
# 查看状态
docker compose ps

# 查看日志
docker compose logs -f api
docker compose logs -f indexing-worker

# 停止（保留数据）
docker compose down

# 重启
docker compose down && docker compose up -d

# 更新版本
git pull
export VERSION=新版本号
docker compose pull
docker compose down && docker compose up -d
```

> ⚠️ 大版本升级前请查阅 release note，可能包含数据库迁移步骤。

---

## 服务说明

| 服务 | 端口 | 说明 |
|------|------|------|
| nginx | 3000 | 统一接入层（/api/* → api，/* → frontend） |
| api | 8000 | 后端 API（内部端口） |
| frontend | 3000（内部） | 前端（由 nginx 代理） |
| indexing-worker | — | 文档解析 / 向量化 / 图索引 |
| postgres | 127.0.0.1:5432 | 元数据 + 图数据（复用同一实例） |
| redis | 127.0.0.1:6379 | 队列 / 缓存 / 配额 |
| qdrant | 127.0.0.1:6333 | 向量数据库 |
| es | 127.0.0.1:9200 | 全文检索 |

**对象存储**：默认使用容器内共享卷（`aperag-shared-data:/shared`），无需额外配置 MinIO/S3。

---

## 常见问题

**问题 1：某个服务 unhealthy**
```bash
docker compose logs <服务名>
# 例如：docker compose logs api
```

**问题 2：端口被占用**
```bash
sudo ss -lntp | grep -E ":(3000|8000|5432|6379|6333|9200)"
# Ubuntu 最常见冲突：系统预装 PostgreSQL 占用 5432
sudo systemctl stop postgresql && sudo systemctl disable postgresql
```

**问题 3：Qdrant / Redis 报 Server disconnected**

代理拦截了内部请求，在 `.env` 中添加 `NO_PROXY=localhost,127.0.0.1,::1` 后重启。

**问题 4：磁盘空间不足**
```bash
docker system prune
```

**问题 5：彻底清理（数据不可恢复）**
```bash
docker compose down -v
```

---

## 可选：Neo4j / Nebula 图数据库

默认使用 PostgreSQL 作为图数据库（零额外组件）。如需独立图数据库：

```bash
# 启用 Neo4j
docker compose --profile neo4j up -d

# 启用 Nebula
docker compose --profile nebula up -d
```

同时在 `.env` 中设置对应的连接参数（`GRAPH_DB_TYPE=neo4j` / `GRAPH_DB_TYPE=nebula`）。
