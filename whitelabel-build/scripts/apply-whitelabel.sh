#!/bin/sh
set -e
set -x # Enable debug logging

echo "🎨 Applying PREMIUM White-Label Customizations (Direct Replacement Mode)..."
echo "Current directory: $(pwd)"

# Load brand config
BRAND_NAME="${BRAND_NAME:-Nexa Inbox}"
PRIMARY_COLOR="${PRIMARY_COLOR:-#1f93ff}"
DEFAULT_CHATWOOT_COLOR="#1f93ff"

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

# Function to copy if exists
copy_asset() {
  src=$1
  dest=$2
  if [ -f "$src" ]; then
    cp -v "$src" "$dest"
    # Also copy to public/packs if it exists (compiled assets)
    if [ -d "public/packs" ]; then
      find public/packs -name "$(basename $dest)" -exec cp -v "$src" {} +
    fi
  else
    echo "  ⚠️ Asset not found: $src"
  fi
}

copy_asset "branding/assets/logo.svg" "app/javascript/dashboard/assets/images/logo.svg"
copy_asset "branding/assets/logo-dark.svg" "app/javascript/dashboard/assets/images/logo-dark.svg"
copy_asset "branding/assets/favicon.ico" "public/favicon.ico"

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

echo "✅ Premium White-Label applied successfully!"
echo "Brand: ${BRAND_NAME}"
echo "Color: ${PRIMARY_COLOR}"
