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
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('artisanId', isEqualTo: artisanId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ReviewModel.fromJson(doc.data()))
          .toList();
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
} 