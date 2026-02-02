#!/bin/bash

echo "Setting up keystore for Codemagic build..."

# Create keystore directory
mkdir -p android/keystore

# Generate keystore if it doesn't exist
if [ ! -f "android/keystore/synclife-release-key.jks" ]; then
    echo "Generating new keystore..."
    keytool -genkey -v \
        -keystore android/keystore/synclife-release-key.jks \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -alias ${KEY_ALIAS:-synclife-key} \
        -storepass ${KEYSTORE_PASSWORD:-synclife123} \
        -keypass ${KEY_PASSWORD:-synclife123} \
        -dname "CN=SyncLife, OU=Development, O=SyncLife, L=City, S=State, C=BR"
    
    if [ $? -eq 0 ]; then
        echo "✅ Keystore generated successfully"
    else
        echo "❌ Failed to generate keystore"
        exit 1
    fi
else
    echo "✅ Keystore already exists"
fi

# Create key.properties
echo "Creating key.properties..."
cat > android/key.properties << EOF
storePassword=${KEYSTORE_PASSWORD:-synclife123}
keyPassword=${KEY_PASSWORD:-synclife123}
keyAlias=${KEY_ALIAS:-synclife-key}
storeFile=keystore/synclife-release-key.jks
EOF

echo "✅ key.properties created"

# Verify files exist
echo "Verifying setup..."
if [ -f "android/keystore/synclife-release-key.jks" ] && [ -f "android/key.properties" ]; then
    echo "✅ Setup complete!"
    echo "Keystore: $(ls -la android/keystore/synclife-release-key.jks)"
    echo "Properties: $(cat android/key.properties)"
else
    echo "❌ Setup failed!"
    exit 1
fi