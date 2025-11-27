# Chatwoot White-Label Customization Plan

**Goal:** Create a fully white-labeled Chatwoot instance that can be branded per client

---

## Strategy Overview

We'll use a **2-tier approach** for maximum flexibility:

### Tier 1: Core White-Label (Remove Chatwoot Branding)
- Fork Chatwoot repository
- Remove all "Chatwoot" references from UI
- Generic branding (e.g., "Nexa Inbox" or just "Inbox")
- Build custom Docker image: `nexateam/chatwoot-custom:latest`

### Tier 2: Client-Specific Branding (Environment-Based)
- Inject client logo/colors via environment variables
- Custom installation name per client
- Domain-based branding (optional)
- No code changes needed per client

---

## Files to Modify (Tier 1: Core White-Label)

### Frontend (Vue.js/React Components)

#### 1. Application Layout & Branding

**File:** `app/javascript/dashboard/components/layout/sidebarComponents/Primary.vue`
- Logo in sidebar
- Application name

**File:** `app/javascript/dashboard/components/layout/Navbar.vue`
- Top navigation bar text

**File:** `app/javascript/dashboard/i18n/locale/pt_BR/index.js`
- Portuguese translations (change "Chatwoot" to generic term)

**Changes:**
```javascript
// Before
BRAND_NAME: 'Chatwoot',

// After
BRAND_NAME: process.env.VUE_APP_BRAND_NAME || 'Inbox',
```

#### 2. Login & Public Pages

**File:** `app/javascript/auth/AuthLayout.vue`
- Login page logo
- Footer text

**File:** `app/javascript/widget/components/Header.vue`
- Widget header (live chat bubble)

**File:** `app/views/layouts/application.html.erb`
- HTML `<title>` tag
- Meta tags (og:title, og:description)

#### 3. Email Templates

**Directory:** `app/views/mailers/`
- All email templates (`.html.erb` and `.text.erb`)

**Files to update:**
- `conversation_mailer/` - New conversation notifications
- `confirmation_instructions.html.erb` - Account confirmation
- `reset_password_instructions.html.erb` - Password reset

**Changes:**
- Replace Chatwoot logo URL
- Remove footer links to chatwoot.com
- Use `ENV['BRAND_NAME']` instead of "Chatwoot"

#### 4. Static Assets

**Directory:** `public/`

**Files:**
- `favicon.ico` - Browser tab icon
- `logo.svg` / `logo.png` - Main logo
- `logo-thumbnail.png` - Small logo (emails, previews)

**Replace with:**
- Generic "inbox" icon OR
- Client logo (injected at build time)

#### 5. Configuration Files

**File:** `config/brand.yml`
**Create new file for centralized branding:**

```yaml
# config/brand.yml
default: &default
  name: <%= ENV.fetch('BRAND_NAME', 'Inbox') %>
  support_email: <%= ENV.fetch('SUPPORT_EMAIL', 'support@example.com') %>
  logo_url: <%= ENV.fetch('LOGO_URL', '/assets/logo.svg') %>
  primary_color: <%= ENV.fetch('PRIMARY_COLOR', '#1f93ff') %>
  website_url: <%= ENV.fetch('WEBSITE_URL', '') %>

development:
  <<: *default

production:
  <<: *default
```

**File:** `config/initializers/brand.rb`
**Create initializer to load brand config:**

```ruby
# config/initializers/brand.rb
BRAND_CONFIG = YAML.load_file(Rails.root.join('config', 'brand.yml'))[Rails.env]
```

---

### Backend (Ruby on Rails)

#### 1. Installation Name

**File:** `app/models/installation_config.rb`

Currently uses `ENV['INSTALLATION_NAME']` - this is good, keep it.

**Best practice:** Set to client name in docker-compose.

#### 2. Email Sender

**File:** `config/environments/production.rb`

Already uses `ENV['MAILER_SENDER_EMAIL']` - keep it.

#### 3. Frontend URL

**File:** `config/environments/production.rb`

Already uses `ENV['FRONTEND_URL']` - keep it.

#### 4. API Documentation

**File:** `swagger/index.html`
- Remove Chatwoot references from Swagger docs

---

## Environment Variables (Tier 2: Client Branding)

Add these new environment variables to your stack:

```yaml
# White-label branding
- BRAND_NAME=Nexa Inbox          # Application name
- BRAND_LOGO_URL=https://cdn.example.com/client-logo.png
- BRAND_PRIMARY_COLOR=#1f93ff    # Hex color for buttons, links
- BRAND_WEBSITE_URL=https://client.com
- SUPPORT_EMAIL=support@nexateam.com.br

# Existing (already in use)
- INSTALLATION_NAME=client_name
- FRONTEND_URL=https://inbox.client.com
- MAILER_SENDER_EMAIL=Client Name <noreply@client.com>
```

---

## Build Process

### Step 1: Fork Chatwoot Repository

```bash
# Clone Chatwoot
git clone https://github.com/chatwoot/chatwoot.git chatwoot-custom
cd chatwoot-custom

# Create white-label branch
git checkout -b white-label-v3.15.0

# Add Nexa remote (optional, for backup)
git remote add nexa https://github.com/nexateam/chatwoot-custom.git
```

### Step 2: Apply Customizations

Create a patch file with all branding changes:

**File:** `scripts/apply-whitelabel.sh`

```bash
#!/bin/bash
# Apply white-label customizations

# Replace brand name in i18n files
find app/javascript/dashboard/i18n -type f -name "*.js" -exec sed -i "s/Chatwoot/${BRAND_NAME:-Inbox}/g" {} +

# Update package.json
sed -i 's/"name": "chatwoot"/"name": "nexa-inbox"/' package.json

# Copy custom assets
cp -r branding/assets/* public/

# Update email templates
find app/views/mailers -type f -name "*.html.erb" -exec sed -i "s/Chatwoot/${BRAND_NAME:-Inbox}/g" {} +

echo "✅ White-label customizations applied"
```

### Step 3: Build Custom Docker Image

**File:** `Dockerfile.whitelabel`

```dockerfile
FROM chatwoot/chatwoot:v3.15.0

# Set working directory
WORKDIR /app

# Copy custom branding assets
COPY branding/logo.svg public/assets/logo.svg
COPY branding/favicon.ico public/favicon.ico
COPY branding/brand.yml config/brand.yml

# Apply white-label patches
COPY scripts/apply-whitelabel.sh /tmp/
RUN chmod +x /tmp/apply-whitelabel.sh && /tmp/apply-whitelabel.sh

# Build assets with custom branding
ARG BRAND_NAME="Inbox"
ARG PRIMARY_COLOR="#1f93ff"
ENV VUE_APP_BRAND_NAME=$BRAND_NAME
ENV VUE_APP_PRIMARY_COLOR=$PRIMARY_COLOR

# Rebuild frontend assets
RUN bundle exec rails assets:precompile

# Clean up
RUN rm -rf /tmp/apply-whitelabel.sh

ENTRYPOINT ["docker/entrypoints/rails.sh"]
CMD ["bundle", "exec", "rails", "s", "-p", "3000", "-b", "0.0.0.0"]
```

**Build command:**

```bash
docker build \
  --build-arg BRAND_NAME="Nexa Inbox" \
  --build-arg PRIMARY_COLOR="#1f93ff" \
  -f Dockerfile.whitelabel \
  -t nexateam/chatwoot-custom:v3.15.0 \
  .
```

### Step 4: Push to Registry

```bash
# Tag image
docker tag nexateam/chatwoot-custom:v3.15.0 nexateam/chatwoot-custom:latest

# Push to Docker Hub (or private registry)
docker push nexateam/chatwoot-custom:v3.15.0
docker push nexateam/chatwoot-custom:latest
```

---

## Directory Structure (White-Label Files)

```
chatwoot-custom/
├── Dockerfile.whitelabel          # Custom build file
├── branding/                      # Branding assets (git-ignored per client)
│   ├── assets/
│   │   ├── logo.svg              # Main logo
│   │   ├── logo-thumbnail.png    # Small logo
│   │   └── favicon.ico           # Browser icon
│   ├── brand.yml                 # Brand configuration
│   └── colors.scss               # Custom color scheme
├── scripts/
│   ├── apply-whitelabel.sh       # Branding automation
│   └── build-custom-image.sh     # Build script
└── patches/                       # Git patches for white-label changes
    ├── 01-remove-chatwoot-branding.patch
    ├── 02-add-brand-config.patch
    └── 03-update-email-templates.patch
```

---

## Branding Injection Strategies

### Option A: Build-Time Injection (Recommended)

**Pros:**
- ✅ Single image per client
- ✅ No runtime performance impact
- ✅ Static assets are optimized

**Cons:**
- ❌ Need to rebuild for each client
- ❌ Longer deployment time

**When to use:** <5 clients, or clients need heavy customization

### Option B: Runtime Injection (Environment Variables)

**Pros:**
- ✅ Single image for all clients
- ✅ Fast deployment (just change ENV)
- ✅ Easy to update branding

**Cons:**
- ❌ Limited to text/colors (not logos)
- ❌ Need CDN for logo hosting

**When to use:** 10+ clients, minimal branding differences

### Option C: Hybrid (Recommended for Nexa)

**Strategy:**
1. **Core white-label image** (no Chatwoot branding) → shared by all clients
2. **Client-specific branding** via ENV + CDN-hosted assets
3. **Heavy customizations** get their own image build

**Implementation:**

```yaml
# docker-compose for Client A
chatwoot_app:
  image: nexateam/chatwoot-custom:latest  # Shared image
  environment:
    - INSTALLATION_NAME=client_a
    - BRAND_NAME=Client A Inbox
    - BRAND_LOGO_URL=https://cdn.nexateam.com.br/clients/client-a/logo.svg
    - BRAND_PRIMARY_COLOR=#ff6b6b
    - FRONTEND_URL=https://inbox.clienta.com

# docker-compose for Client B
chatwoot_app:
  image: nexateam/chatwoot-custom:latest  # Same image!
  environment:
    - INSTALLATION_NAME=client_b
    - BRAND_NAME=Client B Support
    - BRAND_LOGO_URL=https://cdn.nexateam.com.br/clients/client-b/logo.svg
    - BRAND_PRIMARY_COLOR=#4ecdc4
    - FRONTEND_URL=https://support.clientb.com
```

---

## CSS Customization (Colors & Styling)

### Method 1: SCSS Variables Override

**File:** `app/javascript/dashboard/assets/scss/_variables.scss`

```scss
// Before
$color-woot: #1f93ff;

// After (use ENV or default)
$color-woot: var(--primary-color, #1f93ff);
```

**Inject at runtime via CSS variables:**

**File:** `app/views/layouts/application.html.erb`

```erb
<style>
  :root {
    --primary-color: <%= ENV.fetch('BRAND_PRIMARY_COLOR', '#1f93ff') %>;
    --brand-name: "<%= ENV.fetch('BRAND_NAME', 'Inbox') %>";
  }
</style>
```

### Method 2: Dynamic Stylesheet

**File:** `app/controllers/application_controller.rb`

```ruby
before_action :set_brand_css

def set_brand_css
  @primary_color = ENV.fetch('BRAND_PRIMARY_COLOR', '#1f93ff')
  @brand_name = ENV.fetch('BRAND_NAME', 'Inbox')
end
```

**File:** `app/views/layouts/application.html.erb`

```erb
<style>
  .button--primary { background-color: <%= @primary_color %>; }
  .logo::after { content: "<%= @brand_name %>"; }
</style>
```

---

## Testing White-Label Build

### 1. Build Image

```bash
cd chatwoot-custom
./scripts/build-custom-image.sh
```

### 2. Test Locally

```bash
docker run -it --rm \
  -e BRAND_NAME="Test Inbox" \
  -e BRAND_PRIMARY_COLOR="#ff0000" \
  -e FRONTEND_URL="http://localhost:3000" \
  -e SECRET_KEY_BASE="test-secret-key" \
  -e REDIS_URL="redis://localhost:6379" \
  -e POSTGRES_HOST="localhost" \
  -e POSTGRES_USERNAME="postgres" \
  -e POSTGRES_PASSWORD="password" \
  -e POSTGRES_DATABASE="chatwoot_test" \
  -p 3000:3000 \
  nexateam/chatwoot-custom:latest
```

### 3. Verify Changes

**Checklist:**
- [ ] Login page shows "Test Inbox" (not Chatwoot)
- [ ] Sidebar logo is custom/generic
- [ ] Email templates use BRAND_NAME
- [ ] Primary color is red (#ff0000)
- [ ] No links to chatwoot.com in footer
- [ ] Favicon is custom
- [ ] HTML title is "Test Inbox"

---

## Maintenance & Updates

### Updating to New Chatwoot Version

```bash
# Add upstream Chatwoot
git remote add upstream https://github.com/chatwoot/chatwoot.git

# Fetch latest
git fetch upstream

# Create new white-label branch for new version
git checkout -b white-label-v3.16.0 upstream/v3.16.0

# Apply white-label patches
git am patches/*.patch

# Resolve conflicts if any
# ...

# Rebuild image
./scripts/build-custom-image.sh v3.16.0
```

### Creating Patches for Version Control

```bash
# After making white-label changes, create patches
git format-patch upstream/v3.15.0..HEAD -o patches/

# Commit patches to version control
git add patches/
git commit -m "Add white-label patches for v3.15.0"
```

---

## Cost-Benefit Analysis

### Building Custom Image

**Costs:**
- ⏱️ Initial setup: 8-16 hours
- ⏱️ Maintenance per version: 2-4 hours
- 💾 Storage: ~500MB per image version
- 🧠 Learning curve: Ruby on Rails + Vue.js

**Benefits:**
- 💰 No licensing fees (MIT license)
- 🎨 Full branding control
- 🔧 Can add custom features
- 📈 Higher client perceived value
- 🔒 Data sovereignty (self-hosted)

**ROI:** Pays off after **3-5 clients** (vs. paying SaaS per-seat licenses)

---

## Alternative: Quick Win Approach

If full fork is too much work initially, start with **CSS injection only**:

### Minimal White-Label (No Fork Needed)

**File:** `custom-branding.css` (mounted as volume)

```css
/* Hide Chatwoot branding */
.branding-logo { display: none !important; }
.footer-link[href*="chatwoot.com"] { display: none !important; }

/* Inject custom branding */
.application-name::after {
  content: 'Client Inbox';
  font-weight: bold;
}

/* Custom colors */
:root {
  --primary-color: #1f93ff;
}
```

**Mount in docker-compose:**

```yaml
chatwoot_app:
  image: chatwoot/chatwoot:v3.15.0
  volumes:
    - ./custom-branding.css:/app/public/assets/custom-branding.css
```

**Inject in HTML:**

```erb
<!-- app/views/layouts/application.html.erb -->
<link rel="stylesheet" href="/assets/custom-branding.css">
```

**Pros:**
- ✅ Works in 1 hour
- ✅ No build process

**Cons:**
- ❌ Fragile (CSS selectors can break)
- ❌ Limited (can't change all branding)
- ❌ Emails still say "Chatwoot"

---

## Next Steps

Now that we have the white-label plan, we need to:

1. ✅ **Set up build environment** → See `03-BUILD-PROCESS.md`
2. ✅ **Create integration architecture** → See `04-INTEGRATION-ARCHITECTURE.md`
3. ✅ **Deploy multi-client setup** → See `05-DEPLOYMENT-GUIDE.md`

**Recommendation:** Start with **Hybrid Approach** (Option C):
- Build core white-label image (8h work)
- Use ENV variables for client-specific branding (1h per client)
- Heavy customizations get custom builds (rare)

This gives you 80% of the value with 20% of the effort.
