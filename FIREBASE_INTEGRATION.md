# تكامل نظام الحرفيين مع Firebase 🔥

## نظرة عامة

تم تحديث نظام الحرفيين ليعمل بشكل كامل مع Firebase، حيث يتم حفظ واسترجاع جميع البيانات من Firestore بدلاً من البيانات الوهمية.

## المجموعات في Firebase

### 1. مجموعة `artisans` 📋
```json
{
  "id": "unique_artisan_id",
  "name": "اسم الحرفي",
  "email": "email@example.com",
  "phone": "+966501234567",
  "profileImageUrl": "https://firebase-storage-url/profile.jpg",
  "craftType": "carpenter",
  "yearsOfExperience": 12,
  "description": "وصف الحرفي وخبراته",
  "latitude": 24.7136,
  "longitude": 46.6753,
  "address": "العنوان التفصيلي",
  "rating": 4.8,
  "reviewCount": 156,
  "galleryImages": [
    "https://firebase-storage-url/gallery1.jpg",
    "https://firebase-storage-url/gallery2.jpg"
  ],
  "isAvailable": true,
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

### 2. مجموعة `reviews` ⭐
```json
{
  "id": "unique_review_id",
  "artisanId": "artisan_id",
  "userId": "user_id",
  "userName": "اسم المستخدم",
  "userProfileImage": "https://firebase-storage-url/user.jpg",
  "rating": 5.0,
  "comment": "تعليق المستخدم",
  "images": [
    "https://firebase-storage-url/review1.jpg"
  ],
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

### 3. مجموعة `users` 👤
```json
{
  "id": "unique_user_id",
  "name": "اسم المستخدم",
  "email": "email@example.com",
  "phone": "+966501234567",
  "profileImageUrl": "https://firebase-storage-url/user.jpg",
  "artisanId": "artisan_id_if_applicable",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

## الخدمات المتكاملة

### 1. ArtisanService 🛠️
```dart
class ArtisanService {
  // الحصول على حرفي بواسطة المعرف
  Future<ArtisanModel?> getArtisanById(String id)
  
  // تسجيل حرفي جديد
  Future<bool> registerArtisan({...})
  
  // تحديث بيانات الحرفي
  Future<void> updateArtisan(ArtisanModel artisan)
  
  // حذف حرفي
  Future<void> deleteArtisan(String id)
  
  // الحصول على جميع الحرفيين
  Future<List<ArtisanModel>> getAllArtisans()
  
  // البحث عن الحرفيين
  Future<List<ArtisanModel>> searchArtisans(String query)
}
```

### 2. ReviewService ⭐
```dart
class ReviewService {
  // إضافة تقييم جديد
  Future<void> addReview(ReviewModel review)
  
  // الحصول على تقييمات حرفي
  Future<List<ReviewModel>> getReviewsByArtisanId(String artisanId)
  
  // الحصول على تقييم معين
  Future<ReviewModel?> getReviewById(String reviewId)
  
  // تحديث تقييم
  Future<void> updateReview(ReviewModel review)
  
  // حذف تقييم
  Future<void> deleteReview(String reviewId)
  
  // حساب متوسط التقييم
  Future<double> getAverageRating(String artisanId)
  
  // عدد التقييمات
  Future<int> getReviewCount(String artisanId)
  
  // التحقق من وجود تقييم
  Future<bool> hasUserReviewed(String userId, String artisanId)
}
```

## كيفية الاستخدام

### 1. إضافة حرفي جديد
```dart
// في شاشة تسجيل الحرفي
final artisanProvider = Provider.of<ArtisanProvider>(context, listen: false);
await artisanProvider.registerArtisan(
  name: "اسم الحرفي",
  email: "email@example.com",
  phone: "+966501234567",
  craftType: "carpenter",
  yearsOfExperience: 5,
  description: "وصف الحرفي",
  profileImagePath: "/path/to/image.jpg",
  galleryImagePaths: ["/path/to/gallery1.jpg"]
);
```

### 2. عرض تفاصيل الحرفي
```dart
// في شاشة تفاصيل الحرفي
final artisanProvider = Provider.of<ArtisanProvider>(context, listen: false);
final artisan = await artisanProvider.getArtisanById(artisanId);

final reviewService = ReviewService();
final reviews = await reviewService.getReviewsByArtisanId(artisanId);
```

### 3. إضافة تقييم
```dart
// في شاشة إضافة التقييم
final reviewService = ReviewService();
final review = ReviewModel(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  artisanId: artisanId,
  userId: currentUserId,
  userName: currentUserName,
  rating: 5.0,
  comment: "تعليق المستخدم",
  images: ["/path/to/review-image.jpg"],
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await reviewService.addReview(review);
```

## قواعد الأمان في Firebase

### 1. قواعد Firestore
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // قواعد الحرفيين
    match /artisans/{artisanId} {
      allow read: if true;  // أي شخص يمكنه القراءة
      allow write: if request.auth != null;  // المستخدمون المسجلون فقط
    }
    
    // قواعد التقييمات
    match /reviews/{reviewId} {
      allow read: if true;  // أي شخص يمكنه القراءة
      allow create: if request.auth != null;  // المستخدمون المسجلون فقط
      allow update, delete: if request.auth != null && 
        request.auth.uid == resource.data.userId;  // صاحب التقييم فقط
    }
    
    // قواعد المستخدمين
    match /users/{userId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == userId;  // المستخدم نفسه فقط
    }
  }
}
```

### 2. قواعد Storage
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // صور الحرفيين
    match /artisans/{artisanId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // صور التقييمات
    match /reviews/{reviewId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // صور المستخدمين
    match /users/{userId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && 
        request.auth.uid == userId;
    }
  }
}
```

## الميزات المتاحة ✅

- [x] حفظ بيانات الحرفيين في Firestore
- [x] حفظ التقييمات في Firestore
- [x] تحميل البيانات الحقيقية من Firebase
- [x] حساب متوسط التقييمات تلقائياً
- [x] التحقق من التقييمات المكررة
- [x] رفع الصور إلى Firebase Storage
- [x] إدارة المستخدمين
- [x] قواعد أمان متقدمة

## الميزات المستقبلية 🚀

- [ ] إشعارات للتقييمات الجديدة
- [ ] تصفية الحرفيين حسب التقييم
- [ ] نظام الحجز المباشر
- [ ] دفع إلكتروني
- [ ] تقارير وإحصائيات متقدمة
- [ ] دعم الفيديو في المعرض
- [ ] نظام الشهادات والتراخيص

## استكشاف الأخطاء 🔧

### مشاكل شائعة:

1. **خطأ في الاتصال بـ Firebase**
   - تأكد من تكوين Firebase بشكل صحيح
   - تحقق من ملف `google-services.json` (Android)
   - تحقق من ملف `GoogleService-Info.plist` (iOS)

2. **خطأ في الصلاحيات**
   - تأكد من قواعد الأمان في Firestore
   - تحقق من قواعد Storage
   - تأكد من تسجيل دخول المستخدم

3. **خطأ في تحميل البيانات**
   - تحقق من اتصال الإنترنت
   - تأكد من وجود البيانات في Firebase
   - تحقق من معرفات المستندات

## الدعم 💬

إذا واجهت أي مشاكل في التكامل مع Firebase، يرجى:
1. مراجعة سجلات Firebase Console
2. التحقق من قواعد الأمان
3. التأكد من تكوين المشروع بشكل صحيح 