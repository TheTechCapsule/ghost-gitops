#!/bin/bash
# Setup script for ArgoCD applications
# This script helps users set up their ArgoCD applications from examples

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Setting up ArgoCD applications for Ghost GitOps${NC}"
echo

# Check if we're in the right directory
if [ ! -f "argo/README.md" ]; then
    echo -e "${RED}❌ Error: Please run this script from the repository root${NC}"
    exit 1
fi

# Get repository URL from user
echo -e "${YELLOW}📝 Please provide your repository details:${NC}"
read -p "GitHub username/organization: " GITHUB_USER
read -p "Repository name: " REPO_NAME
read -p "Default branch (main/master): " DEFAULT_BRANCH

REPO_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"
DEFAULT_BRANCH=${DEFAULT_BRANCH:-main}

echo
echo -e "${YELLOW}📋 Configuration:${NC}"
echo "Repository URL: ${REPO_URL}"
echo "Default branch: ${DEFAULT_BRANCH}"
echo

read -p "Continue with this configuration? (y/N): " CONFIRM
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}❌ Setup cancelled${NC}"
    exit 0
fi

# Create apps directory if it doesn't exist
mkdir -p argo/apps

# Copy example applications
echo -e "${GREEN}📁 Copying example applications...${NC}"
cp argo/examples/*.yaml argo/apps/

# Update repository URLs in copied files
echo -e "${GREEN}🔧 Updating repository URLs...${NC}"
for file in argo/apps/*.yaml; do
    if [ -f "$file" ]; then
        # Replace the placeholder URL with the actual URL
        sed -i "s|https://github.com/YOUR-USERNAME/YOUR-REPO.git|${REPO_URL}|g" "$file"
        # Replace targetRevision if needed
        sed -i "s|targetRevision: main|targetRevision: ${DEFAULT_BRANCH}|g" "$file"
        echo "  ✅ Updated $(basename "$file")"
    fi
done

# Update kustomization.yaml
echo -e "${GREEN}📝 Updating kustomization.yaml...${NC}"
cat > argo/apps/kustomization.yaml << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ghost-dev-app.yaml
  - ghost-staging-app.yaml
  - ghost-prod-app.yaml
EOF

echo "  ✅ Updated kustomization.yaml"

# Update app-root.yaml
echo -e "${GREEN}🔧 Updating app-root.yaml...${NC}"
sed -i "s|https://github.com/YOUR-USERNAME/YOUR-REPO.git|${REPO_URL}|g" argo/app-root.yaml
sed -i "s|targetRevision: main|targetRevision: ${DEFAULT_BRANCH}|g" argo/app-root.yaml
echo "  ✅ Updated app-root.yaml"

echo
echo -e "${GREEN}✅ ArgoCD applications setup complete!${NC}"
echo
echo -e "${YELLOW}📋 Next steps:${NC}"
echo "1. Review and customize the applications in argo/apps/"
echo "2. Update application names, namespaces, and sync policies as needed"
echo "3. Apply the root application:"
echo "   kubectl apply -f argo/app-root.yaml"
echo
echo -e "${YELLOW}📚 For more information, see:${NC}"
echo "   - argo/README.md"
echo "   - docs/secrets-setup.md"
echo "   - apps/ghost/SECRETS.md"
