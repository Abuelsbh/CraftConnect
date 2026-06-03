# دليل إعداد أنواع الحرف في Firebase 🔧

## نظرة عامة

تم تحديث التطبيق لاستخدام أنواع الحرف من Firebase بدلاً من القيم الثابتة. هذا يتيح إضافة حرف جديدة أو تعديل الحرف الموجودة مباشرة من Firebase دون الحاجة لتحديث التطبيق.

## هيكل البيانات في Firebase

### Collection: `crafts`

كل وثيقة في collection `crafts` تحتوي على الحقول التالية:

```json
{
  "value": "carpenter",
  "translations": {
    "ar": "عطل نجارة",
    "en": "Carpentry Problem"
  },
  "order": 1,
  "isActive": true,
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

### شرح الحقول:

- **`value`** (String, مطلوب): القيمة المستخدمة في الكود (مثل: `carpenter`, `electrical`)
- **`translations`** (Map<String, String>, مطلوب): الترجمات للحرفة
  - `ar`: الترجمة العربية
  - `en`: الترجمة الإنجليزية
- **`order`** (Number, اختياري): ترتيب عرض الحرفة (الأصغر يظهر أولاً)
- **`isActive`** (Boolean, اختياري): هل الحرفة نشطة (افتراضي: `true`)
- **`createdAt`** (Timestamp/String, اختياري): تاريخ الإنشاء
- **`updatedAt`** (Timestamp/String, اختياري): تاريخ آخر تحديث

## كيفية إضافة حرفة جديدة في Firebase

### الطريقة الأولى: من Firebase Console

1. **افتح Firebase Console**
   - اذهب إلى [Firebase Console](https://console.firebase.google.com/)
   - اختر مشروعك

2. **انتقل إلى Firestore Database**
   - من القائمة الجانبية، اختر **Firestore Database**
   - تأكد من أنك في وضع **Data** (وليس Rules)

3. **أضف Collection جديد (إذا لم يكن موجوداً)**
   - إذا لم يكن هناك collection باسم `crafts`، انقر على **Start collection**
   - أدخل اسم Collection: `crafts`
   - انقر **Next**

4. **أضف وثيقة جديدة**
   - انقر على **Add document** في collection `crafts`
   - Document ID: يمكنك استخدام القيمة (value) كـ ID، أو ترك Firebase ينشئ ID تلقائياً
   - أضف الحقول التالية:

   ```
   Field name: value
   Type: string
   Value: plumber (مثال)
   ```

   ```
   Field name: translations
   Type: map
   ثم أضف داخل الـ map:
     - Field: ar, Type: string, Value: عطل سباكة
     - Field: en, Type: string, Value: Plumbing Problem
   ```

   ```
   Field name: order
   Type: number
   Value: 3 (مثال - حسب ترتيب العرض المطلوب)
   ```

   ```
   Field name: isActive
   Type: boolean
   Value: true
   ```

   ```
   Field name: createdAt
   Type: timestamp
   Value: (اختر التاريخ الحالي)
   ```

   ```
   Field name: updatedAt
   Type: timestamp
   Value: (اختر التاريخ الحالي)
   ```

5. **احفظ الوثيقة**
   - انقر على **Save**

### الطريقة الثانية: من الكود (للمطورين)

يمكنك استخدام خدمة `CraftService` لإضافة حرفة جديدة:

```dart
import 'package:uuid/uuid.dart';
import 'lib/services/craft_service.dart';
import 'lib/Models/craft_model.dart';

final craftService = CraftService();
final uuid = Uuid();

// إنشاء حرفة جديدة
final newCraft = CraftModel(
  id: uuid.v4(), // أو استخدم القيمة كـ ID: 'plumber'
  value: 'plumber',
  translations: {
    'ar': 'عطل سباكة',
    'en': 'Plumbing Problem',
  },
  order: 3,
  isActive: true,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// إضافة الحرفة إلى Firebase
await craftService.addCraft(newCraft);
```

## الحرف الافتراضية المطلوبة

يجب إضافة الحرف التالية في Firebase:

| Value | Arabic Translation | English Translation | Order |
|-------|-------------------|---------------------|-------|
| `carpenter` | عطل نجارة | Carpentry Problem | 1 |
| `electrical` | عطل كهربائي | Electrical Problem | 2 |
| `plumbing` | عطل سباكة | Plumbing Problem | 3 |
| `painter` | عطل دهان | Painting Problem | 4 |
| `mechanic` | عطل ميكانيكي | Mechanical Problem | 5 |
| `hvac` | عطل تكييف | HVAC Problem | 6 |
| `satellite` | عطل ستالايت | Satellite Problem | 7 |
| `internet` | عطل إنترنت | Internet Problem | 8 |
| `tiler` | عطل بلاط | Tiling Problem | 9 |
| `locksmith` | عطل أقفال | Locksmith Problem | 10 |

## مثال كامل لإضافة حرفة جديدة

### مثال: إضافة حرفة "نجار أثاث"

1. **في Firebase Console:**
   - Collection: `crafts`
   - Document ID: `furniture_carpenter` (أو اتركه تلقائياً)
   - Fields:
     ```
     value: "furniture_carpenter"
     translations: {
       ar: "نجار أثاث"
       en: "Furniture Carpenter"
     }
     order: 11
     isActive: true
     createdAt: [التاريخ الحالي]
     updatedAt: [التاريخ الحالي]
     ```

2. **النتيجة:**
   - ستظهر الحرفة الجديدة في:
     - صفحة تسجيل العطل الجديد
     - صفحة تعديل الملف الشخصي للحرفي
   - الترجمة ستتغير تلقائياً حسب لغة التطبيق

## تحديث حرفة موجودة

### من Firebase Console:

1. اذهب إلى collection `crafts`
2. اختر الوثيقة التي تريد تحديثها
3. انقر على الحقل الذي تريد تعديله
4. عدّل القيمة
5. احفظ التغييرات

### مثال: تحديث ترجمة حرفة موجودة

```
Document: carpenter
Field: translations.ar
New Value: نجار محترف
```

## تعطيل حرفة (بدون حذفها)

1. اذهب إلى الوثيقة في Firebase
2. عدّل حقل `isActive` إلى `false`
3. احفظ التغييرات

**النتيجة:** لن تظهر الحرفة في التطبيق، لكن البيانات ستبقى محفوظة.

## حذف حرفة

1. اذهب إلى الوثيقة في Firebase
2. انقر على أيقونة القائمة (ثلاث نقاط)
3. اختر **Delete document**
4. أكد الحذف

**تحذير:** احذف فقط إذا كنت متأكداً أنك لن تحتاج هذه الحرفة مرة أخرى.

## قواعد Firestore المطلوبة

تأكد من أن قواعد Firestore تسمح بالقراءة للحرف:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // السماح بقراءة الحرف للجميع
    match /crafts/{craftId} {
      allow read: if true;
      // السماح بالكتابة للمسؤولين فقط (يمكنك تعديل هذا حسب احتياجك)
      allow write: if request.auth != null && 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
```

## ملاحظات مهمة

1. **القيمة (value) يجب أن تكون فريدة:** لا تستخدم نفس القيمة لحرفتين مختلفتين
2. **الترجمات مطلوبة:** تأكد من إضافة ترجمة على الأقل للعربية (`ar`)
3. **الترتيب (order):** استخدم أرقام متسلسلة لتحديد ترتيب العرض
4. **التحديثات الفورية:** التطبيق يستخدم Stream، لذا التغييرات ستظهر فوراً في التطبيق
5. **Fallback:** في حالة فشل الاتصال بـ Firebase، سيستخدم التطبيق القيم الافتراضية

## اختبار الإعداد

1. أضف حرفة جديدة في Firebase
2. افتح التطبيق
3. اذهب إلى صفحة تسجيل عطل جديد
4. تحقق من ظهور الحرفة الجديدة
5. غيّر لغة التطبيق وتحقق من الترجمة

## استكشاف الأخطاء

### المشكلة: الحرف لا تظهر في التطبيق

**الحلول:**
1. تحقق من أن `isActive` = `true`
2. تحقق من أن Collection اسمه `crafts` (بصيغة الجمع)
3. تحقق من اتصال الإنترنت
4. تحقق من قواعد Firestore (يجب السماح بالقراءة)

### المشكلة: الترجمة لا تتغير

**الحلول:**
1. تحقق من أن حقل `translations` يحتوي على المفتاح الصحيح (`ar` أو `en`)
2. أعد تشغيل التطبيق بعد تغيير اللغة
3. تحقق من أن التطبيق يستخدم `CraftService` بشكل صحيح

### المشكلة: خطأ في الترتيب

**الحلول:**
1. تأكد من أن حقل `order` موجود في جميع الوثائق
2. في Firestore، أضف index على `order` إذا كان هناك عدد كبير من الحرف:
   - اذهب إلى Firestore → Indexes
   - أضف index على collection `crafts` مع الحقول: `isActive` (Ascending), `order` (Ascending)

## الدعم

إذا واجهت أي مشاكل، تحقق من:
- ملف `lib/services/craft_service.dart` - خدمة جلب الحرف
- ملف `lib/Models/craft_model.dart` - نموذج الحرفة
- ملفات الصفحات التي تستخدم الحرف:
  - `lib/Modules/ProblemReport/problem_report_stepper_screen.dart`
  - `lib/Modules/ArtisanProfile/edit_artisan_profile_screen.dart`
  - `lib/Modules/FaultReport/fault_report_screen.dart`







