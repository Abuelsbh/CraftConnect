import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../Models/fault_report_model.dart';
import '../../services/fault_service.dart';
import '../../services/craft_service.dart';
import '../../services/voice_recorder_service.dart';
import '../../Utilities/app_constants.dart';
import '../../providers/fault_provider.dart';
import '../../Widgets/custom_button_widget.dart';
import '../../Widgets/custom_textfield_widget.dart';
import 'package:image_picker/image_picker.dart';
import '../../Utilities/theme_helper.dart';
import '../../Utilities/text_style_helper.dart';
import '../../core/Language/locales.dart';
import '../../core/Language/app_languages.dart';

class FaultReportScreen extends StatefulWidget {
  const FaultReportScreen({super.key});

  @override
  State<FaultReportScreen> createState() => _FaultReportScreenState();
}

class _FaultReportScreenState extends State<FaultReportScreen> {
  final FaultService _faultService = FaultService();
  final CraftService _craftService = CraftService();
  final VoiceRecorderService _voiceRecorderService = VoiceRecorderService(); // الآن singleton
  final TextEditingController _descriptionController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // متغيرات الحالة
  String _selectedFaultType = 'carpenter'; // القيمة الافتراضية
  String _selectedServiceType = '';
  List<String> _selectedImages = [];
  String? _voiceRecordingPath;
  bool _isScheduled = false;
  DateTime? _scheduledDate;
  bool _isRecording = false;
  bool _isLoading = false;
  bool _isPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  // قائمة أنواع الأعطال - يتم تحميلها من Firebase
  List<Map<String, String>> _faultTypes = [];
  bool _isLoadingCrafts = true;

  @override
  void initState() {
    super.initState();
    
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
        setState(() {
          _isLoadingCrafts = false;
          // استخدام القيم الافتراضية في حالة الخطأ
          final languageProvider = Provider.of<AppLanguage>(context, listen: false);
          final languageCode = languageProvider.appLang.name;
          _craftService.getCraftsAsMap(languageCode).then((crafts) {
            if (mounted) {
              setState(() {
                _faultTypes = crafts;
              });
            }
          });
        });
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
    _descriptionController.dispose();
    _voiceRecorderService.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // اختيار نوع العطل
  void _selectFaultType(String faultType) {
    setState(() {
      _selectedFaultType = faultType;
      // تحديث نوع الخدمة حسب نوع العطل
      final faultTypeData = _faultTypes.firstWhere((type) => type['value'] == faultType);
      _selectedServiceType = faultTypeData['label'] ?? '';
    });
  }

  // اختيار الصور
  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images.map((image) => image.path).toList();
        });
        _showSuccessSnackBar('${AppLocalizations.of(context)?.translate('images_selected') ?? 'تم اختيار'} ${images.length} ${AppLocalizations.of(context)?.translate('image') ?? 'صورة'}');
      }
    } catch (e) {
      print('❌ خطأ في اختيار الصور: $e');
      _showErrorSnackBar('${AppLocalizations.of(context)?.translate('pick_image_failed') ?? 'فشل في اختيار الصور'}: $e');
    }
  }

  // التقاط صورة من الكاميرا
  Future<void> _takePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      
      if (image != null) {
        setState(() {
          _selectedImages.add(image.path);
        });
        _showSuccessSnackBar(AppLocalizations.of(context)?.translate('photo_taken_success') ?? 'تم التقاط الصورة بنجاح');
      }
    } catch (e) {
      print('❌ خطأ في التقاط الصورة: $e');
      _showErrorSnackBar('${AppLocalizations.of(context)?.translate('take_photo_failed') ?? 'فشل في التقاط الصورة'}: $e');
    }
  }

  // حذف صورة
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // تبديل حالة التسجيل (الدالة الرئيسية)
  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        // إيقاف التسجيل
        final audioPath = await _voiceRecorderService.stopRecording();
        setState(() {
          _voiceRecordingPath = audioPath;
        });
        
        if (audioPath != null) {
          _showSuccessSnackBar(AppLocalizations.of(context)?.translate('voice_message_sent') ?? 'تم تسجيل الرسالة الصوتية بنجاح');
        } else {
          _showErrorSnackBar(AppLocalizations.of(context)?.translate('invalid_voice_recording') ?? 'لم يتم تسجيل رسالة صوتية صالحة');
        }
      } else {
        // بدء التسجيل
        final hasPermission = await _requestMicrophonePermission();
        if (hasPermission) {
          await _voiceRecorderService.startRecording();
        } else {
          _showErrorSnackBar(AppLocalizations.of(context)?.translate('microphone_permission_required') ?? 'صلاحية الميكروفون مطلوبة');
        }
      }
    } catch (e) {
      print('❌ خطأ في التسجيل الصوتي: $e');
      _showErrorSnackBar('${AppLocalizations.of(context)?.translate('recording_failed') ?? 'خطأ في التسجيل الصوتي'}: $e');
    }
  }

  // طلب إذن الميكروفون
  Future<bool> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  // إلغاء تسجيل الصوت (إذا كان مطلوباً)
  void _cancelVoiceRecording() async {
    try {
      await _voiceRecorderService.cancelRecording();
      setState(() {
        _voiceRecordingPath = null;
      });
    } catch (e) {
      print('❌ خطأ في إلغاء التسجيل: $e');
      _showErrorSnackBar('فشل في إلغاء التسجيل: $e');
    }
  }

  // تشغيل التسجيل الصوتي
  Future<void> _playRecording() async {
    if (_voiceRecordingPath == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(DeviceFileSource(_voiceRecordingPath!));
      }
    } catch (e) {
      print('❌ خطأ في تشغيل التسجيل: $e');
      _showErrorSnackBar(AppLocalizations.of(context)?.translate('play_voice_failed') ?? 'فشل في تشغيل التسجيل الصوتي');
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

  // إرسال تقرير العطل
  Future<void> _submitFaultReport() async {
    if (_descriptionController.text.trim().isEmpty) {
      _showErrorSnackBar(AppLocalizations.of(context)?.translate('fault_description_required') ?? 'يرجى إدخال وصف العطل');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final faultProvider = Provider.of<FaultProvider>(context, listen: false);
      final success = await faultProvider.createFaultReport(
        faultType: _selectedFaultType,
        serviceType: _selectedServiceType,
        description: _descriptionController.text.trim(),
        imagePaths: _selectedImages,
        voiceRecordingPath: _voiceRecordingPath,
        isScheduled: _isScheduled,
        scheduledDate: _scheduledDate,
      );

      if (mounted) {
        if (success) {
          _showSuccessSnackBar(AppLocalizations.of(context)?.translate('fault_report_sent_success') ?? 'تم إرسال تقرير العطل بنجاح');
          context.pop();
        } else {
          _showErrorSnackBar(faultProvider.error ?? (AppLocalizations.of(context)?.translate('fault_report_sent_failed') ?? 'فشل في إرسال تقرير العطل'));
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('${AppLocalizations.of(context)?.translate('fault_report_sent_failed') ?? 'خطأ في إرسال تقرير العطل'}: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            _buildCustomHeader(),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // بيانات العطل
                    _buildFaultDetailsSection(),
                    SizedBox(height: 24.h),
                    
                    // صور العطل
                    _buildFaultImagesSection(),
                    SizedBox(height: 24.h),
                    
                    // وصف العطل
                    _buildFaultDescriptionSection(),
                    SizedBox(height: 24.h),
                    
                    // تسجيل صوت
                    _buildVoiceRecordingSection(),
                    SizedBox(height: 24.h),
                    
                    // طلب في موعد مجدول
                    _buildScheduledRequestSection(),
                    SizedBox(height: 32.h),
                    
                    // زر الإرسال
                    _buildSubmitButton(),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface,
                size: 20.sp,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              AppLocalizations.of(context)?.translate('submit_fault_report') ?? 'رفع عطل فني',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaultDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.translate('fault_details') ?? 'بيانات العطل',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedServiceType,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${AppLocalizations.of(context)?.translate('fault_type') ?? 'نوع العطل'}: ${_faultTypes.firstWhere((type) => type['value'] == _selectedFaultType)['label']}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline,
                size: 24.sp,
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        // قائمة أنواع الأعطال
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _faultTypes.map((faultType) {
            final isSelected = _selectedFaultType == faultType['value'];
            return GestureDetector(
              onTap: () => _selectFaultType(faultType['value']!),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  faultType['label']!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isSelected 
                        ? Theme.of(context).colorScheme.onPrimary 
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFaultImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.photo_library,
              color: AppConstants.primaryColor,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              AppLocalizations.of(context)?.translate('fault_images') ?? 'صور العطل',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          height: 120.h,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              style: BorderStyle.solid,
            ),
          ),
          child: _selectedImages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 32.sp,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        AppLocalizations.of(context)?.translate('tap_to_add_images') ?? 'اضغط لإضافة صور',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: EdgeInsets.all(8.w),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8.w,
                    mainAxisSpacing: 8.h,
                  ),
                  itemCount: _selectedImages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _selectedImages.length) {
                      return GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Icon(
                            Icons.add,
                            color: Theme.of(context).colorScheme.outline,
                            size: 24.sp,
                          ),
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.r),
                            image: DecorationImage(
                              image: FileImage(File(_selectedImages[index])),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(2.w),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Theme.of(context).colorScheme.onError,
                                size: 12.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showImagePickerOptions,
                icon: Icon(Icons.photo_library, size: 16.sp),
                label: Text(
                  AppLocalizations.of(context)?.translate('gallery') ?? 'المعرض',
                  style: TextStyle(fontSize: 12.sp),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _takePicture,
                icon: Icon(Icons.camera_alt, size: 16.sp),
                label: Text(
                  AppLocalizations.of(context)?.translate('camera') ?? 'الكاميرا',
                  style: TextStyle(fontSize: 12.sp),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFaultDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.edit,
              color: AppConstants.primaryColor,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              AppLocalizations.of(context)?.translate('fault_description') ?? 'وصف العطل',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        CustomTextFieldWidget(
          controller: _descriptionController,
          hint: AppLocalizations.of(context)?.translate('write_here') ?? 'اكتب هنا',
          maxLine: 5,
          textInputAction: TextInputAction.newline,
          textInputType: TextInputType.multiline,
        ),
      ],
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
              color: AppConstants.primaryColor,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              AppLocalizations.of(context)?.translate('voice_recording') ?? 'تسجيل صوت',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        
        // عرض التسجيل الصوتي إذا كان موجوداً
        if (_voiceRecordingPath != null) ...[
          _buildAudioPlayer(),
          SizedBox(height: 12.h),
        ],
        
        // زر التسجيل
        Container(
          height: 120.h,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _toggleRecording,
                  child: Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      color: _isRecording 
                          ? Theme.of(context).colorScheme.error 
                          : Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: _isRecording
                          ? [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 24.sp,
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  _isRecording 
                      ? (AppLocalizations.of(context)?.translate('tap_to_stop') ?? 'اضغط للإيقاف')
                      : (AppLocalizations.of(context)?.translate('tap_to_record') ?? 'اضغط للتسجيل'),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                if (_voiceRecordingPath != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    AppLocalizations.of(context)?.translate('recording_success') ?? 'تم التسجيل بنجاح',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioPlayer() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.audiotrack,
                color: Theme.of(context).colorScheme.primary,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)?.translate('voice_recording') ?? 'التسجيل الصوتي',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _deleteRecording,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    size: 20.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          // شريط التقدم
          if (_audioDuration.inMilliseconds > 0) ...[
            Slider(
              value: _audioPosition.inMilliseconds.toDouble(),
              max: _audioDuration.inMilliseconds.toDouble(),
              onChanged: (value) {
                _audioPlayer.seek(Duration(milliseconds: value.toInt()));
              },
              activeColor: Theme.of(context).colorScheme.primary,
              inactiveColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
            SizedBox(height: 8.h),
          ],
          
          // أزرار التحكم
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_audioPosition),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              GestureDetector(
                onTap: _playRecording,
                child: Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 24.sp,
                  ),
                ),
              ),
              Text(
                _formatDuration(_audioDuration),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledRequestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Switch(
              value: _isScheduled,
              onChanged: (value) {
                setState(() {
                  _isScheduled = value;
                  if (!value) {
                    _scheduledDate = null;
                  }
                });
              },
              activeColor: AppConstants.primaryColor,
            ),
            SizedBox(width: 12.w),
            Text(
              AppLocalizations.of(context)?.translate('scheduled_request') ?? 'طلب في موعد مجدول',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        if (_isScheduled) ...[
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: _selectScheduledDate,
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: AppConstants.primaryColor,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    _scheduledDate != null
                        ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year} - ${_scheduledDate!.hour}:${_scheduledDate!.minute.toString().padLeft(2, '0')}'
                        : (AppLocalizations.of(context)?.translate('select_date_time') ?? 'اختر التاريخ والوقت'),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: _scheduledDate != null 
                          ? Theme.of(context).colorScheme.onSurface 
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.outline,
                    size: 20.sp,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return CustomButtonWidget(
      title: AppLocalizations.of(context)?.translate('confirm_and_select_address') ?? 'تأكيد وتحديد العنوان',
      onTap: _submitFaultReport,
      isLoading: _isLoading,
      backGroundColor: _canSubmit() 
          ? Theme.of(context).colorScheme.primary 
          : Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }

  bool _canSubmit() {
    return _descriptionController.text.trim().isNotEmpty;
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(context)?.translate('select_from_gallery') ?? 'اختيار من المعرض'),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppLocalizations.of(context)?.translate('take_photo') ?? 'التقاط صورة'),
              onTap: () {
                Navigator.pop(context);
                _takePicture();
              },
            ),
          ],
        ),
      ),
    );
  }

  // رفع التسجيل الصوتي في الخلفية
  Future<void> _uploadVoiceInBackground() async {
    if (_voiceRecordingPath == null) return;
    
    try {
      print('🔄 بدء رفع التسجيل الصوتي في الخلفية...');
      final faultService = FaultService();
      final voiceUrl = await faultService.uploadVoiceRecording(_voiceRecordingPath!, 'voice_recordings');
      
      if (mounted) {
        _showSuccessSnackBar(AppLocalizations.of(context)?.translate('voice_upload_success') ?? 'تم رفع التسجيل الصوتي بنجاح');
        print('✅ تم رفع التسجيل الصوتي في الخلفية: $voiceUrl');
      }
    } catch (e) {
      print('❌ فشل في رفع التسجيل الصوتي في الخلفية: $e');
      if (mounted) {
        _showErrorSnackBar(AppLocalizations.of(context)?.translate('voice_upload_failed') ?? 'فشل في رفع التسجيل الصوتي');
      }
    }
  }
}

