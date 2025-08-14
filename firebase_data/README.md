# ملفات JSON للفيربيز 🔥

هذا المجلد يحتوي على ملفات JSON جاهزة لإضافتها إلى Firebase Firestore.

## الملفات المتاحة

### 1. `artisans.json` - بيانات الحرفيين
يحتوي على 10 حرفيين من مختلف التخصصات:
- **2 نجارين** (carpenter)
- **2 كهربائيين** (electrician)
- **2 سباكين** (plumber)
- **2 صباغين** (painter)
- **2 ميكانيكيين** (mechanic)

### 2. `reviews.json` - بيانات التقييمات
يحتوي على 15 تقييم موزعة على الحرفيين المختلفين.

## كيفية الإضافة إلى Firebase

### الطريقة الأولى: Firebase Console

1. **افتح Firebase Console**
   - اذهب إلى [console.firebase.google.com](https://console.firebase.google.com)
   - اختر مشروعك

2. **اذهب إلى Firestore Database**
   - اختر "Firestore Database" من القائمة الجانبية
   - اضغط على "Start collection" إذا لم تكن موجودة

3. **أضف مجموعة الحرفيين**
   - Collection ID: `artisans`
   - Document ID: استخدم المعرفات من الملف (مثل `artisan_001`)
   - انسخ البيانات من `artisans.json`

4. **أضف مجموعة التقييمات**
   - Collection ID: `reviews`
   - Document ID: استخدم المعرفات من الملف (مثل `review_001`)
   - انسخ البيانات من `reviews.json`

### الطريقة الثانية: Firebase CLI

1. **ثبت Firebase CLI**
   ```bash
   npm install -g firebase-tools
   ```

2. **سجل دخولك**
   ```bash
   firebase login
   ```

3. **اختر مشروعك**
   ```bash
   firebase use your-project-id
   ```

4. **استورد البيانات**
   ```bash
   firebase firestore:import firebase_data/
   ```

### الطريقة الثالثة: Firebase Admin SDK

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./path/to/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// إضافة الحرفيين
const artisansData = require('./firebase_data/artisans.json');
artisansData.artisans.forEach(async (artisan) => {
  await db.collection('artisans').doc(artisan.id).set(artisan);
});

// إضافة التقييمات
const reviewsData = require('./firebase_data/reviews.json');
reviewsData.reviews.forEach(async (review) => {
  await db.collection('reviews').doc(review.id).set(review);
});
```

## هيكل البيانات

### بيانات الحرفي
```json
{
  "id": "artisan_001",
  "name": "اسم الحرفي",
  "email": "email@example.com",
  "phone": "+966501234567",
  "profileImageUrl": "رابط الصورة الشخصية",
  "craftType": "نوع الحرفة",
  "yearsOfExperience": 12,
  "description": "وصف الحرفي",
  "latitude": 24.7136,
  "longitude": 46.6753,
  "address": "العنوان",
  "rating": 4.8,
  "reviewCount": 156,
  "galleryImages": ["روابط صور المعرض"],
  "isAvailable": true,
  "createdAt": "2024-01-15T10:30:00.000Z",
  "updatedAt": "2024-12-19T14:20:00.000Z"
}
```

### بيانات التقييم
```json
{
  "id": "review_001",
  "artisanId": "artisan_001",
  "userId": "user_001",
  "userName": "اسم المستخدم",
  "userProfileImage": "رابط صورة المستخدم",
  "rating": 5.0,
  "comment": "التعليق",
  "images": ["روابط صور التقييم"],
  "createdAt": "2024-12-15T10:30:00.000Z",
  "updatedAt": "2024-12-15T10:30:00.000Z"
}
```

## أنواع الحرف المتاحة

- `carpenter` - نجار
- `electrician` - كهربائي
- `plumber` - سباك
- `painter` - صباغ
- `mechanic` - ميكانيكي
- `tailor` - خياط
- `blacksmith` - حداد
- `welder` - لحام
- `mason` - بناء
- `gardener` - بستاني

## المواقع

جميع الحرفيين موجودون في مدينة الرياض، المملكة العربية السعودية:
- **المنطقة المركزية:** حي الملز، حي العليا
- **المنطقة الشمالية:** حي السليمانية، حي الربوة
- **المنطقة الجنوبية:** حي الشفا، حي النخيل
- **المنطقة الشرقية:** حي الورود، حي الشميسي
- **المنطقة الغربية:** حي النزهة، حي الملقا

## التقييمات

- **متوسط التقييمات:** 4.7/5
- **عدد التقييمات:** 15 تقييم
- **التوزيع:**
  - 5 نجوم: 7 تقييمات
  - 4.5-4.9: 5 تقييمات
  - 4.0-4.4: 3 تقييمات

## ملاحظات مهمة

1. **روابط الصور:** استبدل `your-project.appspot.com` بمعرف مشروعك في Firebase
2. **التواريخ:** جميع التواريخ بصيغة ISO 8601
3. **الإحداثيات:** جميع الإحداثيات في مدينة الرياض
4. **الهواتف:** جميع الأرقام بصيغة السعودية (+966)

## تحديث البيانات

بعد إضافة البيانات، يمكنك:
- تحديث الصور في Firebase Storage
- إضافة حرفيين جدد
- إضافة تقييمات جديدة
- تعديل البيانات الموجودة

## الدعم

إذا واجهت أي مشاكل في إضافة البيانات، تأكد من:
- صحة معرف مشروع Firebase
- صلاحيات الكتابة في Firestore
- صحة تنسيق JSON
- اتصال الإنترنت 