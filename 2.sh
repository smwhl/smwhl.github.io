#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOKEN_FILE="$SCRIPT_DIR/token.txt"

echo -e "${YELLOW}🔄 UPDATE WORKFLOW...${NC}"

if [ ! -f "$TOKEN_FILE" ]; then
    echo -e "${RED}❌ token.txt tidak ditemukan!${NC}"
    exit 1
fi

TOKEN=$(cat "$TOKEN_FILE" | tr -d '\n\r')

git config --global user.email "smwhl@users.noreply.github.com"
git config --global user.name "smwhl"

git remote set-url origin "https://x-access-token:${TOKEN}@github.com/smwhl/smwhl.github.io.git"

git add .
git commit -m "Fix: update artifact actions to v4"
git push origin main

echo -e "${GREEN}✅ UPDATE BERHASIL!${NC}"
echo -e "${GREEN}🌐 https://smwhl.github.io${NC}"
echo -e "${GREEN}📦 https://github.com/smwhl/smwhl.github.io/actions${NC}"

unset TOKEN
