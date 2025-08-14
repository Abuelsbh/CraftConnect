import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart' as location_package;
import 'package:geocoding/geocoding.dart';
import 'package:uuid/uuid.dart';
import '../Models/artisan_model.dart';

class ArtisanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final location_package.Location _location = location_package.Location();
  final Uuid _uuid = const Uuid();

  // تسجيل حرفي جديد
  Future<ArtisanModel?> registerArtisan({
    required String name,
    required String email,
    required String phone,
    required String craftType,
    required int yearsOfExperience,
    required String description,
    String? profileImagePath,
    List<String>? galleryImagePaths,
  }) async {
    try {
      // التحقق من أن المستخدم مسجل دخول
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      // الحصول على الموقع الحالي
      final locationData = await _getCurrentLocation();
      if (locationData == null) {
        throw Exception('فشل في الحصول على الموقع');
      }

      // رفع صورة الملف الشخصي
      String profileImageUrl = '';
      if (profileImagePath != null) {
        profileImageUrl = await uploadImage(profileImagePath, 'profile');
      }

      // رفع صور المعرض
      List<String> galleryImages = [];
      if (galleryImagePaths != null && galleryImagePaths.isNotEmpty) {
        for (String imagePath in galleryImagePaths) {
          final imageUrl = await uploadImage(imagePath, 'gallery');
          galleryImages.add(imageUrl);
        }
      }

      // إنشاء معرف فريد للحرفي
      final artisanId = _uuid.v4();

      // إنشاء نموذج الحرفي
      final artisan = ArtisanModel(
        id: artisanId,
        name: name,
        email: email,
        phone: phone,
        profileImageUrl: profileImageUrl,
        craftType: craftType,
        yearsOfExperience: yearsOfExperience,
        description: description,
        latitude: locationData['latitude'],
        longitude: locationData['longitude'],
        address: locationData['address'],
        galleryImages: galleryImages,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // حفظ الحرفي في Firestore
      await _firestore
          .collection('artisans')
          .doc(artisanId)
          .set(artisan.toJson());

      // ربط الحرفي بالمستخدم
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
        'artisanId': artisanId,
        'userType': 'artisan',
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return artisan;
    } catch (e) {
      throw Exception('فشل في تسجيل الحرفي: $e');
    }
  }

  // الحصول على جميع الحرفيين
  Future<List<ArtisanModel>> getAllArtisans() async {
    try {
      final snapshot = await _firestore
          .collection('artisans')
          .where('isAvailable', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => ArtisanModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('فشل في جلب الحرفيين: $e');
    }
  }

  // الحصول على الحرفيين حسب النوع
  Future<List<ArtisanModel>> getArtisansByCraftType(String craftType) async {
    try {
      Query query = _firestore
          .collection('artisans')
          .where('isAvailable', isEqualTo: true);

      if (craftType != 'all') {
        query = query.where('craftType', isEqualTo: craftType);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => ArtisanModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('فشل في جلب الحرفيين: $e');
    }
  }

  // الحصول على حرفي واحد
  Future<ArtisanModel?> getArtisanById(String artisanId) async {
    try {
      final doc = await _firestore
          .collection('artisans')
          .doc(artisanId)
          .get();

      if (doc.exists) {
        return ArtisanModel.fromJson(doc.data()! as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('فشل في جلب الحرفي: $e');
    }
  }

  // تحديث بيانات الحرفي
  Future<void> updateArtisan(ArtisanModel artisan) async {
    try {
      await _firestore
          .collection('artisans')
          .doc(artisan.id)
          .update({
        ...artisan.toJson(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('فشل في تحديث الحرفي: $e');
    }
  }

  // حذف الحرفي
  Future<void> deleteArtisan(String artisanId) async {
    try {
      await _firestore
          .collection('artisans')
          .doc(artisanId)
          .delete();
    } catch (e) {
      throw Exception('فشل في حذف الحرفي: $e');
    }
  }

  // البحث عن الحرفيين حسب الموقع
  Future<List<ArtisanModel>> searchArtisansByLocation({
    required double latitude,
    required double longitude,
    required double radiusInKm,
    String? craftType,
  }) async {
    try {
      // حساب حدود البحث
      final latDelta = radiusInKm / 111.0; // تقريباً 111 كم لكل درجة
      final lngDelta = radiusInKm / (111.0 * cos(latitude * pi / 180));

      Query query = _firestore
          .collection('artisans')
          .where('isAvailable', isEqualTo: true)
          .where('latitude', isGreaterThanOrEqualTo: latitude - latDelta)
          .where('latitude', isLessThanOrEqualTo: latitude + latDelta);

      if (craftType != null && craftType != 'all') {
        query = query.where('craftType', isEqualTo: craftType);
      }

      final snapshot = await query.get();

      // تصفية النتائج حسب المسافة
      final artisans = snapshot.docs
          .map((doc) => ArtisanModel.fromJson(doc.data() as Map<String, dynamic>))
          .where((artisan) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          artisan.latitude,
          artisan.longitude,
        );
        return distance <= radiusInKm;
      }).toList();

      // ترتيب حسب المسافة
      artisans.sort((a, b) {
        final distanceA = _calculateDistance(
          latitude,
          longitude,
          a.latitude,
          a.longitude,
        );
        final distanceB = _calculateDistance(
          latitude,
          longitude,
          b.latitude,
          b.longitude,
        );
        return distanceA.compareTo(distanceB);
      });

      return artisans;
    } catch (e) {
      throw Exception('فشل في البحث عن الحرفيين: $e');
    }
  }

  // الحصول على الموقع الحالي
  Future<Map<String, dynamic>?> _getCurrentLocation() async {
    try {
      // التحقق من صلاحيات الموقع
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          throw Exception('خدمة الموقع غير متاحة');
        }
      }

      location_package.PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == location_package.PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != location_package.PermissionStatus.granted) {
          throw Exception('تم رفض صلاحية الموقع');
        }
      }

      // الحصول على الموقع
      location_package.LocationData locationData = await _location.getLocation();
      
      // الحصول على العنوان
      String address = '';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          locationData.latitude!,
          locationData.longitude!,
        );
        
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          address = '${place.street}, ${place.locality}, ${place.country}';
        }
      } catch (e) {
        address = '${locationData.latitude}, ${locationData.longitude}';
      }

      return {
        'latitude': locationData.latitude!,
        'longitude': locationData.longitude!,
        'address': address,
      };
    } catch (e) {
      throw Exception('فشل في الحصول على الموقع: $e');
    }
  }

  // رفع صورة
  Future<String> uploadImage(String imagePath, String folder) async {
    try {
      // التحقق من وجود الملف
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('الملف غير موجود: $imagePath');
      }

      // التحقق من حجم الملف (أقل من 10 ميجابايت)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('حجم الملف كبير جداً (الحد الأقصى 10 ميجابايت)');
      }

      // إنشاء اسم فريد للملف
      final fileName = '${_uuid.v4()}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('artisans/$folder/$fileName');
      
      // رفع الملف مع مراقبة التقدم
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'originalPath': imagePath,
          },
        ),
      );

      // انتظار اكتمال الرفع
      final snapshot = await uploadTask;
      
      // التحقق من نجاح الرفع
      if (snapshot.state != TaskState.success) {
        throw Exception('فشل في رفع الصورة: ${snapshot.state}');
      }

      // الحصول على رابط التحميل
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('فشل في رفع الصورة: لا توجد صلاحية للرفع');
      } else if (e.toString().contains('unauthenticated')) {
        throw Exception('فشل في رفع الصورة: يجب تسجيل الدخول');
      } else if (e.toString().contains('network')) {
        throw Exception('فشل في رفع الصورة: مشكلة في الاتصال بالإنترنت');
      } else {
        throw Exception('فشل في رفع الصورة: $e');
      }
    }
  }

  // رفع صورة (دالة خاصة للاستخدام الداخلي)
  Future<String> _uploadImage(String imagePath, String folder) async {
    try {
      // التحقق من وجود الملف
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('الملف غير موجود: $imagePath');
      }

      // التحقق من حجم الملف (أقل من 10 ميجابايت)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('حجم الملف كبير جداً (الحد الأقصى 10 ميجابايت)');
      }

      // إنشاء اسم فريد للملف
      final fileName = '${_uuid.v4()}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('artisans/$folder/$fileName');
      
      // رفع الملف مع مراقبة التقدم
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'originalPath': imagePath,
          },
        ),
      );

      // انتظار اكتمال الرفع
      final snapshot = await uploadTask;
      
      // التحقق من نجاح الرفع
      if (snapshot.state != TaskState.success) {
        throw Exception('فشل في رفع الصورة: ${snapshot.state}');
      }

      // الحصول على رابط التحميل
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('فشل في رفع الصورة: لا توجد صلاحية للرفع');
      } else if (e.toString().contains('unauthenticated')) {
        throw Exception('فشل في رفع الصورة: يجب تسجيل الدخول');
      } else if (e.toString().contains('network')) {
        throw Exception('فشل في رفع الصورة: مشكلة في الاتصال بالإنترنت');
      } else {
        throw Exception('فشل في رفع الصورة: $e');
      }
    }
  }

  // حساب المسافة بين نقطتين
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // نصف قطر الأرض بالكيلومترات
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // اختيار صورة من المعرض
  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      return image?.path;
    } catch (e) {
      throw Exception('فشل في اختيار الصورة: $e');
    }
  }

  // التقاط صورة بالكاميرا
  Future<String?> takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      return image?.path;
    } catch (e) {
      throw Exception('فشل في التقاط الصورة: $e');
    }
  }

  // اختيار صور متعددة للمعرض
  Future<List<String>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      return images.map((image) => image.path).toList();
    } catch (e) {
      throw Exception('فشل في اختيار الصور: $e');
    }
  }
} 