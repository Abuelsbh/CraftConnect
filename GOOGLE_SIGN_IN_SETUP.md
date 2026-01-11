# إعداد Google Sign-In

## المشكلة: ApiException: 10 (DEVELOPER_ERROR)

هذا الخطأ يحدث عادة بسبب مشاكل في إعدادات Firebase و Google Cloud Console.

## الحل خطوة بخطوة:

### 1. إضافة SHA-1 Fingerprint في Firebase Console

#### الحصول على SHA-1:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### SHA-1 الحالي للمشروع:
```
E6:62:FB:53:12:9F:19:30:3D:B9:9A:02:E9:D0:E1:A1:3D:42:1E:99
```

#### خطوات الإضافة:
1. افتح [Firebase Console](https://console.firebase.google.com/)
2. اختر مشروعك: **parking-4d91a**
3. اذهب إلى **⚙️ Project Settings**
4. في تبويب **General**، ابحث عن قسم **Your apps**
5. اختر تطبيق Android: **com.example.template_2025**
6. في قسم **SHA certificate fingerprints**، اضغط **Add fingerprint**
7. الصق SHA-1:
   ```
   E6:62:FB:53:12:9F:19:30:3D:B9:9A:02:E9:D0:E1:A1:3D:42:1E:99
   ```
8. احفظ التغييرات

### 2. تفعيل Google Sign-In في Firebase Authentication

1. في Firebase Console، اذهب إلى **Authentication**
2. اضغط على **Sign-in method**
3. ابحث عن **Google** واضغط عليه
4. فعّل **Enable**
5. أدخل **Support email** (يمكن استخدام بريدك الإلكتروني)
6. احفظ التغييرات

### 3. التحقق من Package Name

تأكد من أن package name في `android/app/build.gradle` يطابق package name في Firebase:
- Package name: `com.example.template_2025`

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

### للـ Release Build:
عند إصدار نسخة production، ستحتاج إلى:
1. إنشاء release keystore
2. الحصول على SHA-1 الخاص به:
   ```bash
   keytool -list -v -keystore /path/to/release.keystore -alias your-key-alias
   ```
3. إضافة SHA-1 الخاص بالـ release في Firebase Console أيضاً

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
- Package Name: `com.example.template_2025`
- Firebase Project Number: `321053041363`
















