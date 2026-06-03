# إعداد Google Sign-In

## التحديثات الأخيرة
- تم إضافة `serverClientId` (Web OAuth client ID) في الكود - مطلوب لـ Firebase Auth
- الـ Web client ID يُستخدم من `google-services.json` تلقائياً

## المشكلة: ApiException: 10 (DEVELOPER_ERROR)

هذا الخطأ يحدث عادة بسبب مشاكل في إعدادات Firebase و Google Cloud Console.

**⚠️ مهم جداً:** عند رفع نسخة على Google Play، يجب إضافة SHA-1 الخاص بـ **Release Keystore** وليس Debug Keystore فقط!

## الحل خطوة بخطوة:

### 1. إضافة SHA-1 Fingerprint في Firebase Console

#### SHA-1 للـ Debug Build (للتطوير):
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**SHA-1 Debug:**
```
E6:62:FB:53:12:9F:19:30:3D:B9:9A:02:E9:D0:E1:A1:3D:42:1E:99
```

#### SHA-1 للـ Release Build (للإنتاج - Google Play):
```bash
cd android
keytool -list -v -keystore app/upload-keystore.jks -alias pixfix -storepass 000111
```

**SHA-1 Release (مطلوب للنسخة على Google Play):**
```
53:F9:D5:0E:D4:F4:19:6F:53:79:84:F4:76:19:F1:7E:6A:AA:31:04
```

#### خطوات الإضافة في Firebase Console:
1. افتح [Firebase Console](https://console.firebase.google.com/)
2. اختر مشروعك: **parking-4d91a**
3. اذهب إلى **⚙️ Project Settings**
4. في تبويب **General**، ابحث عن قسم **Your apps**
5. اختر تطبيق Android: **com.pix.fix**
6. في قسم **SHA certificate fingerprints**، اضغط **Add fingerprint**
7. أضف **SHA-1 للـ Debug** (إذا لم يكن موجوداً):
   ```
   E6:62:FB:53:12:9F:19:30:3D:B9:9A:02:E9:D0:E1:A1:3D:42:1E:99
   ```
8. أضف **SHA-1 للـ Release** (مهم جداً للنسخة على Google Play):
   ```
   53:F9:D5:0E:D4:F4:19:6F:53:79:84:F4:76:19:F1:7E:6A:AA:31:04
   ```
9. احفظ التغييرات
10. **انتظر 5-10 دقائق** حتى يتم تحديث الإعدادات في Firebase

### 2. تفعيل Google Sign-In في Firebase Authentication

1. في Firebase Console، اذهب إلى **Authentication**
2. اضغط على **Sign-in method**
3. ابحث عن **Google** واضغط عليه
4. فعّل **Enable**
5. أدخل **Support email** (يمكن استخدام بريدك الإلكتروني)
6. احفظ التغييرات

### 3. التحقق من Package Name

تأكد من أن package name في `android/app/build.gradle` يطابق package name في Firebase:
- Package name: `com.pix.fix`

### 4. إعادة تحميل google-services.json (اختياري)

بعد إضافة SHA-1، قد تحتاج إلى:
1. تحميل `google-services.json` الجديد من Firebase Console
2. استبدال الملف الموجود في `android/app/google-services.json`

### 5. تنظيف وإعادة بناء المشروع

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

## ملاحظات مهمة:

### للـ Debug Build:
- استخدم SHA-1 من debug keystore (الذي حصلنا عليه أعلاه)

### للـ Release Build (Google Play):
**⚠️ هذا مطلوب للنسخة المرفوعة على Google Play!**

SHA-1 للـ Release Keystore:
```
53:F9:D5:0E:D4:F4:19:6F:53:79:84:F4:76:19:F1:7E:6A:AA:31:04
```

**يجب إضافة هذا SHA-1 في Firebase Console حتى يعمل Google Sign-In في النسخة المرفوعة على Google Play!**

## التحقق من الإعدادات:

بعد إتمام الخطوات أعلاه:
1. تأكد من أن SHA-1 مضاف في Firebase Console
2. تأكد من تفعيل Google Sign-In في Firebase Authentication
3. أعد بناء التطبيق
4. جرب تسجيل الدخول مرة أخرى

## استكشاف الأخطاء:

إذا استمرت المشكلة:
1. تحقق من أن `google-services.json` موجود في `android/app/`
2. تحقق من أن package name متطابق
3. تأكد من أن SHA-1 مضاف بشكل صحيح (بدون مسافات)
4. انتظر بضع دقائق بعد إضافة SHA-1 (قد يستغرق Firebase بعض الوقت لتحديث الإعدادات)

## معلومات إضافية:

- Project ID: `parking-4d91a`
- Package Name: `com.pix.fix`
- Firebase Project Number: `321053041363`

## 🔴 حل مشكلة Google Play:

إذا رفعت نسخة على Google Play وظهرت مشكلة Google Sign-In:

1. **تأكد من إضافة SHA-1 للـ Release في Firebase Console:**
   ```
   53:F9:D5:0E:D4:F4:19:6F:53:79:84:F4:76:19:F1:7E:6A:AA:31:04
   ```

2. **انتظر 5-10 دقائق** بعد إضافة SHA-1

3. **تحميل google-services.json الجديد:**
   - بعد إضافة SHA-1، Firebase سينشئ OAuth client جديد
   - اذهب إلى Firebase Console → Project Settings → Your apps
   - اضغط على "Download google-services.json"
   - استبدل الملف في `android/app/google-services.json`

4. **إعادة بناء التطبيق:**
   ```bash
   flutter clean
   flutter pub get
   flutter build appbundle --release
   ```

5. **رفع نسخة جديدة على Google Play** (اختياري - يمكن أن تعمل النسخة الحالية بعد تحديث Firebase)

















