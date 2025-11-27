# 👋 Comece Aqui - Versão Portainer

**Guia rápido para quem usa Portainer (sem linha de comando)**

---

## 📍 Você Está Aqui

Você tem:
- ✅ Portainer rodando
- ✅ Chatwoot atual funcionando
- ✅ Postgres + Redis já configurados
- ✅ Network `minha_rede` criada

Quer:
- 🎯 Chatwoot white-label (sem marca "Chatwoot")
- 🤖 Atlas Nexa (AI SDR) integrado
- 📊 Dashboard com métricas (opcional)

---

## 🚀 O Que Fazer Agora

### 1️⃣ Ir para a Pasta Portainer

📁 **Tudo que você precisa está aqui:**

```
chatwoot-whitelabel/
└── portainer-stacks/       ← VOCÊ ESTÁ AQUI
    ├── INICIO-RAPIDO.md    ← Comece por este (5 passos)
    ├── GUIA-PORTAINER.md   ← Guia completo (se tiver dúvida)
    ├── stack-chatwoot-whitelabel.yml
    ├── stack-atlas-nexa.yml
    ├── stack-n8n.yml
    └── stack-dashboard.yml
```

### 2️⃣ Escolher Seu Guia

**Opção A: Rápido (10 minutos)**
- Abrir: [`portainer-stacks/INICIO-RAPIDO.md`](portainer-stacks/INICIO-RAPIDO.md)
- Seguir 5 passos
- Pronto!

**Opção B: Completo (30 minutos)**
- Abrir: [`portainer-stacks/GUIA-PORTAINER.md`](portainer-stacks/GUIA-PORTAINER.md)
- Passo a passo detalhado
- Troubleshooting incluído

---

## 📝 Resumo dos Passos

### Para Impacientes

1. **Criar volumes** no Portainer (atlas_data, n8n_data)
2. **Substituir stack Chatwoot** pela versão white-label
3. **Criar database** `atlas_nexa` no Postgres
4. **Deploy stack Atlas Nexa**
5. **Gerar API token** no Chatwoot
6. **Conectar** Atlas com Chatwoot

**Total:** ~10 minutos

**Resultado:** Chatwoot white-label + AI SDR funcionando

---

## 🎯 O Que Você Vai Ter

### Antes (Atual)

```
WhatsApp → Chatwoot → Atendentes humanos
```

### Depois (Com Atlas Nexa)

```
WhatsApp → Atlas Nexa (AI) → Qualifica lead (score 1-10)
                ↓
        Score >= 7? SIM → Chatwoot (humanos)
        Score < 7?  NÃO → Continua no bot
```

**+ Branding customizado:** Sem marca "Chatwoot", usa sua marca

---

## 🗂️ Outras Documentações

**Se quiser entender a fundo:**

### Arquitetura e Planejamento
- [`docs/01-CURRENT-ARCHITECTURE.md`](docs/01-CURRENT-ARCHITECTURE.md) - Como funciona sua stack atual
- [`docs/02-WHITELABEL-PLAN.md`](docs/02-WHITELABEL-PLAN.md) - Estratégia de white-label
- [`docs/04-INTEGRATION-ARCHITECTURE.md`](docs/04-INTEGRATION-ARCHITECTURE.md) - Como Atlas + Chatwoot se conectam

### Build e Deploy
- [`docs/03-BUILD-PROCESS.md`](docs/03-BUILD-PROCESS.md) - Como buildar imagem Docker customizada
- [`docs/05-DEPLOYMENT-GUIDE.md`](docs/05-DEPLOYMENT-GUIDE.md) - Deploy completo (servidor, SSL, backup)

### Business
- [`EXECUTIVE-SUMMARY.md`](EXECUTIVE-SUMMARY.md) - ROI, custos, receita projetada
- [`README.md`](README.md) - Overview do projeto completo

**⚠️ IMPORTANTE:** Esses docs são mais técnicos. Se você só quer fazer deploy via Portainer, **ignore** e use apenas os guias na pasta `portainer-stacks/`.

---

## 🤔 FAQ Rápido

### "Preciso saber linha de comando?"

**NÃO.** Tudo é via interface do Portainer (copiar/colar YAML).

### "Vai quebrar meu Chatwoot atual?"

**NÃO.** A atualização é backward-compatible. Se der errado, é só reverter.

**Recomendação:** Fazer backup antes:
- Portainer → Stacks → chatwoot → Editor → Copiar YAML atual
- Salvar em um `.txt` no seu PC

### "Preciso fazer tudo de uma vez?"

**NÃO.** Pode fazer em etapas:
1. Semana 1: Só atualizar Chatwoot (white-label)
2. Semana 2: Deploy Atlas Nexa
3. Semana 3: Integrar os dois

### "Qual a diferença deste projeto para os docs principais?"

| Projeto Principal | Versão Portainer |
|-------------------|------------------|
| Docker Compose via terminal | Portainer UI (copiar/colar) |
| Scripts bash | Sem scripts |
| Deploy automático | Manual (mas simples) |
| Para devs | Para qualquer um |

**Ambos chegam no mesmo resultado!**

### "E se eu quiser usar linha de comando?"

Aí você usa os arquivos em [`docker/`](docker/) e segue o [`docs/05-DEPLOYMENT-GUIDE.md`](docs/05-DEPLOYMENT-GUIDE.md).

---

## ✅ Checklist Antes de Começar

Antes de fazer qualquer coisa, confirme:

- [ ] Tenho acesso ao Portainer (https://seu-servidor:9443)
- [ ] Chatwoot atual está funcionando
- [ ] Sei a senha do Postgres (`POSTGRES_PASSWORD`)
- [ ] Tenho API keys (OpenAI, WhatsApp) prontas
- [ ] Fiz backup do YAML atual do Chatwoot

**Tudo OK?** → Ir para [`portainer-stacks/INICIO-RAPIDO.md`](portainer-stacks/INICIO-RAPIDO.md)

---

## 🆘 Precisa de Ajuda?

**Durante deploy:**
- Ver logs do container no Portainer
- Consultar troubleshooting: [`portainer-stacks/GUIA-PORTAINER.md#troubleshooting`](portainer-stacks/GUIA-PORTAINER.md#troubleshooting)

**Dúvidas gerais:**
- Ler [`README.md`](README.md) principal
- Ver [`EXECUTIVE-SUMMARY.md`](EXECUTIVE-SUMMARY.md) para contexto de negócio

**Bugs ou problemas:**
- Mandar log do container
- Descrever o que aconteceu vs. o que esperava

---

## 🎯 Próximo Passo

**👉 Abrir:** [`portainer-stacks/INICIO-RAPIDO.md`](portainer-stacks/INICIO-RAPIDO.md)

Lá tem os 5 passos para fazer deploy. Leva 10 minutos.

**Boa sorte!** 🚀
