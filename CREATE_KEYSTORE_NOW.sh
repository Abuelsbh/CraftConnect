#!/bin/bash

# Script to create keystore for PIX & FIX app
# This will create the keystore with the correct alias

echo "🚀 Creating keystore for PIX & FIX app..."
echo ""
echo "📝 You will be asked to enter some information:"
echo ""
echo "⚠️  IMPORTANT: Use '000111' as the password when prompted"
echo "   (or use your own secure password and update key.properties)"
echo ""

# Navigate to android directory
cd "$(dirname "$0")/android" || exit

# Create keystore with alias pixfix (no spaces or special characters)
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pixfix

echo ""
if [ -f "upload-keystore.jks" ]; then
    echo "✅ Keystore created successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Verify that key.properties file exists with correct passwords"
    echo "2. Build the app: flutter build appbundle --release"
    echo ""
    echo "⚠️  IMPORTANT: Keep your keystore file safe!"
else
    echo "❌ Failed to create keystore"
fi

