#!/bin/bash

# Migration script runner for Linux/Mac
# This script helps run the UserLimitations migration

echo "========================================"
echo "UserLimitations Migration Script"
echo "========================================"
echo ""

# Check if GOOGLE_APPLICATION_CREDENTIALS is set
if [ -z "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    if [ -z "$1" ]; then
        echo "ERROR: GOOGLE_APPLICATION_CREDENTIALS environment variable is not set"
        echo ""
        echo "Please set it to the path of your Firebase service account key:"
        echo "  export GOOGLE_APPLICATION_CREDENTIALS=\"/path/to/service-account-key.json\""
        echo ""
        echo "Or run this script with the path as an argument:"
        echo "  ./run_migration.sh /path/to/service-account-key.json"
        echo ""
        exit 1
    else
        echo "Using credentials from: $1"
        export GOOGLE_APPLICATION_CREDENTIALS="$1"
    fi
else
    echo "Using credentials from: $GOOGLE_APPLICATION_CREDENTIALS"
fi

echo ""
echo "Running migration script..."
echo ""

# Run the migration script
dart run scripts/migrate_user_limitations.dart

echo ""
echo "========================================"
echo "Migration script completed"
echo "========================================"
echo ""
