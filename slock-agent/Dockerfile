FROM node:20-slim

# Docker CLI — allows agent to execute host docker / docker compose commands
# when /var/run/docker.sock is mounted (DooD pattern)
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    ca-certificates \
    docker.io \
    docker-compose-plugin \
    git \
    jq \
    openssh-client \
    ripgrep \
    && rm -rf /var/lib/apt/lists/*

# Agent CLIs
RUN npm install -g @anthropic-ai/claude-code @openai/codex

WORKDIR /workspace

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV SLOCK_SERVER_URL=https://api.slock.ai

ENTRYPOINT ["/entrypoint.sh"]
