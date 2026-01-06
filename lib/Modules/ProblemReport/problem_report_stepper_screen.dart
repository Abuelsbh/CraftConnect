import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../Utilities/app_constants.dart';
import '../../Models/fault_report_model.dart';
import '../../services/fault_service.dart';
import '../../services/craft_service.dart';
import '../../services/voice_recorder_service.dart';
import '../../providers/fault_provider.dart';
import '../../providers/simple_auth_provider.dart';
import 'package:provider/provider.dart';
import '../../core/Language/locales.dart';
import '../../core/Language/app_languages.dart';
import 'widgets/step1_images_video_widget.dart';
import 'widgets/step2_fault_type_widget.dart';
import 'widgets/step3_additional_details_widget.dart';

class ProblemReportStepperScreen extends StatefulWidget {
  final String? reportId;
  
  const ProblemReportStepperScreen({super.key, this.reportId});

  @override
  State<ProblemReportStepperScreen> createState() => _ProblemReportStepperScreenState();
}

class _ProblemReportStepperScreenState extends State<ProblemReportStepperScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _descriptionController = TextEditingController();
  final VoiceRecorderService _voiceRecorderService = VoiceRecorderService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FaultService _faultService = FaultService();
  final CraftService _craftService = CraftService();
  
  int _currentStep = 0;
  List<String> _selectedImages = [];
  List<String> _existingImageUrls = []; // الصور الموجودة من التقرير الأصلي
  String? _selectedVideoPath;
  String? _existingVideoUrl; // الفيديو الموجود من التقرير الأصلي
  VideoPlayerController? _videoPlayerController;
  String _selectedFaultType = 'carpenter'; // القيمة الافتراضية
  String _selectedServiceType = '';
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _voiceRecordingPath;
  String? _existingVoiceRecordingUrl; // التسجيل الصوتي الموجود
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  bool _isScheduled = false;
  DateTime? _scheduledDate;
  bool _isEditMode = false;
  FaultReportModel? _existingReport;

  // قائمة أنواع الأعطال - يتم تحميلها من Firebase
  List<Map<String, String>> _faultTypes = [];
  bool _isLoadingCrafts = true;

  @override
  void initState() {
    super.initState();
    
    _isEditMode = widget.reportId != null;
    
    // تعيين callback لتحديث حالة التسجيل
    _voiceRecorderService.onRecordingStateChanged = (isRecording) {
      if (mounted) {
        setState(() {
          _isRecording = isRecording;
        });
      }
    };

    // إعداد AudioPlayer
    _setupAudioPlayer();
    
    // تحميل أنواع الحرف من Firebase
    _loadCrafts();
    
    // إذا كان في وضع التعديل، تحميل بيانات التقرير
    if (_isEditMode && widget.reportId != null) {
      _loadExistingReport();
    }
  }

  /// تحميل أنواع الحرف من Firebase
  Future<void> _loadCrafts() async {
    setState(() {
      _isLoadingCrafts = true;
    });

    try {
      final languageProvider = Provider.of<AppLanguage>(context, listen: false);
      final languageCode = languageProvider.appLang.name;
      
      final crafts = await _craftService.getCraftsAsMap(languageCode);
      
      if (mounted) {
        setState(() {
          _faultTypes = crafts;
          _isLoadingCrafts = false;
          // تعيين القيمة الافتراضية إذا كانت القائمة غير فارغة
          if (_faultTypes.isNotEmpty && _selectedFaultType.isEmpty) {
            _selectedFaultType = _faultTypes.first['value'] ?? 'carpenter';
          }
        });
      }
    } catch (e) {
      print('خطأ في تحميل الحرف: $e');
      if (mounted) {
        setState(() async {
          _isLoadingCrafts = false;
          // استخدام القيم الافتراضية في حالة الخطأ
          final languageProvider = Provider.of<AppLanguage>(context, listen: false);
          final languageCode = languageProvider.appLang.name;
          _faultTypes = await _craftService.getCraftsAsMap(languageCode);
        });
      }
    }
  }
  
  Future<void> _loadExistingReport() async {
    try {
      setState(() => _isLoading = true);
      
      final report = await _faultService.getFaultReport(widget.reportId!);
      if (report != null && mounted) {
        setState(() {
          _existingReport = report;
          
          // التحقق من أن faultType موجود في قائمة الحرف المحملة
          final faultType = report.faultType;
          if (_faultTypes.isNotEmpty) {
            final exists = _faultTypes.any((craft) => craft['value'] == faultType);
            if (exists) {
              _selectedFaultType = faultType;
            } else {
              // إذا لم تكن القيمة موجودة، استخدم أول حرفة في القائمة
              _selectedFaultType = _faultTypes.first['value'] ?? 'carpenter';
              print('⚠️ نوع العطل "$faultType" غير موجود في Firebase - تم تعيينه إلى: $_selectedFaultType');
            }
          } else {
            _selectedFaultType = faultType;
          }
          
          _selectedServiceType = report.serviceType;
          _descriptionController.text = report.description;
          _existingImageUrls = List.from(report.imageUrls);
          _existingVoiceRecordingUrl = report.voiceRecordingUrl;
          _existingVideoUrl = report.videoUrl;
          _isScheduled = report.isScheduled;
          _scheduledDate = report.scheduledDate;
          
          // تهيئة مشغل الفيديو إذا كان هناك فيديو موجود
          if (_existingVideoUrl != null) {
            _videoPlayerController?.dispose();
            _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(_existingVideoUrl!));
            _videoPlayerController!.initialize().then((_) {
              if (mounted) setState(() {});
            });
          }
        });
      }
    } catch (e) {
      print('❌ خطأ في تحميل التقرير: $e');
      if (mounted) {
        _showErrorToast(AppLocalizations.of(context)?.translate('load_report_failed') ?? 'فشل في تحميل التقرير');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _audioDuration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _audioPosition = position;
        });
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _descriptionController.dispose();
    _voiceRecorderService.dispose();
    _audioPlayer.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  // التقاط صورة من الكاميرا
  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image != null && mounted) {
        setState(() {
          _selectedImages.add(image.path);
        });
        _showSuccessToast(AppLocalizations.of(context)?.translate('photo_taken_success') ?? 'تم التقاط الصورة بنجاح');
      }
    } catch (e) {
      print('❌ خطأ في التقاط الصورة: $e');
      _showErrorToast('${AppLocalizations.of(context)?.translate('take_photo_failed') ?? 'فشل في التقاط الصورة'}: $e');
    }
  }

  // اختيار صور متعددة من المعرض
  Future<void> _pickFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (images.isNotEmpty && mounted) {
        setState(() {
          _selectedImages.addAll(images.map((img) => img.path));
        });
        _showSuccessToast('${AppLocalizations.of(context)?.translate('images_selected') ?? 'تم اختيار'} ${images.length} ${AppLocalizations.of(context)?.translate('image') ?? 'صورة'} ${AppLocalizations.of(context)?.translate('successfully') ?? 'بنجاح'}');
      }
    } catch (e) {
      print('❌ خطأ في اختيار الصور: $e');
      _showErrorToast('${AppLocalizations.of(context)?.translate('pick_image_failed') ?? 'فشل في اختيار الصور'}: $e');
    }
  }

  // حذف صورة
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // اختيار فيديو من المعرض
  Future<void> _pickVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 1),
      );
      
      if (video != null && mounted) {
        // التحقق من مدة الفيديو باستخدام video_player
        try {
          final tempController = VideoPlayerController.file(File(video.path));
          await tempController.initialize();
          final duration = tempController.value.duration;
          await tempController.dispose();
          
          if (duration.inSeconds > 60) {
            _showErrorToast('مدة الفيديو يجب ألا تتجاوز دقيقة واحدة');
            return;
          }
        } catch (e) {
          print('⚠️ خطأ في التحقق من مدة الفيديو: $e');
          // المتابعة حتى لو فشل التحقق
        }
        
        // ضغط الفيديو
        setState(() => _isUploading = true);
        _showSuccessToast('جارٍ ضغط الفيديو...');
        
        try {
          final compressedVideo = await VideoCompress.compressVideo(
            video.path,
            quality: VideoQuality.LowQuality, // استخدام جودة منخفضة لضغط أفضل
            deleteOrigin: false,
            includeAudio: true,
          );
          
          if (compressedVideo != null && mounted) {
            setState(() {
              _selectedVideoPath = compressedVideo.path;
              _isUploading = false;
            });
            _showSuccessToast('تم ضغط الفيديو بنجاح');
            
            // تهيئة مشغل الفيديو
            _videoPlayerController?.dispose();
            _videoPlayerController = VideoPlayerController.file(File(compressedVideo.path??''));
            await _videoPlayerController!.initialize();
            setState(() {});
          } else {
            setState(() => _isUploading = false);
            _showErrorToast('فشل في ضغط الفيديو');
          }
        } catch (e) {
          setState(() => _isUploading = false);
          print('❌ خطأ في ضغط الفيديو: $e');
          _showErrorToast('فشل في ضغط الفيديو: $e');
        }
      }
    } catch (e) {
      print('❌ خطأ في اختيار الفيديو: $e');
      _showErrorToast('${AppLocalizations.of(context)?.translate('pick_video_failed') ?? 'فشل في اختيار الفيديو'}: $e');
    }
  }

  // التقاط فيديو من الكاميرا
  Future<void> _takeVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 1),
      );
      
      if (video != null && mounted) {
        // التحقق من مدة الفيديو باستخدام video_player
        try {
          final tempController = VideoPlayerController.file(File(video.path));
          await tempController.initialize();
          final duration = tempController.value.duration;
          await tempController.dispose();
          
          if (duration.inSeconds > 60) {
            _showErrorToast('مدة الفيديو يجب ألا تتجاوز دقيقة واحدة');
            return;
          }
        } catch (e) {
          print('⚠️ خطأ في التحقق من مدة الفيديو: $e');
          // المتابعة حتى لو فشل التحقق
        }
        
        // ضغط الفيديو
        setState(() => _isUploading = true);
        _showSuccessToast('جارٍ ضغط الفيديو...');
        
        try {
          final compressedVideo = await VideoCompress.compressVideo(
            video.path,
            quality: VideoQuality.LowQuality, // استخدام جودة منخفضة لضغط أفضل
            deleteOrigin: false,
            includeAudio: true,
          );
          
          if (compressedVideo != null && mounted) {
            setState(() {
              _selectedVideoPath = compressedVideo.path;
              _isUploading = false;
            });
            _showSuccessToast('تم ضغط الفيديو بنجاح');
            
            // تهيئة مشغل الفيديو
            _videoPlayerController?.dispose();
            _videoPlayerController = VideoPlayerController.file(File(compressedVideo.path??''));
            await _videoPlayerController!.initialize();
            setState(() {});
          } else {
            setState(() => _isUploading = false);
            _showErrorToast('فشل في ضغط الفيديو');
          }
        } catch (e) {
          setState(() => _isUploading = false);
          print('❌ خطأ في ضغط الفيديو: $e');
          _showErrorToast('فشل في ضغط الفيديو: $e');
        }
      }
    } catch (e) {
      print('❌ خطأ في التقاط الفيديو: $e');
      _showErrorToast('${AppLocalizations.of(context)?.translate('take_video_failed') ?? 'فشل في التقاط الفيديو'}: $e');
    }
  }

  // حذف الفيديو
  void _removeVideo() {
    setState(() {
      _selectedVideoPath = null;
      _existingVideoUrl = null;
      _videoPlayerController?.dispose();
      _videoPlayerController = null;
    });
  }

  // تبديل حالة التسجيل الصوتي
  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        // إيقاف التسجيل
        final audioPath = await _voiceRecorderService.stopRecording();
        setState(() {
          _voiceRecordingPath = audioPath;
        });
        
        if (audioPath != null) {
          _showSuccessToast(AppLocalizations.of(context)?.translate('voice_message_sent') ?? 'تم تسجيل الرسالة الصوتية بنجاح');
        } else {
          _showErrorToast(AppLocalizations.of(context)?.translate('invalid_voice_recording') ?? 'لم يتم تسجيل رسالة صوتية صالحة');
        }
      } else {
        // بدء التسجيل
        final hasPermission = await _requestMicrophonePermission();
        if (hasPermission) {
          await _voiceRecorderService.startRecording();
        } else {
          _showErrorToast(AppLocalizations.of(context)?.translate('microphone_permission_required') ?? 'صلاحية الميكروفون مطلوبة');
        }
      }
    } catch (e) {
      print('❌ خطأ في التسجيل الصوتي: $e');
      _showErrorToast('${AppLocalizations.of(context)?.translate('recording_failed') ?? 'خطأ في التسجيل الصوتي'}: $e');
    }
  }

  // طلب إذن الميكروفون
  Future<bool> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  // إلغاء تسجيل الصوت
  void _cancelVoiceRecording() async {
    try {
      await _voiceRecorderService.cancelRecording();
      setState(() {
        _voiceRecordingPath = null;
      });
    } catch (e) {
      print('❌ خطأ في إلغاء التسجيل: $e');
      _showErrorToast('${AppLocalizations.of(context)?.translate('cancel_recording_failed') ?? 'فشل في إلغاء التسجيل'}: $e');
    }
  }


  // حذف التسجيل الصوتي
  void _deleteRecording() {
    setState(() {
      _voiceRecordingPath = null;
      _audioPosition = Duration.zero;
      _audioDuration = Duration.zero;
    });
    _audioPlayer.stop();
  }

  // تنسيق المدة
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // الحصول على الموقع الحالي
  Future<Map<String, dynamic>?> _getCurrentLocation() async {
    try {
      print('📍 بدء الحصول على الموقع الحالي...');
      
      // التحقق من تفعيل خدمة الموقع
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ خدمة الموقع غير مفعلة');
        throw Exception('خدمة الموقع غير متاحة');
      }

      // التحقق من الصلاحيات
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('⚠️ تم رفض صلاحية الموقع');
          throw Exception('تم رفض صلاحية الموقع');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('⚠️ صلاحية الموقع مرفوضة نهائياً');
        throw Exception('تم رفض صلاحية الموقع نهائياً');
      }

      // الحصول على الموقع
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      
      print('📍 تم الحصول على الموقع: ${position.latitude}, ${position.longitude}');
      
      // الحصول على العنوان
      String? address;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          address = '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}'.trim();
          if (address.startsWith(',')) {
            address = address.substring(1).trim();
          }
          if (address.endsWith(',')) {
            address = address.substring(0, address.length - 1).trim();
          }
        }
      } catch (e) {
        print('⚠️ خطأ في الحصول على العنوان: $e');
        address = '${position.latitude}, ${position.longitude}';
      }
      
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
      };
    } catch (e) {
      print('❌ خطأ في الحصول على الموقع: $e');
      return null;
    }
  }

  // اختيار تاريخ مجدول
  Future<void> _selectScheduledDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      
      if (time != null) {
        setState(() {
          _scheduledDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  // الانتقال للخطوة التالية
  void _goToNextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitReport();
    }
  }

  // العودة للخطوة السابقة
  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  // التحقق من صحة الخطوة الحالية
  bool _canProceedToNext() {
    switch (_currentStep) {
      case 0:
        // التحقق من وجود صورة واحدة على الأقل أو فيديو (صورة أو فيديو)
        final hasImages = _selectedImages.isNotEmpty || _existingImageUrls.isNotEmpty;
        final hasVideo = _selectedVideoPath != null || _existingVideoUrl != null;
        return hasImages || hasVideo;
      case 1:
        return _selectedFaultType.isNotEmpty;
      case 2:
        return true; // الخطوة الأخيرة اختيارية
      default:
        return false;
    }
  }

  // إرسال التقرير
  Future<void> _submitReport() async {
    // التحقق من وجود صورة واحدة على الأقل أو فيديو (صورة أو فيديو)
    final hasImages = _selectedImages.isNotEmpty || _existingImageUrls.isNotEmpty;
    final hasVideo = _selectedVideoPath != null || _existingVideoUrl != null;
    
    if (!hasImages && !hasVideo) {
      _showErrorToast('يجب رفع صورة واحدة على الأقل أو فيديو للمشكلة');
      return;
    }

    try {
      setState(() => _isLoading = true);

      final faultProvider = Provider.of<FaultProvider>(context, listen: false);
      
      bool success;
      
      if (_isEditMode && widget.reportId != null) {
        // تحديث التقرير الموجود
        success = await faultProvider.updateFaultReport(
          faultId: widget.reportId!,
          faultType: _selectedFaultType,
          serviceType: _selectedServiceType,
          description: _descriptionController.text.isEmpty 
              ? (AppLocalizations.of(context)?.translate('problem_needs_check') ?? 'مشكلة تحتاج إلى فحص') 
              : _descriptionController.text,
          imagePaths: _selectedImages.isNotEmpty ? _selectedImages : null,
          voiceRecordingPath: _voiceRecordingPath,
          videoPath: _selectedVideoPath,
          isScheduled: _isScheduled,
          scheduledDate: _scheduledDate,
          address: null,
          latitude: null,
          longitude: null,
        );
        
        if (mounted) {
          if (success) {
            _showSuccessToast(AppLocalizations.of(context)?.translate('report_updated_success') ?? 'تم تحديث التقرير بنجاح');
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                context.pop();
              }
            });
          } else {
            _showErrorToast(faultProvider.error ?? (AppLocalizations.of(context)?.translate('report_update_failed') ?? 'فشل في تحديث التقرير'));
          }
        }
      } else {
        // إنشاء تقرير جديد
        // التحقق من وجود صورة واحدة على الأقل أو فيديو
        final hasImages = _selectedImages.isNotEmpty;
        final hasVideo = _selectedVideoPath != null;
        
        if (!hasImages && !hasVideo) {
          _showErrorToast('يجب رفع صورة واحدة على الأقل أو فيديو للمشكلة');
          return;
        }
        
        // الحصول على الموقع الحالي للمستخدم
        String? userAddress;
        double? userLatitude;
        double? userLongitude;
        
        try {
          final locationData = await _getCurrentLocation();
          if (locationData != null) {
            userAddress = locationData['address'];
            userLatitude = locationData['latitude'];
            userLongitude = locationData['longitude'];
            
            print('📍 موقع المستخدم:');
            print('   - العنوان: $userAddress');
            print('   - خط العرض: $userLatitude');
            print('   - خط الطول: $userLongitude');
          } else {
            print('⚠️ لم يتم الحصول على الموقع');
          }
        } catch (e) {
          print('⚠️ خطأ في الحصول على الموقع: $e');
          _showErrorToast('فشل في الحصول على الموقع: $e');
        }
        
        success = await faultProvider.createFaultReport(
          faultType: _selectedFaultType,
          serviceType: _selectedServiceType,
          description: _descriptionController.text.isEmpty 
              ? (AppLocalizations.of(context)?.translate('problem_needs_check') ?? 'مشكلة تحتاج إلى فحص') 
              : _descriptionController.text,
          imagePaths: _selectedImages,
          voiceRecordingPath: _voiceRecordingPath,
          videoPath: _selectedVideoPath,
          isScheduled: _isScheduled,
          scheduledDate: _scheduledDate,
          address: userAddress,
          latitude: userLatitude,
          longitude: userLongitude,
        );
        
        if (mounted) {
          if (success) {
            _showSuccessToast(AppLocalizations.of(context)?.translate('fault_report_sent_success') ?? 'تم إرسال التقرير بنجاح');
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                context.pop();
              }
            });
          } else {
            _showErrorToast(faultProvider.error ?? (AppLocalizations.of(context)?.translate('fault_report_sent_failed') ?? 'فشل في إرسال التقرير'));
          }
        }
      }
    } catch (e) {
      print('❌ خطأ في ${_isEditMode ? "تحديث" : "إرسال"} التقرير: $e');
      _showErrorToast('${AppLocalizations.of(context)?.translate(_isEditMode ? 'report_update_failed' : 'fault_report_sent_failed') ?? (_isEditMode ? 'فشل في تحديث' : 'فشل في إرسال')} التقرير: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Theme.of(context).colorScheme.error,
      textColor: Theme.of(context).colorScheme.onError,
      fontSize: 14.sp,
    );
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Theme.of(context).colorScheme.primary,
      textColor: Theme.of(context).colorScheme.onPrimary,
      fontSize: 14.sp,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => _goToPreviousStep(),
        ),
        title: Text(
          _isEditMode 
              ? (AppLocalizations.of(context)?.translate('edit_report') ?? 'تعديل التقرير')
              : (AppLocalizations.of(context)?.translate('submit_problem') ?? 'رفع المشكلة'),
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Stepper Indicator
          _buildStepperIndicator(),
          
          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              children: [
                _buildStep1Content(), // التقاط صور وفيديو
                _buildStep2Content(), // اختيار القسم
                _buildStep3Content(), // تفاصيل إضافية + موعد مجدول وصوتي
              ],
            ),
          ),
          
          // Navigation Buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStepperIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(5, (index) {
          // 3 steps + 2 connectors = 5 items
          if (index % 2 == 0) {
            // This is a step (0, 2, 4)
            final stepIndex = index ~/ 2;
            final isActive = stepIndex <= _currentStep;
            final isCompleted = stepIndex < _currentStep;

            return Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: isActive
                    ? (isCompleted ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.onPrimary, size: 20)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          color: isActive ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.outline,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
              ),
            );
          } else {
            // This is a connector (1, 3)
            final previousStepIndex = (index - 1) ~/ 2;
            final isCompleted = previousStepIndex < _currentStep;

            return Container(
              height: 2.h,
              width: 30.w,
              margin: EdgeInsets.symmetric(horizontal: 10.w),
              color: isCompleted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
            );
          }
        }),
      ),
    );
  }

  String _getStepTitle(int index) {
    switch (index) {
      case 0:
        return AppLocalizations.of(context)?.translate('problem_images') ?? 'صور المشكلة';
      case 1:
        return AppLocalizations.of(context)?.translate('select_section') ?? 'تحديد القسم';
      case 2:
        return AppLocalizations.of(context)?.translate('additional_details') ?? 'تفاصيل إضافية';
      default:
        return '';
    }
  }

  Widget _buildStep1Content() {
    return Step1ImagesVideoWidget(
      selectedImages: _selectedImages,
      existingImageUrls: _existingImageUrls,
      selectedVideoPath: _selectedVideoPath,
      existingVideoUrl: _existingVideoUrl,
      videoPlayerController: _videoPlayerController,
      isUploading: _isUploading,
      onTakePhoto: _takePhoto,
      onPickFromGallery: _pickFromGallery,
      onTakeVideo: _takeVideo,
      onPickVideo: _pickVideo,
      onRemoveImage: (index) {
        setState(() {
          if (index < _existingImageUrls.length) {
            _existingImageUrls.removeAt(index);
          } else {
            _selectedImages.removeAt(index - _existingImageUrls.length);
          }
        });
      },
      onRemoveVideo: _removeVideo,
    );
  }

  Widget _buildStep2Content() {
    // التأكد من أن selectedFaultType موجود في القائمة
    String validSelectedType = _selectedFaultType;
    if (_faultTypes.isNotEmpty) {
      final exists = _faultTypes.any((craft) => craft['value'] == _selectedFaultType);
      if (!exists) {
        validSelectedType = _faultTypes.first['value'] ?? 'carpenter';
      }
    }
    
    return Step2FaultTypeWidget(
      faultTypes: _faultTypes,
      selectedFaultType: validSelectedType,
      onFaultTypeSelected: (value, label) {
        setState(() {
          _selectedFaultType = value;
          _selectedServiceType = label;
        });
      },
    );
  }

  Widget _buildStep3Content() {
    return Step3AdditionalDetailsWidget(
      descriptionController: _descriptionController,
      voiceRecordingSection: _buildVoiceRecordingSection(),
      scheduledDateSection: _buildScheduledDateSection(),
    );
  }

  Widget _buildVoiceRecordingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.mic,
              color: Theme.of(context).colorScheme.primary,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              AppLocalizations.of(context)?.translate('voice_recording') ?? 'تسجيل صوتي',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // عرض التسجيل الصوتي إذا كان موجوداً
        if (_voiceRecordingPath != null || _existingVoiceRecordingUrl != null) ...[
          _buildAudioPlayer(),
          SizedBox(height: 16.h),
        ],

        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _toggleRecording,
                icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                label: Text(
                  _isRecording 
                      ? (AppLocalizations.of(context)?.translate('stop_recording') ?? 'إيقاف التسجيل')
                      : (AppLocalizations.of(context)?.translate('start_recording') ?? 'بدء التسجيل'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording 
                      ? Theme.of(context).colorScheme.error 
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
            if (_voiceRecordingPath != null) ...[
              SizedBox(width: 8.w),
              IconButton(
                onPressed: _deleteRecording,
                icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAudioPlayer() {
    final hasRecording = _voiceRecordingPath != null || _existingVoiceRecordingUrl != null;
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: hasRecording ? _playRecording : null,
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: hasRecording 
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _voiceRecordingPath != null 
                          ? (AppLocalizations.of(context)?.translate('new_voice_recording') ?? 'تسجيل صوتي جديد')
                          : _existingVoiceRecordingUrl != null
                              ? (AppLocalizations.of(context)?.translate('existing_voice_recording') ?? 'التسجيل الصوتي الموجود')
                              : (AppLocalizations.of(context)?.translate('voice_recording') ?? 'التسجيل الصوتي'),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${_formatDuration(_audioPosition)} / ${_formatDuration(_audioDuration)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              if (_existingVoiceRecordingUrl != null && _voiceRecordingPath == null)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _existingVoiceRecordingUrl = null;
                    });
                  },
                  icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
          if (_audioDuration.inSeconds > 0)
            LinearProgressIndicator(
              value: _audioPosition.inSeconds / _audioDuration.inSeconds,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
  
  Future<void> _playRecording() async {
    // إذا كان هناك تسجيل جديد، استخدمه
    if (_voiceRecordingPath != null) {
      await _playRecordingFromPath(_voiceRecordingPath!);
    } 
    // وإلا استخدم التسجيل الموجود
    else if (_existingVoiceRecordingUrl != null) {
      await _playRecordingFromUrl(_existingVoiceRecordingUrl!);
    }
  }
  
  Future<void> _playRecordingFromPath(String path) async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(DeviceFileSource(path));
      }
    } catch (e) {
      print('❌ خطأ في تشغيل التسجيل: $e');
      _showErrorToast(AppLocalizations.of(context)?.translate('play_voice_failed') ?? 'فشل في تشغيل التسجيل الصوتي');
    }
  }
  
  Future<void> _playRecordingFromUrl(String url) async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(UrlSource(url));
      }
    } catch (e) {
      print('❌ خطأ في تشغيل التسجيل: $e');
      _showErrorToast(AppLocalizations.of(context)?.translate('play_voice_failed') ?? 'فشل في تشغيل التسجيل الصوتي');
    }
  }

  Widget _buildScheduledDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: Theme.of(context).colorScheme.primary,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              AppLocalizations.of(context)?.translate('scheduled_date') ?? 'موعد مجدول',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        SwitchListTile(
          title: Text(AppLocalizations.of(context)?.translate('set_scheduled_date') ?? 'تحديد موعد مجدول'),
          subtitle: _scheduledDate != null
              ? Text(
                  '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year} - ${_scheduledDate!.hour}:${_scheduledDate!.minute.toString().padLeft(2, '0')}',
                )
              : null,
          value: _isScheduled,
          onChanged: (value) {
            setState(() {
              _isScheduled = value;
              if (!value) {
                _scheduledDate = null;
              }
            });
            if (value) {
              _selectScheduledDate();
            }
          },
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        if (_isScheduled && _scheduledDate == null)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: ElevatedButton.icon(
              onPressed: _selectScheduledDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(AppLocalizations.of(context)?.translate('select_date_time') ?? 'اختر التاريخ والوقت'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        if (_isScheduled && _scheduledDate != null)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: OutlinedButton.icon(
              onPressed: _selectScheduledDate,
              icon: const Icon(Icons.edit),
              label: Text(AppLocalizations.of(context)?.translate('change_date') ?? 'تغيير الموعد'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 60.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel/Back Button
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : _goToPreviousStep,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                _currentStep == 0 
                    ? (AppLocalizations.of(context)?.translate('cancel') ?? 'إلغاء')
                    : (AppLocalizations.of(context)?.translate('previous') ?? 'السابق'),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // Next/Submit Button
          Expanded(
            flex: 2,
            child: AbsorbPointer(
              absorbing: _isLoading || !_canProceedToNext(),
              child: ElevatedButton(
                onPressed: _isLoading || !_canProceedToNext() ? () {} : _goToNextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_isLoading && _currentStep == 2) 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  disabledBackgroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: _isLoading && _currentStep == 2
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            _isEditMode 
                                ? (AppLocalizations.of(context)?.translate('saving') ?? 'جارٍ الحفظ...')
                                : (AppLocalizations.of(context)?.translate('sending') ?? 'جارٍ الإرسال...'),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        _currentStep == 2 
                            ? (_isEditMode 
                                ? (AppLocalizations.of(context)?.translate('save_changes') ?? 'حفظ التعديلات')
                                : (AppLocalizations.of(context)?.translate('send') ?? 'إرسال'))
                            : (AppLocalizations.of(context)?.translate('next') ?? 'التالي'),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

