#!/bin/bash

# Script to create keystore for PIX & FIX app
# Run this script from the android directory

echo "🚀 Creating keystore for PIX & FIX app..."
echo ""
echo "📝 Please enter the following information:"
echo ""

# Navigate to android directory
cd "$(dirname "$0")/android" || exit

# Create keystore
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pixfix

echo ""
echo "✅ Keystore created successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Create key.properties file in android directory"
echo "2. Add the following content (replace passwords with your actual passwords):"
echo ""
echo "storePassword=YOUR_KEYSTORE_PASSWORD"
echo "keyPassword=YOUR_KEY_PASSWORD"
echo "keyAlias=pixfix"
echo "storeFile=upload-keystore.jks"
echo ""
echo "⚠️  IMPORTANT: Keep your keystore file and passwords safe!"
echo "   You will need them to update your app on Google Play."

