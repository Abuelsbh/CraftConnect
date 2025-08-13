import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:location/location.dart' as location_package;
import 'package:geocoding/geocoding.dart';
import '../Models/chat_model.dart';

class MediaService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();
  final location_package.Location _location = location_package.Location();

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
        return await _uploadImageToStorage(image.path);
      }
      return null;
    } catch (e) {
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
        return await _uploadImageToStorage(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('فشل في التقاط الصورة: $e');
    }
  }

  // رفع ملف
  Future<Map<String, String>?> uploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileSize = result.files.single.size.toString();

        final downloadUrl = await _uploadFileToStorage(file.path, fileName);
        
        return {
          'url': downloadUrl,
          'name': fileName,
          'size': fileSize,
        };
      }
      return null;
    } catch (e) {
      throw Exception('فشل في رفع الملف: $e');
    }
  }

  // رفع رسالة صوتية
  Future<String?> uploadVoiceMessage(String audioPath) async {
    try {
      return await _uploadAudioToStorage(audioPath);
    } catch (e) {
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
      final file = File(imagePath);
      final fileName = '${_uuid.v4()}_${path.basename(imagePath)}';
      final ref = _storage.ref().child('chat_images/$fileName');
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('فشل في رفع الصورة: $e');
    }
  }

  // رفع ملف إلى Firebase Storage
  Future<String> _uploadFileToStorage(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      final storageFileName = '${_uuid.v4()}_$fileName';
      final ref = _storage.ref().child('chat_files/$storageFileName');
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('فشل في رفع الملف: $e');
    }
  }

  // رفع رسالة صوتية إلى Firebase Storage
  Future<String> _uploadAudioToStorage(String audioPath) async {
    try {
      final file = File(audioPath);
      final fileName = '${_uuid.v4()}_${path.basename(audioPath)}';
      final ref = _storage.ref().child('chat_voice/$fileName');
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
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