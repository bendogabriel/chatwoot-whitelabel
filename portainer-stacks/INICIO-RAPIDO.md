# Início Rápido - Portainer

**Versão super resumida para quem tem pressa**

---

## 📁 Arquivos Nesta Pasta

| Arquivo | O que é | Quando usar |
|---------|---------|-------------|
| `stack-chatwoot-whitelabel.yml` | Chatwoot customizado | Substituir sua stack atual |
| `stack-atlas-nexa.yml` | AI SDR Agent | Criar stack nova |
| `stack-n8n.yml` | Automação | Opcional |
| `stack-dashboard.yml` | Métricas | Opcional |
| `GUIA-PORTAINER.md` | Guia completo | Ler se tiver dúvida |
| **Este arquivo** | Resumo rápido | Começar aqui |

---

## ⚡ Quick Start (5 Passos)

### 1️⃣ Criar Volumes

**Portainer → Volumes → Add Volume**

Criar:
- `atlas_data` (novo)
- `n8n_data` (se for usar N8N)

### 2️⃣ Atualizar Chatwoot

**Portainer → Stacks → chatwoot → Editor**

1. Apagar tudo
2. Copiar `stack-chatwoot-whitelabel.yml` e colar
3. Environment variables:
   ```
   BRAND_NAME=Nexa Inbox
   CHATWOOT_DOMAIN=chatwoot.nexateam.com.br
   ```
4. **Update the stack**

### 3️⃣ Criar Database Atlas

**Portainer → Containers → postgres → Console**

```bash
psql -U postgres
CREATE DATABASE atlas_nexa;
\q
```

### 4️⃣ Deploy Atlas Nexa

**Portainer → Stacks → Add Stack**

1. Name: `atlas-nexa`
2. Copiar `stack-atlas-nexa.yml` e colar
3. Environment variables:
   ```
   OPENAI_API_KEY=sk-...
   WHATSAPP_API_URL=https://...
   WHATSAPP_API_KEY=...
   ATLAS_DOMAIN=atlas.nexateam.com.br
   ```
4. **Deploy the stack**

### 5️⃣ Conectar Atlas com Chatwoot

1. **Login:** https://chatwoot.nexateam.com.br
2. **Settings → Integrations → API → Platform → Create Token**
3. **Copiar token**
4. **Portainer → Stacks → atlas-nexa → Editor**
5. Environment variables:
   ```
   CHATWOOT_API_TOKEN=<token-copiado>
   ```
6. **Update the stack**

---

## ✅ Pronto!

Agora você tem:
- ✅ Chatwoot white-label rodando
- ✅ Atlas Nexa (AI SDR) integrado
- ✅ Handoff automático bot → humano

**Testar:**
```
Enviar mensagem WhatsApp → Atlas qualifica → Se score >= 7 → Cria conversa no Chatwoot
```

---

## 📊 Opcional: N8N e Dashboard

**Só se quiser automação avançada:**

### N8N

```bash
# Criar database
psql -U postgres -c "CREATE DATABASE n8n;"

# Portainer → Add Stack
Name: n8n
Colar: stack-n8n.yml
Deploy
```

### Dashboard

```bash
# Portainer → Add Stack
Name: dashboard
Colar: stack-dashboard.yml
Deploy
```

---

## 🚨 Erros Comuns

| Problema | Solução |
|----------|---------|
| Container não inicia | Ver logs: Container → Logs |
| "database not exist" | Criar database manualmente (passo 3) |
| "network not found" | `docker network create minha_rede` |
| SSL não funciona | Verificar DNS propagou (5-15 min) |

---

## 📖 Mais Detalhes

- **Guia completo:** [GUIA-PORTAINER.md](GUIA-PORTAINER.md)
- **Troubleshooting:** [GUIA-PORTAINER.md#troubleshooting](GUIA-PORTAINER.md#troubleshooting)
- **Customização:** Ver docs principais em `/docs`

---

**É isso!** Se tiver dúvida, leia o [GUIA-PORTAINER.md](GUIA-PORTAINER.md) completo.
