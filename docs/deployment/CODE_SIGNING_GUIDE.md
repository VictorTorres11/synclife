# SyncLife - Code Signing Guide

## Android Code Signing

### 1. Generate Release Keystore

```bash
# Navigate to android/app directory
cd android/app

# Generate keystore (do this once)
keytool -genkey -v -keystore synclife-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias synclife-key

# You'll be prompted for:
# - Keystore password (save this securely!)
# - Key password (save this securely!)
# - Your name, organization, city, state, country
```

**IMPORTANT**: 
- Store the keystore file securely (NOT in git)
- Save passwords in a secure password manager
- Backup the keystore file - if lost, you cannot update your app!

### 2. Create key.properties File

Create `android/key.properties` (this file is gitignored):

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=synclife-key
storeFile=synclife-release-key.jks
```

### 3. Verify build.gradle Configuration

The `android/app/build.gradle` is already configured to use the keystore:

```gradle
signingConfigs {
    release {
        if (keystorePropertiesFile.exists()) {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
}

buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
    }
}
```

### 4. Google Play App Signing (Recommended)

Google Play offers app signing service:

1. **Initial Setup**:
   - Upload your first release signed with your upload key
   - Google Play will generate and manage the app signing key
   - You keep the upload key for future updates

2. **Benefits**:
   - Google manages the signing key securely
   - You can reset your upload key if compromised
   - Automatic optimization for different devices

3. **Enable in Play Console**:
   - Go to Release > Setup > App integrity
   - Follow the app signing setup wizard

### 5. Build Signed Release

```bash
# Build App Bundle (recommended)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab

# Build APK (alternative)
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### 6. Verify Signature

```bash
# Verify AAB signature
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab

# Verify APK signature
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk

# Check certificate details
keytool -list -v -keystore android/app/synclife-release-key.jks -alias synclife-key
```

## iOS Code Signing

### 1. Apple Developer Account Setup

1. **Enroll in Apple Developer Program**:
   - Visit https://developer.apple.com
   - Enroll as an individual or organization ($99/year)
   - Complete verification process

2. **Create App ID**:
   - Go to Certificates, Identifiers & Profiles
   - Create new App ID: `com.synclife.synclifeApp`
   - Enable capabilities:
     - Push Notifications
     - Sign in with Apple
     - In-App Purchase
     - Associated Domains (for deep linking)

### 2. Create Certificates

#### Development Certificate
```bash
# Generate Certificate Signing Request (CSR)
# Keychain Access > Certificate Assistant > Request a Certificate from a Certificate Authority
# Save to disk

# Upload CSR to Apple Developer Portal
# Download and install the certificate
```

#### Distribution Certificate
```bash
# Same process as development
# Select "App Store and Ad Hoc" distribution type
# Download and install the certificate
```

### 3. Create Provisioning Profiles

#### Development Provisioning Profile
1. Go to Profiles in Apple Developer Portal
2. Create new Development profile
3. Select App ID: `com.synclife.synclifeApp`
4. Select development certificate
5. Select test devices
6. Download and install

#### Distribution Provisioning Profile
1. Create new App Store distribution profile
2. Select App ID: `com.synclife.synclifeApp`
3. Select distribution certificate
4. Download and install

### 4. Configure Xcode

1. **Open Xcode**:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Select Runner target**:
   - General tab
   - Bundle Identifier: `com.synclife.synclifeApp`
   - Version: `1.0.0`
   - Build: `1`

3. **Signing & Capabilities**:
   - Team: Select your Apple Developer team
   - Automatically manage signing: ✓ (recommended)
   - Or manually select provisioning profiles

4. **Add Capabilities**:
   - Push Notifications
   - Sign in with Apple
   - In-App Purchase
   - Associated Domains

### 5. Build and Archive

#### Using Flutter Command
```bash
# Build IPA
flutter build ipa --release

# Output: build/ios/ipa/synclife_app.ipa
```

#### Using Xcode
```bash
# Open workspace
open ios/Runner.xcworkspace

# In Xcode:
# 1. Select "Any iOS Device (arm64)" as destination
# 2. Product > Archive
# 3. Wait for archive to complete
# 4. Organizer window opens automatically
# 5. Select archive > Distribute App
# 6. Choose distribution method (App Store Connect)
# 7. Follow wizard to upload
```

### 6. Verify Build

```bash
# Check IPA contents
unzip -l build/ios/ipa/synclife_app.ipa

# Verify code signature
codesign -dvv build/ios/ipa/Payload/Runner.app

# Check entitlements
codesign -d --entitlements - build/ios/ipa/Payload/Runner.app
```

## Security Best Practices

### Keystore/Certificate Storage

1. **Never commit to git**:
   - Add to `.gitignore`:
     ```
     android/key.properties
     android/app/*.jks
     android/app/*.keystore
     ios/*.p12
     ios/*.mobileprovision
     ```

2. **Secure Backup**:
   - Store in encrypted cloud storage
   - Keep offline backup on encrypted USB drive
   - Document recovery procedures

3. **Access Control**:
   - Limit access to signing keys
   - Use CI/CD secrets management
   - Rotate keys periodically (if possible)

### CI/CD Integration

#### GitHub Actions Example
```yaml
# .github/workflows/release.yml
name: Release Build

on:
  push:
    tags:
      - 'v*'

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          java-version: '17'
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      
      - name: Decode keystore
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/synclife-release-key.jks
      
      - name: Create key.properties
        run: |
          echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" > android/key.properties
          echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties
          echo "keyAlias=synclife-key" >> android/key.properties
          echo "storeFile=synclife-release-key.jks" >> android/key.properties
      
      - name: Build AAB
        run: flutter build appbundle --release
      
      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_JSON }}
          packageName: com.synclife.synclife_app
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: production
```

## Troubleshooting

### Android Issues

**Problem**: "Keystore file not found"
```bash
# Solution: Verify path in key.properties
# Path should be relative to android/app/
storeFile=synclife-release-key.jks  # Correct
storeFile=../synclife-release-key.jks  # If in android/ directory
```

**Problem**: "Wrong password"
```bash
# Solution: Verify password in key.properties
# Test keystore access:
keytool -list -v -keystore android/app/synclife-release-key.jks
```

**Problem**: "R8 optimization errors"
```bash
# Solution: Check proguard-rules.pro
# Add keep rules for problematic classes
-keep class com.problematic.class.** { *; }
```

### iOS Issues

**Problem**: "Code signing failed"
```bash
# Solution: Clean and rebuild
flutter clean
rm -rf ios/Pods ios/Podfile.lock
cd ios && pod install && cd ..
flutter build ios --release
```

**Problem**: "Provisioning profile doesn't match"
```bash
# Solution: Refresh profiles in Xcode
# Xcode > Preferences > Accounts > Download Manual Profiles
# Or enable "Automatically manage signing"
```

**Problem**: "Missing entitlements"
```bash
# Solution: Add to Runner.entitlements
# Xcode > Runner > Signing & Capabilities > + Capability
```

## Checklist

### Android Release Checklist
- [ ] Keystore generated and backed up
- [ ] key.properties created (not in git)
- [ ] ProGuard rules tested
- [ ] Release build successful
- [ ] Signature verified
- [ ] App bundle uploaded to Play Console

### iOS Release Checklist
- [ ] Apple Developer account active
- [ ] App ID created with capabilities
- [ ] Distribution certificate installed
- [ ] Provisioning profile configured
- [ ] Archive build successful
- [ ] IPA uploaded to App Store Connect

## References

- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [iOS Code Signing](https://developer.apple.com/support/code-signing/)
- [Flutter Deployment Guide](https://docs.flutter.dev/deployment)
