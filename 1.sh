#!/bin/bash

# ============================================
# 1.SH - ALL IN ONE
# Clean Repo + Setup Project + Build + Upload
# ============================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ========== DETEKSI TOKEN OTOMATIS ==========
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOKEN_FILE="$SCRIPT_DIR/token.txt"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 1.SH - ALL IN ONE DEPLOY${NC}"
echo -e "${BLUE}========================================${NC}"

# Cek token di current path
echo -e "${YELLOW}🔍 Mencari token di: $TOKEN_FILE${NC}"

if [ -f "$TOKEN_FILE" ]; then
    TOKEN=$(cat "$TOKEN_FILE" 2>/dev/null | tr -d '\n\r')
    echo -e "${GREEN}✅ Token ditemukan!${NC}"
else
    echo -e "${RED}❌ token.txt tidak ditemukan di $SCRIPT_DIR${NC}"
    echo -e "${YELLOW}💡 Buat token.txt di folder ini:${NC}"
    echo -e "${YELLOW}   echo \"ghp_xxxxxxxxxxxx\" > token.txt${NC}"
    exit 1
fi

# Validasi token (minimal 10 karakter)
if [ ${#TOKEN} -lt 10 ]; then
    echo -e "${RED}❌ Token terlalu pendek! Cek isi token.txt${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Token valid! (${#TOKEN} karakter)${NC}"

# ========== SETUP GIT ==========
echo -e "${YELLOW}⚙️  Setup Git...${NC}"
git config --global user.email "smwhl@users.noreply.github.com"
git config --global user.name "smwhl"
git config --global init.defaultBranch main

# ========== CLEAN ==========
echo -e "${YELLOW}🧹 Clean repository...${NC}"
rm -rf .git

# ========== INIT GIT ==========
echo -e "${GREEN}📦 Init Git...${NC}"
git init

# ========== SET REMOTE ==========
echo -e "${GREEN}🔗 Set remote...${NC}"
git remote add origin "https://x-access-token:${TOKEN}@github.com/smwhl/smwhl.github.io.git"

# ========== BUAT .gitignore ==========
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

# ========== BUAT WORKFLOW ==========
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
    steps:
      - uses: actions/checkout@v3
      - name: Setup JDK
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'
      - name: Setup Android SDK
        uses: android-actions/setup-android@v2
      - name: Build APK
        run: |
          cd app
          gradle assembleDebug
      - name: Upload APK
        uses: actions/upload-artifact@v3
        with:
          name: app-debug
          path: app/build/outputs/apk/debug/*.apk
EOF

# ========== ADD ALL FILE ==========
echo -e "${GREEN}📤 Add semua file...${NC}"
git add .

# ========== COMMIT ==========
echo -e "${GREEN}📝 Commit...${NC}"
git commit -m "Deploy: $(date '+%Y-%m-%d %H:%M:%S')"

# ========== PUSH ==========
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

# Hapus token dari memory
unset TOKEN
