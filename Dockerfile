# HexStrike AI — imagem para deploy no Easypanel (build na VPS)
# Base: Kali Rolling + toolset COMPLETO (kali-linux-headless, 150+ ferramentas)
# Fonte do app: https://github.com/0x4m4/hexstrike-ai
#
# ATENCAO DE SEGURANCA:
#   O servidor faz bind em 0.0.0.0:${HEXSTRIKE_PORT} (hardcoded) e NAO tem
#   autenticacao propria. E uma RCE-API por design. NUNCA exponha sem
#   protecao na borda (Basic Auth + IP allowlist + HTTPS).
FROM kalilinux/kali-rolling

LABEL org.opencontainers.image.title="hexstrike-ai" \
      org.opencontainers.image.description="HexStrike AI MCP server (full Kali toolset) for Easypanel" \
      org.opencontainers.image.source="https://github.com/0x4m4/hexstrike-ai"

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    HEXSTRIKE_PORT=8888 \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    PIP_NO_CACHE_DIR=1

# 1) Toolchain base: Python, git, deps de build e navegador headless (selenium)
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 python3-pip python3-venv python3-dev \
        git curl wget ca-certificates \
        build-essential libffi-dev libssl-dev pkg-config \
        chromium chromium-driver \
    && rm -rf /var/lib/apt/lists/*

# 2) Toolset COMPLETO do Kali (150+ ferramentas) — camada pesada
RUN apt-get update && apt-get install -y --no-install-recommends \
        kali-linux-headless \
    && rm -rf /var/lib/apt/lists/*

# 3) Codigo-fonte do HexStrike AI
WORKDIR /opt
RUN git clone --depth 1 https://github.com/0x4m4/hexstrike-ai.git hexstrike-ai
WORKDIR /opt/hexstrike-ai

# 4) Dependencias Python (Kali e PEP-668 "externally managed")
#    --ignore-installed: evita "Cannot uninstall <pkg> ... installed by debian"
#    (ex.: pyperclip via apt) — o pip instala em /usr/local sem tentar remover
#    os pacotes geridos pelo apt.
RUN pip3 install --break-system-packages --no-cache-dir --ignore-installed -r requirements.txt

# 5) Cobertura ampla de ferramentas CLI do Kali (suites kali-tools-*).
#    Camadas separadas + limpeza de cache para limitar o PICO de disco no build.
#    --no-install-recommends: instala as ferramentas (Depends) sem GUI/docs extra.
RUN apt-get update && apt-get install -y --no-install-recommends \
        kali-tools-information-gathering kali-tools-web \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*.deb
RUN apt-get update && apt-get install -y --no-install-recommends \
        kali-tools-vulnerability kali-tools-exploitation kali-tools-post-exploitation \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*.deb
RUN apt-get update && apt-get install -y --no-install-recommends \
        kali-tools-passwords kali-tools-fuzzing kali-tools-database \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*.deb
RUN apt-get update && apt-get install -y --no-install-recommends \
        kali-tools-forensics kali-tools-reverse-engineering kali-tools-sniffing-spoofing \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*.deb

EXPOSE 8888

# Healthcheck no endpoint /health do proprio servidor
HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3 \
    CMD curl -fsS "http://127.0.0.1:${HEXSTRIKE_PORT}/health" || exit 1

# O server escuta em 0.0.0.0:${HEXSTRIKE_PORT}. Proteja SEMPRE na borda.
CMD ["python3", "hexstrike_server.py"]
