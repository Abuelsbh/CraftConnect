import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:location/location.dart' as location_package;
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../Models/chat_model.dart';

class MediaService {
  late final FirebaseStorage _storage;
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();
  final location_package.Location _location = location_package.Location();

  MediaService() {
    try {
      _storage = FirebaseStorage.instance;
      print('✅ تم تهيئة Firebase Storage في MediaService');
    } catch (e) {
      print('❌ خطأ في تهيئة Firebase Storage: $e');
      rethrow;
    }
  }

  // رفع صورة من المعرض
  Future<String?> uploadImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        print('📸 تم اختيار الصورة: ${image.path}');
        final downloadUrl = await _uploadImageToStorage(image.path);
        print('✅ تم رفع الصورة بنجاح: $downloadUrl');
        return downloadUrl;
      }
      print('❌ لم يتم اختيار صورة');
      return null;
    } catch (e) {
      print('❌ خطأ في اختيار الصورة: $e');
      throw Exception('فشل في اختيار الصورة: $e');
    }
  }

  // رفع صورة من الكاميرا
  Future<String?> uploadImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        print('📸 تم التقاط الصورة: ${image.path}');
        final downloadUrl = await _uploadImageToStorage(image.path);
        print('✅ تم رفع الصورة بنجاح: $downloadUrl');
        return downloadUrl;
      }
      print('❌ لم يتم التقاط صورة');
      return null;
    } catch (e) {
      print('❌ خطأ في التقاط الصورة: $e');
      throw Exception('فشل في التقاط الصورة: $e');
    }
  }

  // رفع أيقونة حرفة
  Future<String?> uploadCraftIcon() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (image != null) {
        print('📸 تم اختيار أيقونة الحرفة: ${image.path}');
        final downloadUrl = await _uploadCraftIconToStorage(image.path);
        print('✅ تم رفع أيقونة الحرفة بنجاح: $downloadUrl');
        return downloadUrl;
      }
      print('❌ لم يتم اختيار أيقونة');
      return null;
    } catch (e) {
      print('❌ خطأ في اختيار أيقونة الحرفة: $e');
      throw Exception('فشل في اختيار أيقونة الحرفة: $e');
    }
  }

  // رفع أيقونة حرفة إلى Firebase Storage
  Future<String> _uploadCraftIconToStorage(String imagePath) async {
    try {
      print('🚀 بدء رفع أيقونة الحرفة: $imagePath');
      
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('الملف غير موجود: $imagePath');
      }
      
      final fileName = '${_uuid.v4()}_${path.basename(imagePath)}';
      final ref = _storage.ref().child('craft_icons/$fileName');
      
      print('📤 رفع أيقونة الحرفة إلى Firebase Storage...');
      final uploadTask = ref.putFile(file);
      
      // مراقبة تقدم الرفع
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('📊 تقدم رفع الأيقونة: ${(progress * 100).toStringAsFixed(1)}%');
      });
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ تم رفع أيقونة الحرفة بنجاح: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ خطأ في رفع أيقونة الحرفة: $e');
      throw Exception('فشل في رفع أيقونة الحرفة: $e');
    }
  }

  // رفع ملف
  Future<Map<String, String>?> uploadFile() async {
    try {
      print('📁 بدء اختيار ملف...');
      
      // على Android 13+، file_picker يعمل بدون صلاحيات خاصة
      // لكن نتحقق من الصلاحيات على الأجهزة القديمة
      if (Platform.isAndroid) {
        try {
          // التحقق من صلاحيات التخزين (لأجهزة Android القديمة)
          final storageStatus = await Permission.storage.status;
          if (storageStatus.isDenied) {
            print('⚠️ صلاحية التخزين غير ممنوحة، سيتم طلبها...');
            final result = await Permission.storage.request();
            if (result.isDenied) {
              print('❌ تم رفض صلاحية التخزين');
              // نستمر على أي حال لأن file_picker قد يعمل بدونها على Android 13+
            }
          }
        } catch (e) {
          print('⚠️ خطأ في التحقق من صلاحيات التخزين: $e');
          // نستمر على أي حال
        }
      }
      
      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
          withData: false, // لا نحتاج البيانات في الذاكرة
          withReadStream: false,
        );
      } catch (e) {
        print('❌ خطأ في فتح file picker: $e');
        throw Exception('فشل في فتح محدد الملفات: $e');
      }

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.single;
        
        // التحقق من وجود مسار الملف
        if (pickedFile.path == null || pickedFile.path!.isEmpty) {
          print('❌ مسار الملف فارغ');
          throw Exception('لم يتم تحديد مسار الملف');
        }
        
        final filePath = pickedFile.path!;
        final file = File(filePath);
        
        // التحقق من وجود الملف
        if (!await file.exists()) {
          print('❌ الملف غير موجود: $filePath');
          throw Exception('الملف المحدد غير موجود');
        }
        
        // التحقق من حجم الملف
        final fileSize = await file.length();
        if (fileSize == 0) {
          print('❌ الملف فارغ');
          throw Exception('الملف المحدد فارغ');
        }
        
        final fileName = pickedFile.name.isNotEmpty 
            ? pickedFile.name 
            : path.basename(filePath);
        final fileSizeString = fileSize.toString();

        print('📁 تم اختيار الملف: $fileName (${fileSizeString} bytes)');
        print('📁 مسار الملف: $filePath');
        
        final downloadUrl = await _uploadFileToStorage(filePath, fileName);
        print('✅ تم رفع الملف بنجاح: $downloadUrl');
        
        return {
          'url': downloadUrl,
          'name': fileName,
          'size': fileSizeString,
        };
      }
      print('ℹ️ المستخدم ألغى اختيار الملف');
      return null;
    } catch (e) {
      print('❌ خطأ في رفع الملف: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // رفع رسالة صوتية
  Future<String?> uploadVoiceMessage(String audioPath) async {
    try {
      print('🎤 بدء رفع الرسالة الصوتية: $audioPath');
      final downloadUrl = await _uploadAudioToStorage(audioPath);
      print('✅ تم رفع الرسالة الصوتية بنجاح: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ خطأ في رفع الرسالة الصوتية: $e');
      throw Exception('فشل في رفع الرسالة الصوتية: $e');
    }
  }

  // الحصول على الموقع الحالي
  Future<LocationData?> getCurrentLocation() async {
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
      String? address;
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
        // إذا فشل في الحصول على العنوان، نستخدم الإحداثيات فقط
        address = '${locationData.latitude}, ${locationData.longitude}';
      }

      return LocationData(
        latitude: locationData.latitude!,
        longitude: locationData.longitude!,
        address: address,
        placeName: address,
      );
    } catch (e) {
      throw Exception('فشل في الحصول على الموقع: $e');
    }
  }

  // رفع صورة إلى Firebase Storage
  Future<String> _uploadImageToStorage(String imagePath) async {
    try {
      print('🚀 بدء رفع الصورة: $imagePath');
      
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('الملف غير موجود: $imagePath');
      }
      
      final fileName = '${_uuid.v4()}_${path.basename(imagePath)}';
      final ref = _storage.ref().child('chat_images/$fileName');
      
      print('📤 رفع الصورة إلى Firebase Storage...');
      final uploadTask = ref.putFile(file);
      
      // مراقبة تقدم الرفع
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('📊 تقدم الرفع: ${(progress * 100).toStringAsFixed(1)}%');
      });
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ تم رفع الصورة بنجاح: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ خطأ في رفع الصورة: $e');
      throw Exception('فشل في رفع الصورة: $e');
    }
  }

  // رفع ملف إلى Firebase Storage
  Future<String> _uploadFileToStorage(String filePath, String fileName) async {
    try {
      print('🚀 بدء رفع الملف: $fileName');
      
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('الملف غير موجود: $filePath');
      }
      

      
      final storageFileName = '${_uuid.v4()}_$fileName';
      final ref = _storage.ref().child('chat_files/$storageFileName');
      
      print('📤 رفع الملف إلى Firebase Storage...');
      print('📁 مسار التخزين: chat_files/$storageFileName');
      
      final uploadTask = ref.putFile(file);
      
      // مراقبة تقدم الرفع
      uploadTask.snapshotEvents.listen(
        (snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          print('📊 تقدم رفع الملف: ${(progress * 100).toStringAsFixed(1)}%');
        },
        onError: (error) {
          print('❌ خطأ في مراقبة تقدم الرفع: $error');
        },
      );
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ تم رفع الملف بنجاح: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ خطأ في رفع الملف: $e');
      if (e.toString().contains('channel-error')) {
        throw Exception('خطأ في الاتصال بـ Firebase Storage. تأكد من إعدادات Firebase');
      }
      throw Exception('فشل في رفع الملف: $e');
    }
  }

  // رفع رسالة صوتية إلى Firebase Storage
  Future<String> _uploadAudioToStorage(String audioPath) async {
    try {
      print('🚀 بدء رفع الرسالة الصوتية: $audioPath');
      
      final file = File(audioPath);
      if (!await file.exists()) {
        throw Exception('الملف الصوتي غير موجود: $audioPath');
      }
      
      final fileName = '${_uuid.v4()}_${path.basename(audioPath)}';
      final ref = _storage.ref().child('chat_voice/$fileName');
      
      print('📤 رفع الرسالة الصوتية إلى Firebase Storage...');
      final uploadTask = ref.putFile(file);
      
      // مراقبة تقدم الرفع
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('📊 تقدم رفع الرسالة الصوتية: ${(progress * 100).toStringAsFixed(1)}%');
      });
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ تم رفع الرسالة الصوتية بنجاح: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ خطأ في رفع الرسالة الصوتية: $e');
      throw Exception('فشل في رفع الرسالة الصوتية: $e');
    }
  }

  // حذف ملف من Firebase Storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('فشل في حذف الملف: $e');
    }
  }

  // الحصول على حجم الملف بتنسيق مقروء
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // الحصول على نوع الملف من الامتداد
  String getFileType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.pdf':
        return 'PDF';
      case '.doc':
      case '.docx':
        return 'Word';
      case '.xls':
      case '.xlsx':
        return 'Excel';
      case '.ppt':
      case '.pptx':
        return 'PowerPoint';
      case '.txt':
        return 'Text';
      case '.zip':
      case '.rar':
        return 'Archive';
      case '.mp3':
      case '.wav':
      case '.m4a':
        return 'Audio';
      case '.mp4':
      case '.avi':
      case '.mov':
        return 'Video';
      default:
        return 'File';
    }
  }

  // الحصول على أيقونة الملف
  String getFileIcon(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.pdf':
        return '📄';
      case '.doc':
      case '.docx':
        return '📝';
      case '.xls':
      case '.xlsx':
        return '📊';
      case '.ppt':
      case '.pptx':
        return '📈';
      case '.txt':
        return '📄';
      case '.zip':
      case '.rar':
        return '📦';
      case '.mp3':
      case '.wav':
      case '.m4a':
        return '🎵';
      case '.mp4':
      case '.avi':
      case '.mov':
        return '🎬';
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return '🖼️';
      default:
        return '📎';
    }
  }
} 