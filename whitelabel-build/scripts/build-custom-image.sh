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
