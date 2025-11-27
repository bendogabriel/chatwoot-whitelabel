#!/bin/sh
set -e
set -x # Enable debug logging

echo "🎨 Applying white-label customizations..."
echo "Current directory: $(pwd)"

# Load brand config
BRAND_NAME="${BRAND_NAME:-Nexa Inbox}"
PRIMARY_COLOR="${PRIMARY_COLOR:-#1f93ff}"

# Helper function to safely replace text
safe_replace() {
  dir=$1
  pattern=$2
  replacement=$3
  file_pattern=$4
  
  if [ -d "$dir" ]; then
    echo "  Processing $dir..."
    find "$dir" -type f -name "$file_pattern" -exec sed -i "s|$pattern|$replacement|g" {} +
  else
    echo "  ⚠️ Directory not found: $dir (skipping)"
  fi
}

# 1. Update i18n translations (Portuguese)
echo "  📝 Updating translations..."
# Try both pt_BR and pt-BR just in case
safe_replace "app/javascript/dashboard/i18n/locale/pt_BR" "Chatwoot" "$BRAND_NAME" "*.json"
safe_replace "app/javascript/dashboard/i18n/locale/pt-BR" "Chatwoot" "$BRAND_NAME" "*.json"

# 2. Update package.json
echo "  📦 Updating package.json..."
if [ -f "package.json" ]; then
  sed -i 's/"name": "chatwoot"/"name": "nexa-inbox"/' package.json
  sed -i 's/"description": ".*"/"description": "AI-Powered Customer Support Platform"/' package.json
else
  echo "  ⚠️ package.json not found"
fi

# 3. Copy branding assets
echo "  🖼️  Copying branding assets..."
# Ensure target directories exist
mkdir -p app/javascript/dashboard/assets/images
mkdir -p public

[ -f branding/assets/logo.svg ] && cp -v branding/assets/logo.svg app/javascript/dashboard/assets/images/logo.svg || echo "  ⚠️ Custom logo.svg not found"
[ -f branding/assets/logo-dark.svg ] && cp -v branding/assets/logo-dark.svg app/javascript/dashboard/assets/images/logo-dark.svg || echo "  ⚠️ Custom logo-dark.svg not found"
[ -f branding/assets/favicon.ico ] && cp -v branding/assets/favicon.ico public/favicon.ico || echo "  ⚠️ Custom favicon.ico not found"

# 4. Update email templates
echo "  📧 Updating email templates..."
safe_replace "app/views/mailers" "Chatwoot" "$BRAND_NAME" "*.erb"

# Remove footer links to chatwoot.com
if [ -d "app/views/mailers" ]; then
  find app/views/mailers -type f -name "*.html.erb" -exec sed -i '/chatwoot\.com/d' {} +
fi

# 5. Update HTML layout
echo "  🌐 Updating HTML layout..."
LAYOUT_FILE="app/views/layouts/application.html.erb"
if [ -f "$LAYOUT_FILE" ]; then
  sed -i "s|<title>Chatwoot</title>|<title>${BRAND_NAME}</title>|" "$LAYOUT_FILE"
  sed -i "s|content=\"Chatwoot\"|content=\"${BRAND_NAME}\"|" "$LAYOUT_FILE"
else
  echo "  ⚠️ Layout file not found: $LAYOUT_FILE"
fi

# 6. Copy custom SCSS variables
echo "  🎨 Applying custom colors..."
if [ -f branding/colors.scss ]; then
  TARGET_SCSS="app/javascript/dashboard/assets/scss/_custom-variables.scss"
  mkdir -p $(dirname "$TARGET_SCSS")
  cp branding/colors.scss "$TARGET_SCSS"
  
  MAIN_SCSS="app/javascript/dashboard/assets/scss/app.scss"
  if [ -f "$MAIN_SCSS" ]; then
    if ! grep -q "_custom-variables" "$MAIN_SCSS"; then
      sed -i "1i @import 'custom-variables';" "$MAIN_SCSS"
    fi
  else
    echo "  ⚠️ Main SCSS file not found: $MAIN_SCSS"
  fi
fi

echo "✅ White-label customizations applied successfully!"
