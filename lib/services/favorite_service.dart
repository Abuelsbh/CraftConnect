import 'package:cloud_firestore/cloud_firestore.dart';

/// خدمة للتعامل مع نظام المفضلة في Firestore
///
/// البنية المقترحة:
/// users/{userId}/favorites/{artisanId} => {
///   'artisanId': String,
///   'createdAt': Timestamp
/// }
class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// إرجاع مرجع كولكشن المفضلة للمستخدم
  CollectionReference<Map<String, dynamic>> _userFavoritesRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('favorites');
  }

  /// التأكد إذا كان الحرفي في مفضلة المستخدم
  Future<bool> isFavorite({
    required String userId,
    required String artisanId,
  }) async {
    try {
      final doc =
          await _userFavoritesRef(userId).doc(artisanId).get(const GetOptions(source: Source.serverAndCache));
      return doc.exists;
    } catch (e) {
      // في حالة الخطأ نعتبره غير موجود في المفضلة ولا نوقف التطبيق
      return false;
    }
  }

  /// جلب جميع معرفات الحرفيين في مفضلة المستخدم
  Future<Set<String>> getUserFavoriteArtisanIds(String userId) async {
    try {
      final snapshot = await _userFavoritesRef(userId).get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      return {};
    }
  }

  /// إضافة حرفي إلى المفضلة
  Future<void> addToFavorites({
    required String userId,
    required String artisanId,
  }) async {
    try {
      await _userFavoritesRef(userId).doc(artisanId).set({
        'artisanId': artisanId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('فشل في إضافة الحرفي إلى المفضلة: $e');
    }
  }

  /// إزالة حرفي من المفضلة
  Future<void> removeFromFavorites({
    required String userId,
    required String artisanId,
  }) async {
    try {
      await _userFavoritesRef(userId).doc(artisanId).delete();
    } catch (e) {
      throw Exception('فشل في إزالة الحرفي من المفضلة: $e');
    }
  }

  /// تبديل حالة المفضلة وإرجاع الحالة الجديدة (true إذا أصبح في المفضلة)
  Future<bool> toggleFavorite({
    required String userId,
    required String artisanId,
  }) async {
    final docRef = _userFavoritesRef(userId).doc(artisanId);
    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.delete();
      return false;
    } else {
      await docRef.set({
        'artisanId': artisanId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    }
  }
}















