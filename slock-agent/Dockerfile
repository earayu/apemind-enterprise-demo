FROM node:22-slim

ARG SLOCK_DAEMON_VERSION=0.57.5
ARG PI_CODING_AGENT_VERSION=0.79.1

# Docker CLI lets the agent operate the host Docker daemon when the socket is mounted.
# Install only the client and compose plugin; do not install dockerd in this image.
RUN printf 'Acquire::Retries "5";\nAcquire::http::Timeout "30";\nAcquire::https::Timeout "30";\n' > /etc/apt/apt.conf.d/80-retries \
    && apt-get update && apt-get install -y --no-install-recommends --fix-missing \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    openssh-client \
    ripgrep \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update && apt-get install -y --no-install-recommends --fix-missing \
    docker-ce-cli \
    docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Slock daemon embeds the Pi SDK runtime. The global Pi CLI is kept for manual
# checks inside the container, using DeepSeek through DEEPSEEK_API_KEY.
RUN npm install -g --ignore-scripts \
    @slock-ai/daemon@${SLOCK_DAEMON_VERSION} \
    @earendil-works/pi-coding-agent@${PI_CODING_AGENT_VERSION} \
    && npm cache clean --force

# POC 现场作业 Skill：构建时从 deploy 仓库拉最新版，预装到 Pi 的用户级技能目录
# /root/.agents/skills（Pi 启动默认加载该目录，与 cwd 无关；刻意不放 /root/.pi 下，
# 因为运行时 slock-agent-pi-data 卷挂在 /root/.pi，会把镜像内文件遮住）。
# deploy 仓库是私有库：CI 构建需传 SKILLS_REPO_TOKEN（对 apecloud/aperag-enterprise-deploy
# 只读即可）。SKILLS_REVISION 双重用途：钉版本 + 破层缓存——CI 应把它解析为 deploy 仓库
# main 的当前 commit SHA 再传入，这样"每次 build 拉最新"才真正成立（固定传 main 字符串
# 会命中 Docker 层缓存、拉不到新内容）。本地无 token 构建时跳过并告警，不阻断开发。
ARG SKILLS_REPO_TOKEN
ARG SKILLS_REVISION=main
RUN if [ -n "$SKILLS_REPO_TOKEN" ]; then \
      mkdir -p /root/.agents/skills/poc-onsite-ops \
      && curl -fsSL -H "Authorization: token ${SKILLS_REPO_TOKEN}" \
        "https://raw.githubusercontent.com/apecloud/aperag-enterprise-deploy/${SKILLS_REVISION}/.agents/skills/poc-onsite-ops/SKILL.md" \
        -o /root/.agents/skills/poc-onsite-ops/SKILL.md \
      && grep -q "^name: poc-onsite-ops" /root/.agents/skills/poc-onsite-ops/SKILL.md; \
    else \
      echo "WARN: SKILLS_REPO_TOKEN 未提供——本次构建不含 poc-onsite-ops skill（仅限本地开发构建）"; \
    fi

WORKDIR /workspace

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV SLOCK_SERVER_URL=https://api.slock.ai
ENV PI_SKIP_VERSION_CHECK=1
ENV PI_TELEMETRY=0

ENTRYPOINT ["/entrypoint.sh"]
