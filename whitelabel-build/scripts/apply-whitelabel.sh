#!/bin/sh
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
# Check if files exist before copying to avoid errors if some are missing
[ -f branding/assets/logo.svg ] && cp branding/assets/logo.svg app/javascript/dashboard/assets/images/logo.svg
[ -f branding/assets/logo-dark.svg ] && cp branding/assets/logo-dark.svg app/javascript/dashboard/assets/images/logo-dark.svg
[ -f branding/assets/favicon.ico ] && cp branding/assets/favicon.ico public/favicon.ico

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
if [ -f branding/colors.scss ]; then
  cp branding/colors.scss app/javascript/dashboard/assets/scss/_custom-variables.scss
  
  # Import custom variables in main SCSS
  if ! grep -q "_custom-variables" app/javascript/dashboard/assets/scss/app.scss; then
    sed -i "1i @import 'custom-variables';" app/javascript/dashboard/assets/scss/app.scss
  fi
fi

echo "✅ White-label customizations applied successfully!"
echo ""
echo "Brand Name: ${BRAND_NAME}"
echo "Primary Color: ${PRIMARY_COLOR}"
