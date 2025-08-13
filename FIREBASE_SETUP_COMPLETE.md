# دليل إعداد Firebase الكامل - تطبيق الحرفيين

## نظرة عامة

تم إكمال ربط المشروع بالكامل مع Firebase بنجاح. هذا الدليل يوضح كيفية إعداد Firebase وتشغيل التطبيق.

## المميزات المكتملة

### ✅ نظام المصادقة الكامل
- **تسجيل حساب جديد**: إنشاء حساب مع Firebase Authentication
- **تسجيل الدخول**: تسجيل الدخول بالبريد الإلكتروني وكلمة المرور
- **إعادة تعيين كلمة المرور**: إرسال رابط إعادة التعيين
- **حفظ حالة تسجيل الدخول**: حفظ البيانات محلياً
- **تكامل Firestore**: حفظ بيانات المستخدم في Firestore

### ✅ إدارة البيانات
- **Firebase Authentication**: مصادقة آمنة
- **Cloud Firestore**: قاعدة بيانات وثائقية
- **SharedPreferences**: تخزين محلي للبيانات
- **Provider Pattern**: إدارة الحالة

## خطوات إعداد Firebase

### 1. إنشاء مشروع Firebase

1. اذهب إلى [Firebase Console](https://console.firebase.google.com/)
2. انقر على "إنشاء مشروع"
3. أدخل اسم المشروع: `artisans-app-2025`
4. اختر "تمكين Google Analytics" (اختياري)
5. انقر على "إنشاء مشروع"

### 2. إعداد Authentication

1. في لوحة التحكم، اذهب إلى "Authentication"
2. انقر على "Get started"
3. في تبويب "Sign-in method"، فعّل:
   - **Email/Password**: ✅ مفعل
   - **Google Sign-In**: (اختياري للمرحلة القادمة)

### 3. إعداد Firestore Database

1. اذهب إلى "Firestore Database"
2. انقر على "Create database"
3. اختر "Start in test mode" (للاختبار)
4. اختر موقع قاعدة البيانات (الأقرب لمنطقتك)

### 4. قواعد الأمان لـ Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // قواعد المستخدمين
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // قواعد الحرفيين
    match /artisans/{artisanId} {
      allow read: if true; // يمكن للجميع القراءة
      allow write: if request.auth != null && request.auth.uid == artisanId;
    }
    
    // قواعد الحرف
    match /crafts/{craftId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### 5. تحميل ملفات التكوين

#### للـ Android:
1. في Firebase Console، اذهب إلى "Project settings"
2. في تبويب "General"، انزل إلى "Your apps"
3. انقر على أيقونة Android
4. أدخل package name: `com.example.template_2025`
5. انقر "Register app"
6. حمل ملف `google-services.json`
7. ضعه في `android/app/`

#### للـ iOS:
1. في نفس الصفحة، انقر على أيقونة iOS
2. أدخل Bundle ID: `com.example.template2025`
3. انقر "Register app"
4. حمل ملف `GoogleService-Info.plist`
5. ضعه في `ios/Runner/`

### 6. إعداد Firebase Options

ملف `lib/firebase_options.dart` موجود بالفعل ومُعد للعمل مع المشروع.

## تشغيل التطبيق

### 1. تثبيت التبعيات
```bash
flutter pub get
```

### 2. تشغيل التطبيق
```bash
flutter run
```

## هيكل البيانات في Firestore

### مجموعة المستخدمين (users)
```json
{
  "id": "user_uid",
  "name": "اسم المستخدم",
  "email": "user@example.com",
  "phone": "+966501234567",
  "profileImageUrl": "https://...",
  "latitude": 24.7136,
  "longitude": 46.6753,
  "address": "الرياض، السعودية",
  "token": "",
  "createdAt": "2025-01-01T00:00:00.000Z",
  "updatedAt": "2025-01-01T00:00:00.000Z"
}
```

### مجموعة الحرفيين (artisans)
```json
{
  "id": "artisan_uid",
  "name": "اسم الحرفي",
  "email": "artisan@example.com",
  "phone": "+966501234567",
  "profileImageUrl": "https://...",
  "craftType": "نجار",
  "yearsOfExperience": 5,
  "description": "وصف الحرفي",
  "latitude": 24.7136,
  "longitude": 46.6753,
  "address": "الرياض، السعودية",
  "rating": 4.5,
  "reviewCount": 10,
  "galleryImages": ["url1", "url2"],
  "isAvailable": true,
  "createdAt": "2025-01-01T00:00:00.000Z",
  "updatedAt": "2025-01-01T00:00:00.000Z"
}
```

## الملفات المحدثة

### 1. `lib/providers/simple_auth_provider.dart`
- ✅ تكامل Firebase Authentication
- ✅ تكامل Cloud Firestore
- ✅ إدارة حالة تسجيل الدخول
- ✅ حفظ البيانات محلياً

### 2. `lib/models/user_model.dart`
- ✅ نموذج بيانات المستخدم
- ✅ تحويل JSON
- ✅ حقول متوافقة مع Firebase

### 3. `lib/models/artisan_model.dart`
- ✅ نموذج بيانات الحرفي
- ✅ تحويل JSON
- ✅ حقول متوافقة مع Firebase

### 4. `lib/models/craft_model.dart`
- ✅ نموذج بيانات الحرف
- ✅ تحويل JSON

### 5. `lib/Utilities/shared_preferences.dart`
- ✅ إدارة التخزين المحلي
- ✅ حفظ واسترجاع بيانات المستخدم

### 6. `lib/main.dart`
- ✅ تهيئة Firebase
- ✅ تهيئة SharedPreferences
- ✅ تسجيل مزودي الحالة

## اختبار الوظائف

### 1. تسجيل حساب جديد
1. افتح التطبيق
2. اذهب إلى صفحة التسجيل
3. أدخل البيانات المطلوبة
4. انقر "تسجيل"
5. تحقق من إنشاء الحساب في Firebase Console

### 2. تسجيل الدخول
1. اذهب إلى صفحة تسجيل الدخول
2. أدخل البريد وكلمة المرور
3. انقر "تسجيل الدخول"
4. تحقق من تحديث البيانات في Firestore

### 3. إعادة تعيين كلمة المرور
1. اذهب إلى صفحة نسيان كلمة المرور
2. أدخل البريد الإلكتروني
3. تحقق من وصول الرسالة

## استكشاف الأخطاء

### مشاكل شائعة:

1. **خطأ في تهيئة Firebase**
   - تأكد من وضع ملفات التكوين في المكان الصحيح
   - تحقق من صحة package name / bundle ID

2. **خطأ في Authentication**
   - تأكد من تفعيل Email/Password في Firebase Console
   - تحقق من قواعد الأمان

3. **خطأ في Firestore**
   - تأكد من إنشاء قاعدة البيانات
   - تحقق من قواعد الأمان

## المرحلة القادمة

### المميزات المخططة:
- ✅ نظام الشات في الوقت الفعلي
- ✅ خرائط تفاعلية
- ✅ إدارة ملفات الحرفيين
- ✅ نظام التقييمات والمراجعات

## الدعم

للحصول على المساعدة:
1. تحقق من [Firebase Documentation](https://firebase.google.com/docs)
2. راجع [Flutter Documentation](https://flutter.dev/docs)
3. تحقق من ملفات المشروع للتأكد من الإعداد الصحيح

---

**ملاحظة**: هذا المشروع جاهز للاستخدام مع Firebase بالكامل. تأكد من إعداد Firebase Console قبل تشغيل التطبيق. 