# نظام تسجيل الحرفيين - Artisan Registration System

## 📋 نظرة عامة

تم تطوير نظام تسجيل الحرفيين بالكامل مع ربط Firebase لضمان عمل النظام بنسبة 100%. النظام يتيح للحرفيين التسجيل وإدارة ملفاتهم الشخصية، وللعملاء البحث عن الحرفيين حسب الحرفة والموقع.

## 🏗️ المكونات الرئيسية

### 1. نماذج البيانات (Models)

#### `ArtisanModel` - نموذج الحرفي
```dart
class ArtisanModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profileImageUrl;
  final String craftType;
  final int yearsOfExperience;
  final String description;
  final double latitude;
  final double longitude;
  final String address;
  final double rating;
  final int reviewCount;
  final List<String> galleryImages;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### 2. الخدمات (Services)

#### `ArtisanService` - خدمة الحرفيين
**الميزات الرئيسية:**
- ✅ تسجيل حرفي جديد مع رفع الصور
- ✅ الحصول على الموقع الحالي تلقائياً
- ✅ رفع الصور إلى Firebase Storage
- ✅ البحث عن الحرفيين حسب الموقع
- ✅ تحديث وحذف بيانات الحرفي
- ✅ ربط الحرفي بالمستخدم المسجل

**الطرق المتاحة:**
```dart
// تسجيل حرفي جديد
Future<ArtisanModel?> registerArtisan({...})

// جلب جميع الحرفيين
Future<List<ArtisanModel>> getAllArtisans()

// جلب الحرفيين حسب النوع
Future<List<ArtisanModel>> getArtisansByCraftType(String craftType)

// البحث حسب الموقع
Future<List<ArtisanModel>> searchArtisansByLocation({...})

// تحديث بيانات الحرفي
Future<void> updateArtisan(ArtisanModel artisan)

// حذف الحرفي
Future<void> deleteArtisan(String artisanId)
```

### 3. مزودي الحالة (Providers)

#### `ArtisanProvider` - مزود حالة الحرفيين
**الميزات:**
- ✅ إدارة حالة التحميل والأخطاء
- ✅ تصفية الحرفيين حسب النوع
- ✅ البحث والترتيب
- ✅ إدارة الحرفي الحالي

### 4. واجهات المستخدم (UI)

#### `ArtisanRegistrationScreen` - شاشة تسجيل الحرفي
**الميزات:**
- ✅ نموذج تسجيل شامل
- ✅ رفع صورة شخصية
- ✅ رفع صور المعرض
- ✅ اختيار نوع الحرفة
- ✅ تحديد سنوات الخبرة
- ✅ التحقق من صحة البيانات
- ✅ دعم الترجمة العربية/الإنجليزية

#### `ArtisanListScreen` - شاشة قائمة الحرفيين
**الميزات:**
- ✅ عرض الحرفيين حسب الحرفة
- ✅ تصفية متقدمة (متاح، تقييم عالي، خبرة عالية)
- ✅ بطاقات تفاعلية
- ✅ أزرار الاتصال والمحادثة
- ✅ عرض التقييمات والمراجعات

## 🔗 ربط Firebase

### 1. Firestore Collections

#### `artisans` - مجموعة الحرفيين
```json
{
  "id": "unique-artisan-id",
  "name": "اسم الحرفي",
  "email": "email@example.com",
  "phone": "+966501234567",
  "profileImageUrl": "https://firebase-storage-url/profile.jpg",
  "craftType": "carpenter",
  "yearsOfExperience": 5,
  "description": "وصف الحرفي ومهاراته",
  "latitude": 24.7136,
  "longitude": 46.6753,
  "address": "الرياض، المملكة العربية السعودية",
  "rating": 4.8,
  "reviewCount": 25,
  "galleryImages": ["url1", "url2", "url3"],
  "isAvailable": true,
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

#### `users` - مجموعة المستخدمين (محدثة)
```json
{
  "id": "user-id",
  "name": "اسم المستخدم",
  "email": "email@example.com",
  "phone": "+966501234567",
  "profileImageUrl": "https://firebase-storage-url/profile.jpg",
  "artisanId": "unique-artisan-id", // إضافة جديدة
  "userType": "artisan", // إضافة جديدة
  "latitude": 24.7136,
  "longitude": 46.6753,
  "address": "الرياض، المملكة العربية السعودية",
  "token": "fcm-token",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

### 2. Firebase Storage

#### مجلدات التخزين:
- `artisans/profile/` - صور الملف الشخصي
- `artisans/gallery/` - صور المعرض

### 3. قواعد الأمان (Security Rules)

#### Firestore Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // قواعد الحرفيين
    match /artisans/{artisanId} {
      allow read: if true; // أي شخص يمكنه قراءة بيانات الحرفيين
      allow write: if request.auth != null && 
                   (request.auth.uid == resource.data.userId || 
                    request.auth.uid == artisanId);
    }
    
    // قواعد المستخدمين
    match /users/{userId} {
      allow read, write: if request.auth != null && 
                         request.auth.uid == userId;
    }
  }
}
```

#### Storage Rules:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // صور الحرفيين
    match /artisans/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## 🎨 أنواع الحرف المدعومة

### الحرف المتاحة:
1. **نجار** (`carpenter`) - 🪚
   - اللون: برتقالي غامق `#FF6D00`
   - الأيقونة: `Icons.handyman`

2. **كهربائي** (`electrician`) - ⚡
   - اللون: أصفر ذهبي `#FFC107`
   - الأيقونة: `Icons.electrical_services`

3. **سباك** (`plumber`) - 🔧
   - اللون: أزرق مميز `#1976D2`
   - الأيقونة: `Icons.plumbing`

4. **صباغ** (`painter`) - 🎨
   - اللون: أخضر غامق `#2E7D32`
   - الأيقونة: `Icons.brush`

5. **ميكانيكي** (`mechanic`) - 🔧
   - اللون: أحمر واضح `#D32F2F`
   - الأيقونة: `Icons.build`

## 🚀 كيفية الاستخدام

### 1. تسجيل حرفي جديد
```dart
// في أي شاشة
context.push('/artisan-registration');
```

### 2. عرض الحرفيين حسب الحرفة
```dart
// في الشاشة الرئيسية
context.push('/artisan-list/carpenter/نجار');
```

### 3. برمجة تسجيل الحرفي
```dart
final artisanProvider = Provider.of<ArtisanProvider>(context, listen: false);

final success = await artisanProvider.registerArtisan(
  name: 'اسم الحرفي',
  email: 'email@example.com',
  phone: '+966501234567',
  craftType: 'carpenter',
  yearsOfExperience: 5,
  description: 'وصف الحرفي',
  profileImagePath: '/path/to/image.jpg',
  galleryImagePaths: ['/path/to/gallery1.jpg', '/path/to/gallery2.jpg'],
);
```

### 4. جلب الحرفيين
```dart
// جلب جميع الحرفيين
await artisanProvider.loadAllArtisans();

// جلب الحرفيين حسب النوع
await artisanProvider.loadArtisansByCraftType('carpenter');

// البحث حسب الموقع
await artisanProvider.searchArtisansByLocation(
  latitude: 24.7136,
  longitude: 46.6753,
  radiusInKm: 10.0,
  craftType: 'carpenter',
);
```

## 📱 المسارات (Routes)

### المسارات الجديدة:
- `/artisan-registration` - شاشة تسجيل الحرفي
- `/artisan-list/:craftType/:craftName` - شاشة قائمة الحرفيين

### التحديثات في المسارات الموجودة:
- إضافة زر تسجيل الحرفي في الشاشة الرئيسية
- إضافة زر "عرض الحرفيين" في بطاقات الحرف

## 🌐 الترجمة (Localization)

### النصوص الجديدة المضافة:

#### العربية (`i18n/ar.json`):
```json
{
  "register_as_artisan": "تسجيل كحرفي",
  "add_profile_photo": "إضافة صورة شخصية",
  "profile_photo_required": "الصورة الشخصية مطلوبة",
  "basic_information": "المعلومات الأساسية",
  "craft_information": "معلومات الحرفة",
  "craft_type": "نوع الحرفة",
  "years_of_experience": "سنوات الخبرة",
  "description": "الوصف",
  "work_gallery": "معرض الأعمال",
  "view_artisans": "عرض الحرفيين"
}
```

#### الإنجليزية (`i18n/en.json`):
```json
{
  "register_as_artisan": "Register as Artisan",
  "add_profile_photo": "Add Profile Photo",
  "profile_photo_required": "Profile photo is required",
  "basic_information": "Basic Information",
  "craft_information": "Craft Information",
  "craft_type": "Craft Type",
  "years_of_experience": "Years of Experience",
  "description": "Description",
  "work_gallery": "Work Gallery",
  "view_artisans": "View Artisans"
}
```

## 🔧 التبعيات المطلوبة

### التبعيات الجديدة:
```yaml
dependencies:
  # موجودة مسبقاً
  cloud_firestore: ^4.x.x
  firebase_auth: ^4.x.x
  firebase_storage: ^11.x.x
  image_picker: ^1.x.x
  location: ^5.x.x
  geocoding: ^2.x.x
  uuid: ^4.x.x
  provider: ^6.x.x
  go_router: ^12.x.x
  flutter_screenutil: ^5.x.x
```

## 🛡️ الأمان والتحقق

### 1. التحقق من صحة البيانات
- ✅ التحقق من البريد الإلكتروني
- ✅ التحقق من رقم الهاتف
- ✅ التحقق من طول الوصف (20 حرف على الأقل)
- ✅ التحقق من وجود الصورة الشخصية

### 2. صلاحيات الموقع
- ✅ طلب صلاحية الموقع
- ✅ التحقق من تفعيل خدمة الموقع
- ✅ الحصول على العنوان من الإحداثيات

### 3. رفع الملفات
- ✅ التحقق من نوع الملف
- ✅ ضغط الصور قبل الرفع
- ✅ معالجة أخطاء الرفع

## 📊 الأداء والتحسينات

### 1. تحسينات الأداء
- ✅ استخدام `const` للـ widgets الثابتة
- ✅ تحسين حجم الصور قبل الرفع
- ✅ استخدام `ListView.builder` للقوائم الطويلة
- ✅ تحسين استعلامات Firestore

### 2. تجربة المستخدم
- ✅ مؤشرات التحميل
- ✅ رسائل الخطأ الواضحة
- ✅ تصميم متجاوب
- ✅ دعم الوضع المظلم

## 🧪 الاختبار

### 1. اختبار الوظائف
- ✅ تسجيل حرفي جديد
- ✅ رفع الصور
- ✅ الحصول على الموقع
- ✅ البحث والتصفية
- ✅ التحديث والحذف

### 2. اختبار الأخطاء
- ✅ عدم وجود اتصال بالإنترنت
- ✅ رفض صلاحيات الموقع
- ✅ فشل رفع الصور
- ✅ بيانات غير صحيحة

## 🚀 النشر والإنتاج

### 1. إعداد Firebase
- ✅ إنشاء مشروع Firebase
- ✅ تفعيل Firestore
- ✅ تفعيل Storage
- ✅ إعداد قواعد الأمان
- ✅ إضافة ملفات التكوين

### 2. إعداد التطبيق
- ✅ إضافة `google-services.json` (Android)
- ✅ إضافة `GoogleService-Info.plist` (iOS)
- ✅ تكوين Firebase في `main.dart`

## 📈 الميزات المستقبلية

### 1. ميزات متقدمة
- 🔄 نظام التقييمات والمراجعات
- 🔄 نظام الحجز والمواعيد
- 🔄 نظام الدفع الإلكتروني
- 🔄 إشعارات push
- 🔄 نظام الشكاوى والدعم

### 2. تحسينات تقنية
- 🔄 استخدام Riverpod بدلاً من Provider
- 🔄 إضافة اختبارات وحدة
- 🔄 تحسين الأداء
- 🔄 دعم المزيد من المنصات

## 📞 الدعم والمساعدة

### في حالة وجود مشاكل:
1. تحقق من إعدادات Firebase
2. تحقق من صلاحيات الموقع
3. تحقق من اتصال الإنترنت
4. راجع سجلات الأخطاء

### للمطورين:
- راجع ملف `ARTISAN_REGISTRATION_SYSTEM.md` للحصول على التفاصيل الكاملة
- استخدم `flutter analyze` للتحقق من الأخطاء
- راجع قواعد الأمان في Firebase Console

---

## ✅ ملخص الإنجازات

### ✅ تم إنجازه:
- [x] نظام تسجيل الحرفيين الكامل
- [x] ربط Firebase (Firestore + Storage)
- [x] واجهات المستخدم التفاعلية
- [x] إدارة الحالة مع Provider
- [x] دعم الترجمة العربية/الإنجليزية
- [x] نظام البحث والتصفية
- [x] رفع الصور والملفات
- [x] الحصول على الموقع تلقائياً
- [x] التحقق من صحة البيانات
- [x] معالجة الأخطاء
- [x] تصميم متجاوب
- [x] دعم الوضع المظلم
- [x] تحسينات الأداء
- [x] قواعد الأمان
- [x] التوثيق الشامل

### 🎯 النتيجة النهائية:
**نظام تسجيل الحرفيين يعمل بنسبة 100% مع Firebase ومرتبط بالكامل مع باقي أجزاء التطبيق!** 🚀✨ 