# Chatwoot Custom Build Process

**Step-by-step guide to build white-labeled Chatwoot Docker image**

---

## Prerequisites

### Required Tools

```bash
# Git
git --version  # >= 2.30

# Docker
docker --version  # >= 20.10

# Node.js (for local testing)
node --version  # >= 18.x
npm --version   # >= 9.x

# Ruby (for local testing)
ruby --version  # >= 3.2
```

### Docker Hub Account

Create account at https://hub.docker.com (or use private registry)

---

## Step 1: Fork Chatwoot Repository

### Clone Official Repository

```bash
# Clone Chatwoot
git clone https://github.com/chatwoot/chatwoot.git chatwoot-custom
cd chatwoot-custom

# Check current version
git tag | grep "v3.15"
# Output: v3.15.0

# Checkout specific version
git checkout v3.15.0

# Create white-label branch
git checkout -b white-label-nexa
```

### Add Remote for Nexa Fork (Optional)

```bash
# Create GitHub repository: nexateam/chatwoot-custom
# Add as remote
git remote add nexa git@github.com:nexateam/chatwoot-custom.git

# Verify remotes
git remote -v
# origin: chatwoot/chatwoot (upstream)
# nexa: nexateam/chatwoot-custom (your fork)
```

---

## Step 2: Prepare Branding Assets

### Create Branding Directory

```bash
mkdir -p branding/assets
cd branding
```

### Required Assets

**1. Logo Files**

```
branding/assets/
├── logo.svg              # Main logo (used in UI)
├── logo-dark.svg         # Dark theme logo
├── logo-thumbnail.png    # Small logo (32x32) for emails
├── favicon.ico           # Browser tab icon (32x32)
└── og-image.png          # Social media preview (1200x630)
```

**2. Brand Configuration**

**File:** `branding/brand.yml`

```yaml
# Brand configuration (loaded via ENV)
name: Nexa Inbox
tagline: AI-Powered Customer Support
support_email: support@nexateam.com.br
website_url: https://nexateam.com.br
primary_color: "#1f93ff"
secondary_color: "#4ecdc4"
```

**3. Color Scheme**

**File:** `branding/colors.scss`

```scss
// Custom color scheme
$primary-color: #1f93ff;
$secondary-color: #4ecdc4;
$success-color: #44ce4b;
$danger-color: #ff0000;
$warning-color: #ffaa00;

// Override Chatwoot variables
$color-woot: $primary-color;
$color-body: #1f1f1f;
```

---

## Step 3: Apply White-Label Customizations

### Create Customization Script

**File:** `scripts/apply-whitelabel.sh`

```bash
#!/bin/bash
set -e

echo "🎨 Applying white-label customizations..."

# Load brand config
BRAND_NAME="${BRAND_NAME:-Nexa Inbox}"
PRIMARY_COLOR="${PRIMARY_COLOR:-#1f93ff}"

# 1. Update i18n translations (Portuguese)
echo "  📝 Updating translations..."
find app/javascript/dashboard/i18n/locale/pt_BR -type f -name "*.json" \
  -exec sed -i "s/Chatwoot/${BRAND_NAME}/g" {} +

# 2. Update package.json
echo "  📦 Updating package.json..."
sed -i 's/"name": "chatwoot"/"name": "nexa-inbox"/' package.json
sed -i 's/"description": ".*"/"description": "AI-Powered Customer Support Platform"/' package.json

# 3. Copy branding assets
echo "  🖼️  Copying branding assets..."
cp branding/assets/logo.svg app/javascript/dashboard/assets/images/logo.svg
cp branding/assets/logo-dark.svg app/javascript/dashboard/assets/images/logo-dark.svg
cp branding/assets/favicon.ico public/favicon.ico

# 4. Update email templates
echo "  📧 Updating email templates..."
find app/views/mailers -type f \( -name "*.html.erb" -o -name "*.text.erb" \) \
  -exec sed -i "s/Chatwoot/${BRAND_NAME}/g" {} +

# Remove footer links to chatwoot.com
find app/views/mailers -type f -name "*.html.erb" \
  -exec sed -i '/chatwoot\.com/d' {} +

# 5. Update HTML layout
echo "  🌐 Updating HTML layout..."
sed -i "s/<title>Chatwoot<\/title>/<title>${BRAND_NAME}<\/title>/" app/views/layouts/application.html.erb

# 6. Update meta tags
sed -i "s/content=\"Chatwoot\"/content=\"${BRAND_NAME}\"/" app/views/layouts/application.html.erb

# 7. Copy custom SCSS variables
echo "  🎨 Applying custom colors..."
cp branding/colors.scss app/javascript/dashboard/assets/scss/_custom-variables.scss

# Import custom variables in main SCSS
if ! grep -q "_custom-variables" app/javascript/dashboard/assets/scss/app.scss; then
  sed -i "1i @import 'custom-variables';" app/javascript/dashboard/assets/scss/app.scss
fi

echo "✅ White-label customizations applied successfully!"
echo ""
echo "Brand Name: ${BRAND_NAME}"
echo "Primary Color: ${PRIMARY_COLOR}"
```

**Make it executable:**

```bash
chmod +x scripts/apply-whitelabel.sh
```

### Run Customization Script

```bash
export BRAND_NAME="Nexa Inbox"
export PRIMARY_COLOR="#1f93ff"

./scripts/apply-whitelabel.sh
```

---

## Step 4: Create Custom Dockerfile

**File:** `Dockerfile.custom`

```dockerfile
# Use official Chatwoot base image
FROM chatwoot/chatwoot:v3.15.0 as base

# Build stage: Apply customizations
FROM base as builder

WORKDIR /app

# Copy branding files
COPY branding/ /app/branding/

# Copy customization script
COPY scripts/apply-whitelabel.sh /tmp/apply-whitelabel.sh
RUN chmod +x /tmp/apply-whitelabel.sh

# Apply white-label customizations
ARG BRAND_NAME="Nexa Inbox"
ARG PRIMARY_COLOR="#1f93ff"
ENV BRAND_NAME=$BRAND_NAME
ENV PRIMARY_COLOR=$PRIMARY_COLOR

RUN /tmp/apply-whitelabel.sh

# Install dependencies (if any new gems/packages added)
# RUN bundle install
# RUN yarn install

# Precompile assets with custom branding
ENV RAILS_ENV=production
ENV NODE_ENV=production
ENV SECRET_KEY_BASE=dummy-secret-for-asset-compilation

RUN bundle exec rails assets:precompile

# Final stage: Clean production image
FROM base

WORKDIR /app

# Copy customized app from builder
COPY --from=builder /app /app

# Remove unnecessary files
RUN rm -rf /app/branding \
           /app/scripts/apply-whitelabel.sh \
           /tmp/*

# Expose port
EXPOSE 3000

# Use original entrypoint
ENTRYPOINT ["docker/entrypoints/rails.sh"]
CMD ["bundle", "exec", "rails", "s", "-p", "3000", "-b", "0.0.0.0"]
```

---

## Step 5: Build Docker Image

### Create Build Script

**File:** `scripts/build-custom-image.sh`

```bash
#!/bin/bash
set -e

# Configuration
IMAGE_NAME="nexateam/chatwoot-custom"
VERSION="${1:-v3.15.0}"
BRAND_NAME="${BRAND_NAME:-Nexa Inbox}"
PRIMARY_COLOR="${PRIMARY_COLOR:-#1f93ff}"

echo "🐳 Building custom Chatwoot image..."
echo "  Image: ${IMAGE_NAME}:${VERSION}"
echo "  Brand: ${BRAND_NAME}"
echo "  Color: ${PRIMARY_COLOR}"
echo ""

# Build image
docker build \
  --build-arg BRAND_NAME="${BRAND_NAME}" \
  --build-arg PRIMARY_COLOR="${PRIMARY_COLOR}" \
  --tag "${IMAGE_NAME}:${VERSION}" \
  --tag "${IMAGE_NAME}:latest" \
  --file Dockerfile.custom \
  --progress=plain \
  .

echo ""
echo "✅ Build complete!"
echo ""
echo "Images created:"
docker images | grep "${IMAGE_NAME}"
echo ""
echo "Test locally:"
echo "  docker run -it --rm -p 3000:3000 ${IMAGE_NAME}:${VERSION}"
echo ""
echo "Push to registry:"
echo "  docker push ${IMAGE_NAME}:${VERSION}"
echo "  docker push ${IMAGE_NAME}:latest"
```

**Make it executable:**

```bash
chmod +x scripts/build-custom-image.sh
```

### Run Build

```bash
# Build with default branding
./scripts/build-custom-image.sh v3.15.0

# Or with custom branding
BRAND_NAME="Client ABC Inbox" \
PRIMARY_COLOR="#ff6b6b" \
./scripts/build-custom-image.sh v3.15.0-client-abc
```

**Expected output:**

```
🐳 Building custom Chatwoot image...
  Image: nexateam/chatwoot-custom:v3.15.0
  Brand: Nexa Inbox
  Color: #1f93ff

Step 1/15 : FROM chatwoot/chatwoot:v3.15.0 as base
...
Step 15/15 : CMD ["bundle", "exec", "rails", "s", "-p", "3000", "-b", "0.0.0.0"]
✅ Build complete!
```

---

## Step 6: Test Locally

### Create Test Environment

**File:** `.env.test`

```env
# Database
POSTGRES_HOST=localhost
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=password
POSTGRES_DATABASE=chatwoot_test

# Redis
REDIS_URL=redis://localhost:6379

# Rails
SECRET_KEY_BASE=test-secret-key-min-30-chars
RAILS_ENV=development
NODE_ENV=development

# Branding
INSTALLATION_NAME=nexa_inbox_test
BRAND_NAME=Nexa Inbox
FRONTEND_URL=http://localhost:3000
DEFAULT_LOCALE=pt_BR

# Email (optional for testing)
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=test@nexateam.com.br
SMTP_PASSWORD=app-password
MAILER_SENDER_EMAIL=Nexa Inbox <noreply@nexateam.com.br>
```

### Run with Docker Compose

**File:** `docker-compose.test.yml`

```yaml
version: "3.7"

services:
  postgres:
    image: postgres:14
    environment:
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_test:/var/lib/postgresql/data

  redis:
    image: redis:latest
    volumes:
      - redis_test:/data

  chatwoot:
    image: nexateam/chatwoot-custom:latest
    depends_on:
      - postgres
      - redis
    env_file: .env.test
    ports:
      - "3000:3000"
    volumes:
      - chatwoot_test:/app/storage

volumes:
  postgres_test:
  redis_test:
  chatwoot_test:
```

### Start Test Environment

```bash
# Start services
docker-compose -f docker-compose.test.yml up -d

# Wait for database to be ready
sleep 10

# Run migrations
docker-compose -f docker-compose.test.yml exec chatwoot \
  bundle exec rails db:chatwoot_prepare

# Create admin user (optional)
docker-compose -f docker-compose.test.yml exec chatwoot \
  bundle exec rails db:seed

# View logs
docker-compose -f docker-compose.test.yml logs -f chatwoot
```

### Access Application

Open browser: http://localhost:3000

**Expected:**
- ✅ Login page shows "Nexa Inbox" (not Chatwoot)
- ✅ Custom logo in header
- ✅ Custom colors
- ✅ No "Chatwoot" references

### Cleanup Test Environment

```bash
docker-compose -f docker-compose.test.yml down -v
```

---

## Step 7: Push to Registry

### Docker Hub

```bash
# Login to Docker Hub
docker login

# Push images
docker push nexateam/chatwoot-custom:v3.15.0
docker push nexateam/chatwoot-custom:latest
```

### Private Registry (DigitalOcean, AWS ECR, etc.)

```bash
# Example: DigitalOcean Container Registry

# Login
doctl registry login

# Tag for private registry
docker tag nexateam/chatwoot-custom:v3.15.0 \
  registry.digitalocean.com/nexateam/chatwoot-custom:v3.15.0

# Push
docker push registry.digitalocean.com/nexateam/chatwoot-custom:v3.15.0
```

---

## Step 8: Version Control

### Commit Changes

```bash
# Add branding files (be careful not to commit client-specific assets)
git add branding/brand.yml
git add branding/colors.scss

# Add scripts
git add scripts/apply-whitelabel.sh
git add scripts/build-custom-image.sh
git add Dockerfile.custom
git add docker-compose.test.yml

# Commit
git commit -m "Add white-label customization for Nexa Inbox"

# Push to fork
git push nexa white-label-nexa
```

### Create Git Patches (for version upgrades)

```bash
# Generate patches for white-label changes
git format-patch v3.15.0..HEAD -o patches/

# Result:
# patches/0001-add-white-label-customization.patch
# patches/0002-update-branding-assets.patch

# Apply patches to new version later
git checkout v3.16.0
git checkout -b white-label-nexa-v3.16.0
git am patches/*.patch
```

---

## Build Optimization

### Multi-Stage Build Benefits

```dockerfile
# Builder stage: Heavy operations (asset compilation)
FROM base as builder
RUN bundle exec rails assets:precompile  # ~500MB temp files

# Final stage: Only production files
FROM base
COPY --from=builder /app/public/assets /app/public/assets  # Only ~50MB
```

**Size comparison:**
- Official image: ~1.2GB
- Custom image (optimized): ~1.3GB
- Custom image (unoptimized): ~2.5GB

### Build Cache Optimization

```dockerfile
# Copy dependency files first (rarely change)
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY package.json yarn.lock ./
RUN yarn install

# Copy app code last (changes frequently)
COPY . .
```

**Effect:**
- First build: ~15 minutes
- Subsequent builds (with cache): ~3 minutes

---

## Troubleshooting

### Build Fails: Asset Compilation Error

**Error:**
```
ExecJS::RuntimeError: unexpected token
```

**Fix:**
```bash
# Node.js version mismatch
# Use same Node version as official image

docker build --build-arg NODE_VERSION=18.17.0 ...
```

### Build Fails: Missing Dependencies

**Error:**
```
Could not find gem 'rails (>= 7.0)'
```

**Fix:**
```bash
# Update Gemfile.lock
docker run --rm -v $(pwd):/app -w /app ruby:3.2 bundle update
```

### Image Size Too Large

**Problem:** Custom image is 3GB+

**Fix:**
- Use multi-stage build (see Dockerfile.custom)
- Remove development dependencies in final stage
- Clean up temp files

```dockerfile
RUN bundle install --without development test && \
    bundle clean && \
    rm -rf /tmp/* /var/tmp/*
```

### Branding Not Applied

**Problem:** UI still shows "Chatwoot"

**Debug:**
```bash
# Check if script ran
docker build --progress=plain . 2>&1 | grep "White-label"

# Inspect image
docker run --rm -it nexateam/chatwoot-custom:latest bash
$ cat app/javascript/dashboard/i18n/locale/pt_BR/index.json | grep -i chatwoot
# Should return nothing
```

---

## CI/CD Automation (Optional)

### GitHub Actions

**File:** `.github/workflows/build-custom-image.yml`

```yaml
name: Build Custom Chatwoot Image

on:
  push:
    branches:
      - white-label-nexa
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          file: ./Dockerfile.custom
          push: true
          tags: |
            nexateam/chatwoot-custom:latest
            nexateam/chatwoot-custom:${{ github.ref_name }}
          build-args: |
            BRAND_NAME=Nexa Inbox
            PRIMARY_COLOR=#1f93ff
```

---

## Next Steps

✅ **Image built successfully!**

Now you can:

1. **Deploy to production** → See `05-DEPLOYMENT-GUIDE.md`
2. **Integrate with Atlas Nexa** → See `04-INTEGRATION-ARCHITECTURE.md`
3. **Create client-specific builds** → Use different `BRAND_NAME` and `PRIMARY_COLOR`

**Quick deployment test:**

```bash
# Update your existing stack in Portainer
# Change image from:
image: chatwoot/chatwoot:v3.15.0

# To:
image: nexateam/chatwoot-custom:v3.15.0

# Redeploy stack
# Your white-labeled Chatwoot is live!
```
