# دليل إعداد Firebase - Firebase Setup Guide

## نظرة عامة

هذا الدليل يوضح كيفية إعداد Firebase للتطبيق بشكل كامل، بما في ذلك Authentication و Realtime Database و Storage.

## الخطوة 1: إنشاء مشروع Firebase

### 1.1 إنشاء المشروع
1. اذهب إلى [Firebase Console](https://console.firebase.google.com/)
2. انقر على "إنشاء مشروع" (Create Project)
3. أدخل اسم المشروع: `artisans-app` (أو أي اسم تفضله)
4. اختر "تمكين Google Analytics" (اختياري)
5. انقر على "إنشاء المشروع"

### 1.2 إضافة التطبيق
1. في لوحة التحكم، انقر على أيقونة Android/iOS
2. أدخل معرف الحزمة: `com.example.template_2025`
3. أدخل اسم التطبيق: `Artisans App`
4. انقر على "تسجيل التطبيق"

## الخطوة 2: إعداد Authentication

### 2.1 تفعيل طرق المصادقة
1. في لوحة التحكم، اذهب إلى "Authentication"
2. انقر على "Get started"
3. في تبويب "Sign-in method"، فعّل:
   - **Email/Password**: الطريقة الأساسية
   - **Google**: (اختياري) للمصادقة عبر Google

### 2.2 إعداد Email/Password
1. انقر على "Email/Password"
2. فعّل "Enable"
3. فعّل "Email link (passwordless sign-in)" (اختياري)
4. انقر على "Save"

### 2.3 إعداد Google Sign-In (اختياري)
1. انقر على "Google"
2. فعّل "Enable"
3. أدخل "Project support email"
4. انقر على "Save"

## الخطوة 3: إعداد Realtime Database

### 3.1 إنشاء قاعدة البيانات
1. في لوحة التحكم، اذهب إلى "Realtime Database"
2. انقر على "Create Database"
3. اختر "Start in test mode" (للاختبار)
4. اختر موقع قاعدة البيانات (الأقرب لمنطقتك)

### 3.2 إعداد قواعد الأمان
1. في تبويب "Rules"، استبدل القواعد الحالية بما يلي:

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    },
    "chats": {
      "$chatId": {
        ".read": "data.child('participant1Id').val() === auth.uid || data.child('participant2Id').val() === auth.uid",
        ".write": "data.child('participant1Id').val() === auth.uid || data.child('participant2Id').val() === auth.uid"
      }
    },
    "messages": {
      "$chatId": {
        "$messageId": {
          ".read": "root.child('chats').child($chatId).child('participant1Id').val() === auth.uid || root.child('chats').child($chatId).child('participant2Id').val() === auth.uid",
          ".write": "root.child('chats').child($chatId).child('participant1Id').val() === auth.uid || root.child('chats').child($chatId).child('participant2Id').val() === auth.uid"
        }
      }
    },
    "artisans": {
      ".read": true,
      ".write": "auth != null"
    },
    "crafts": {
      ".read": true,
      ".write": "auth != null"
    }
  }
}
```

### 3.3 شرح قواعد الأمان

#### المستخدمين (users)
- **القراءة**: المستخدم يمكنه قراءة بياناته فقط
- **الكتابة**: المستخدم يمكنه تحديث بياناته فقط

#### المحادثات (chats)
- **القراءة**: المشاركين في المحادثة فقط
- **الكتابة**: المشاركين في المحادثة فقط

#### الرسائل (messages)
- **القراءة**: المشاركين في المحادثة فقط
- **الكتابة**: المشاركين في المحادثة فقط

#### الحرفيين (artisans)
- **القراءة**: متاح للجميع
- **الكتابة**: المستخدمين المسجلين فقط

#### الحرف (crafts)
- **القراءة**: متاح للجميع
- **الكتابة**: المستخدمين المسجلين فقط

## الخطوة 4: إعداد Storage (اختياري)

### 4.1 إنشاء Storage
1. في لوحة التحكم، اذهب إلى "Storage"
2. انقر على "Get started"
3. اختر "Start in test mode"
4. اختر موقع Storage

### 4.2 قواعد Storage
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## الخطوة 5: تحميل ملفات التكوين

### 5.1 Android (google-services.json)
1. في لوحة التحكم، اذهب إلى "Project settings"
2. في تبويب "General"، ابحث عن "Your apps"
3. انقر على "Download google-services.json"
4. ضع الملف في `android/app/`

### 5.2 iOS (GoogleService-Info.plist)
1. في لوحة التحكم، اذهب إلى "Project settings"
2. في تبويب "General"، ابحث عن "Your apps"
3. انقر على "Download GoogleService-Info.plist"
4. ضع الملف في `ios/Runner/`

## الخطوة 6: تحديث firebase_options.dart

### 6.1 إنشاء firebase_options.dart
```bash
flutterfire configure
```

### 6.2 أو إنشاء الملف يدوياً
```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'your-api-key',
    appId: 'your-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'your-project-id',
    authDomain: 'your-project-id.firebaseapp.com',
    storageBucket: 'your-project-id.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'your-api-key',
    appId: 'your-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'your-project-id',
    storageBucket: 'your-project-id.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'your-api-key',
    appId: 'your-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'your-project-id',
    storageBucket: 'your-project-id.appspot.com',
    iosClientId: 'your-ios-client-id',
    iosBundleId: 'com.example.template_2025',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'your-api-key',
    appId: 'your-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'your-project-id',
    storageBucket: 'your-project-id.appspot.com',
    iosClientId: 'your-ios-client-id',
    iosBundleId: 'com.example.template_2025',
  );
}
```

## الخطوة 7: اختبار الإعداد

### 7.1 اختبار Authentication
```dart
// في main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```

### 7.2 اختبار Realtime Database
```dart
// اختبار الكتابة
await FirebaseDatabase.instance
    .ref()
    .child('test')
    .set({'message': 'Hello Firebase!'});

// اختبار القراءة
final snapshot = await FirebaseDatabase.instance
    .ref()
    .child('test')
    .get();
print(snapshot.value);
```

## الخطوة 8: إعدادات إضافية

### 8.1 إعداد Google Maps (إذا كنت تستخدم الخرائط)
1. اذهب إلى [Google Cloud Console](https://console.cloud.google.com/)
2. اختر مشروع Firebase الخاص بك
3. فعّل Maps SDK for Android/iOS
4. أنشئ API Key
5. أضف API Key في `android/app/src/main/AndroidManifest.xml`

### 8.2 إعداد Push Notifications (اختياري)
1. في Firebase Console، اذهب إلى "Cloud Messaging"
2. اتبع الخطوات لإعداد Push Notifications

## استكشاف الأخطاء

### مشاكل شائعة

#### 1. خطأ "No Firebase App '[DEFAULT]' has been created"
```dart
// تأكد من استدعاء Firebase.initializeApp() في main()
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

#### 2. خطأ "Permission denied"
- تحقق من قواعد الأمان في Realtime Database
- تأكد من أن المستخدم مسجل دخول
- تحقق من أن المستخدم لديه الصلاحيات المطلوبة

#### 3. خطأ "Network error"
- تحقق من اتصال الإنترنت
- تحقق من إعدادات Firewall
- تأكد من أن Firebase متاح في منطقتك

### نصائح للأمان

1. **لا تشارك API Keys**: لا تضع API Keys في الكود العام
2. **استخدم قواعد الأمان**: دائماً استخدم قواعد أمان مناسبة
3. **راقب الاستخدام**: راقب استخدام Firebase في Console
4. **حديث المكتبات**: حافظ على تحديث مكتبات Firebase

## المراجع

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)

---

**ملاحظة**: تأكد من اختبار جميع المميزات قبل النشر للإنتاج. 