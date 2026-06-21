# hexstrike-easypanel

Imagem de deploy do [HexStrike AI](https://github.com/0x4m4/hexstrike-ai) para o **Easypanel**
(build na VPS via Dockerfile). Base **Kali Rolling** com o toolset completo
(`kali-linux-headless`, 150+ ferramentas).

## Como usar no Easypanel

1. Crie um **projeto isolado** (ex.: `hexstrike`), separado da produção.
2. Crie um serviço **App** com:
   - **Source:** Git → este repositório (branch `main`).
   - **Build:** Dockerfile (raiz do repo).
   - **Port (target):** `8888`.
3. **NÃO** adicione domínio público até validar o `/health` interno.
4. Exponha apenas atrás de **HTTPS + Basic Auth + IP allowlist**.

## ⚠️ Segurança

O `hexstrike_server.py` faz bind em `0.0.0.0:8888` (hardcoded) e **não possui
autenticação própria** — executa ferramentas/comandos de shell arbitrários
(RCE por design). Tratar como serviço hostil:

- Nunca expor cru na internet.
- Manter **parado** quando não estiver em uso.
- Restringir o endpoint por IP.

## Variáveis de ambiente

| Var | Default | Descrição |
|-----|---------|-----------|
| `HEXSTRIKE_PORT` | `8888` | Porta do servidor |
| `DEBUG_MODE` | `0` | Modo debug do Flask |
