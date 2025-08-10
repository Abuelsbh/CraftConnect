# إعداد Google Maps للتطبيق

## ⚠️ الحالة الحالية
التطبيق يعمل حالياً في **الوضع التجريبي** لعرض الحرفيين بدون خرائط فعلية. لتفعيل Google Maps الكاملة، تحتاج لإضافة API Key صحيح.

## 🔧 خطوات التفعيل

### 1. الحصول على Google Maps API Key

1. اذهب إلى [Google Cloud Console](https://console.cloud.google.com/)
2. إنشاء مشروع جديد أو اختيار مشروع موجود
3. تفعيل الخدمات التالية:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API
   - Geocoding API

4. إنشاء API Key جديد:
   - اذهب إلى **APIs & Services** > **Credentials**
   - اضغط **Create Credentials** > **API Key**
   - انسخ الـ API Key

### 2. إضافة API Key للتطبيق

#### Android:
استبدل القيمة في `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_API_KEY_HERE" />
```

#### iOS:
أضف API Key في `ios/Runner/AppDelegate.swift`:

```swift
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### 3. استبدال الصفحة التجريبية

في `lib/Modules/Home/home_screen.dart`، استبدل:

```dart
import '../Maps/demo_maps_page.dart';
// ...
const DemoMapsPage(),
```

بـ:

```dart
import '../Maps/maps_page.dart';
// ...
const MapsPage(),
```

### 4. التحقق من الصلاحيات

تأكد من وجود الصلاحيات في `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

## 🌟 المميزات المتاحة بعد التفعيل

- ✅ عرض الخريطة الفعلية
- ✅ تحديد الموقع الحالي
- ✅ علامات الحرفيين على الخريطة
- ✅ فلترة حسب المسافة
- ✅ ألوان مختلفة لكل نوع حرفة
- ✅ تفاصيل الحرفيين عند الضغط على العلامات

## 🚨 ملاحظات مهمة

1. **التكلفة**: Google Maps API قد تتطلب دفع رسوم حسب الاستخدام
2. **القيود**: ضع قيود على API Key لحماية من الاستخدام غير المصرح به
3. **البيئات**: استخدم API Keys مختلفة للتطوير والإنتاج

## 🔄 العودة للوضع التجريبي

إذا أردت العودة للوضع التجريبي، ببساطة استبدل `MapsPage` بـ `DemoMapsPage` في ملف `home_screen.dart`.

---

**ملاحظة**: الوضع التجريبي الحالي يعرض جميع ميزات التطبيق عدا الخرائط الفعلية، وهو مناسب للتطوير والاختبار. 