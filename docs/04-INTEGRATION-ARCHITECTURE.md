# Atlas Nexa ↔ Chatwoot Integration Architecture

**Goal:** Seamlessly hand off qualified leads from AI SDR (Atlas Nexa) to human agents (Chatwoot)

---

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      Nexa AI Platform                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐ │
│  │              │      │              │      │              │ │
│  │ Atlas Nexa   │─────▶│  Chatwoot    │◀────▶│  Dashboard   │ │
│  │  (AI SDR)    │      │  (Human CRM) │      │  (Analytics) │ │
│  │              │      │              │      │              │ │
│  └──────────────┘      └──────────────┘      └──────────────┘ │
│         │                      │                      │        │
│         │                      │                      │        │
│         ▼                      ▼                      ▼        │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │            Shared PostgreSQL (pgvector)                   │ │
│  │  - leads (Atlas)                                          │ │
│  │  - conversations (Atlas)                                  │ │
│  │  - messages (Atlas)                                       │ │
│  │  - contacts (Chatwoot)                                    │ │
│  │  - conversations (Chatwoot)                               │ │
│  │  - messages (Chatwoot)                                    │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │                 Shared Redis Cache                        │ │
│  │  - DB 0: Chatwoot (sessions, jobs)                        │ │
│  │  - DB 1: Atlas Nexa (cache, rate limits)                  │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Integration Flow

### Phase 1: AI Qualification (Atlas Nexa)

```
WhatsApp → Evolution API → N8N → Atlas Nexa (GPT-4o + RAG)
                                      │
                                      ▼
                              ┌──────────────┐
                              │ Lead Scoring │
                              │ (1-10 scale) │
                              └──────────────┘
                                      │
                      ┌───────────────┴───────────────┐
                      ▼                               ▼
              Score < 7                         Score >= 7
          ┌────────────────┐              ┌────────────────┐
          │ Keep in bot    │              │ Hand off to    │
          │ Auto-follow-up │              │ human agent    │
          └────────────────┘              └────────────────┘
                                                  │
                                                  ▼
                                          Create conversation
                                          in Chatwoot via API
```

### Phase 2: Human Handoff (Chatwoot)

```
Atlas Nexa detects qualified lead (score >= 7)
    ↓
1. Create/update Chatwoot contact via API
    POST /api/v1/accounts/{account_id}/contacts
    {
      "name": "Lead Name",
      "phone_number": "+5511999999999",
      "custom_attributes": {
        "qualification_score": 8,
        "interest": "Automação com IA",
        "source": "atlas_nexa",
        "last_bot_message": "Gostaria de agendar reunião"
      }
    }
    ↓
2. Create conversation in Chatwoot
    POST /api/v1/accounts/{account_id}/conversations
    {
      "source_id": "whatsapp_+5511999999999",
      "inbox_id": 1,
      "contact_id": 123,
      "status": "open",
      "assignee_id": null  // Auto-assign to team
    }
    ↓
3. Add conversation messages (history)
    POST /api/v1/accounts/{account_id}/conversations/{id}/messages
    {
      "content": "Bot: Qual seu interesse?\nLead: Quero automação...",
      "message_type": "outgoing",
      "private": true  // Internal note with bot history
    }
    ↓
4. Assign to agent (round-robin or AI-based)
    POST /api/v1/accounts/{account_id}/conversations/{id}/assignments
    {
      "assignee_id": 5  // Team member
    }
    ↓
5. Notify agent (webhook + email)
    Chatwoot sends notification:
    "New qualified lead assigned to you"
```

### Phase 3: Human Agent Takes Over

```
Agent receives notification in Chatwoot
    ↓
Opens conversation, sees:
- Contact details
- Qualification score: 8/10
- Interest: "Automação com IA"
- Full bot conversation history (as internal note)
    ↓
Agent sends first message:
    "Olá! Vi que você está interessado em automação.
     Vamos agendar uma reunião?"
    ↓
Message delivered via WhatsApp (Evolution API)
    ↓
Lead responds → Message appears in Chatwoot
    ↓
Agent continues conversation until closed
```

### Phase 4: Sync Back to Atlas Nexa (Optional)

```
Chatwoot conversation updated
    ↓
Webhook to N8N:
    POST https://n8n.nexateam.com.br/webhook/chatwoot-update
    {
      "event": "conversation_updated",
      "conversation": { ... },
      "status": "resolved"
    }
    ↓
N8N updates Atlas Nexa database:
    UPDATE leads SET status = 'convertido', closed_at = NOW()
    WHERE phone = '+5511999999999';
    ↓
Dashboard shows updated metrics
```

---

## Data Model Alignment

### Atlas Nexa Schema (Supabase)

```sql
-- Current Atlas Nexa tables
CREATE TABLE leads (
  id UUID PRIMARY KEY,
  name TEXT,
  phone TEXT UNIQUE,
  email TEXT,
  interest TEXT,
  qualification_score INTEGER,  -- 1-10
  status TEXT,  -- 'novo', 'qualificado', 'convertido'
  chatwoot_contact_id INTEGER,  -- FK to Chatwoot
  chatwoot_conversation_id INTEGER,  -- FK to Chatwoot
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

CREATE TABLE conversations (
  id UUID PRIMARY KEY,
  lead_id UUID REFERENCES leads(id),
  status TEXT,  -- 'active', 'handed_off', 'closed'
  last_message_at TIMESTAMP,
  messages_count INTEGER,
  handoff_at TIMESTAMP  -- When handed to Chatwoot
);

CREATE TABLE messages (
  id UUID PRIMARY KEY,
  conversation_id UUID REFERENCES conversations(id),
  sender TEXT,  -- 'bot', 'lead', 'agent'
  content TEXT,
  created_at TIMESTAMP
);
```

### Chatwoot Schema (PostgreSQL)

```sql
-- Chatwoot tables (simplified)
CREATE TABLE contacts (
  id SERIAL PRIMARY KEY,
  name VARCHAR,
  phone_number VARCHAR UNIQUE,
  email VARCHAR,
  custom_attributes JSONB,  -- Store Atlas Nexa data here
  created_at TIMESTAMP
);

CREATE TABLE conversations (
  id SERIAL PRIMARY KEY,
  contact_id INTEGER REFERENCES contacts(id),
  inbox_id INTEGER,
  status VARCHAR,  -- 'open', 'resolved', 'pending'
  assignee_id INTEGER,
  created_at TIMESTAMP
);

CREATE TABLE messages (
  id SERIAL PRIMARY KEY,
  conversation_id INTEGER REFERENCES conversations(id),
  message_type VARCHAR,  -- 'incoming', 'outgoing'
  content TEXT,
  private BOOLEAN,  -- Internal notes
  created_at TIMESTAMP
);
```

### Shared Database Strategy

**Option A: Separate Databases (Recommended for Production)**

```
PostgreSQL Instance
├── Database: atlas_nexa
│   ├── leads
│   ├── conversations (AI bot)
│   └── messages (AI bot)
└── Database: chatwoot
    ├── contacts
    ├── conversations (human agents)
    └── messages (human agents)
```

**Integration:** API calls + foreign key references in custom_attributes

**Option B: Single Database (Easier for Small Deployments)**

```
PostgreSQL Instance
└── Database: nexa_platform
    ├── atlas_leads (rename from 'leads')
    ├── atlas_conversations
    ├── atlas_messages
    ├── chatwoot_contacts (Chatwoot tables)
    ├── chatwoot_conversations
    └── chatwoot_messages
```

**Integration:** Direct foreign keys + database views

---

## API Integration Points

### Chatwoot API

**Base URL:** `https://chatwoot.nexateam.com.br/api/v1`
**Authentication:** API Access Token (per user or platform)

#### Generate API Token

```bash
# In Chatwoot Rails console
docker exec -it chatwoot_app bundle exec rails c

# Create platform API token (never expires)
account = Account.first
api_token = account.platform_app_api_keys.create!(
  name: 'Atlas Nexa Integration',
  scopes: ['conversation:read', 'conversation:write', 'contact:read', 'contact:write']
)
puts api_token.access_token
# Output: abc123xyz789 (save this!)
```

#### Key Endpoints for Integration

**1. Create/Update Contact**

```http
POST /api/v1/accounts/{account_id}/contacts
Authorization: Bearer abc123xyz789
Content-Type: application/json

{
  "inbox_id": 1,
  "name": "João Silva",
  "phone_number": "+5511999999999",
  "email": "joao@example.com",
  "custom_attributes": {
    "atlas_lead_id": "uuid-here",
    "qualification_score": 8,
    "interest": "Automação com IA",
    "source": "atlas_nexa",
    "bot_conversation_url": "https://n8n.nexateam.com.br/conversation/uuid"
  }
}
```

**Response:**
```json
{
  "id": 123,
  "name": "João Silva",
  "phone_number": "+5511999999999",
  "conversations_count": 0
}
```

**2. Create Conversation**

```http
POST /api/v1/accounts/{account_id}/conversations
Authorization: Bearer abc123xyz789
Content-Type: application/json

{
  "source_id": "whatsapp_+5511999999999",
  "inbox_id": 1,
  "contact_id": 123,
  "status": "open",
  "custom_attributes": {
    "handoff_reason": "qualified_lead",
    "bot_score": 8
  }
}
```

**3. Add Message (Bot History as Internal Note)**

```http
POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/messages
Authorization: Bearer abc123xyz789
Content-Type: application/json

{
  "content": "**Histórico da conversa com o bot:**\n\nBot: Olá! Como posso ajudar?\nLead: Quero saber sobre automação\nBot: Excelente! Qual seu maior desafio?\nLead: Atendimento ao cliente\n\n**Score de qualificação:** 8/10",
  "message_type": "outgoing",
  "private": true
}
```

**4. Assign to Agent**

```http
POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/assignments
Authorization: Bearer abc123xyz789
Content-Type: application/json

{
  "assignee_id": 5
}
```

**5. Get Conversation Status (for Dashboard)**

```http
GET /api/v1/accounts/{account_id}/conversations/{conversation_id}
Authorization: Bearer abc123xyz789
```

---

## N8N Integration Workflow

### Workflow: Atlas Nexa → Chatwoot Handoff

**File:** `n8n-workflows/atlas-chatwoot-handoff.json`

```json
{
  "name": "Atlas Nexa → Chatwoot Handoff",
  "nodes": [
    {
      "name": "Webhook: Lead Qualified",
      "type": "n8n-nodes-base.webhook",
      "parameters": {
        "path": "atlas-qualified-lead",
        "responseMode": "responseNode"
      }
    },
    {
      "name": "Validate Lead Score",
      "type": "n8n-nodes-base.if",
      "parameters": {
        "conditions": {
          "number": [
            {
              "value1": "={{ $json.qualification_score }}",
              "operation": "largerEqual",
              "value2": 7
            }
          ]
        }
      }
    },
    {
      "name": "Create Chatwoot Contact",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "https://chatwoot.nexateam.com.br/api/v1/accounts/1/contacts",
        "method": "POST",
        "authentication": "genericCredentialType",
        "genericAuthType": "httpHeaderAuth",
        "headerAuth": {
          "name": "Authorization",
          "value": "Bearer abc123xyz789"
        },
        "bodyParameters": {
          "parameters": [
            { "name": "name", "value": "={{ $json.name }}" },
            { "name": "phone_number", "value": "={{ $json.phone }}" },
            { "name": "custom_attributes", "value": "={{ JSON.stringify({ atlas_lead_id: $json.id, qualification_score: $json.qualification_score, interest: $json.interest }) }}" }
          ]
        }
      }
    },
    {
      "name": "Create Chatwoot Conversation",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "https://chatwoot.nexateam.com.br/api/v1/accounts/1/conversations",
        "method": "POST",
        "authentication": "genericCredentialType",
        "bodyParameters": {
          "parameters": [
            { "name": "contact_id", "value": "={{ $node['Create Chatwoot Contact'].json.id }}" },
            { "name": "inbox_id", "value": 1 },
            { "name": "status", "value": "open" }
          ]
        }
      }
    },
    {
      "name": "Add Bot History",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "https://chatwoot.nexateam.com.br/api/v1/accounts/1/conversations/={{ $node['Create Chatwoot Conversation'].json.id }}/messages",
        "method": "POST",
        "bodyParameters": {
          "parameters": [
            { "name": "content", "value": "**Bot Conversation:**\n{{ $json.bot_history }}\n\n**Score:** {{ $json.qualification_score }}/10" },
            { "name": "private", "value": true }
          ]
        }
      }
    },
    {
      "name": "Update Atlas Lead",
      "type": "n8n-nodes-base.supabase",
      "parameters": {
        "operation": "update",
        "table": "leads",
        "filterType": "manual",
        "filterValues": [
          { "key": "id", "value": "={{ $json.id }}" }
        ],
        "updateFields": {
          "chatwoot_contact_id": "={{ $node['Create Chatwoot Contact'].json.id }}",
          "chatwoot_conversation_id": "={{ $node['Create Chatwoot Conversation'].json.id }}",
          "status": "handed_off"
        }
      }
    }
  ]
}
```

**Trigger from Atlas Nexa (Python script):**

```python
import requests

def handoff_to_chatwoot(lead):
    """Hand off qualified lead to Chatwoot"""

    if lead['qualification_score'] < 7:
        return  # Keep in bot

    # Trigger N8N workflow
    webhook_url = "https://n8n.nexateam.com.br/webhook/atlas-qualified-lead"
    payload = {
        "id": lead['id'],
        "name": lead['name'],
        "phone": lead['phone'],
        "email": lead.get('email'),
        "interest": lead['interest'],
        "qualification_score": lead['qualification_score'],
        "bot_history": get_conversation_history(lead['id'])
    }

    response = requests.post(webhook_url, json=payload)

    if response.status_code == 200:
        print(f"✅ Lead {lead['name']} handed off to Chatwoot")
    else:
        print(f"❌ Handoff failed: {response.text}")
```

---

## Webhooks (Bidirectional Sync)

### Chatwoot → N8N (Conversation Updates)

**Configure in Chatwoot UI:**
- Settings → Integrations → Webhooks
- Add webhook: `https://n8n.nexateam.com.br/webhook/chatwoot-updates`

**Events to subscribe:**
- `conversation_updated` - Status changed
- `conversation_resolved` - Closed by agent
- `message_created` - New message

**N8N Workflow: Sync Chatwoot → Atlas**

```json
{
  "name": "Chatwoot → Atlas Sync",
  "nodes": [
    {
      "name": "Webhook: Chatwoot Event",
      "type": "n8n-nodes-base.webhook",
      "parameters": {
        "path": "chatwoot-updates"
      }
    },
    {
      "name": "Check Event Type",
      "type": "n8n-nodes-base.switch",
      "parameters": {
        "dataPropertyName": "event",
        "rules": {
          "rules": [
            { "value": "conversation_resolved" }
          ]
        }
      }
    },
    {
      "name": "Update Lead Status in Supabase",
      "type": "n8n-nodes-base.supabase",
      "parameters": {
        "operation": "update",
        "table": "leads",
        "filterType": "manual",
        "filterValues": [
          { "key": "chatwoot_conversation_id", "value": "={{ $json.conversation.id }}" }
        ],
        "updateFields": {
          "status": "convertido",
          "closed_at": "={{ new Date().toISOString() }}"
        }
      }
    }
  ]
}
```

---

## Dashboard Integration

### Unified Metrics

**Data Sources:**
1. **Atlas Nexa (Supabase):** Bot conversations, lead scoring
2. **Chatwoot (PostgreSQL):** Human conversations, resolution time
3. **Combined view:** Total funnel metrics

### Dashboard Queries

**1. Leads by Status**

```sql
-- Query Atlas Nexa + Chatwoot
SELECT
  COUNT(*) FILTER (WHERE status = 'novo') as leads_novos,
  COUNT(*) FILTER (WHERE status = 'qualificado') as leads_qualificados,
  COUNT(*) FILTER (WHERE status = 'handed_off') as em_atendimento,
  COUNT(*) FILTER (WHERE status = 'convertido') as convertidos
FROM atlas_nexa.leads;
```

**2. Handoff Rate**

```sql
SELECT
  COUNT(*) as total_leads,
  COUNT(*) FILTER (WHERE qualification_score >= 7) as qualificados,
  ROUND(100.0 * COUNT(*) FILTER (WHERE qualification_score >= 7) / COUNT(*), 2) as taxa_qualificacao
FROM atlas_nexa.leads
WHERE DATE(created_at) = CURRENT_DATE;
```

**3. Agent Performance**

```sql
SELECT
  u.name as agent,
  COUNT(c.id) as conversations_handled,
  AVG(EXTRACT(EPOCH FROM (c.updated_at - c.created_at)) / 3600) as avg_resolution_hours,
  COUNT(*) FILTER (WHERE c.status = 'resolved') as resolved_count
FROM chatwoot.conversations c
JOIN chatwoot.users u ON u.id = c.assignee_id
WHERE DATE(c.created_at) = CURRENT_DATE
GROUP BY u.name;
```

**4. Full Funnel**

```sql
-- Combined Atlas + Chatwoot
WITH bot_stats AS (
  SELECT
    COUNT(*) as total_contacts,
    AVG(qualification_score) as avg_score
  FROM atlas_nexa.leads
),
human_stats AS (
  SELECT
    COUNT(*) as total_conversations,
    COUNT(*) FILTER (WHERE status = 'resolved') as resolved
  FROM chatwoot.conversations
  WHERE custom_attributes->>'source' = 'atlas_nexa'
)
SELECT
  bot_stats.total_contacts,
  bot_stats.avg_score,
  human_stats.total_conversations as handoffs,
  human_stats.resolved as conversoes,
  ROUND(100.0 * human_stats.resolved / NULLIF(human_stats.total_conversations, 0), 2) as conversion_rate
FROM bot_stats, human_stats;
```

---

## Real-Time Sync (Optional)

### Using PostgreSQL LISTEN/NOTIFY

**Atlas Nexa → Chatwoot (Real-time lead updates)**

```sql
-- In Atlas Nexa database
CREATE OR REPLACE FUNCTION notify_qualified_lead()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.qualification_score >= 7 AND OLD.qualification_score < 7 THEN
    PERFORM pg_notify('qualified_lead', row_to_json(NEW)::text);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER qualified_lead_trigger
AFTER UPDATE ON leads
FOR EACH ROW
EXECUTE FUNCTION notify_qualified_lead();
```

**N8N Listener Node (custom):**

```javascript
// Custom N8N node to listen to PostgreSQL notifications
const { Client } = require('pg');
const client = new Client({ connectionString: process.env.ATLAS_DATABASE_URL });

await client.connect();
client.query('LISTEN qualified_lead');

client.on('notification', async (msg) => {
  const lead = JSON.parse(msg.payload);

  // Trigger Chatwoot handoff workflow
  await fetch('https://n8n.nexateam.com.br/webhook/atlas-qualified-lead', {
    method: 'POST',
    body: JSON.stringify(lead)
  });
});
```

---

## Security Considerations

### API Token Management

**Best practices:**
- ✅ Use separate API tokens per integration (Atlas, N8N, Dashboard)
- ✅ Store tokens in environment variables (not hardcoded)
- ✅ Rotate tokens quarterly
- ✅ Use token scopes to limit access

**Chatwoot Token Scopes:**
```
contact:read, contact:write
conversation:read, conversation:write
inbox:read
team:read
```

### Network Security

**Portainer Stack:**
```yaml
services:
  chatwoot_app:
    networks:
      - minha_rede  # Internal only
      - traefik_public  # HTTPS only
```

**Firewall rules:**
- ✅ Only Traefik exposed to internet (443)
- ✅ Chatwoot, Atlas, Postgres internal only
- ✅ N8N webhooks with signature validation

---

## Performance Optimization

### Database Connection Pooling

**Chatwoot (config/database.yml):**
```yaml
production:
  pool: <%= ENV.fetch("DB_POOL", 20) %>
```

**Atlas Nexa (Supabase):**
```python
# Use connection pooling
from supabase import create_client, Client
supabase: Client = create_client(
    SUPABASE_URL,
    SUPABASE_KEY,
    options={'postgrest': {'connection_pool_size': 20}}
)
```

### Redis Caching

**Shared Redis, separate databases:**
```yaml
# Chatwoot
REDIS_URL=redis://redis:6379/0

# Atlas Nexa
REDIS_URL=redis://redis:6379/1
```

**Cache strategy:**
- Chatwoot: Session data, background jobs
- Atlas Nexa: Lead scores, conversation history

---

## Next Steps

✅ **Integration architecture defined!**

Now implement:

1. **N8N workflows** - Create handoff automation
2. **API tokens** - Generate Chatwoot platform token
3. **Test handoff** - Qualify a lead in Atlas, verify Chatwoot creation
4. **Dashboard queries** - Build unified metrics view

See next: `05-DEPLOYMENT-GUIDE.md` for deploying the full stack.
