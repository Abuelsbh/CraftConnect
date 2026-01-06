import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import '../Models/fault_report_model.dart';

class FaultService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final FirebaseStorage _storage;
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();
  final InternetConnection _connectionChecker = InternetConnection();

  // Firebase Storage REST API URL
  static const String _firebaseStorageBaseUrl = 'https://firebasestorage.googleapis.com/v0/b/parking-4d91a.appspot.com/o';

  FaultService() {
    _storage = FirebaseStorage.instance;
    _configureFirebaseStorage();
  }

  void _configureFirebaseStorage() {
    try {
      _storage.setMaxUploadRetryTime(const Duration(minutes: 5));
      _storage.setMaxDownloadRetryTime(const Duration(minutes: 2));
      _storage.setMaxOperationRetryTime(const Duration(minutes: 3));
      print('✅ تم تكوين Firebase Storage بنجاح');
    } catch (e) {
      print('⚠️ تحذير في تكوين Firebase Storage: $e');
    }
  }

  // فحص اتصال الإنترنت
  Future<bool> _checkInternetConnection() async {
    try {
      // استخدام internet_connection_checker_plus للتحقق من الاتصال الفعلي بالإنترنت
      // هذا يعمل على جميع المنصات بما فيها الويب
      // إضافة timeout لتجنب الانتظار الطويل
      try {
        final hasConnection = await _connectionChecker.hasInternetAccess
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                print('⚠️ انتهت مهلة فحص الاتصال بالإنترنت - سيتم المتابعة');
                return true; // افتراض وجود اتصال في حالة timeout
              },
            );
        
        if (hasConnection) {
          print('✅ تم التحقق من الاتصال بالإنترنت بنجاح');
          return true;
        } else {
          print('⚠️ لا يوجد اتصال بالإنترنت');
          return false;
        }
      } on TimeoutException {
        print('⚠️ انتهت مهلة فحص الاتصال بالإنترنت - سيتم المتابعة');
        return true; // افتراض وجود اتصال في حالة timeout
      }
    } catch (e) {
      print('⚠️ خطأ في فحص الاتصال بالإنترنت: $e');
      // في حالة الخطأ، نفترض أن الاتصال موجود ونحاول المتابعة
      // لأن بعض الأخطاء قد تكون بسبب إعدادات الشبكة وليس عدم وجود اتصال
      // Firebase SDK نفسه سيفشل إذا لم يكن هناك اتصال حقيقي
      print('ℹ️ سيتم المتابعة على افتراض وجود اتصال بالإنترنت');
      return true;
    }
  }

  // رفع الملف باستخدام HTTP REST API كبديل
  Future<String> _uploadFileViaHttp({
    required File file,
    required String fileName,
    required String folder,
    String contentType = 'application/octet-stream',
  }) async {
    try {
      print('🌐 بدء رفع الملف عبر HTTP API: $fileName');
      
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      // الحصول على Access Token
      final idToken = await user.getIdToken();

      // قراءة بيانات الملف
      final fileBytes = await file.readAsBytes();
      final filePath = '$folder%2F$fileName'; // URL encoded path
      
      // رفع الملف عبر REST API
      final uploadUrl = '$_firebaseStorageBaseUrl/$filePath?uploadType=media';
      
      final response = await http.post(
        Uri.parse(uploadUrl),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': contentType,
          'Content-Length': '${fileBytes.length}',
        },
        body: fileBytes,
      ).timeout(const Duration(minutes: 10));

      if (response.statusCode == 200) {
        // الحصول على Download URL
        final downloadUrlResponse = await http.get(
          Uri.parse('$_firebaseStorageBaseUrl/$filePath'),
          headers: {
            'Authorization': 'Bearer $idToken',
          },
        );

        if (downloadUrlResponse.statusCode == 200) {
          final responseData = json.decode(downloadUrlResponse.body);
          final downloadUrl = responseData['downloadTokens'] != null
              ? '$_firebaseStorageBaseUrl/$filePath?alt=media&token=${responseData['downloadTokens']}'
              : '$_firebaseStorageBaseUrl/$filePath?alt=media';
          
          print('✅ تم رفع الملف بنجاح عبر HTTP: $downloadUrl');
          return downloadUrl;
        } else {
          throw Exception('فشل في الحصول على رابط التحميل');
        }
      } else {
        throw Exception('فشل في رفع الملف: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ خطأ في رفع الملف عبر HTTP: $e');
      rethrow;
    }
  }

  // رفع صورة مع fallback إلى HTTP API
  Future<String> uploadImage(String imagePath, String folder) async {
    int retryCount = 0;
    const maxRetries = 3;
    bool useHttpFallback = false;
    
    while (retryCount < maxRetries) {
      try {
        print('📸 بدء رفع الصورة (محاولة ${retryCount + 1}/$maxRetries): $imagePath');
        
        // فحص اتصال الإنترنت
        final hasInternet = await _checkInternetConnection();
        if (!hasInternet) {
          throw Exception('لا يوجد اتصال بالإنترنت');
        }

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

        // فحص حجم الملف
        final file = File(imagePath);
        if (!await file.exists()) {
          throw Exception('الملف غير موجود');
        }

        final fileSize = await file.length();
        if (fileSize > 20 * 1024 * 1024) { // 20MB
          throw Exception('حجم الصورة كبير جداً (الحد الأقصى 20MB)');
        }

        if (fileSize == 0) {
          throw Exception('الملف فارغ');
        }

        final fileName = '${_uuid.v4()}.jpg';
        
        // إذا كان في المحاولة الأولى أو الثانية، استخدم Firebase SDK
        // في المحاولة الثالثة، استخدم HTTP API
        if (retryCount < 2 && !useHttpFallback) {
          try {
            final ref = _storage.ref().child(folder).child(fileName);
            
            final metadata = SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {
                'uploaded_by': user.uid,
                'upload_timestamp': DateTime.now().toIso8601String(),
              },
            );

            final uploadTask = ref.putFile(file, metadata);
            
            uploadTask.snapshotEvents.listen(
              (TaskSnapshot snapshot) {
                final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
                print('📤 تقدم رفع الصورة: ${progress.toStringAsFixed(1)}%');
              },
              onError: (error) {
                print('❌ خطأ في مراقبة التقدم: $error');
              },
            );

            final snapshot = await uploadTask.timeout(
              const Duration(minutes: 5),
              onTimeout: () {
                uploadTask.cancel();
                throw Exception('انتهت مهلة رفع الصورة');
              },
            );

            if (snapshot.state != TaskState.success) {
              throw Exception('فشل في رفع الصورة: ${snapshot.state}');
            }

            final downloadUrl = await ref.getDownloadURL();
            print('✅ تم رفع الصورة بنجاح عبر Firebase SDK: $downloadUrl');
            return downloadUrl;
            
          } catch (e) {
            if (e.toString().contains('channel-error') || 
                e.toString().contains('Unable to establish connection')) {
              print('🔄 خطأ Channel detected، التبديل إلى HTTP API...');
              useHttpFallback = true;
              throw e; // إعادة رمي الخطأ للمحاولة مرة أخرى
            } else {
              throw e;
            }
          }
        } else {
          // استخدام HTTP API كبديل
          print('🌐 استخدام HTTP API لرفع الصورة...');
          return await _uploadFileViaHttp(
            file: file,
            fileName: fileName,
            folder: folder,
            contentType: 'image/jpeg',
          );
        }
        
    } catch (e) {
        retryCount++;
        print('❌ خطأ في رفع الصورة (محاولة $retryCount): $e');
        
        // إذا كان خطأ Channel، فعّل HTTP fallback فوراً
        if (e.toString().contains('channel-error') || 
            e.toString().contains('Unable to establish connection')) {
          print('🔧 تفعيل HTTP fallback بسبب Channel error...');
          useHttpFallback = true;
        }
        
        if (retryCount >= maxRetries) {
          throw Exception('فشل في رفع الصورة بعد $maxRetries محاولات: $e');
  }

        // انتظار قبل المحاولة التالية
        final waitTime = useHttpFallback ? 2 : (3 * retryCount);
        print('⏳ انتظار $waitTime ثواني قبل المحاولة التالية...');
        await Future.delayed(Duration(seconds: waitTime));
      }
    }
    
    throw Exception('فشل في رفع الصورة');
  }

  // رفع التسجيل الصوتي مع fallback إلى HTTP API
  Future<String> uploadVoiceRecording(String voicePath, String folder) async {
    int retryCount = 0;
    const maxRetries = 3;
    bool useHttpFallback = false;
    
    while (retryCount < maxRetries) {
      try {
        print('🎤 بدء رفع التسجيل الصوتي (محاولة ${retryCount + 1}/$maxRetries): $voicePath');
        
        // فحص اتصال الإنترنت
        final hasInternet = await _checkInternetConnection();
        if (!hasInternet) {
          throw Exception('لا يوجد اتصال بالإنترنت');
        }

        final user = _auth.currentUser;
        if (user == null) {
          throw Exception('يجب تسجيل الدخول أولاً');
        }

        // فحص الملف
        final file = File(voicePath);
        if (!await file.exists()) {
          throw Exception('ملف التسجيل غير موجود');
        }

        final fileSize = await file.length();
        if (fileSize > 20 * 1024 * 1024) { // 20MB
          throw Exception('حجم التسجيل كبير جداً (الحد الأقصى 20MB)');
        }

        if (fileSize == 0) {
          throw Exception('ملف التسجيل فارغ');
        }

        // تحديد امتداد الملف
        final extension = voicePath.split('.').last.toLowerCase();
        final fileName = '${_uuid.v4()}.$extension';
        
        // محاولة Firebase SDK أولاً، ثم HTTP API
        if (retryCount < 2 && !useHttpFallback) {
          try {
            final ref = _storage.ref().child(folder).child(fileName);
            
            final metadata = SettableMetadata(
              contentType: _getAudioContentType(extension),
              customMetadata: {
                'uploaded_by': user.uid,
                'upload_timestamp': DateTime.now().toIso8601String(),
              },
            );

            final uploadTask = ref.putFile(file, metadata);
            
            uploadTask.snapshotEvents.listen(
              (TaskSnapshot snapshot) {
                final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
                print('📤 تقدم رفع التسجيل: ${progress.toStringAsFixed(1)}%');
              },
              onError: (error) {
                print('❌ خطأ في مراقبة التقدم: $error');
              },
            );

            final snapshot = await uploadTask.timeout(
              const Duration(minutes: 15),
              onTimeout: () {
                uploadTask.cancel();
                throw Exception('انتهت مهلة رفع التسجيل الصوتي');
              },
            );

            if (snapshot.state != TaskState.success) {
              throw Exception('فشل في رفع التسجيل الصوتي: ${snapshot.state}');
            }

            final downloadUrl = await ref.getDownloadURL();
            print('✅ تم رفع التسجيل الصوتي بنجاح عبر Firebase SDK: $downloadUrl');
            return downloadUrl;
            
    } catch (e) {
            if (e.toString().contains('channel-error') || 
                e.toString().contains('Unable to establish connection')) {
              print('🔄 خطأ Channel detected، التبديل إلى HTTP API...');
              useHttpFallback = true;
              throw e;
            } else {
              throw e;
    }
  }
        } else {
          // استخدام HTTP API كبديل
          print('🌐 استخدام HTTP API لرفع التسجيل الصوتي...');
          return await _uploadFileViaHttp(
            file: file,
            fileName: fileName,
            folder: folder,
            contentType: _getAudioContentType(extension),
          );
        }
        
    } catch (e) {
        retryCount++;
        print('❌ خطأ في رفع التسجيل الصوتي (محاولة $retryCount): $e');
        
        // إذا كان خطأ Channel، فعّل HTTP fallback فوراً
        if (e.toString().contains('channel-error') || 
            e.toString().contains('Unable to establish connection')) {
          print('🔧 تفعيل HTTP fallback بسبب Channel error...');
          useHttpFallback = true;
        }
        
        if (retryCount >= maxRetries) {
          throw Exception('فشل في رفع التسجيل الصوتي بعد $maxRetries محاولات: $e');
        }
        
        final waitTime = useHttpFallback ? 3 : (5 * retryCount);
        print('⏳ انتظار $waitTime ثواني قبل المحاولة التالية...');
        await Future.delayed(Duration(seconds: waitTime));
      }
    }
    
    throw Exception('فشل في رفع التسجيل الصوتي');
  }

  // تحديد نوع المحتوى للملفات الصوتية
  String _getAudioContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'aac':
        return 'audio/aac';
      case 'm4a':
        return 'audio/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      default:
        return 'audio/mpeg';
    }
  }

  // تحسين ملف الصوت
  Future<String> _optimizeAudioFile(String audioPath) async {
    try {
      // يمكن إضافة تحسين الصوت هنا
      // للآن سنعيد نفس المسار
      return audioPath;
    } catch (e) {
      print('❌ خطأ في تحسين ملف الصوت: $e');
      return audioPath;
    }
  }

  // اختيار الصور من المعرض
  Future<List<String>> pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      return images.map((image) => image.path).toList();
    } catch (e) {
      print('خطأ في اختيار الصور: $e');
      return [];
    }
  }

  // اختيار صورة واحدة من الكاميرا
  Future<String?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
      return image?.path;
    } catch (e) {
      print('خطأ في التقاط الصورة: $e');
      return null;
    }
  }

  // حذف تقرير عطل
  Future<bool> deleteFaultReport(String faultId) async {
    try {
      await _firestore.collection('fault_reports').doc(faultId).delete();
      return true;
    } catch (e) {
      print('خطأ في حذف تقرير العطل: $e');
      return false;
    }
  }

  // الحصول على تقرير عطل محدد
  Future<FaultReportModel?> getFaultReport(String faultId) async {
    try {
      final doc = await _firestore.collection('fault_reports').doc(faultId).get();
      if (doc.exists) {
        return FaultReportModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('خطأ في الحصول على تقرير العطل: $e');
      return null;
    }
  }

  // رفع فيديو
  Future<String> uploadVideo(String videoPath, String folder) async {
    int retryCount = 0;
    const maxRetries = 3;
    bool useHttpFallback = false;
    
    while (retryCount < maxRetries) {
      try {
        print('🎥 بدء رفع الفيديو (محاولة ${retryCount + 1}/$maxRetries): $videoPath');
        
        final hasInternet = await _checkInternetConnection();
        if (!hasInternet) {
          throw Exception('لا يوجد اتصال بالإنترنت');
        }

        final user = _auth.currentUser;
        if (user == null) {
          throw Exception('يجب تسجيل الدخول أولاً');
        }

        final file = File(videoPath);
        if (!await file.exists()) {
          throw Exception('ملف الفيديو غير موجود');
        }

        final fileSize = await file.length();
        if (fileSize > 100 * 1024 * 1024) { // 100MB
          throw Exception('حجم الفيديو كبير جداً (الحد الأقصى 100MB)');
        }

        if (fileSize == 0) {
          throw Exception('ملف الفيديو فارغ');
        }

        final fileName = '${_uuid.v4()}.mp4';
        
        if (retryCount < 2 && !useHttpFallback) {
          try {
            final ref = _storage.ref().child(folder).child(fileName);
            
            final metadata = SettableMetadata(
              contentType: 'video/mp4',
              customMetadata: {
                'uploaded_by': user.uid,
                'upload_timestamp': DateTime.now().toIso8601String(),
              },
            );

            final uploadTask = ref.putFile(file, metadata);
            
            uploadTask.snapshotEvents.listen(
              (TaskSnapshot snapshot) {
                final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
                print('📤 تقدم رفع الفيديو: ${progress.toStringAsFixed(1)}%');
              },
              onError: (error) {
                print('❌ خطأ في مراقبة التقدم: $error');
              },
            );

            final snapshot = await uploadTask.timeout(
              const Duration(minutes: 10),
              onTimeout: () {
                uploadTask.cancel();
                throw Exception('انتهت مهلة رفع الفيديو');
              },
            );

            if (snapshot.state != TaskState.success) {
              throw Exception('فشل في رفع الفيديو: ${snapshot.state}');
            }

            final downloadUrl = await ref.getDownloadURL();
            print('✅ تم رفع الفيديو بنجاح عبر Firebase SDK: $downloadUrl');
            return downloadUrl;
            
          } catch (e) {
            if (e.toString().contains('channel-error') || 
                e.toString().contains('Unable to establish connection')) {
              print('🔄 خطأ Channel detected، التبديل إلى HTTP API...');
              useHttpFallback = true;
              throw e;
            } else {
              throw e;
            }
          }
        } else {
          print('🌐 استخدام HTTP API لرفع الفيديو...');
          return await _uploadFileViaHttp(
            file: file,
            fileName: fileName,
            folder: folder,
            contentType: 'video/mp4',
          );
        }
        
      } catch (e) {
        retryCount++;
        print('❌ خطأ في رفع الفيديو (محاولة $retryCount): $e');
        
        if (e.toString().contains('channel-error') || 
            e.toString().contains('Unable to establish connection')) {
          print('🔧 تفعيل HTTP fallback بسبب Channel error...');
          useHttpFallback = true;
        }
        
        if (retryCount >= maxRetries) {
          throw Exception('فشل في رفع الفيديو بعد $maxRetries محاولات: $e');
        }

        final waitTime = useHttpFallback ? 2 : (3 * retryCount);
        print('⏳ انتظار $waitTime ثواني قبل المحاولة التالية...');
        await Future.delayed(Duration(seconds: waitTime));
      }
    }
    
    throw Exception('فشل في رفع الفيديو');
  }

  // إنشاء تقرير عطل جديد
  Future<FaultReportModel?> createFaultReport({
    required String faultType,
    required String serviceType,
    required String description,
    List<String>? imagePaths,
    String? voiceRecordingPath,
    String? videoPath,
    bool isScheduled = false,
    DateTime? scheduledDate,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    try {
      print('🚀 بدء إنشاء تقرير العطل...');
      
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        throw Exception('لا يوجد اتصال بالإنترنت');
      }
      
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      final faultId = _uuid.v4();
      final now = DateTime.now();
      
      print('📝 تفاصيل التقرير:');
      print('   - المستخدم: ${user.uid}');
      print('   - نوع العطل: $faultType');
      print('   - نوع الخدمة: $serviceType');
      print('   - الوصف: $description');
      print('   - عدد الصور: ${imagePaths?.length ?? 0}');
      print('   - مسار التسجيل الصوتي: $voiceRecordingPath');
      print('   - مسار الفيديو: $videoPath');
      print('   - مجدول: $isScheduled');

      // رفع الصور
      List<String> imageUrls = [];
      if (imagePaths != null && imagePaths.isNotEmpty) {
        print('📸 بدء رفع الصور...');
        for (int i = 0; i < imagePaths.length; i++) {
          try {
            print('📤 رفع الصورة ${i + 1}/${imagePaths.length}: ${imagePaths[i]}');
            final imageUrl = await uploadImage(imagePaths[i], 'fault_images');
            imageUrls.add(imageUrl);
            print('✅ تم رفع الصورة ${i + 1}: $imageUrl');
          } catch (e) {
            print('❌ فشل في رفع الصورة ${i + 1}: $e');
            print('⚠️ سيتم تخطي الصورة ${i + 1} والمتابعة');
          }
        }
        print('✅ تم رفع ${imageUrls.length} من ${imagePaths.length} صورة');
      }

      // رفع التسجيل الصوتي
      String? voiceRecordingUrl;
      if (voiceRecordingPath != null) {
        try {
          print('🎤 بدء رفع التسجيل الصوتي...');
          
          final file = File(voiceRecordingPath);
          if (await file.exists()) {
            final fileSize = await file.length();
            print('📊 حجم ملف التسجيل: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
            
            if (fileSize > 20 * 1024 * 1024) {
              print('⚠️ ملف التسجيل كبير جداً، سيتم تخطيه');
              voiceRecordingUrl = null;
            } else {
              voiceRecordingUrl = await uploadVoiceRecording(voiceRecordingPath, 'voice_recordings');
              print('✅ تم رفع التسجيل الصوتي بنجاح');
            }
          } else {
            print('⚠️ ملف التسجيل غير موجود، سيتم تخطيه');
            voiceRecordingUrl = null;
          }
        } catch (e) {
          print('❌ فشل في رفع التسجيل الصوتي: $e');
          print('⚠️ سيتم إنشاء التقرير بدون التسجيل الصوتي');
          voiceRecordingUrl = null;
        }
      }

      // رفع الفيديو
      String? videoUrl;
      if (videoPath != null) {
        try {
          print('🎥 بدء رفع الفيديو...');
          
          final file = File(videoPath);
          if (await file.exists()) {
            final fileSize = await file.length();
            print('📊 حجم ملف الفيديو: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
            
            if (fileSize > 100 * 1024 * 1024) {
              print('⚠️ ملف الفيديو كبير جداً، سيتم تخطيه');
              videoUrl = null;
            } else {
              videoUrl = await uploadVideo(videoPath, 'fault_videos');
              print('✅ تم رفع الفيديو بنجاح');
            }
          } else {
            print('⚠️ ملف الفيديو غير موجود، سيتم تخطيه');
            videoUrl = null;
          }
        } catch (e) {
          print('❌ فشل في رفع الفيديو: $e');
          print('⚠️ سيتم إنشاء التقرير بدون الفيديو');
          videoUrl = null;
        }
      }

      print('💾 حفظ التقرير في Firestore...');
      final faultReport = FaultReportModel(
        id: faultId,
        userId: user.uid,
        faultType: faultType,
        serviceType: serviceType,
        description: description,
        imageUrls: imageUrls,
        voiceRecordingUrl: voiceRecordingUrl,
        videoUrl: videoUrl,
        isScheduled: isScheduled,
        scheduledDate: scheduledDate,
        status: FaultStatus.pending.value,
        address: address,
        latitude: latitude,
        longitude: longitude,
        createdAt: now,
        updatedAt: now,
        isActive: true,
      );

      await _firestore
          .collection('fault_reports')
          .doc(faultId)
          .set(faultReport.toJson())
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('انتهت مهلة حفظ التقرير في قاعدة البيانات');
            },
          );

      print('✅ تم إنشاء تقرير العطل بنجاح: $faultId');
      print('📊 ملخص التقرير:');
      print('   - المستخدم: ${user.uid}');
      print('   - الصور المرفوعة: ${imageUrls.length}');
      print('   - التسجيل الصوتي: ${voiceRecordingUrl != null ? "مرفوع" : "غير مرفوع"}');
      print('   - الفيديو: ${videoUrl != null ? "مرفوع" : "غير مرفوع"}');
      
      return faultReport;
    } catch (e) {
      print('❌ خطأ في إنشاء تقرير العطل: $e');
      rethrow;
    }
  }

  Future<List<FaultReportModel>> getUserFaultReports() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      print('🔍 جلب تقارير الأعطال للمستخدم: ${user.uid}');

      QuerySnapshot querySnapshot;
      
      // محاولة الاستعلام مع orderBy أولاً
      try {
        querySnapshot = await _firestore
            .collection('fault_reports')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .get();
        
        print('✅ تم جلب التقارير باستخدام orderBy');
      } catch (orderByError) {
        // إذا فشل الاستعلام مع orderBy (مثلاً بسبب عدم وجود index)، جرب بدون orderBy
        print('⚠️ فشل الاستعلام مع orderBy: $orderByError');
        print('🔄 محاولة الاستعلام بدون orderBy...');
        
        try {
          querySnapshot = await _firestore
              .collection('fault_reports')
              .where('userId', isEqualTo: user.uid)
              .get();
          
          print('✅ تم جلب التقارير بدون orderBy');
        } catch (e) {
          print('❌ فشل الاستعلام بدون orderBy أيضاً: $e');
          rethrow;
        }
      }

      final reports = <FaultReportModel>[];
      
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          
          // إضافة id من document id إذا لم يكن موجوداً
          if (!data.containsKey('id') || data['id'] == null || data['id'] == '') {
            data['id'] = doc.id;
          }
          
          // التحقق من أن userId يطابق المستخدم الحالي
          final reportUserId = data['userId']?.toString() ?? '';
          if (reportUserId == user.uid) {
            try {
              final report = FaultReportModel.fromJson(data);
              reports.add(report);
            } catch (parseError) {
              print('⚠️ خطأ في تحليل التقرير ${doc.id}: $parseError');
              print('   البيانات: $data');
            }
          } else {
            print('⚠️ تحذير: تقرير بمعرف ${doc.id} لا يطابق المستخدم الحالي');
            print('   userId في التقرير: $reportUserId');
            print('   userId الحالي: ${user.uid}');
          }
        } catch (e) {
          print('⚠️ خطأ في معالجة التقرير ${doc.id}: $e');
        }
      }

      // ترتيب التقارير حسب التاريخ إذا لم يكن orderBy يعمل
      if (reports.isNotEmpty) {
        reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      print('✅ تم جلب ${reports.length} تقرير عطل للمستخدم ${user.uid}');
      
      // طباعة معلومات إضافية للتشخيص
      if (reports.isEmpty) {
        print('⚠️ لا توجد تقارير للمستخدم ${user.uid}');
        print('🔍 جلب جميع التقارير للتحقق...');
        try {
          final allReports = await _firestore
              .collection('fault_reports')
              .limit(5)
              .get();
          print('📊 عدد التقارير في قاعدة البيانات: ${allReports.docs.length}');
          for (var doc in allReports.docs) {
            final data = doc.data();
            print('   - تقرير ${doc.id}: userId = ${data['userId']}');
          }
        } catch (e) {
          print('⚠️ لا يمكن جلب معلومات إضافية: $e');
        }
      }
      
      return reports;
    } catch (e) {
      print('❌ خطأ في الحصول على تقارير الأعطال: $e');
      print('   نوع الخطأ: ${e.runtimeType}');
      print('   تفاصيل الخطأ: ${e.toString()}');
      return [];
    }
  }

  Future<List<FaultReportModel>> getAllFaultReports() async {
    try {
      final querySnapshot = await _firestore
          .collection('fault_reports')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FaultReportModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ خطأ في الحصول على جميع تقارير الأعطال: $e');
      return [];
    }
  }

  // جلب الأعطال حسب نوع العطل
  Future<List<FaultReportModel>> getFaultReportsByType(String faultType, {String? excludeArtisanId}) async {
    try {
      print('🔍 البحث عن أعطال من نوع: $faultType');
      
      // استخدام استعلام واحد فقط لتجنب مشاكل الفهارس المركبة
      // ثم التصفية محلياً للحالة
      final querySnapshot = await _firestore
          .collection('fault_reports')
          .where('faultType', isEqualTo: faultType)
          .orderBy('createdAt', descending: true)
          .get();

      print('📊 عدد الأعطال المطابقة للنوع: ${querySnapshot.docs.length}');

      // تصفية محلياً للأعطال في حالة pending والنشطة فقط
      final allParsedReports = querySnapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              final report = FaultReportModel.fromJson(data);
              
              // طباعة معلومات للتشخيص
              if (report.status == 'pending') {
                print('   - عطل ${doc.id}: status=${report.status}, isActive=${report.isActive}, faultType=${report.faultType}');
              }
              
              return report;
            } catch (e) {
              print('⚠️ خطأ في تحويل المستند ${doc.id}: $e');
              return null;
            }
          })
          .whereType<FaultReportModel>()
          .toList();

      // فلترة صارمة: فقط pending و isActive = true
      final reports = allParsedReports
          .where((report) {
            final isPending = report.status == 'pending';
            final isActive = report.isActive == true; // تأكيد صريح
            
            if (isPending && !isActive) {
              print('🚫 تم استبعاد عطل ${report.id}: pending لكن غير نشط (isActive=${report.isActive})');
            }
            
            if (isPending && isActive) {
              print('✅ عطل ${report.id} مقبول: pending ونشط');
            }
            
            return isPending && isActive;
          })
          .toList();

      print('✅ عدد الأعطال النشطة في حالة pending: ${reports.length} من ${allParsedReports.length}');
      
      // فحص نهائي للتأكد
      final inactiveInResults = reports.where((r) => !r.isActive).toList();
      if (inactiveInResults.isNotEmpty) {
        print('❌ خطأ: تم العثور على ${inactiveInResults.length} عطل غير نشط في النتائج!');
        reports.removeWhere((r) => !r.isActive);
      }
      
      // تصفية التقارير المرفوضة من قبل الحرفي
      if (excludeArtisanId != null && excludeArtisanId.isNotEmpty) {
        print('🔍 تصفية التقارير المرفوضة من قبل الحرفي: $excludeArtisanId');
        final filteredReports = <FaultReportModel>[];
        
        for (final report in reports) {
          final isDeclined = await isReportDeclinedByArtisan(report.id, excludeArtisanId);
          if (!isDeclined) {
            filteredReports.add(report);
          } else {
            print('🚫 تم استبعاد التقرير ${report.id} - مرفوض من قبل الحرفي');
          }
        }
        
        print('✅ عدد التقارير بعد تصفية المرفوضة: ${filteredReports.length} من ${reports.length}');
        return filteredReports;
      }
      
      return reports;
    } catch (e) {
      print('❌ خطأ في الحصول على تقارير الأعطال حسب النوع: $e');
      print('   نوع الخطأ: ${e.runtimeType}');
      
      // محاولة بديلة: جلب جميع الأعطال ثم التصفية محلياً
      try {
        print('🔄 محاولة طريقة بديلة...');
        final allReports = await getAllFaultReports();
        var filtered = allReports
            .where((report) => 
                report.faultType == faultType && 
                report.status == 'pending' &&
                report.isActive)
            .toList();
        
        // تصفية التقارير المرفوضة من قبل الحرفي في الطريقة البديلة أيضاً
        if (excludeArtisanId != null && excludeArtisanId.isNotEmpty) {
          final filteredReports = <FaultReportModel>[];
          for (final report in filtered) {
            final isDeclined = await isReportDeclinedByArtisan(report.id, excludeArtisanId);
            if (!isDeclined) {
              filteredReports.add(report);
            }
          }
          filtered = filteredReports;
        }
        
        print('✅ تم العثور على ${filtered.length} عطل نشط باستخدام الطريقة البديلة');
        return filtered;
      } catch (fallbackError) {
        print('❌ فشلت الطريقة البديلة أيضاً: $fallbackError');
        return [];
      }
    }
  }

  Future<bool> updateFaultStatus(String faultId, String status, {String? assignedArtisanId, String? notes}) async {
    try {
      await _firestore.collection('fault_reports').doc(faultId).update({
        'status': status,
        'assignedArtisanId': assignedArtisanId,
        'notes': notes,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('❌ خطأ في تحديث حالة العطل: $e');
      return false;
    }
  }

  // زيادة عدد المشاهدات للعطل
  Future<bool> incrementFaultViews(String faultId) async {
    try {
      await _firestore.collection('fault_reports').doc(faultId).update({
        'viewsCount': FieldValue.increment(1),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('❌ خطأ في تحديث عدد المشاهدات: $e');
      return false;
    }
  }

  // تحديث حالة تفعيل العطل
  Future<bool> updateFaultActiveStatus(String faultId, bool isActive) async {
    try {
      await _firestore.collection('fault_reports').doc(faultId).update({
        'isActive': isActive,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('❌ خطأ في تحديث حالة تفعيل العطل: $e');
      return false;
    }
  }

  // رفض التقرير من قبل الحرفي (سيخفي التقرير من قائمة الحرفي)
  Future<bool> declineFaultReport(String faultId, String artisanId) async {
    try {
      print('🚫 رفض التقرير $faultId من قبل الحرفي $artisanId');
      
      // إضافة سجل في subcollection لتتبع التقارير المرفوضة
      await _firestore
          .collection('fault_reports')
          .doc(faultId)
          .collection('declined_by')
          .doc(artisanId)
          .set({
        'declinedAt': DateTime.now().toIso8601String(),
        'artisanId': artisanId,
      });
      
      print('✅ تم تسجيل رفض التقرير بنجاح');
      return true;
    } catch (e) {
      print('❌ خطأ في رفض التقرير: $e');
      return false;
    }
  }

  // التحقق من رفض الحرفي للتقرير
  Future<bool> isReportDeclinedByArtisan(String faultId, String artisanId) async {
    try {
      final doc = await _firestore
          .collection('fault_reports')
          .doc(faultId)
          .collection('declined_by')
          .doc(artisanId)
          .get();
      
      return doc.exists;
    } catch (e) {
      print('❌ خطأ في التحقق من رفض التقرير: $e');
      return false;
    }
  }

  // جلب قائمة بمعرفات الحرفيين الذين رفضوا التقرير
  Future<List<String>> getDeclinedArtisanIds(String faultId) async {
    try {
      final snapshot = await _firestore
          .collection('fault_reports')
          .doc(faultId)
          .collection('declined_by')
          .get();
      
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('❌ خطأ في جلب قائمة الحرفيين الذين رفضوا التقرير: $e');
      return [];
    }
  }

  // تحديث تقرير عطل موجود
  Future<FaultReportModel?> updateFaultReport({
    required String faultId,
    String? faultType,
    String? serviceType,
    String? description,
    List<String>? imagePaths,
    String? voiceRecordingPath,
    String? videoPath,
    bool? isScheduled,
    DateTime? scheduledDate,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    try {
      print('🔄 بدء تحديث تقرير العطل: $faultId');
      
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        throw Exception('لا يوجد اتصال بالإنترنت');
      }
      
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      // الحصول على التقرير الحالي
      final currentReport = await getFaultReport(faultId);
      if (currentReport == null) {
        throw Exception('التقرير غير موجود');
      }

      // التحقق من أن المستخدم هو صاحب التقرير
      if (currentReport.userId != user.uid) {
        throw Exception('ليس لديك صلاحية لتعديل هذا التقرير');
      }

      final now = DateTime.now();
      final updateData = <String, dynamic>{
        'updatedAt': now.toIso8601String(),
      };

      // تحديث الحقول المقدمة
      if (faultType != null) {
        updateData['faultType'] = faultType;
      }
      if (serviceType != null) {
        updateData['serviceType'] = serviceType;
      }
      if (description != null) {
        updateData['description'] = description;
      }
      if (isScheduled != null) {
        updateData['isScheduled'] = isScheduled;
      }
      if (scheduledDate != null) {
        updateData['scheduledDate'] = scheduledDate.toIso8601String();
      } else if (isScheduled == false) {
        updateData['scheduledDate'] = null;
      }
      if (address != null) {
        updateData['address'] = address;
      }
      if (latitude != null) {
        updateData['latitude'] = latitude;
      }
      if (longitude != null) {
        updateData['longitude'] = longitude;
      }

      // رفع الصور الجديدة إذا كانت موجودة
      List<String> imageUrls = currentReport.imageUrls;
      if (imagePaths != null && imagePaths.isNotEmpty) {
        print('📸 بدء رفع الصور الجديدة...');
        final newImageUrls = <String>[];
        for (int i = 0; i < imagePaths.length; i++) {
          try {
            print('📤 رفع الصورة ${i + 1}/${imagePaths.length}: ${imagePaths[i]}');
            final imageUrl = await uploadImage(imagePaths[i], 'fault_images');
            newImageUrls.add(imageUrl);
            print('✅ تم رفع الصورة ${i + 1}: $imageUrl');
          } catch (e) {
            print('❌ فشل في رفع الصورة ${i + 1}: $e');
            print('⚠️ سيتم تخطي الصورة ${i + 1} والمتابعة');
          }
        }
        if (newImageUrls.isNotEmpty) {
          imageUrls = [...currentReport.imageUrls, ...newImageUrls];
          updateData['imageUrls'] = imageUrls;
        }
        print('✅ تم رفع ${newImageUrls.length} من ${imagePaths.length} صورة جديدة');
      }

      // رفع التسجيل الصوتي الجديد إذا كان موجوداً
      String? voiceRecordingUrl = currentReport.voiceRecordingUrl;
      if (voiceRecordingPath != null) {
        try {
          print('🎤 بدء رفع التسجيل الصوتي الجديد...');
          
          final file = File(voiceRecordingPath);
          if (await file.exists()) {
            final fileSize = await file.length();
            print('📊 حجم ملف التسجيل: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
            
            if (fileSize > 20 * 1024 * 1024) {
              print('⚠️ ملف التسجيل كبير جداً، سيتم تخطيه');
            } else {
              voiceRecordingUrl = await uploadVoiceRecording(voiceRecordingPath, 'voice_recordings');
              updateData['voiceRecordingUrl'] = voiceRecordingUrl;
              print('✅ تم رفع التسجيل الصوتي بنجاح');
            }
          } else {
            print('⚠️ ملف التسجيل غير موجود، سيتم تخطيه');
          }
        } catch (e) {
          print('❌ فشل في رفع التسجيل الصوتي: $e');
          print('⚠️ سيتم تحديث التقرير بدون التسجيل الصوتي');
        }
      }

      // رفع الفيديو الجديد إذا كان موجوداً
      String? videoUrl = currentReport.videoUrl;
      if (videoPath != null) {
        try {
          print('🎥 بدء رفع الفيديو الجديد...');
          
          final file = File(videoPath);
          if (await file.exists()) {
            final fileSize = await file.length();
            print('📊 حجم ملف الفيديو: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
            
            if (fileSize > 100 * 1024 * 1024) {
              print('⚠️ ملف الفيديو كبير جداً، سيتم تخطيه');
            } else {
              videoUrl = await uploadVideo(videoPath, 'fault_videos');
              updateData['videoUrl'] = videoUrl;
              print('✅ تم رفع الفيديو بنجاح');
            }
          } else {
            print('⚠️ ملف الفيديو غير موجود، سيتم تخطيه');
          }
        } catch (e) {
          print('❌ فشل في رفع الفيديو: $e');
          print('⚠️ سيتم تحديث التقرير بدون الفيديو');
        }
      }

      print('💾 تحديث التقرير في Firestore...');
      await _firestore
          .collection('fault_reports')
          .doc(faultId)
          .update(updateData)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('انتهت مهلة تحديث التقرير في قاعدة البيانات');
            },
          );

      // الحصول على التقرير المحدث
      final updatedReport = await getFaultReport(faultId);
      if (updatedReport != null) {
        print('✅ تم تحديث تقرير العطل بنجاح: $faultId');
        return updatedReport;
      } else {
        throw Exception('فشل في الحصول على التقرير المحدث');
      }
    } catch (e) {
      print('❌ خطأ في تحديث تقرير العطل: $e');
      rethrow;
    }
  }
}
