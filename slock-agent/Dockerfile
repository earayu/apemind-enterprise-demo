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

WORKDIR /workspace

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV SLOCK_SERVER_URL=https://api.slock.ai
ENV PI_SKIP_VERSION_CHECK=1
ENV PI_TELEMETRY=0

ENTRYPOINT ["/entrypoint.sh"]
