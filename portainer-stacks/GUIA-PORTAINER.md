# Guia Completo - Deploy no Portainer

**Passo a passo para fazer deploy das stacks no Portainer**

---

## ✅ Pré-requisitos

Você JÁ tem isso rodando (não mexer):

- ✅ Stack Postgres
- ✅ Stack Redis
- ✅ Stack Chatwoot (vai substituir)
- ✅ Network `minha_rede`
- ✅ Traefik configurado

---

## 📦 O Que Vamos Fazer

1. **Atualizar Chatwoot** para versão white-label
2. **Criar Atlas Nexa** (SDR com IA)
3. **Criar N8N** (automação) - opcional
4. **Criar Dashboard** (métricas) - opcional

---

## 🚀 Passo 1: Criar Volumes

**Antes** de fazer deploy das stacks, crie os volumes.

### No Portainer:

1. **Sidebar** → **Volumes**
2. **Add Volume**
3. Criar esses volumes:

| Nome do Volume | Notas |
|----------------|-------|
| `chatwoot_data` | Já existe? Pode usar o existente |
| `atlas_data` | Novo |
| `n8n_data` | Novo (se for usar N8N) |

Para cada volume:
- **Name:** (nome acima)
- **Driver:** local
- **Clique:** Create the volume

---

## 🎨 Passo 2: Atualizar Chatwoot para White-Label

### 2.1 Editar Stack Atual

**Portainer → Stacks → chatwoot → Editor**

1. **Scroll até o fim** e clique **Editor**
2. **Selecionar tudo** (Ctrl+A)
3. **Apagar** tudo
4. **Copiar** o conteúdo de `stack-chatwoot-whitelabel.yml`
5. **Colar** no editor

### 2.2 Configurar Variáveis de Ambiente

Scroll até **Environment variables** e adicione:

```
BRAND_NAME=Nexa Inbox
BRAND_LOGO_URL=https://nexateam.com.br/logo.svg
BRAND_PRIMARY_COLOR=#1f93ff
CHATWOOT_DOMAIN=chatwoot.nexateam.com.br
```

**Opcional (se quiser customizar mais):**
```
INSTALLATION_NAME=nexa_inbox
SUPPORT_EMAIL=support@nexateam.com.br
```

### 2.3 Atualizar Stack

1. **Scroll até o fim**
2. Clique **Update the stack**
3. Aguardar deploy (30-60 segundos)

### 2.4 Verificar

**Portainer → Stacks → chatwoot → Containers**

- `chatwoot_app` deve estar **running** (verde)
- `chatwoot_sidekiq` deve estar **running** (verde)

**Se algum container estiver stopped ou unhealthy:**
- Clique no container → **Logs**
- Procure por erros (geralmente senha do banco ou variável faltando)

---

## 🤖 Passo 3: Criar Stack Atlas Nexa

### 3.1 Criar Database (IMPORTANTE!)

**Primeiro** precisa criar o database `atlas_nexa` no Postgres.

**Opção A: Via Portainer Console**

1. **Portainer → Containers → postgres (seu container)**
2. **Console** (ícone de terminal)
3. Clicar **Connect**
4. Digitar:
   ```bash
   psql -U postgres
   ```
5. Digitar:
   ```sql
   CREATE DATABASE atlas_nexa;
   ```
6. Verificar:
   ```sql
   \l
   ```
   (deve aparecer `atlas_nexa` na lista)
7. Sair:
   ```sql
   \q
   ```

**Opção B: Via SSH**

```bash
ssh root@seu-servidor
docker exec -it <nome-container-postgres> psql -U postgres -c "CREATE DATABASE atlas_nexa;"
```

### 3.2 Criar Stack no Portainer

1. **Portainer → Stacks → Add Stack**
2. **Name:** `atlas-nexa`
3. **Web editor:** Copiar e colar `stack-atlas-nexa.yml`

### 3.3 Configurar Variáveis

Em **Environment variables**, adicionar:

```
OPENAI_API_KEY=sk-... (sua chave)
WHATSAPP_API_URL=https://evolution.nexateam.com.br
WHATSAPP_API_KEY=... (sua chave)
ATLAS_DOMAIN=atlas.nexateam.com.br
```

**⚠️ Deixar em branco por enquanto (vai preencher depois):**
```
CHATWOOT_API_TOKEN=
```

### 3.4 Deploy

1. **Scroll até o fim**
2. **Deploy the stack**
3. Aguardar (pode demorar 1-2 minutos na primeira vez)

### 3.5 Verificar

**Portainer → Stacks → atlas-nexa → Containers**

- `atlas_nexa` deve estar **running**

**Testar acesso:**
- https://atlas.nexateam.com.br/health (deve retornar "OK")

---

## 🔗 Passo 4: Conectar Atlas Nexa com Chatwoot

Agora precisa gerar o **API Token** do Chatwoot para o Atlas poder criar conversas.

### 4.1 Gerar Token no Chatwoot

1. **Abrir:** https://chatwoot.nexateam.com.br
2. **Login** com suas credenciais
3. **Settings** (engrenagem) → **Integrations** → **API**
4. **Platform** tab
5. **Create Token**
6. **Copiar** o token gerado

### 4.2 Adicionar Token no Atlas Nexa

1. **Portainer → Stacks → atlas-nexa → Editor**
2. **Scroll** até **Environment variables**
3. **Adicionar:**
   ```
   CHATWOOT_API_TOKEN=<token-copiado>
   ```
4. **Update the stack**

### 4.3 Testar Integração

**Via N8N (se tiver) ou manualmente:**

Enviar mensagem teste no WhatsApp → Verificar se aparece no Chatwoot quando score >= 7

---

## 🔄 Passo 5: Criar N8N (Opcional)

N8N é usado para automações avançadas. **Pode pular** se não quiser por enquanto.

### 5.1 Criar Database

Igual ao Atlas Nexa:

```sql
psql -U postgres
CREATE DATABASE n8n;
\q
```

### 5.2 Criar Stack

1. **Portainer → Stacks → Add Stack**
2. **Name:** `n8n`
3. **Web editor:** Copiar e colar `stack-n8n.yml`
4. **Environment variables:** (opcional)
   ```
   N8N_DOMAIN=n8n.nexateam.com.br
   ```
5. **Deploy the stack**

### 5.3 Configurar N8N

1. **Abrir:** https://n8n.nexateam.com.br
2. **Criar conta** de owner (primeira vez)
3. **Importar workflows** (vou te mandar depois)

---

## 📊 Passo 6: Criar Dashboard (Opcional)

Se quiser métricas e analytics.

### 6.1 Criar Stack

1. **Portainer → Stacks → Add Stack**
2. **Name:** `dashboard`
3. **Web editor:** Copiar e colar `stack-dashboard.yml`
4. **Environment variables:**
   ```
   DASHBOARD_DOMAIN=dashboard.nexateam.com.br
   CHATWOOT_API_TOKEN=<mesmo-token-do-atlas>
   ```
5. **Deploy the stack**

### 6.2 Acessar

https://dashboard.nexateam.com.br

---

## ✅ Checklist Final

Depois de tudo:

- [ ] Chatwoot atualizado e rodando
- [ ] Atlas Nexa rodando
- [ ] API Token do Chatwoot gerado
- [ ] API Token adicionado no Atlas Nexa
- [ ] Todas as stacks mostrando **running** (verde)
- [ ] SSL funcionando (https://)

**Testar:**
- [ ] Acessar Chatwoot: https://chatwoot.nexateam.com.br
- [ ] Acessar Atlas: https://atlas.nexateam.com.br/health
- [ ] Enviar mensagem teste no WhatsApp
- [ ] Verificar se aparece no Chatwoot (se score >= 7)

---

## 🚨 Troubleshooting

### Container não inicia

**1. Ver logs:**
- **Portainer → Containers → [container com problema] → Logs**

**Erros comuns:**

| Erro | Causa | Solução |
|------|-------|---------|
| "connection refused postgres" | Postgres não está rodando | Iniciar stack do Postgres |
| "database does not exist" | Database não foi criado | Criar database manualmente (passo 3.1) |
| "password authentication failed" | Senha errada | Verificar POSTGRES_PASSWORD na stack |
| "network not found" | Network não existe | Criar network: `docker network create minha_rede` |

### SSL não funciona

**Verificar Traefik:**
- Portainer → Containers → traefik → Logs
- Procurar por erros de certificado

**Verificar DNS:**
```bash
dig atlas.nexateam.com.br +short
# Deve retornar o IP do servidor
```

### Chatwoot não mostra branding customizado

**Significa que está usando imagem vanilla, não custom**

**Solução:**
1. Buildar imagem customizada (vou te ajudar depois)
2. Fazer push para Docker Hub: `nexateam/chatwoot-custom:latest`
3. Na stack, atualizar:
   ```
   CHATWOOT_IMAGE=nexateam/chatwoot-custom:latest
   ```

Por enquanto, pode usar a imagem oficial: `chatwoot/chatwoot:v3.15.0`

---

## 📝 Notas Importantes

### Variáveis de Ambiente vs. YAML

**Tem 2 jeitos de configurar:**

**1. Via Environment Variables (recomendado):**
- Portainer → Stack → Editor → Environment variables
- Mais fácil de mudar depois
- Não precisa editar YAML

**2. Direto no YAML:**
```yaml
environment:
  - BRAND_NAME=Meu Cliente
  - BRAND_LOGO_URL=https://...
```
- Fixo no YAML
- Precisa editar e dar Update na stack

### Secrets

**⚠️ NUNCA** coloque senhas/API keys direto no YAML se for commitar no Git!

**Use Environment Variables no Portainer** (elas não aparecem no Git).

### Ordem de Deploy

**Importante seguir essa ordem:**

1. ✅ Postgres (já existe)
2. ✅ Redis (já existe)
3. ✅ Chatwoot (atualizar)
4. 🆕 Atlas Nexa (depende de Chatwoot)
5. 🆕 N8N (opcional)
6. 🆕 Dashboard (opcional)

### Backups

**Fazer backup antes de atualizar Chatwoot:**

```bash
# Backup Postgres
docker exec postgres pg_dumpall -U postgres | gzip > backup_$(date +%Y%m%d).sql.gz

# Backup volume Chatwoot
docker run --rm -v chatwoot_data:/data -v $(pwd):/backup alpine tar czf /backup/chatwoot_data.tar.gz /data
```

---

## 🎯 Próximos Passos

Depois de tudo rodando:

1. **Customizar branding** completo (buildar imagem custom)
2. **Configurar N8N workflows** para automação
3. **Testar handoff** Atlas → Chatwoot
4. **Configurar monitoring** (Grafana)
5. **Onboarding primeiro cliente**

---

**Dúvidas?** Qualquer erro, me manda o log do container que eu te ajudo!
