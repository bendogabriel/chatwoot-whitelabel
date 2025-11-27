# 📦 O Que Tem Nesta Pasta

**Tudo que você precisa para fazer deploy via Portainer**

---

## 📄 Arquivos

### 🚀 Guias (Leia Estes)

| Arquivo | Quando Usar | Tempo |
|---------|-------------|-------|
| **[INICIO-RAPIDO.md](INICIO-RAPIDO.md)** | Quer fazer rápido | 5 min de leitura, 10 min de deploy |
| **[GUIA-PORTAINER.md](GUIA-PORTAINER.md)** | Quer entender tudo | 15 min de leitura, 30 min de deploy |
| [O-QUE-TEM-AQUI.md](O-QUE-TEM-AQUI.md) | **Você está aqui** | 2 min |
| [README.md](README.md) | Overview da pasta | 5 min |

### 📝 Stacks YAML (Copiar/Colar no Portainer)

| Arquivo YAML | Descrição | O Que Faz |
|--------------|-----------|-----------|
| **[stack-chatwoot-whitelabel.yml](stack-chatwoot-whitelabel.yml)** | Chatwoot customizado | Remove marca "Chatwoot", adiciona sua marca |
| **[stack-atlas-nexa.yml](stack-atlas-nexa.yml)** | AI SDR Agent | Qualifica leads automaticamente (IA) |
| [stack-n8n.yml](stack-n8n.yml) | Automação | Workflows para integrar tudo (opcional) |
| [stack-dashboard.yml](stack-dashboard.yml) | Dashboard | Métricas e analytics (opcional) |

**Negrito** = obrigatório | Normal = opcional

---

## 🎯 Por Onde Começar?

### Se Você Nunca Usou Isso Antes

1. **Abrir:** [INICIO-RAPIDO.md](INICIO-RAPIDO.md)
2. **Seguir:** 5 passos simples
3. **Resultado:** Chatwoot white-label + AI SDR funcionando

**Tempo total:** 10 minutos

### Se Você Quer Entender Tudo

1. **Abrir:** [GUIA-PORTAINER.md](GUIA-PORTAINER.md)
2. **Ler:** Explicação detalhada de cada passo
3. **Fazer:** Deploy seguindo o guia completo

**Tempo total:** 30-45 minutos

### Se Você Já Sabe o Que Está Fazendo

1. **Pegar:** Os arquivos `.yml`
2. **Copiar/Colar:** No Portainer
3. **Ajustar:** Variáveis de ambiente
4. **Deploy**

**Tempo total:** 5 minutos

---

## 🔄 Fluxo de Deploy

```
1. Criar volumes
      ↓
2. Substituir stack Chatwoot → White-label
      ↓
3. Criar database atlas_nexa
      ↓
4. Deploy stack Atlas Nexa
      ↓
5. Gerar API token no Chatwoot
      ↓
6. Conectar Atlas + Chatwoot
      ↓
✅ FUNCIONANDO!
```

---

## 📊 O Que Cada Stack Faz

### Chatwoot White-Label

**Antes:**
```
┌─────────────────┐
│   [Chatwoot]    │  ← Marca "Chatwoot" aparece
│                 │
│  Login: Chatwoot│
│  Logo: Chatwoot │
└─────────────────┘
```

**Depois (White-Label):**
```
┌─────────────────┐
│  [Seu Cliente]  │  ← Sua marca
│                 │
│  Login: Cliente │
│  Logo: Cliente  │
└─────────────────┘
```

### Atlas Nexa (AI SDR)

**Fluxo:**
```
WhatsApp Message
      ↓
Atlas Nexa (IA analisa)
      ↓
Score: 1-10
      ↓
  Score >= 7?
  ├─ SIM → Cria conversa no Chatwoot
  └─ NÃO → Continua no bot (follow-up automático)
```

### N8N (Automação)

**Exemplo de workflow:**
```
Lead qualificado no Atlas
      ↓
N8N recebe webhook
      ↓
Cria contato no Chatwoot
      ↓
Cria conversa com histórico do bot
      ↓
Atribui para agente humano
      ↓
Notifica agente
```

### Dashboard

**Métricas unificadas:**
```
┌──────────────────────────┐
│  Total Leads: 150        │ ← Atlas Nexa
│  Qualificados: 45 (30%)  │
│  Em atendimento: 20      │ ← Chatwoot
│  Convertidos: 12         │
└──────────────────────────┘
```

---

## 🛠️ Requisitos

### Você Precisa Ter

- ✅ Portainer rodando
- ✅ Stack Postgres rodando
- ✅ Stack Redis rodando
- ✅ Network `minha_rede` criada
- ✅ Traefik configurado (para SSL)

### Você Precisa Conseguir

- ✅ API key da OpenAI (https://platform.openai.com/api-keys)
- ✅ Credenciais WhatsApp API (Evolution ou UAZAPI)
- ✅ Email SMTP (Gmail app password)

### Você NÃO Precisa Saber

- ❌ Linha de comando / terminal
- ❌ Docker Compose CLI
- ❌ Git / GitHub
- ❌ SSH avançado

**Tudo é via interface do Portainer!**

---

## ❓ FAQ Desta Pasta

### "Qual a diferença entre os guias?"

| INICIO-RAPIDO | GUIA-PORTAINER |
|---------------|----------------|
| 5 passos | Passo a passo detalhado |
| 10 minutos | 30 minutos |
| Vai direto ao ponto | Explica cada detalhe |
| Para quem tem pressa | Para quem quer aprender |

**Ambos chegam no mesmo resultado!**

### "Preciso usar todas as stacks?"

**NÃO.** Mínimo necessário:
- ✅ Chatwoot White-Label (obrigatório)
- ✅ Atlas Nexa (obrigatório)

**Opcional:**
- N8N (só se quiser automação avançada)
- Dashboard (só se quiser métricas visuais)

### "Meu Chatwoot atual vai parar de funcionar?"

**NÃO.** A atualização é compatível. Mas recomendamos:
1. Fazer backup do YAML atual
2. Testar em horário de baixo movimento
3. Ter o YAML antigo salvo para reverter se precisar

### "Posso testar antes de usar em produção?"

**SIM!** Recomendamos:
1. Criar uma stack de teste (`chatwoot-test`)
2. Usar porta diferente (3001)
3. Testar tudo
4. Só depois aplicar em produção

---

## 🆘 Ajuda

### Durante o Deploy

**Se algo der errado:**
1. Ver logs: Portainer → Containers → [container] → Logs
2. Procurar erro específico
3. Consultar: [GUIA-PORTAINER.md#troubleshooting](GUIA-PORTAINER.md#troubleshooting)

### Dúvidas Gerais

**Sobre o projeto:**
- [`../README.md`](../README.md) - Overview completo
- [`../EXECUTIVE-SUMMARY.md`](../EXECUTIVE-SUMMARY.md) - Business value

**Sobre arquitetura:**
- [`../docs/04-INTEGRATION-ARCHITECTURE.md`](../docs/04-INTEGRATION-ARCHITECTURE.md) - Como tudo se conecta

---

## ✅ Próximo Passo

👉 **[INICIO-RAPIDO.md](INICIO-RAPIDO.md)** (se tem pressa)

👉 **[GUIA-PORTAINER.md](GUIA-PORTAINER.md)** (se quer entender)

**Boa sorte!** 🚀
