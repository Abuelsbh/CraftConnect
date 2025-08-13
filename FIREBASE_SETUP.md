# إعداد Firebase للتطبيق

## الخطوات المطلوبة لإعداد Firebase

### 1. إنشاء مشروع Firebase

1. اذهب إلى [Firebase Console](https://console.firebase.google.com/)
2. انقر على "إنشاء مشروع" أو "Add project"
3. أدخل اسم المشروع (مثال: `craftconnect-app`)
4. اختر ما إذا كنت تريد تفعيل Google Analytics (اختياري)
5. انقر على "إنشاء المشروع"

### 2. إضافة التطبيق إلى Firebase

#### لنظام Android:
1. في لوحة التحكم، انقر على أيقونة Android
2. أدخل معرف الحزمة: `com.example.template_2025`
3. أدخل اسم التطبيق (اختياري)
4. انقر على "تسجيل التطبيق"
5. قم بتحميل ملف `google-services.json`
6. ضع الملف في مجلد `android/app/`

#### لنظام iOS:
1. في لوحة التحكم، انقر على أيقونة iOS
2. أدخل معرف الحزمة: `com.example.template2025`
3. أدخل اسم التطبيق (اختياري)
4. انقر على "تسجيل التطبيق"
5. قم بتحميل ملف `GoogleService-Info.plist`
6. ضع الملف في مجلد `ios/Runner/`

#### للويب:
1. في لوحة التحكم، انقر على أيقونة الويب
2. أدخل اسم التطبيق
3. انقر على "تسجيل التطبيق"
4. انسخ كود التهيئة

### 3. تفعيل خدمات Firebase

#### Authentication:
1. في القائمة الجانبية، اختر "Authentication"
2. انقر على "Get started"
3. في تبويب "Sign-in method"، فعّل:
   - Email/Password
   - Google (اختياري)
   - Phone (اختياري)

#### Firestore Database:
1. في القائمة الجانبية، اختر "Firestore Database"
2. انقر على "Create database"
3. اختر "Start in test mode" للتطوير
4. اختر موقع قاعدة البيانات (يفضل الأقرب لمنطقتك)

#### Storage (اختياري):
1. في القائمة الجانبية، اختر "Storage"
2. انقر على "Get started"
3. اختر "Start in test mode" للتطوير

### 4. إعداد قواعد الأمان

#### قواعد Firestore:
1. في Firestore Database، انقر على تبويب "Rules"
2. استبدل القواعد الموجودة بالقواعد التالية:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // قواعد المستخدمين
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null && request.auth.uid == userId;
    }
    
    // قواعد الحرفيين
    match /artisans/{artisanId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == artisanId;
    }
    
    // قواعد الحرف
    match /crafts/{craftId} {
      allow read: if true;
      allow write: if request.auth != null && 
        request.auth.uid == resource.data.artisanId;
    }
    
    // قواعد المحادثات
    match /chats/{chatId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid in resource.data.participants);
    }
    
    // قواعد الرسائل
    match /chats/{chatId}/messages/{messageId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants);
    }
    
    // قواعد التقييمات
    match /reviews/{reviewId} {
      allow read: if true;
      allow create: if request.auth != null && 
        request.auth.uid == request.resource.data.userId;
      allow update: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    // قواعد الطلبات
    match /orders/{orderId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.customerId || 
         request.auth.uid == resource.data.artisanId);
    }
    
    // قواعد الإشعارات
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    // قواعد الملفات الشخصية
    match /profiles/{profileId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == profileId;
    }
    
    // قواعد الإعدادات
    match /settings/{settingId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == settingId;
    }
  }
}
```

#### قواعد Storage (إذا كنت تستخدم Storage):
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /artisans/{artisanId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == artisanId;
    }
  }
}
```

### 5. إعداد Authentication

#### إعداد Email/Password:
1. في Authentication > Sign-in method
2. فعّل "Email/Password"
3. فعّل "Email link (passwordless sign-in)" إذا كنت تريد

#### إعداد Google Sign-In (اختياري):
1. في Authentication > Sign-in method
2. فعّل "Google"
3. أدخل اسم المشروع وبيانات الاتصال
4. احفظ معرف العميل

#### إعداد Phone Authentication (اختياري):
1. في Authentication > Sign-in method
2. فعّل "Phone"
3. أدخل رقم الهاتف للاختبار

### 6. اختبار الإعداد

1. قم بتشغيل التطبيق
2. جرب إنشاء حساب جديد
3. جرب تسجيل الدخول
4. تحقق من ظهور البيانات في Firestore

### 7. ملاحظات مهمة

- تأكد من أن جميع الملفات المطلوبة موجودة في المكان الصحيح
- لا تشارك مفاتيح Firebase مع أي شخص
- استخدم قواعد أمان مناسبة للإنتاج
- احتفظ بنسخة احتياطية من ملفات التكوين

### 8. استكشاف الأخطاء

#### مشاكل شائعة:
1. **خطأ في التهيئة**: تأكد من وجود ملف `google-services.json` في المكان الصحيح
2. **خطأ في القواعد**: تأكد من صحة قواعد Firestore
3. **خطأ في Authentication**: تأكد من تفعيل طرق تسجيل الدخول المطلوبة

#### للحصول على المساعدة:
- راجع [وثائق Firebase](https://firebase.google.com/docs)
- تحقق من [Stack Overflow](https://stackoverflow.com/questions/tagged/firebase)
- راجع سجلات الأخطاء في Firebase Console 