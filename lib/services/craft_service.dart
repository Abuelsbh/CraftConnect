import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/craft_model.dart';
import '../Utilities/app_constants.dart';

/// خدمة إدارة أنواع الحرف من Firebase
class CraftService {
  static final CraftService _instance = CraftService._internal();
  factory CraftService() => _instance;
  CraftService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'crafts';

  /// جلب جميع الحرف النشطة من Firebase
  Future<List<CraftModel>> getAllCrafts({bool activeOnly = true}) async {
    try {
      QuerySnapshot querySnapshot;
      
      if (activeOnly) {
        // محاولة جلب البيانات مع orderBy
        try {
          querySnapshot = await _firestore
              .collection(_collectionName)
              .where('isActive', isEqualTo: true)
              .orderBy('order')
              .get();
        } catch (e) {
          // إذا فشل بسبب عدم وجود index، جرب بدون orderBy
          if (e.toString().contains('index') || e.toString().contains('requires an index')) {
            print('⚠️ لا يوجد index - جلب البيانات بدون ترتيب');
            querySnapshot = await _firestore
                .collection(_collectionName)
                .where('isActive', isEqualTo: true)
                .get();
          } else {
            rethrow;
          }
        }
      } else {
        // محاولة جلب البيانات مع orderBy
        try {
          querySnapshot = await _firestore
              .collection(_collectionName)
              .orderBy('order')
              .get();
        } catch (e) {
          // إذا فشل بسبب عدم وجود index، جرب بدون orderBy
          if (e.toString().contains('index') || e.toString().contains('requires an index')) {
            print('⚠️ لا يوجد index - جلب البيانات بدون ترتيب');
            querySnapshot = await _firestore
                .collection(_collectionName)
                .get();
          } else {
            rethrow;
          }
        }
      }

      // إذا كانت القائمة فارغة، ارجع قائمة فارغة (وليس القيم الافتراضية)
      if (querySnapshot.docs.isEmpty) {
        print('⚠️ لا توجد حرف في Firebase - القائمة فارغة');
        return [];
      }

      final crafts = querySnapshot.docs
          .map((doc) => CraftModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // ترتيب الحرف حسب order يدوياً إذا لم يكن orderBy متاحاً
      crafts.sort((a, b) => a.order.compareTo(b.order));
      
      print('✅ تم جلب ${crafts.length} حرفة من Firebase');
      return crafts;
    } catch (e) {
      print('❌ خطأ في جلب الحرف من Firebase: $e');
      // إرجاع القيم الافتراضية فقط في حالة الخطأ في الاتصال (وليس عندما تكون القائمة فارغة)
      // لكن فقط إذا كان الخطأ متعلق بالاتصال وليس ببساطة عدم وجود بيانات
      if (e.toString().contains('permission') || 
          e.toString().contains('network') ||
          e.toString().contains('connection') ||
          e.toString().contains('unavailable')) {
        print('⚠️ خطأ في الاتصال - استخدام القيم الافتراضية');
        return _getDefaultCrafts();
      }
      // إذا كان الخطأ في البنية أو البيانات، ارجع قائمة فارغة
      print('⚠️ خطأ في البيانات - إرجاع قائمة فارغة');
      return [];
    }
  }

  /// جلب حرفة واحدة حسب القيمة (value)
  Future<CraftModel?> getCraftByValue(String value) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('value', isEqualTo: value)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return CraftModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print('خطأ في جلب الحرفة من Firebase: $e');
      return null;
    }
  }

  /// Stream للحرف (للتحديثات الفورية)
  Stream<List<CraftModel>> getCraftsStream({bool activeOnly = true}) {
    try {
      if (activeOnly) {
        return _firestore
            .collection(_collectionName)
            .where('isActive', isEqualTo: true)
            .orderBy('order')
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => CraftModel.fromJson(
                    doc.data() as Map<String, dynamic>, doc.id))
                .toList());
      } else {
        return _firestore
            .collection(_collectionName)
            .orderBy('order')
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => CraftModel.fromJson(
                    doc.data() as Map<String, dynamic>, doc.id))
                .toList());
      }
    } catch (e) {
      print('❌ خطأ في جلب stream الحرف من Firebase: $e');
      // إرجاع stream فارغ في حالة الخطأ (وليس القيم الافتراضية)
      return Stream.value([]);
    }
  }

  /// الحصول على قائمة الحرف كـ Map للاستخدام في Dropdowns
  /// تُرجع List<Map<String, String>> حيث كل عنصر يحتوي على 'value' و 'label'
  Future<List<Map<String, String>>> getCraftsAsMap(String languageCode) async {
    try {
      final crafts = await getAllCrafts();
      
      // إذا كانت القائمة فارغة، ارجع قائمة فارغة
      if (crafts.isEmpty) {
        print('⚠️ لا توجد حرف لعرضها');
        return [];
      }
      
      return crafts.map((craft) {
        return {
          'value': craft.value,
          'label': craft.getDisplayName(languageCode),
        };
      }).toList();
    } catch (e) {
      print('❌ خطأ في تحويل الحرف إلى Map: $e');
      // فقط في حالة خطأ الاتصال، استخدم القيم الافتراضية
      if (e.toString().contains('permission') || 
          e.toString().contains('network') ||
          e.toString().contains('connection')) {
        return _getDefaultCraftsAsMap(languageCode);
      }
      return [];
    }
  }

  /// إضافة حرفة جديدة (للمسؤولين فقط)
  Future<void> addCraft(CraftModel craft) async {
    try {
      await _firestore.collection(_collectionName).doc(craft.id).set(craft.toJson());
    } catch (e) {
      print('خطأ في إضافة الحرفة: $e');
      rethrow;
    }
  }

  /// تحديث حرفة موجودة
  Future<void> updateCraft(CraftModel craft) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(craft.id)
          .update(craft.toJson());
    } catch (e) {
      print('خطأ في تحديث الحرفة: $e');
      rethrow;
    }
  }

  /// حذف حرفة (تعطيلها)
  Future<void> deleteCraft(String craftId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(craftId)
          .update({'isActive': false});
    } catch (e) {
      print('خطأ في حذف الحرفة: $e');
      rethrow;
    }
  }

  /// الحصول على القيم الافتراضية (fallback)
  List<CraftModel> _getDefaultCrafts() {
    return [
      CraftModel(
        id: 'carpenter',
        value: 'carpenter',
        translations: {'ar': 'عطل نجارة', 'en': 'Carpentry Problem'},
        order: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CraftModel(
        id: 'electrical',
        value: 'electrical',
        translations: {'ar': 'عطل كهربائي', 'en': 'Electrical Problem'},
        order: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CraftModel(
        id: 'plumbing',
        value: 'plumbing',
        translations: {'ar': 'عطل سباكة', 'en': 'Plumbing Problem'},
        order: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CraftModel(
        id: 'painter',
        value: 'painter',
        translations: {'ar': 'عطل دهان', 'en': 'Painting Problem'},
        order: 4,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CraftModel(
        id: 'mechanic',
        value: 'mechanic',
        translations: {'ar': 'عطل ميكانيكي', 'en': 'Mechanical Problem'},
        order: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CraftModel(
        id: 'hvac',
        value: 'hvac',
        translations: {'ar': 'عطل تكييف', 'en': 'HVAC Problem'},
        order: 6,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CraftModel(
        id: 'satellite',
        value: 'satellite',
        translations: {'ar': 'عطل ستالايت', 'en': 'Satellite Problem'},
        order: 7,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CraftModel(
        id: 'internet',
        value: 'internet',
        translations: {'ar': 'عطل إنترنت', 'en': 'Internet Problem'},
        order: 8,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CraftModel(
        id: 'tiler',
        value: 'tiler',
        translations: {'ar': 'عطل بلاط', 'en': 'Tiling Problem'},
        order: 9,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CraftModel(
        id: 'locksmith',
        value: 'locksmith',
        translations: {'ar': 'عطل أقفال', 'en': 'Locksmith Problem'},
        order: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  /// الحصول على القيم الافتراضية كـ Map
  List<Map<String, String>> _getDefaultCraftsAsMap(String languageCode) {
    final crafts = _getDefaultCrafts();
    return crafts.map((craft) {
      return {
        'value': craft.value,
        'label': craft.getDisplayName(languageCode),
      };
    }).toList();
  }
}

