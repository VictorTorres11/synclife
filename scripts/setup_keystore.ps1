# PowerShell script to generate keystore for CodeMagic

Write-Host "SyncLife - Keystore Setup for CodeMagic" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$KEYSTORE_DIR = "android\keystore"
$KEYSTORE_FILE = "$KEYSTORE_DIR\synclife-release-key.jks"
$KEY_ALIAS = "synclife-key"
$VALIDITY_DAYS = 10000

# Find keytool
$keytool = $null
$javaHome = $env:JAVA_HOME

if ($javaHome) {
    $keytool = Join-Path $javaHome "bin\keytool.exe"
    if (-not (Test-Path $keytool)) {
        $keytool = $null
    }
}

if (-not $keytool) {
    $keytool = (Get-Command keytool -ErrorAction SilentlyContinue).Source
}

if (-not $keytool) {
    Write-Host "ERROR: keytool not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Java JDK and set JAVA_HOME" -ForegroundColor Yellow
    Write-Host "Download from: https://www.oracle.com/java/technologies/downloads/" -ForegroundColor Yellow
    exit 1
}

Write-Host "Found keytool at: $keytool" -ForegroundColor Green
Write-Host ""

if (Test-Path $KEYSTORE_FILE) {
    Write-Host "Keystore already exists at: $KEYSTORE_FILE" -ForegroundColor Yellow
    Write-Host ""
    $use_existing = Read-Host "Use existing keystore? (y/n)"
    
    if ($use_existing -ne "y" -and $use_existing -ne "Y") {
        Write-Host "Aborting." -ForegroundColor Red
        exit 1
    }
    
    $KEYSTORE_PASSWORD = Read-Host "Enter keystore password" -AsSecureString
    $KEYSTORE_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($KEYSTORE_PASSWORD))
    $KEY_PASSWORD = $KEYSTORE_PASSWORD
} else {
    Write-Host "Creating new keystore..." -ForegroundColor Cyan
    Write-Host ""
    
    New-Item -ItemType Directory -Force -Path $KEYSTORE_DIR | Out-Null
    
    Write-Host "Enter keystore password (or press Enter for 'synclife123'):"
    $securePassword = Read-Host -AsSecureString
    $KEYSTORE_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
    
    if ([string]::IsNullOrWhiteSpace($KEYSTORE_PASSWORD)) {
        $KEYSTORE_PASSWORD = "synclife123"
    }
    
    Write-Host ""
    Write-Host "Enter key password (or press Enter to use same):"
    $secureKeyPassword = Read-Host -AsSecureString
    $KEY_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKeyPassword))
    
    if ([string]::IsNullOrWhiteSpace($KEY_PASSWORD)) {
        $KEY_PASSWORD = $KEYSTORE_PASSWORD
    }
    
    Write-Host ""
    Write-Host "Generating keystore..." -ForegroundColor Cyan
    
    $arguments = @(
        "-genkey", "-v",
        "-keystore", $KEYSTORE_FILE,
        "-keyalg", "RSA",
        "-keysize", "2048",
        "-validity", $VALIDITY_DAYS,
        "-alias", $KEY_ALIAS,
        "-storepass", $KEYSTORE_PASSWORD,
        "-keypass", $KEY_PASSWORD,
        "-dname", "CN=SyncLife, OU=Development, O=SyncLife, L=Sao Paulo, S=SP, C=BR"
    )
    
    & $keytool $arguments
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Keystore generated successfully!" -ForegroundColor Green
    } else {
        Write-Host "Failed to generate keystore" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Keystore Information" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan
Write-Host ""

$listArgs = @("-list", "-v", "-keystore", $KEYSTORE_FILE, "-storepass", $KEYSTORE_PASSWORD, "-alias", $KEY_ALIAS)
$keystoreInfo = & $keytool $listArgs | Select-String -Pattern "SHA1:|SHA256:"

Write-Host $keystoreInfo
Write-Host ""

Write-Host "CodeMagic Configuration" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Converting keystore to base64..." -ForegroundColor Cyan
$keystoreBytes = [System.IO.File]::ReadAllBytes((Resolve-Path $KEYSTORE_FILE))
$KEYSTORE_BASE64 = [System.Convert]::ToBase64String($keystoreBytes)

Write-Host "Keystore converted to base64" -ForegroundColor Green
Write-Host ""
Write-Host "Add these environment variables to CodeMagic:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Variable Name: KEYSTORE_BASE64" -ForegroundColor Blue
Write-Host "Value:"
Write-Host $KEYSTORE_BASE64
Write-Host ""
Write-Host "Variable Name: KEYSTORE_PASSWORD" -ForegroundColor Blue
Write-Host "Value: $KEYSTORE_PASSWORD"
Write-Host ""
Write-Host "Variable Name: KEY_ALIAS" -ForegroundColor Blue
Write-Host "Value: $KEY_ALIAS"
Write-Host ""
Write-Host "Variable Name: KEY_PASSWORD" -ForegroundColor Blue
Write-Host "Value: $KEY_PASSWORD"
Write-Host ""

Write-Host "Instructions" -ForegroundColor Cyan
Write-Host "============" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Go to CodeMagic Dashboard"
Write-Host "2. Select your app"
Write-Host "3. Go to: App settings -> Environment variables"
Write-Host "4. Add the variables shown above"
Write-Host "5. Mark all as 'Secure'"
Write-Host "6. Save and run your workflow"
Write-Host ""
Write-Host "IMPORTANT: Backup this keystore file!" -ForegroundColor Yellow
Write-Host "Location: $KEYSTORE_FILE"
Write-Host ""

$infoContent = @"
Keystore Information
====================

File: synclife-release-key.jks
Alias: $KEY_ALIAS
Validity: $VALIDITY_DAYS days
Created: $(Get-Date)

Fingerprints:
$keystoreInfo

IMPORTANT: Keep this keystore and passwords safe!
"@

$infoContent | Out-File -FilePath "android\keystore\KEYSTORE_INFO.txt" -Encoding UTF8

Write-Host "Keystore info saved to: android\keystore\KEYSTORE_INFO.txt" -ForegroundColor Green
Write-Host ""
Write-Host "Done!" -ForegroundColor Green
