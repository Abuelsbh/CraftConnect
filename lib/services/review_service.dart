import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reviews';

  // إضافة تقييم جديد
  Future<void> addReview(ReviewModel review) async {
    try {
      await _firestore.collection(_collection).doc(review.id).set(review.toJson());
    } catch (e) {
      throw Exception('فشل في إضافة التقييم: $e');
    }
  }

  // الحصول على تقييمات حرفي معين
  Future<List<ReviewModel>> getReviewsByArtisanId(String artisanId) async {
    try {
      // استخدام where فقط بدون orderBy لتجنب الحاجة لـ index
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('artisanId', isEqualTo: artisanId)
          .get();

      // تحويل البيانات وترتيبها محلياً
      final reviews = querySnapshot.docs
          .map((doc) => ReviewModel.fromJson(doc.data()))
          .toList();
      
      // ترتيب حسب التاريخ (الأحدث أولاً)
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return reviews;
    } catch (e) {
      throw Exception('فشل في تحميل التقييمات: $e');
    }
  }

  // الحصول على تقييم معين
  Future<ReviewModel?> getReviewById(String reviewId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(reviewId).get();
      if (doc.exists) {
        return ReviewModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('فشل في تحميل التقييم: $e');
    }
  }

  // تحديث تقييم
  Future<void> updateReview(ReviewModel review) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(review.id)
          .update(review.toJson());
    } catch (e) {
      throw Exception('فشل في تحديث التقييم: $e');
    }
  }

  // حذف تقييم
  Future<void> deleteReview(String reviewId) async {
    try {
      await _firestore.collection(_collection).doc(reviewId).delete();
    } catch (e) {
      throw Exception('فشل في حذف التقييم: $e');
    }
  }

  // الحصول على متوسط تقييم حرفي
  Future<double> getAverageRating(String artisanId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('artisanId', isEqualTo: artisanId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return 0.0;
      }

      double totalRating = 0;
      for (var doc in querySnapshot.docs) {
        final review = ReviewModel.fromJson(doc.data());
        totalRating += review.rating;
      }

      return totalRating / querySnapshot.docs.length;
    } catch (e) {
      throw Exception('فشل في حساب متوسط التقييم: $e');
    }
  }

  // الحصول على عدد تقييمات حرفي
  Future<int> getReviewCount(String artisanId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('artisanId', isEqualTo: artisanId)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('فشل في حساب عدد التقييمات: $e');
    }
  }

  // التحقق من وجود تقييم من مستخدم معين لحرفي معين
  Future<bool> hasUserReviewed(String userId, String artisanId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('artisanId', isEqualTo: artisanId)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('فشل في التحقق من التقييم: $e');
    }
  }

  // الحصول على تقييم مستخدم معين لحرفي معين
  Future<ReviewModel?> getUserReview(String userId, String artisanId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('artisanId', isEqualTo: artisanId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return ReviewModel.fromJson(querySnapshot.docs.first.data());
    } catch (e) {
      throw Exception('فشل في تحميل التقييم: $e');
    }
  }

  // إضافة أو تحديث تقييم (تقييم واحد فقط لكل مستخدم لكل حرفي)
  Future<void> addOrUpdateReview(ReviewModel review) async {
    try {
      // استخدام ID ثابت بناءً على userId + artisanId
      // هذا يضمن أن كل مستخدم له تقييم واحد فقط لكل حرفي
      final reviewId = '${review.userId}_${review.artisanId}';
      
      final reviewToSave = review.copyWith(
        id: reviewId,
        updatedAt: DateTime.now(),
      );

      // استخدام set مع merge: true للتحديث إذا كان موجوداً أو الإضافة إذا لم يكن موجوداً
      await _firestore
          .collection(_collection)
          .doc(reviewId)
          .set(reviewToSave.toJson(), SetOptions(merge: true));

      // تحديث rating و reviewCount في بيانات الحرفي
      await _updateArtisanRating(review.artisanId);
    } catch (e) {
      throw Exception('فشل في حفظ التقييم: $e');
    }
  }

  // تحديث rating و reviewCount في بيانات الحرفي
  Future<void> _updateArtisanRating(String artisanId) async {
    try {
      // حساب متوسط التقييم وعدد التقييمات
      final averageRating = await getAverageRating(artisanId);
      final reviewCount = await getReviewCount(artisanId);

      // تحديث بيانات الحرفي
      await _firestore.collection('artisans').doc(artisanId).update({
        'rating': averageRating,
        'reviewCount': reviewCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // لا نرمي خطأ هنا حتى لا نفشل عملية حفظ التقييم
      print('تحذير: فشل في تحديث rating الحرفي: $e');
    }
  }

  // حذف تقييم وتحديث rating الحرفي
  Future<void> deleteReviewAndUpdateArtisan(String reviewId, String artisanId) async {
    try {
      await deleteReview(reviewId);
      await _updateArtisanRating(artisanId);
    } catch (e) {
      throw Exception('فشل في حذف التقييم: $e');
    }
  }
} 