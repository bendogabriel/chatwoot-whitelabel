#!/usr/bin/env python3
"""
Nexa AI Platform - Client Configuration Generator

Reads client config YAML and generates:
- .env file for deployment
- docker-compose.yml with client branding
- DNS configuration
- Deployment checklist

Usage:
    python generate-client-config.py clients/client-abc.yml
"""

import yaml
import os
import sys
import secrets
import string
from pathlib import Path
from datetime import datetime

class ClientConfigGenerator:
    def __init__(self, config_file):
        self.config_file = Path(config_file)
        self.config = self.load_config()
        self.output_dir = Path(f"generated/{self.config['client']['id']}")
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def load_config(self):
        """Load and validate client configuration"""
        if not self.config_file.exists():
            raise FileNotFoundError(f"Config file not found: {self.config_file}")

        with open(self.config_file, 'r', encoding='utf-8') as f:
            config = yaml.safe_load(f)

        # Validate required fields
        required_fields = ['client', 'branding', 'domains', 'email']
        for field in required_fields:
            if field not in config:
                raise ValueError(f"Missing required field: {field}")

        return config

    def generate_secret(self, length=32):
        """Generate cryptographically secure random string"""
        alphabet = string.ascii_letters + string.digits
        return ''.join(secrets.choice(alphabet) for _ in range(length))

    def generate_env_file(self):
        """Generate .env file for Docker deployment"""
        client = self.config['client']
        branding = self.config['branding']
        domains = self.config['domains']
        email = self.config['email']

        env_content = f"""# Nexa AI Platform - Environment Configuration
# Generated: {datetime.now().isoformat()}
# Client: {client['name']}

# ==========================================
# CLIENT INFORMATION
# ==========================================
CLIENT_NAME={client['id']}
BRAND_NAME={branding['name']}
BRAND_LOGO_URL={branding['logo']['url']}
BRAND_PRIMARY_COLOR={branding['colors']['primary']}
SUPPORT_EMAIL={email['support_email']}

# ==========================================
# DOMAINS
# ==========================================
CHATWOOT_DOMAIN={domains['inbox']}
CHATWOOT_URL=https://{domains['inbox']}
ATLAS_DOMAIN={domains['atlas']}
DASHBOARD_DOMAIN={domains['dashboard']}
N8N_DOMAIN={domains['n8n']}
N8N_URL=https://{domains['n8n']}

# ==========================================
# DOCKER IMAGES
# ==========================================
CHATWOOT_IMAGE=nexateam/chatwoot-custom:v3.15.0
ATLAS_IMAGE=nexateam/atlas-nexa:latest
DASHBOARD_IMAGE=nexateam/nexa-dashboard:latest

# ==========================================
# PORTS (For local development)
# ==========================================
CHATWOOT_PORT=3000
ATLAS_PORT=4000
DASHBOARD_PORT=5000
N8N_PORT=5678

# ==========================================
# DATABASE (PostgreSQL)
# ==========================================
POSTGRES_PASSWORD={self.generate_secret(32)}

# ==========================================
# REDIS
# ==========================================
REDIS_PASSWORD={self.generate_secret(32)}

# ==========================================
# CHATWOOT CONFIGURATION
# ==========================================
CHATWOOT_SECRET_KEY={self.generate_secret(64)}

# Generate after first login (see deployment guide)
CHATWOOT_API_TOKEN=
CHATWOOT_ACCOUNT_ID=1
CHATWOOT_INBOX_ID=1

# ==========================================
# EMAIL (SMTP)
# ==========================================
SMTP_DOMAIN={email['smtp']['host'].split('.')[-2]}.{email['smtp']['host'].split('.')[-1]}
SMTP_ADDRESS={email['smtp']['host']}
SMTP_PORT={email['smtp']['port']}
SMTP_USERNAME={email['smtp']['username']}
SMTP_PASSWORD=  # ⚠️ SET THIS MANUALLY (Gmail app password)

# ==========================================
# ATLAS NEXA CONFIGURATION
# ==========================================
ATLAS_SUPABASE_KEY=  # ⚠️ SET THIS MANUALLY

# AI Services
OPENAI_API_KEY=  # ⚠️ SET THIS MANUALLY
GOOGLE_AI_API_KEY=
ELEVENLABS_API_KEY=

# WhatsApp API
WHATSAPP_API_URL=  # ⚠️ SET THIS MANUALLY
WHATSAPP_API_KEY=  # ⚠️ SET THIS MANUALLY
WHATSAPP_PHONE_ID=  # ⚠️ SET THIS MANUALLY

# Qualification Settings
QUALIFICATION_THRESHOLD={self.config['ai']['qualification']['threshold']}
AUTO_HANDOFF_ENABLED={str(self.config['ai']['qualification']['auto_handoff']).lower()}

# ==========================================
# DASHBOARD CONFIGURATION
# ==========================================
DASHBOARD_JWT_SECRET={self.generate_secret(32)}
DASHBOARD_SESSION_SECRET={self.generate_secret(32)}

# ==========================================
# N8N CONFIGURATION
# ==========================================
N8N_ENCRYPTION_KEY={self.generate_secret(32)}

# ==========================================
# TRAEFIK / SSL
# ==========================================
ACME_EMAIL={client['contact']['email']}

# ==========================================
# WARNING: SENSITIVE FILE
# ==========================================
# This file contains secrets. Do NOT commit to version control.
# Store securely in password manager (1Password, Bitwarden, etc.)
"""

        output_file = self.output_dir / '.env'
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(env_content)

        print(f"✅ Generated: {output_file}")
        return output_file

    def generate_dns_config(self):
        """Generate DNS configuration guide"""
        domains = self.config['domains']
        client = self.config['client']

        dns_content = f"""# DNS Configuration for {client['name']}

Add the following A records to your DNS provider:

## Records Required

| Type | Name      | Value        | TTL  |
|------|-----------|--------------|------|
| A    | inbox     | <server-ip>  | 300  |
| A    | atlas     | <server-ip>  | 300  |
| A    | dashboard | <server-ip>  | 300  |
| A    | n8n       | <server-ip>  | 300  |

Replace `<server-ip>` with your DigitalOcean droplet IP address.

## Full Domain Names

- Chatwoot:  {domains['inbox']}
- Atlas SDR: {domains['atlas']}
- Dashboard: {domains['dashboard']}
- N8N:       {domains['n8n']}

## Verification

After adding records, verify propagation:

```bash
dig {domains['inbox']} +short
# Should return: <server-ip>

# Check all domains
for domain in {domains['inbox']} {domains['atlas']} {domains['dashboard']} {domains['n8n']}; do
    echo -n "$domain: "
    dig $domain +short
done
```

## Cloudflare Configuration (if using)

1. Add A records as above
2. **IMPORTANT:** Set SSL/TLS mode to "Full" (not "Flexible")
3. Enable "Always Use HTTPS"
4. Disable "Automatic HTTPS Rewrites" (can cause issues with Traefik)

DNS propagation usually takes 5-15 minutes.
"""

        output_file = self.output_dir / 'DNS-CONFIG.md'
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(dns_content)

        print(f"✅ Generated: {output_file}")
        return output_file

    def generate_deployment_checklist(self):
        """Generate deployment checklist"""
        client = self.config['client']
        domains = self.config['domains']

        checklist_content = f"""# Deployment Checklist - {client['name']}

**Date:** {datetime.now().strftime('%Y-%m-%d')}
**Client ID:** {client['id']}

---

## Pre-Deployment

- [ ] Server provisioned (DigitalOcean droplet or equivalent)
  - Region: {self.config['deployment']['server']['region']}
  - Size: {self.config['deployment']['server']['size']}
  - Server IP: _______________

- [ ] DNS records configured (see DNS-CONFIG.md)
  - [ ] {domains['inbox']} → Server IP
  - [ ] {domains['atlas']} → Server IP
  - [ ] {domains['dashboard']} → Server IP
  - [ ] {domains['n8n']} → Server IP
  - [ ] DNS propagation verified (wait 5-15 min)

- [ ] API Keys obtained
  - [ ] OpenAI API key
  - [ ] WhatsApp API credentials
  - [ ] SMTP password (Gmail app password)
  - [ ] Stored in password manager

---

## Deployment Steps

- [ ] SSH into server
  ```bash
  ssh root@<server-ip>
  ```

- [ ] Install Docker & Docker Compose
  ```bash
  curl -fsSL https://get.docker.com | sh
  apt install docker-compose-plugin -y
  ```

- [ ] Clone/upload Nexa Platform files
  ```bash
  mkdir -p /opt/nexa-platform
  # Upload files via SCP or git clone
  ```

- [ ] Copy generated .env file to server
  ```bash
  scp .env root@<server-ip>:/opt/nexa-platform/docker/.env
  ```

- [ ] Edit .env with manual secrets
  ```bash
  nano /opt/nexa-platform/docker/.env
  # Fill in:
  # - SMTP_PASSWORD
  # - OPENAI_API_KEY
  # - WHATSAPP_API_KEY
  # - WHATSAPP_API_URL
  # - WHATSAPP_PHONE_ID
  ```

- [ ] Make scripts executable
  ```bash
  cd /opt/nexa-platform/docker
  chmod +x scripts/*.sh
  ```

- [ ] Start platform
  ```bash
  ./scripts/start.sh
  ```

- [ ] Verify services are running
  ```bash
  docker compose -f docker-compose.nexa-platform.yml ps
  # All services should show "running"
  ```

---

## Initial Configuration

- [ ] Access Chatwoot: https://{domains['inbox']}
  - [ ] Login with default credentials
  - [ ] Change admin password
  - [ ] Update profile (name, email)

- [ ] Create Chatwoot inbox
  - [ ] Settings → Inboxes → Add WhatsApp
  - [ ] Note inbox ID: _______________

- [ ] Generate Chatwoot API token
  - [ ] Settings → Integrations → API → Platform → Create Token
  - [ ] Copy token: _______________________________
  - [ ] Add to .env: CHATWOOT_API_TOKEN=...
  - [ ] Restart: `./scripts/restart.sh`

- [ ] Configure N8N: https://{domains['n8n']}
  - [ ] Create owner account
  - [ ] Import workflows from `n8n-workflows/`
  - [ ] Configure credentials (Chatwoot, Supabase, WhatsApp)
  - [ ] Activate workflows

- [ ] Test integration
  - [ ] Send test message to WhatsApp
  - [ ] Verify Atlas Nexa receives it
  - [ ] Verify handoff to Chatwoot when score >= {self.config['ai']['qualification']['threshold']}

---

## Post-Deployment

- [ ] Configure firewall (UFW)
  ```bash
  ufw allow 22/tcp
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw enable
  ```

- [ ] Set up automated backups
  ```bash
  /opt/nexa-platform/backup.sh
  # Add to crontab: 0 2 * * * /opt/nexa-platform/backup.sh
  ```

- [ ] Verify SSL certificates
  ```bash
  curl -vI https://{domains['inbox']} 2>&1 | grep "SSL certificate"
  ```

- [ ] Create client admin user
  - [ ] Email: {self.config['team'][0]['email']}
  - [ ] Role: {self.config['team'][0]['role']}

---

## Client Handoff

- [ ] Send access credentials (via secure channel)
- [ ] Send onboarding documentation
- [ ] Schedule training call
- [ ] Add to monitoring/alerting
- [ ] Update internal knowledge base

---

## Troubleshooting

If services fail to start:
```bash
# Check logs
./scripts/logs.sh

# Common issues:
# 1. DNS not propagated → wait 15 min
# 2. Port conflict → change ports in .env
# 3. Out of memory → upgrade server
```

---

**Deployment completed:** _______________ (date/time)
**Deployed by:** _______________
**Notes:**



"""

        output_file = self.output_dir / 'DEPLOYMENT-CHECKLIST.md'
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(checklist_content)

        print(f"✅ Generated: {output_file}")
        return output_file

    def generate_readme(self):
        """Generate README for client deployment"""
        client = self.config['client']

        readme_content = f"""# {client['name']} - Nexa AI Platform Deployment

**Generated:** {datetime.now().isoformat()}

## Quick Start

This directory contains all configuration files needed to deploy Nexa AI Platform for {client['name']}.

### Files Included

- `.env` - Environment variables for Docker deployment (⚠️ contains secrets)
- `DNS-CONFIG.md` - DNS records to configure
- `DEPLOYMENT-CHECKLIST.md` - Step-by-step deployment guide

### Prerequisites

- Server (DigitalOcean droplet or equivalent)
- Docker & Docker Compose installed
- DNS access to configure subdomains
- API keys (OpenAI, WhatsApp, SMTP)

### Deployment

1. **Provision server** (see DEPLOYMENT-CHECKLIST.md)
2. **Configure DNS** (see DNS-CONFIG.md)
3. **Upload files to server:**
   ```bash
   scp -r . root@<server-ip>:/opt/nexa-platform/
   ```
4. **Fill in manual secrets in .env:**
   - SMTP_PASSWORD
   - OPENAI_API_KEY
   - WHATSAPP_API_KEY
5. **Start platform:**
   ```bash
   cd /opt/nexa-platform/docker
   ./scripts/start.sh
   ```

### Access Points

- Chatwoot: https://{self.config['domains']['inbox']}
- Dashboard: https://{self.config['domains']['dashboard']}
- N8N: https://{self.config['domains']['n8n']}

### Support

For assistance, contact Nexa Team:
- Email: support@nexateam.com.br
- WhatsApp: +55 11 9 9999-9999

---

**⚠️ SECURITY WARNING**

This directory contains sensitive credentials in `.env` file.

- ✅ DO: Store in secure password manager
- ✅ DO: Encrypt before sending to team
- ❌ DON'T: Commit to Git
- ❌ DON'T: Send via email/Slack unencrypted
"""

        output_file = self.output_dir / 'README.md'
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(readme_content)

        print(f"✅ Generated: {output_file}")
        return output_file

    def generate_all(self):
        """Generate all configuration files"""
        print(f"\n🚀 Generating configuration for: {self.config['client']['name']}")
        print(f"📁 Output directory: {self.output_dir}\n")

        self.generate_env_file()
        self.generate_dns_config()
        self.generate_deployment_checklist()
        self.generate_readme()

        print(f"\n✅ All files generated successfully!")
        print(f"\n📂 Files created in: {self.output_dir}")
        print(f"\n📝 Next steps:")
        print(f"   1. Review {self.output_dir}/.env and fill in manual secrets")
        print(f"   2. Follow {self.output_dir}/DEPLOYMENT-CHECKLIST.md")
        print(f"   3. Configure DNS as per {self.output_dir}/DNS-CONFIG.md")
        print(f"\n⚠️  Remember: Store .env file securely (password manager)\n")

def main():
    if len(sys.argv) < 2:
        print("Usage: python generate-client-config.py <client-config.yml>")
        print("\nExample:")
        print("  python generate-client-config.py clients/client-abc.yml")
        sys.exit(1)

    config_file = sys.argv[1]

    try:
        generator = ClientConfigGenerator(config_file)
        generator.generate_all()
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
