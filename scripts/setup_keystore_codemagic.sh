#!/bin/bash

# Script to generate a keystore and prepare it for CodeMagic
# This ensures you use the same keystore consistently

set -e

echo "🔐 SyncLife - Keystore Setup for CodeMagic"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
KEYSTORE_DIR="android/keystore"
KEYSTORE_FILE="$KEYSTORE_DIR/synclife-release-key.jks"
KEY_ALIAS="synclife-key"
VALIDITY_DAYS=10000

# Check if keystore already exists
if [ -f "$KEYSTORE_FILE" ]; then
    echo -e "${YELLOW}⚠️  Keystore already exists at: $KEYSTORE_FILE${NC}"
    echo ""
    read -p "Do you want to use the existing keystore? (y/n): " use_existing
    
    if [ "$use_existing" = "y" ] || [ "$use_existing" = "Y" ]; then
        echo -e "${GREEN}✅ Using existing keystore${NC}"
        KEYSTORE_PASSWORD=""
        KEY_PASSWORD=""
    else
        echo -e "${RED}❌ Aborting. Please backup or delete the existing keystore first.${NC}"
        exit 1
    fi
else
    echo "📝 Creating new keystore..."
    echo ""
    
    # Create keystore directory
    mkdir -p "$KEYSTORE_DIR"
    
    # Prompt for passwords
    echo "Enter keystore password (or press Enter for default 'synclife123'):"
    read -s KEYSTORE_PASSWORD
    KEYSTORE_PASSWORD=${KEYSTORE_PASSWORD:-synclife123}
    
    echo ""
    echo "Enter key password (or press Enter to use same as keystore):"
    read -s KEY_PASSWORD
    KEY_PASSWORD=${KEY_PASSWORD:-$KEYSTORE_PASSWORD}
    
    echo ""
    echo "🔑 Generating keystore..."
    
    # Generate keystore
    keytool -genkey -v \
        -keystore "$KEYSTORE_FILE" \
        -keyalg RSA \
        -keysize 2048 \
        -validity $VALIDITY_DAYS \
        -alias "$KEY_ALIAS" \
        -storepass "$KEYSTORE_PASSWORD" \
        -keypass "$KEY_PASSWORD" \
        -dname "CN=SyncLife, OU=Development, O=SyncLife, L=Sao Paulo, S=SP, C=BR"
    
    echo -e "${GREEN}✅ Keystore generated successfully!${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Keystore Information"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get keystore password if not set
if [ -z "$KEYSTORE_PASSWORD" ]; then
    echo "Enter keystore password to view details:"
    read -s KEYSTORE_PASSWORD
    echo ""
fi

# Show keystore details
keytool -list -v -keystore "$KEYSTORE_FILE" -storepass "$KEYSTORE_PASSWORD" -alias "$KEY_ALIAS" | grep -A 5 "Certificate fingerprints"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 CodeMagic Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Convert keystore to base64
echo "Converting keystore to base64..."
KEYSTORE_BASE64=$(base64 -i "$KEYSTORE_FILE")

echo -e "${GREEN}✅ Keystore converted to base64${NC}"
echo ""
echo "📝 Add these environment variables to CodeMagic:"
echo ""
echo -e "${BLUE}Variable Name: KEYSTORE_BASE64${NC}"
echo "Value (copy this entire line):"
echo "$KEYSTORE_BASE64"
echo ""
echo -e "${BLUE}Variable Name: KEYSTORE_PASSWORD${NC}"
echo "Value: $KEYSTORE_PASSWORD"
echo ""
echo -e "${BLUE}Variable Name: KEY_ALIAS${NC}"
echo "Value: $KEY_ALIAS"
echo ""
echo -e "${BLUE}Variable Name: KEY_PASSWORD${NC}"
echo "Value: ${KEY_PASSWORD:-$KEYSTORE_PASSWORD}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📖 Instructions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Go to CodeMagic Dashboard"
echo "2. Select your app"
echo "3. Go to: App settings → Environment variables"
echo "4. Add the variables shown above"
echo "5. Mark all variables as 'Secure' (lock icon)"
echo "6. Save and run your workflow"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Backup this keystore file!${NC}"
echo "   Location: $KEYSTORE_FILE"
echo "   Without it, you cannot update your app on Play Store!"
echo ""
echo "Backup locations:"
echo "  - Password manager (1Password, LastPass, etc.)"
echo "  - Encrypted cloud storage (Google Drive, Dropbox)"
echo "  - External encrypted USB drive"
echo ""

# Save configuration to a file (without passwords)
cat > android/keystore/KEYSTORE_INFO.txt << EOF
Keystore Information
====================

File: synclife-release-key.jks
Alias: $KEY_ALIAS
Validity: $VALIDITY_DAYS days
Created: $(date)

SHA1 Fingerprint:
$(keytool -list -v -keystore "$KEYSTORE_FILE" -storepass "$KEYSTORE_PASSWORD" -alias "$KEY_ALIAS" | grep SHA1 | head -1)

SHA256 Fingerprint:
$(keytool -list -v -keystore "$KEYSTORE_FILE" -storepass "$KEYSTORE_PASSWORD" -alias "$KEY_ALIAS" | grep SHA256 | head -1)

IMPORTANT: Keep this keystore and passwords safe!
Passwords are stored in CodeMagic environment variables.
EOF

echo -e "${GREEN}✅ Keystore info saved to: android/keystore/KEYSTORE_INFO.txt${NC}"
echo ""
echo "Done! 🎉"
