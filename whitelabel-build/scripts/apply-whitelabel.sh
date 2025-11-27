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

# 3. Replace branding assets in COMPILED location (public/packs)
echo "  🖼️  Replacing compiled logos..."

# Function to replace compiled assets (finds files by pattern and replaces them)
replace_compiled_asset() {
  asset_file=$1     # e.g. "branding/assets/logo.png"
  search_pattern=$2 # e.g. "logo*.svg" or "logo-dark*.svg"
  
  if [ ! -f "$asset_file" ]; then
    echo "  ⚠️ Asset not found: $asset_file (skipping)"
    return
  fi
  
  # Find and replace in public/packs (compiled Webpack assets)
  if [ -d "public/packs" ]; then
    found=0
    for compiled_file in public/packs/$search_pattern; do
      if [ -f "$compiled_file" ]; then
        cp -v "$asset_file" "$compiled_file"
        echo "  ✅ Replaced: $compiled_file"
        found=1
      fi
    done
    
    if [ $found -eq 0 ]; then
      echo "  ⚠️ No compiled files matching '$search_pattern' found in public/packs"
    fi
  else
    echo "  ⚠️ public/packs directory not found"
  fi
  
  # Also replace in source (for future builds)
  if [ -d "app/javascript/dashboard/assets/images" ]; then
    base_name=$(basename "$search_pattern" | sed 's/\*//g')
    cp -v "$asset_file" "app/javascript/dashboard/assets/images/$base_name" 2>/dev/null || true
  fi
}

# Find custom logo (PNG or SVG)
for ext in png svg; do
  if [ -f "branding/assets/logo.$ext" ]; then
    replace_compiled_asset "branding/assets/logo.$ext" "logo*.svg"
    replace_compiled_asset "branding/assets/logo.$ext" "logo*.png"
    break
  fi
done

# Find custom dark logo (PNG or SVG)
for ext in png svg; do
  if [ -f "branding/assets/logo-dark.$ext" ]; then
    replace_compiled_asset "branding/assets/logo-dark.$ext" "logo-dark*.svg"
    replace_compiled_asset "branding/assets/logo-dark.$ext" "logo-dark*.png"
    break
  fi
done

# Favicon
for ext in ico png; do
  if [ -f "branding/assets/favicon.$ext" ]; then
    [ -f "public/favicon.ico" ] && cp -v "branding/assets/favicon.$ext" "public/favicon.ico"
    break
  fi
done

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
