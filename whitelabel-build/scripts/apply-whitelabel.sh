#!/bin/sh
set -e
set -x # Enable debug logging

echo "🎨 Applying PREMIUM White-Label Customizations (Direct Replacement Mode)..."
echo "Current directory: $(pwd)"

# Load brand config
BRAND_NAME="${BRAND_NAME:-Nexa Inbox}"
PRIMARY_COLOR="${PRIMARY_COLOR:-#1f93ff}"
DEFAULT_CHATWOOT_COLOR="#1f93ff"

# Detect App User (to restore permissions later)
# We look at who owns the config.ru file
APP_USER=$(ls -ld config.ru | awk '{print $3}')
echo "Detected App User: $APP_USER"

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

# 1. Update i18n translations (Backend/API)
echo "  📝 Updating backend translations..."
safe_replace "app/javascript/dashboard/i18n/locale/pt_BR" "Chatwoot" "$BRAND_NAME" "*.json"
safe_replace "app/javascript/dashboard/i18n/locale/pt-BR" "Chatwoot" "$BRAND_NAME" "*.json"

# 2. Update package.json (Metadata)
echo "  📦 Updating metadata..."
if [ -f "package.json" ]; then
  sed -i 's/"name": "chatwoot"/"name": "nexa-inbox"/' package.json
else
  echo "  ⚠️ package.json not found"
fi

# 3. Copy branding assets (Images)
echo "  🖼️  Replacing images..."
mkdir -p app/javascript/dashboard/assets/images
mkdir -p public

# Function to copy if exists (supports PNG and SVG)
copy_asset() {
  base_src=$1  # e.g. "branding/assets/logo" (without extension)
  dest=$2      # e.g. "app/javascript/dashboard/assets/images/logo.svg"
  
  # Try to find the file with .svg, .png, or .ico extension
  src=""
  for ext in svg png ico; do
    if [ -f "${base_src}.${ext}" ]; then
      src="${base_src}.${ext}"
      break
    fi
  done
  
  if [ -n "$src" ]; then
    cp -v "$src" "$dest"
    echo "  ✓ Copied $src to $dest"
    # Also copy to public/packs if it exists (compiled assets)
    if [ -d "public/packs" ]; then
      find public/packs -name "$(basename $dest)" -exec cp -v "$src" {} +
    fi
  else
    echo "  ⚠️ Asset not found: ${base_src}.{svg,png,ico}"
  fi
}

# Copy logos (will auto-detect .svg or .png)
copy_asset "branding/assets/logo" "app/javascript/dashboard/assets/images/logo.svg"
copy_asset "branding/assets/logo-dark" "app/javascript/dashboard/assets/images/logo-dark.svg"
copy_asset "branding/assets/favicon" "public/favicon.ico"

# 4. Update HTML Layout (Title & Meta)
echo "  🌐 Updating HTML layout..."
LAYOUT_FILE="app/views/layouts/application.html.erb"
if [ -f "$LAYOUT_FILE" ]; then
  sed -i "s|<title>Chatwoot</title>|<title>${BRAND_NAME}</title>|" "$LAYOUT_FILE"
  sed -i "s|content=\"Chatwoot\"|content=\"${BRAND_NAME}\"|" "$LAYOUT_FILE"
fi

# 5. DIRECT REPLACEMENT: CSS Colors
# Instead of recompiling, we find the compiled CSS and replace the hex code.
echo "  🎨 Injecting custom colors into compiled CSS..."

if [ "$PRIMARY_COLOR" != "$DEFAULT_CHATWOOT_COLOR" ]; then
  echo "  Replacing $DEFAULT_CHATWOOT_COLOR with $PRIMARY_COLOR..."
  
  # Replace in public/packs (Webpack assets)
  safe_replace "public/packs" "$DEFAULT_CHATWOOT_COLOR" "$PRIMARY_COLOR" "*.css"
  
  # Replace in public/assets (Sprockets assets)
  safe_replace "public/assets" "$DEFAULT_CHATWOOT_COLOR" "$PRIMARY_COLOR" "*.css"
else
  echo "  Color is same as default, skipping replacement."
fi

# 6. DIRECT REPLACEMENT: Frontend Text
# Replace "Chatwoot" in compiled JS files to catch UI strings
echo "  🔤 Injecting brand name into compiled JS..."
safe_replace "public/packs" "Chatwoot" "$BRAND_NAME" "*.js"
safe_replace "public/assets" "Chatwoot" "$BRAND_NAME" "*.js"

# 7. RESTORE PERMISSIONS
# We force ownership to user ID 1001 (standard non-root) to match Dockerfile
echo "  🔒 Restoring permissions to User 1001..."
chown -R 1001:0 app/javascript/dashboard/i18n
chown -R 1001:0 app/javascript/dashboard/assets
chown -R 1001:0 public
chown -R 1001:0 app/views/mailers
chown -R 1001:0 app/views/layouts
chown -R 1001:0 tmp
chown -R 1001:0 log
[ -f package.json ] && chown 1001:0 package.json

echo "✅ Premium White-Label applied successfully!"
echo "Brand: ${BRAND_NAME}"
echo "Color: ${PRIMARY_COLOR}"
