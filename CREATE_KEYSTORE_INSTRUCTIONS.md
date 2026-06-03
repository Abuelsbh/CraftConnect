# ⚠️ IMPORTANT: Create Keystore Now

## The Problem
You uploaded an APK/App Bundle signed in **debug mode**. Google Play requires **release mode** signing.

## Solution - Create Keystore (Required)

### Option 1: Using the Script (Recommended)

Run this command from the project root:

```bash
cd android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pixfix -storepass 000111 -keypass 000111 -dname "CN=PIX & FIX, OU=Development, O=PIX & FIX Company, L=Cairo, ST=Cairo, C=EG"
```

**This will create the keystore file automatically with the passwords you specified.**

### Option 2: Interactive Mode

Run this command and answer the questions:

```bash
cd android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pixfix
```

When prompted:
- **Enter keystore password**: `000111` (or your password)
- **Re-enter new password**: `000111` (same)
- **What is your first and last name?**: `PIX & FIX`
- **What is the name of your organizational unit?**: `Development`
- **What is the name of your organization?**: `PIX & FIX Company`
- **What is the name of your City or Locality?**: `Cairo` (or your city)
- **What is the name of your State or Province?**: `Cairo` (or your state)
- **What is the two-letter country code?**: `EG` (or your country code)
- **Is CN=... correct?**: `yes`
- **Enter key password for <pixfix>**: Press Enter (to use same password)

## After Creating Keystore

1. **Verify files exist:**
   ```bash
   cd android
   ls -la upload-keystore.jks key.properties
   ```

2. **Build the app bundle:**
   ```bash
   flutter build appbundle --release
   ```

3. **Upload the new file:**
   - Location: `build/app/outputs/bundle/release/app-release.aab`
   - This file will be signed in **release mode** ✅

## Important Notes

- ✅ The `key.properties` file is already created with your passwords
- ✅ The keyAlias is set to `pixfix` (correct, no spaces)
- ⚠️ Make sure `upload-keystore.jks` is created in the `android` folder
- ⚠️ Keep the keystore file safe - you'll need it for all future updates!

