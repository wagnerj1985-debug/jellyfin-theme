#!/usr/bin/env bash
# deploy.sh - Deploy Jellyfin Custom Theme (Aurora Noir)
# Domain: stream.free-warez.win
# Target Host: free-warez.win -> /opt/containers/jellyfin

set -euo pipefail

TARGET_HOST="free-warez.win"
TARGET_DIR="/opt/containers/jellyfin"
LOCAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Deploying Jellyfin Theme (Aurora Noir)"
echo "   Target: $TARGET_HOST:$TARGET_DIR"
echo "==============================================="

# 1. Check SSH connection
echo "📡 Checking SSH connection to $TARGET_HOST..."
if ! ssh -q -o BatchMode=yes -o ConnectTimeout=5 "$TARGET_HOST" exit; then
    echo "❌ Cannot connect to $TARGET_HOST via SSH."
    exit 1
fi

# 2. Sync web-assets
echo "🔄 Syncing theme assets to VPS..."
rsync -avz \
    "$LOCAL_DIR/web-assets/" "$TARGET_HOST:$TARGET_DIR/web-assets/"

# 3. Regenerate branding.xml & restart container
echo "🔄 Regenerating branding.xml from aurora_noir.css..."
ssh "$TARGET_HOST" "python3 - <<'PYEOF'
import xml.sax.saxutils as sx
css = open('/opt/containers/jellyfin/web-assets/aurora_noir.css').read()
out = ('<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<BrandingOptions>\n'
       '  <LoginDisclaimer>Private media cloud. Authorized access only.</LoginDisclaimer>\n'
       '  <CustomCss>%s</CustomCss>\n'
       '  <SplashscreenEnabled>false</SplashscreenEnabled>\n'
       '</BrandingOptions>\n') % sx.escape(css)
open('/opt/containers/jellyfin/library/branding.xml', 'w').write(out)
print('branding.xml updated with', len(out), 'bytes')
PYEOF
docker restart jellyfin
"

echo "✅ Jellyfin container restarted with updated theme!"
echo "✨ Deployment complete!"
