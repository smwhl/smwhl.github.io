#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOKEN_FILE="$SCRIPT_DIR/token.txt"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 1.SH - ALL IN ONE DEPLOY${NC}"
echo -e "${BLUE}========================================${NC}"

if [ -f "$TOKEN_FILE" ]; then
    TOKEN=$(cat "$TOKEN_FILE" 2>/dev/null | tr -d '\n\r')
    echo -e "${GREEN}✅ Token ditemukan! (${#TOKEN} karakter)${NC}"
else
    echo -e "${RED}❌ token.txt tidak ditemukan!${NC}"
    echo -e "${YELLOW}💡 Buat token: echo \"ghp_xxxxxxxxxxxx\" > token.txt${NC}"
    exit 1
fi

if [ ${#TOKEN} -lt 10 ]; then
    echo -e "${RED}❌ Token tidak valid!${NC}"
    exit 1
fi

echo -e "${YELLOW}⚙️  Setup Git...${NC}"
git config --global user.email "smwhl@users.noreply.github.com"
git config --global user.name "smwhl"
git config --global init.defaultBranch main

echo -e "${YELLOW}🧹 Clean repository...${NC}"
rm -rf .git

echo -e "${GREEN}📦 Init Git...${NC}"
git init

echo -e "${GREEN}🔗 Set remote...${NC}"
git remote add origin "https://x-access-token:${TOKEN}@github.com/smwhl/smwhl.github.io.git"

echo -e "${YELLOW}📝 Buat .gitignore...${NC}"
cat > .gitignore << 'EOF'
# Security
token.txt
*.txt
*.log
*.tmp

# Android
*.apk
*.aab
.gradle/
build/
app/build/
local.properties
*.iml
.idea/
.DS_Store
EOF

echo -e "${YELLOW}📝 Buat GitHub Actions workflow...${NC}"
mkdir -p .github/workflows
cat > .github/workflows/build.yml << 'EOF'
name: Android Build APK

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    env:
      FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup JDK
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
          
      - name: Setup Android SDK
        uses: android-actions/setup-android@v3
        
      - name: Build APK
        run: |
          cd app
          gradle assembleDebug
          
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: app-debug
          path: app/build/outputs/apk/debug/*.apk
          overwrite: true
EOF

echo -e "${GREEN}📤 Add semua file...${NC}"
git add .

echo -e "${GREEN}📝 Commit...${NC}"
git commit -m "Deploy: $(date '+%Y-%m-%d %H:%M:%S')"

echo -e "${GREEN}🚀 Push ke GitHub...${NC}"
git push -u origin main --force 2>&1 | grep -v "token"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✅ DEPLOY BERHASIL!${NC}"
    echo -e "${GREEN}🌐 https://smwhl.github.io${NC}"
    echo -e "${GREEN}📦 https://github.com/smwhl/smwhl.github.io/actions${NC}"
    echo -e "${GREEN}========================================${NC}"
else
    echo -e "${RED}❌ DEPLOY GAGAL!${NC}"
    exit 1
fi

unset TOKEN
