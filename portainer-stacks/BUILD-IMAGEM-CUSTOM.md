# Como Buildar Imagem Chatwoot Customizada

**Guia simplificado para criar sua própria imagem white-label**

---

## 🎯 Por Que Fazer Isso?

### Com Imagem Oficial (`chatwoot/chatwoot:v3.15.0`)

❌ Logo "Chatwoot" no login
❌ Textos "Chatwoot" na interface
❌ Emails com marca Chatwoot
❌ Links para chatwoot.com

### Com Imagem Customizada (`nexateam/chatwoot-custom:v3.15.0`)

✅ Logo customizado
✅ Textos genéricos ou sua marca
✅ Emails sem marca Chatwoot
✅ White-label completo

---

## ⚠️ Importante

**Você NÃO PRECISA fazer isso agora!**

**Faça DEPOIS que validar tudo funcionando com a imagem oficial.**

Ordem recomendada:
1. ✅ Deploy com `chatwoot/chatwoot:v3.15.0` (imagem oficial)
2. ✅ Testar tudo funcionando
3. ✅ Validar integração Atlas Nexa
4. 🔄 Aí sim buildar imagem customizada

---

## 🛠️ Como Buildar (2 Métodos)

### Método 1: No Seu PC (Windows)

**Requisitos:**
- Git instalado
- Docker Desktop instalado
- Conta no Docker Hub

**Passos:**

```bash
# 1. Clonar Chatwoot
git clone https://github.com/chatwoot/chatwoot.git chatwoot-custom
cd chatwoot-custom
git checkout v3.15.0

# 2. Aplicar customizações (ver abaixo)

# 3. Buildar imagem
docker build -t nexateam/chatwoot-custom:v3.15.0 .

# 4. Fazer push para Docker Hub
docker login
docker push nexateam/chatwoot-custom:v3.15.0
```

**Tempo:** ~30-60 minutos (build é lento)

---

### Método 2: No Servidor (Via SSH)

Mais rápido porque servidor geralmente tem internet melhor.

```bash
# SSH no servidor
ssh root@seu-servidor

# Clonar e buildar
git clone https://github.com/chatwoot/chatwoot.git
cd chatwoot
git checkout v3.15.0

# Aplicar customizações...

# Build
docker build -t nexateam/chatwoot-custom:v3.15.0 .

# Push
docker login
docker push nexateam/chatwoot-custom:v3.15.0
```

---

## 🎨 Customizações a Fazer

### Opção A: Mínima (Rápido)

**Arquivo:** `app/javascript/dashboard/i18n/locale/pt_BR/index.js`

Buscar e substituir:
```javascript
// Antes
BRAND_NAME: 'Chatwoot',

// Depois
BRAND_NAME: process.env.VUE_APP_BRAND_NAME || 'Inbox',
```

**Resultado:** Textos ficam genéricos ("Inbox" ao invés de "Chatwoot")

---

### Opção B: Completa (Recomendada)

Use o script que criei:

**Arquivo:** `scripts/apply-whitelabel.sh`

```bash
#!/bin/bash
# Substitui todas as referências "Chatwoot" por genérico

# 1. Traduções PT_BR
find app/javascript/dashboard/i18n/locale/pt_BR -type f -name "*.json" \
  -exec sed -i 's/Chatwoot/Inbox/g' {} +

# 2. Templates de email
find app/views/mailers -type f \( -name "*.html.erb" -o -name "*.text.erb" \) \
  -exec sed -i 's/Chatwoot/Suporte/g' {} +

# 3. Remove links para chatwoot.com
find app/views/mailers -type f -name "*.html.erb" \
  -exec sed -i '/chatwoot\.com/d' {} +

# 4. HTML title
sed -i 's/<title>Chatwoot<\/title>/<title>Inbox<\/title>/' app/views/layouts/application.html.erb

echo "✅ Customizações aplicadas!"
```

**Como usar:**

```bash
# Copiar script para pasta do Chatwoot
cd chatwoot-custom
# Criar arquivo scripts/apply-whitelabel.sh com conteúdo acima
chmod +x scripts/apply-whitelabel.sh

# Executar
./scripts/apply-whitelabel.sh
```

---

## 📦 Build da Imagem

### Dockerfile Simplificado

**Arquivo:** `Dockerfile.custom`

```dockerfile
FROM chatwoot/chatwoot:v3.15.0

# Copiar customizações
COPY scripts/apply-whitelabel.sh /tmp/
RUN chmod +x /tmp/apply-whitelabel.sh && /tmp/apply-whitelabel.sh

# Rebuild assets (se mudou frontend)
# RUN bundle exec rails assets:precompile

# Cleanup
RUN rm /tmp/apply-whitelabel.sh
```

**Build:**

```bash
docker build -f Dockerfile.custom -t nexateam/chatwoot-custom:v3.15.0 .
```

---

## 🚀 Usar Imagem Customizada

### No Portainer

**Opção A: Variável de Ambiente**

Portainer → Stack → chatwoot → Environment variables:
```
CHATWOOT_IMAGE=nexateam/chatwoot-custom:v3.15.0
```

**Opção B: Direto no YAML**

```yaml
services:
  chatwoot_app:
    image: nexateam/chatwoot-custom:v3.15.0  # ← Mudar esta linha
    # resto igual...
```

**Update the stack** e pronto!

---

## 🔄 Workflow Completo (Resumo)

```
1. Clonar Chatwoot oficial
      ↓
2. Checkout versão v3.15.0
      ↓
3. Aplicar script de customização
      ↓
4. Buildar imagem Docker
      ↓
5. Push para Docker Hub
      ↓
6. Atualizar stack no Portainer
      ↓
✅ White-label completo!
```

---

## 💡 Dica: Usar Imagem Base Primeiro

**Estratégia recomendada:**

### Fase 1: Validação (Agora)
```yaml
image: chatwoot/chatwoot:v3.15.0  # Oficial
```
- Deploy rápido
- Testar tudo
- Validar integração

### Fase 2: White-Label (Depois)
```yaml
image: nexateam/chatwoot-custom:v3.15.0  # Custom
```
- Build da imagem
- Push para Docker Hub
- Update stack

**Vantagem:** Não perde tempo buildando se algo não funcionar

---

## 🚨 Troubleshooting Build

### Build muito lento

**Problema:** Download de dependências demora

**Solução:** Buildar no servidor (internet melhor)

### Erro: "Assets precompile failed"

**Problema:** Mudou frontend mas não rebuilou assets

**Solução:**
```dockerfile
RUN RAILS_ENV=production bundle exec rails assets:precompile
```

### Imagem ficou muito grande (>3GB)

**Problema:** Não limpou arquivos temporários

**Solução:** Multi-stage build (ver `docs/03-BUILD-PROCESS.md`)

---

## 📝 Checklist de Build

Antes de buildar:
- [ ] Docker instalado e funcionando
- [ ] Conta Docker Hub criada
- [ ] Git instalado
- [ ] Espaço em disco (mínimo 5GB livre)

Durante build:
- [ ] Clonou repositório correto
- [ ] Checkout na versão certa (v3.15.0)
- [ ] Aplicou customizações
- [ ] Testou script de white-label

Depois do build:
- [ ] Imagem buildou sem erros
- [ ] Fez push para Docker Hub
- [ ] Testou localmente antes de usar em produção
- [ ] Atualizou stack no Portainer

---

## 🎯 Resumo: O Que Fazer AGORA

### Agora (Hoje)

✅ **Use imagem oficial:**
```yaml
image: chatwoot/chatwoot:v3.15.0
```

✅ **Configure variáveis de ambiente:**
```
BRAND_NAME=Nexa Inbox
CHATWOOT_DOMAIN=inbox.nexateam.com.br
```

✅ **Faça deploy e teste**

### Depois (Semana que vem)

🔄 **Quando tudo estiver validado:**
1. Buildar imagem customizada
2. Push para Docker Hub
3. Atualizar stack

---

## 📖 Mais Detalhes

**Guia completo de build:**
- [`docs/03-BUILD-PROCESS.md`](../docs/03-BUILD-PROCESS.md) - Processo completo, otimizações, CI/CD

**Estratégia de white-label:**
- [`docs/02-WHITELABEL-PLAN.md`](../docs/02-WHITELABEL-PLAN.md) - O que customizar, opções, trade-offs

---

**Dúvida?** Por enquanto, **use a imagem oficial** e teste. Build vem depois!
