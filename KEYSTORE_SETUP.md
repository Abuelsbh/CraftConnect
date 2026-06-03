# إعداد Keystore لرفع التطبيق على Google Play

## خطوات إنشاء Keystore

### 1. افتح Terminal وانتقل إلى مجلد android

```bash
cd android
```

### 2. قم بإنشاء Keystore باستخدام الأمر التالي:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pixfix
```

### 3. ستظهر لك أسئلة، أجب عليها:

- **Enter keystore password**: أدخل كلمة مرور قوية واحتفظ بها (مثال: `YourSecurePassword123!`)
- **Re-enter new password**: أعد إدخال نفس كلمة المرور
- **What is your first and last name?**: اسمك أو اسم الشركة (مثال: `PIX & FIX`)
- **What is the name of your organizational unit?**: قسمك (مثال: `Development`)
- **What is the name of your organization?**: اسم الشركة (مثال: `PIX & FIX Company`)
- **What is the name of your City or Locality?**: المدينة (مثال: `Cairo`)
- **What is the name of your State or Province?**: المحافظة (مثال: `Cairo`)
- **What is the two-letter country code for this unit?**: رمز البلد (مثال: `EG` لمصر أو `US` لأمريكا)
- **Is CN=... correct?**: اكتب `yes`

### 4. أدخل كلمة مرور للمفتاح:

- **Enter key password for <pixfix>**: 
  - اضغط Enter لاستخدام نفس كلمة مرور keystore
  - أو أدخل كلمة مرور مختلفة واحتفظ بها

### 5. إنشاء ملف key.properties

بعد إنشاء الملف `upload-keystore.jks`، قم بإنشاء ملف `key.properties` في مجلد `android`:

```bash
cd android
nano key.properties
```

أو افتحه بأي محرر نصوص وأضف المحتوى التالي (استبدل كلمات المرور بما أدخلته):

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=pixfix
storeFile=upload-keystore.jks
```

**مهم جداً:**
- احفظ هذا الملف في مكان آمن
- لا ترفع `key.properties` أو `upload-keystore.jks` إلى Git
- احتفظ بنسخة احتياطية من `upload-keystore.jks` في مكان آمن

### 6. التحقق من الملفات

تأكد من وجود:
- ✅ `android/upload-keystore.jks`
- ✅ `android/key.properties`

## بناء التطبيق للتوزيع

بعد إعداد الملفات، يمكنك بناء APK أو App Bundle:

### بناء App Bundle (موصى به لـ Google Play):

```bash
flutter build appbundle --release
```

الملف الناتج: `build/app/outputs/bundle/release/app-release.aab`

### بناء APK:

```bash
flutter build apk --release
```

الملف الناتج: `build/app/outputs/flutter-apk/app-release.apk`

## ملاحظات أمنية مهمة

⚠️ **تحذيرات مهمة:**

1. **لا تفقد ملف keystore أبداً!** إذا فقدته، لن تتمكن من تحديث التطبيق على Google Play
2. احتفظ بنسخة احتياطية من `upload-keystore.jks` في مكان آمن (مثل Google Drive أو USB)
3. لا تشارك ملف keystore مع أي شخص
4. احتفظ بكلمات المرور في مكان آمن
5. تأكد من أن `key.properties` موجود في `.gitignore`

## استكشاف الأخطاء

### الخطأ: "keystore file does not exist"

- تأكد من أن ملف `upload-keystore.jks` موجود في مجلد `android`
- تحقق من المسار في `key.properties`

### الخطأ: "keystore was tampered with, or password was incorrect"

- تحقق من كلمات المرور في `key.properties`
- تأكد من استخدام الكلمات الصحيحة

### الخطأ: "keytool command not found"

- تأكد من تثبيت Java JDK
- على macOS: `brew install openjdk`
- أضف Java إلى PATH

---

**بعد إتمام هذه الخطوات، سيكون التطبيق جاهزاً للرفع على Google Play!** 🚀

