# إعداد Sign in with Apple

## المتطلبات
- حساب Apple Developer (مدفوع)
- تفعيل Sign in with Apple في Firebase Console

## خطوات الإعداد

### 1. إعداد Apple Developer
1. ادخل إلى [Apple Developer](https://developer.apple.com/account/)
2. اذهب إلى **Certificates, Identifiers & Profiles** → **Identifiers**
3. اختر App ID الخاص بتطبيقك (`com.pix.fix`)
4. فعّل **Sign In with Apple** capability
5. احفظ التغييرات

### 2. إعداد Firebase
1. ادخل إلى [Firebase Console](https://console.firebase.google.com/)
2. اختر مشروعك: **parking-4d91a**
3. اذهب إلى **Authentication** → **Sign-in method**
4. اختر **Apple** واضغط **Enable**
5. أدخل **Services ID** (اختياري للويب) و **Team ID** و **Key ID** و **Private Key** إذا أردت إعداد متقدم
6. للاستخدام الأساسي مع التطبيق، يكفي تفعيل Apple فقط

### 3. إعداد Xcode (تم تلقائياً)
- تم إضافة `Runner.entitlements` مع Sign in with Apple capability
- تأكد من تفعيل **Sign in with Apple** في Xcode:
  1. افتح المشروع في Xcode: `ios/Runner.xcworkspace`
  2. اختر target **Runner**
  3. اذهب إلى **Signing & Capabilities**
  4. اضغط **+ Capability** وأضف **Sign in with Apple**

### 4. للـ Android (اختياري)
Sign in with Apple يعمل على Android عبر Web flow. يتطلب إعداد إضافي في Apple Developer (Service ID) إذا أردت دعم Android.

## ملاحظات
- على iOS 13+، Apple يتطلب عرض زر "Sign in with Apple" إذا كان التطبيق يقدم تسجيل دخول طرف ثالث (مثل Google)
- قد يختار المستخدم إخفاء بريده الإلكتروني - Apple يوفر بريد relay
- الاسم والبريد يُعادان فقط في أول تسجيل دخول
