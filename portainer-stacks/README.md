# Stacks Prontas para Portainer

**✅ Arquivos prontos para copiar e colar direto no Portainer**

**Não sabe usar linha de comando? Sem problema!** Tudo aqui é feito pela interface do Portainer.

---

## 🚀 Começar Aqui

**Nunca usou Docker Compose via terminal? Perfeito!**

### 📌 Primeiro Acesso?

👉 **[O-QUE-TEM-AQUI.md](O-QUE-TEM-AQUI.md)** - Índice de tudo que tem nesta pasta (2 min)

### 📚 Escolha Seu Guia:

- **⚡ [INICIO-RAPIDO.md](INICIO-RAPIDO.md)** - 5 passos, vai direto ao ponto (10 min)
- **📖 [GUIA-PORTAINER.md](GUIA-PORTAINER.md)** - Completo com screenshots mentais e troubleshooting (30 min)

---

## 📦 Arquivos Disponíveis

| Arquivo YAML | Descrição | Status |
|--------------|-----------|--------|
| `stack-chatwoot-whitelabel.yml` | Chatwoot customizado (white-label) | **Substituir sua stack atual** |
| `stack-atlas-nexa.yml` | AI SDR Agent (qualificação de leads) | **Criar stack nova** |
| `stack-n8n.yml` | Automação de workflows | Opcional |
| `stack-dashboard.yml` | Dashboard de métricas | Opcional |

---

## 🎯 Como Usar (Simples)

### Você Já Tem (Não Mexer)

✅ Stack Postgres (mantém como está)
✅ Stack Redis (mantém como está)
✅ Network `minha_rede` (já existe)

### Vai Criar (Novas Stacks)

1. **Chatwoot White-Label** (substitui o Chatwoot atual)
2. **Atlas Nexa** (SDR com IA)
3. **Dashboard** (métricas)
4. **N8N** (automação) - opcional

---

## 📋 Passo a Passo

### 1. Criar Volumes no Portainer

Antes de criar as stacks, crie os volumes:

**Portainer → Volumes → Add Volume:**

- Nome: `chatwoot_data` (se não existir)
- Nome: `atlas_data`
- Nome: `dashboard_data`
- Nome: `n8n_data`

### 2. Criar Arquivo de Variáveis

**IMPORTANTE:** Antes de copiar as stacks, você precisa de um `.env` com as senhas.

Vou criar um arquivo `.env` customizado para você em outra stack "Nexa Config".

### 3. Fazer Deploy das Stacks

**Ordem:**

1. ✅ Postgres (já existe, não mexer)
2. ✅ Redis (já existe, não mexer)
3. 🆕 Chatwoot White-Label (substituir a stack atual)
4. 🆕 Atlas Nexa
5. 🆕 Dashboard
6. 🆕 N8N (opcional)

---

## 📝 Instruções Detalhadas

### Passo 1: Atualizar Chatwoot para White-Label

**Portainer → Stacks → chatwoot → Editor:**

1. Copie o conteúdo de `stack-chatwoot-whitelabel.yml`
2. Cole **substituindo** o YAML atual
3. Vá em "Environment variables" e adicione:
   ```
   BRAND_NAME=Nexa Inbox
   BRAND_LOGO_URL=https://nexateam.com.br/logo.svg
   BRAND_PRIMARY_COLOR=#1f93ff
   ```
4. Clique **Update the stack**

### Passo 2: Criar Stack Atlas Nexa

**Portainer → Stacks → Add Stack:**

1. **Name:** `atlas-nexa`
2. **Web editor:** Cole o conteúdo de `stack-atlas-nexa.yml`
3. **Environment variables:** Adicione as variáveis (veja no arquivo)
4. Clique **Deploy the stack**

### Passo 3: Criar Stack Dashboard

**Portainer → Stacks → Add Stack:**

1. **Name:** `dashboard`
2. **Web editor:** Cole o conteúdo de `stack-dashboard.yml`
3. Clique **Deploy the stack**

### Passo 4: Criar Stack N8N (Opcional)

**Portainer → Stacks → Add Stack:**

1. **Name:** `n8n`
2. **Web editor:** Cole o conteúdo de `stack-n8n.yml`
3. Clique **Deploy the stack**

---

## 🔐 Variáveis de Ambiente

Cada stack tem variáveis que você precisa configurar no Portainer.

**Como adicionar:**
1. Portainer → Stacks → [sua stack] → Editor
2. Scroll até "Environment variables"
3. Adicione as variáveis necessárias
4. Update the stack

**Variáveis obrigatórias por stack:**

### Chatwoot White-Label
```
BRAND_NAME=Nome do Cliente
BRAND_LOGO_URL=https://url-do-logo.com/logo.svg
BRAND_PRIMARY_COLOR=#hexcolor
```

### Atlas Nexa
```
OPENAI_API_KEY=sk-...
WHATSAPP_API_URL=https://...
WHATSAPP_API_KEY=...
CHATWOOT_API_TOKEN=... (gerar depois do primeiro login)
```

### Dashboard
```
# Geralmente não precisa (usa defaults)
```

---

## ✅ Verificar se Funcionou

Depois de fazer deploy de cada stack:

**Portainer → Stacks → [stack] → Containers:**
- Todos devem estar **running** (verde)
- Se algum estiver **unhealthy** ou **stopped**, clicar em **Logs** para ver o erro

**Testar acesso:**
- Chatwoot: https://chatwoot.nexateam.com.br
- Atlas: https://atlas.nexateam.com.br
- Dashboard: https://dashboard.nexateam.com.br

---

## 🚨 Troubleshooting

### Container não inicia

1. **Portainer → Containers → [container] → Logs**
2. Procure por erros tipo:
   - "connection refused" → serviço dependente não está rodando
   - "password authentication failed" → senha errada no .env
   - "port already in use" → mudar porta na stack

### Variável de ambiente não funciona

**Problema:** Portainer tem um bug às vezes com env vars

**Solução:** Colocar direto no YAML:
```yaml
environment:
  - BRAND_NAME=Meu Cliente
  - BRAND_LOGO_URL=https://...
```

### Network não encontrada

**Erro:** "network minha_rede not found"

**Solução:**
```bash
# Via SSH no servidor
docker network create --driver overlay minha_rede
```

Ou no Portainer:
**Networks → Add Network:**
- Name: `minha_rede`
- Driver: `overlay`

---

## 📚 Próximos Passos

Depois que tudo estiver rodando:

1. **Gerar API Token do Chatwoot:**
   - Login no Chatwoot
   - Settings → Integrations → API → Platform → Create Token
   - Copiar token

2. **Adicionar token no Atlas Nexa:**
   - Portainer → Stacks → atlas-nexa → Editor
   - Environment variables → `CHATWOOT_API_TOKEN=...`
   - Update the stack

3. **Criar workflows no N8N:**
   - Acessar https://n8n.nexateam.com.br
   - Importar workflows (vou te passar depois)

---

**Dúvidas?** Todos os arquivos YAML estão na pasta `portainer-stacks/`
