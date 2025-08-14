// سكريبت إضافة البيانات إلى Firebase
// استخدم هذا الملف لإضافة بيانات الحرفيين والتقييمات إلى Firebase

const admin = require('firebase-admin');
const fs = require('fs');

// تحميل بيانات JSON
const artisansData = JSON.parse(fs.readFileSync('./artisans.json', 'utf8'));
const reviewsData = JSON.parse(fs.readFileSync('./reviews.json', 'utf8'));

// تهيئة Firebase Admin SDK
// استبدل 'path/to/serviceAccountKey.json' بمسار ملف مفتاح الخدمة الخاص بك
const serviceAccount = require('./path/to/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// دالة إضافة الحرفيين
async function addArtisans() {
  console.log('🚀 بدء إضافة الحرفيين...');
  
  for (const artisan of artisansData.artisans) {
    try {
      await db.collection('artisans').doc(artisan.id).set(artisan);
      console.log(`✅ تم إضافة الحرفي: ${artisan.name}`);
    } catch (error) {
      console.error(`❌ خطأ في إضافة الحرفي ${artisan.name}:`, error);
    }
  }
  
  console.log('🎉 تم إضافة جميع الحرفيين بنجاح!');
}

// دالة إضافة التقييمات
async function addReviews() {
  console.log('🚀 بدء إضافة التقييمات...');
  
  for (const review of reviewsData.reviews) {
    try {
      await db.collection('reviews').doc(review.id).set(review);
      console.log(`✅ تم إضافة التقييم: ${review.id}`);
    } catch (error) {
      console.error(`❌ خطأ في إضافة التقييم ${review.id}:`, error);
    }
  }
  
  console.log('🎉 تم إضافة جميع التقييمات بنجاح!');
}

// دالة حذف البيانات (اختيارية)
async function deleteAllData() {
  console.log('🗑️ بدء حذف جميع البيانات...');
  
  try {
    // حذف جميع التقييمات
    const reviewsSnapshot = await db.collection('reviews').get();
    const reviewsDeletePromises = reviewsSnapshot.docs.map(doc => doc.ref.delete());
    await Promise.all(reviewsDeletePromises);
    console.log('✅ تم حذف جميع التقييمات');
    
    // حذف جميع الحرفيين
    const artisansSnapshot = await db.collection('artisans').get();
    const artisansDeletePromises = artisansSnapshot.docs.map(doc => doc.ref.delete());
    await Promise.all(artisansDeletePromises);
    console.log('✅ تم حذف جميع الحرفيين');
    
    console.log('🎉 تم حذف جميع البيانات بنجاح!');
  } catch (error) {
    console.error('❌ خطأ في حذف البيانات:', error);
  }
}

// دالة عرض البيانات
async function showData() {
  console.log('📊 عرض البيانات الموجودة...');
  
  try {
    // عرض الحرفيين
    const artisansSnapshot = await db.collection('artisans').get();
    console.log(`\n👥 عدد الحرفيين: ${artisansSnapshot.size}`);
    artisansSnapshot.forEach(doc => {
      const artisan = doc.data();
      console.log(`- ${artisan.name} (${artisan.craftType}) - تقييم: ${artisan.rating}/5`);
    });
    
    // عرض التقييمات
    const reviewsSnapshot = await db.collection('reviews').get();
    console.log(`\n⭐ عدد التقييمات: ${reviewsSnapshot.size}`);
    
    // حساب متوسط التقييمات
    let totalRating = 0;
    let count = 0;
    reviewsSnapshot.forEach(doc => {
      const review = doc.data();
      totalRating += review.rating;
      count++;
    });
    
    if (count > 0) {
      console.log(`📈 متوسط التقييمات: ${(totalRating / count).toFixed(2)}/5`);
    }
    
  } catch (error) {
    console.error('❌ خطأ في عرض البيانات:', error);
  }
}

// الدالة الرئيسية
async function main() {
  const action = process.argv[2];
  
  switch (action) {
    case 'add':
      await addArtisans();
      await addReviews();
      break;
    case 'artisans':
      await addArtisans();
      break;
    case 'reviews':
      await addReviews();
      break;
    case 'delete':
      await deleteAllData();
      break;
    case 'show':
      await showData();
      break;
    default:
      console.log(`
📋 استخدم السكريبت كالتالي:

🔧 إضافة جميع البيانات:
   node import_script.js add

👥 إضافة الحرفيين فقط:
   node import_script.js artisans

⭐ إضافة التقييمات فقط:
   node import_script.js reviews

🗑️ حذف جميع البيانات:
   node import_script.js delete

📊 عرض البيانات الموجودة:
   node import_script.js show

⚠️ ملاحظة: تأكد من تحديث مسار ملف مفتاح الخدمة في السكريبت
      `);
  }
  
  process.exit(0);
}

// تشغيل السكريبت
main().catch(console.error); 