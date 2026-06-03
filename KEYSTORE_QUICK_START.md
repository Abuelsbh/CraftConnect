# ⚡ Quick Start - إنشاء Key لرفع التطبيق على Google Play

## الخطوات السريعة (5 دقائق)

### 1️⃣ إنشاء Keystore

افتح Terminal في مجلد المشروع وقم بتشغيل:

```bash
cd android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pixfix
```

**أو استخدم السكريبت الجاهز:**
```bash
./CREATE_KEYSTORE.sh
```

### 2️⃣ إنشاء ملف key.properties

في مجلد `android`، أنشئ ملف `key.properties` وأضف:

```properties
storePassword=كلمة_المرور_التي_أدخلتها
keyPassword=كلمة_المرور_التي_أدخلتها
keyAlias=pixfix
storeFile=upload-keystore.jks
```

### 3️⃣ بناء التطبيق

```bash
flutter build appbundle --release
```

الملف جاهز في: `build/app/outputs/bundle/release/app-release.aab`

---

## 📚 للمزيد من التفاصيل

راجع ملف: `KEYSTORE_SETUP.md`

---

## ⚠️ مهم جداً

- احتفظ بنسخة احتياطية من `upload-keystore.jks`
- احفظ كلمات المرور في مكان آمن
- لا ترفع الملفات إلى Git (موجودة في .gitignore)

