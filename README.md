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

`.env` 中只有一项必填：

```bash
# JWT 密钥（必填，生成命令：openssl rand -hex 32）
JWT_SECRET=
```

> ⚠️ `.env` 文件包含密钥，请勿提交到任何代码仓库。

> **AI Provider API Key 不在此处配置**：DASHSCOPE / OpenRouter 等 API Key 是 AI 模型调用凭据，**不属于基础设施配置**，不需要写入 `.env`。系统启动后，在管理员页面配置 Provider 即可（见第五步）。

**2.3 代理环境配置（可选）**

如果服务器配置了 HTTP/HTTPS 代理，取消注释 `.env` 末尾的 `NO_PROXY` 行：

```bash
NO_PROXY=localhost,127.0.0.1,::1
no_proxy=localhost,127.0.0.1,::1
```

否则容器内组件（Qdrant、Redis、ES 等）会尝试通过代理访问本地地址，导致连接失败。

**2.4 指定版本（可选）**

默认使用 SG 当前版本 `v2.3.3`。如需切换版本，在启动命令前设置：

```bash
export VERSION=v2.3.3
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
apemind-api               Up X minutes (healthy)
apemind-frontend          Up X minutes
apemind-nginx             Up X minutes
apemind-indexing-worker   Up X minutes
apemind-postgres          Up X minutes (healthy)
apemind-redis             Up X minutes (healthy)
apemind-qdrant            Up X minutes (healthy)
apemind-es                Up X minutes (healthy)
```

---

## 第五步：初始化（可选）

> **这一步完全可以跳过。** 系统启动后，在页面注册的**第一个账号**即为管理员账号；AI Provider 也可以在管理员页面手动配置。以下脚本仅供希望快速批量初始化的场景使用。

### 脚本批量初始化（适合快速 POC）

> ⚠️ **脚本需要 Python ≥ 3.7**。可以先检查版本：`python3 --version`。
> 如果版本是 3.6 或更低，请直接跳过此步骤，用浏览器访问系统后在管理员页面手动完成配置即可。

如果你有 DASHSCOPE（阿里云百炼）和 OpenRouter 的 API Key，可以用脚本一次性完成：管理员账号创建 + 常用模型配置（embedding、LLM、场景绑定）：

```bash
# 检查 Python 版本（需要 3.7+）
python3 --version

# 安装依赖
pip3 install requests

# 运行初始化脚本
APERAG_ADMIN_PASSWORD=自定义管理员密码 \
DASHSCOPE_API_KEY=sk-xxxx \
OPENROUTER_API_KEY=sk-or-v1-xxxx \
python3 scripts/init-local-demo.py
```

脚本会创建：管理员账号、embedding 模型（text-embedding-v4）、多个 LLM（DeepSeek / GPT / Claude / Kimi / Qwen 等）、以及 agent_chat / collection_completion 等场景绑定。脚本是幂等的，重复运行无副作用。

> **使用其他 Provider**（如自建 OpenAI-compatible 服务、Azure、其他国内模型）：跳过脚本，直接登录后在「管理员」→「模型配置」页面手动添加即可。

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

**账号：**

- 如果跑了第五步脚本：用户名 `admin`，密码为脚本中设置的 `APERAG_ADMIN_PASSWORD`
- 如果跳过了第五步：在页面直接注册，**第一个注册的账号即为管理员账号**

> **AI Provider 配置**：首次登录后，在「管理员」→「模型配置」页面添加你使用的 AI 服务商（支持阿里云百炼、OpenRouter、Azure OpenAI、自建 OpenAI-compatible 服务等），配置完成后即可创建知识库和使用对话功能。

---

## 日常运维

```bash
# 查看状态
docker compose ps

# 查看日志
docker compose logs -f api          # apemind-api
docker compose logs -f indexing-worker  # apemind-indexing-worker

# 停止（保留数据）
docker compose down

# 重启
docker compose down && docker compose up -d

# 更新配置/版本（docker-compose.yml、nginx.conf、脚本等所有变更都靠 git pull 落地）
git pull
# 可选：仅当本地镜像版本低于目标版本时才需要；已在目标版本可跳过
docker compose pull
# 全量重建：docker-compose.yml 变更（restart 策略等）+ volume-mount 文件（nginx.conf、init-es.sh）全部生效
docker compose up -d --force-recreate
```

> ⚠️ 升级后如遇界面语言显示异常，清除浏览器缓存中的 `locale` cookie（或 F12 → Application → Clear site data）后刷新即可。

> ⚠️ 大版本升级前请查阅 release note，可能包含数据库迁移步骤。

---

## 可选：启动远程 Slock Agent

需要远程排查客户环境时，可以用 `docker run` 启动一个 Slock Agent 容器。容器会连接到 Slock Server，并挂载宿主机 Docker socket 和当前目录，因此 agent 可以在容器内执行宿主机的 `docker` / `docker compose` 诊断命令、读写当前工作目录，并通过 host network 访问本机服务。

> ⚠️ `/var/run/docker.sock`、`--pid host` 和 `--privileged` 都是宿主机高权限能力。只在受信任客户环境、受控 Slock Server 和已轮换的 API key 下使用。

### 一条命令启动

```bash
docker run --rm \
  --name slock-agent \
  --network host \
  --pid host \
  --privileged \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd)":/workspace \
  -w /workspace \
  -v slock-agent-pi-data:/root/.pi \
  -e DEEPSEEK_API_KEY=<your-deepseek-api-key> \
  -e PI_SKIP_VERSION_CHECK=1 \
  -e PI_TELEMETRY=0 \
  apecloud/slock-agent:latest \
  slock-daemon \
    --server-url https://api.slock.ai \
    --api-key <your-slock-machine-api-key>
```

如需后台常驻，把 `--rm` 改成 `-d --restart unless-stopped`。如需读写其他目录，把对应宿主机目录额外挂到容器内。

镜像会同步发布到三处：

| Registry | Image |
|------|------|
| Docker Hub | `apecloud/slock-agent:latest` |
| GHCR | `ghcr.io/apecloud/slock-agent:latest` |
| 阿里云 ACR | `registry.cn-hangzhou.aliyuncs.com/apecloud/slock-agent:latest` |

### Slock Server 侧 Agent 配置

启动容器后，在 Slock Server 创建或启动 agent 时使用：

| 配置项 | 值 |
|------|------|
| Runtime | `Pi` |
| Model | `deepseek/deepseek-v4-pro` |
| Thinking | `high` |

DeepSeek key 通过容器环境变量 `DEEPSEEK_API_KEY` 注入。镜像不包含任何 key。

### 交互式 Pi 验证

如需在客户机器上先验证 DeepSeek + Pi 是否可用：

```bash
docker run -it --rm \
  --name pi-deepseek \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd)":/workspace \
  -w /workspace \
  -e DEEPSEEK_API_KEY=<your-deepseek-api-key> \
  apecloud/slock-agent:latest \
  pi --provider deepseek --model deepseek-v4-pro --thinking high
```

---

## 服务说明

| 服务 | 端口 | 说明 |
|------|------|------|
| apemind-nginx | 3000 | 统一接入层（/api/* → api，/* → frontend） |
| apemind-api | 8000 | 后端 API（内部端口） |
| apemind-frontend | 3000（内部） | 前端（由 nginx 代理） |
| apemind-indexing-worker | — | 文档解析 / 向量化 / 图索引 |
| apemind-postgres | 127.0.0.1:5432 | 元数据 + 图数据（复用同一实例） |
| apemind-redis | 127.0.0.1:6379 | 队列 / 缓存 / 配额 |
| apemind-qdrant | 127.0.0.1:6333 | 向量数据库 |
| apemind-es | 127.0.0.1:9200 | 全文检索 |

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
