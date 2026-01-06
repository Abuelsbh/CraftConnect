import 'dart:async';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecorderService {
  // Singleton pattern
  static final VoiceRecorderService _instance = VoiceRecorderService._internal();
  factory VoiceRecorderService() => _instance;
  VoiceRecorderService._internal();

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final Uuid _uuid = const Uuid();
  
  String? _currentRecordingPath;
  Function(bool)? onRecordingStateChanged;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  bool _isInitialized = false;
  Timer? _durationTimer;

  bool get isRecording => _isRecording;
  Duration get recordingDuration => _recordingDuration;
  String? get currentRecordingPath => _currentRecordingPath;
  String? get recordingPath => _currentRecordingPath;

  // تهيئة المسجل
  Future<void> _initializeRecorder() async {
    if (_isInitialized) {
      // التحقق من أن المسجل لا يزال مفتوحاً
      try {
        final isOpen = await _recorder.isRecording;
        print('🔍 حالة المسجل: $isOpen');
      } catch (e) {
        // إذا فشل التحقق، قد يكون المسجل مغلقاً - نحتاج لإعادة فتحه
        print('⚠️ المسجل قد يكون مغلقاً، سيتم إعادة فتحه');
        _isInitialized = false;
      }
    }
    
    if (_isInitialized) return;
    
    try {
      print('🔧 بدء تهيئة المسجل...');
      await _recorder.openRecorder();
      _isInitialized = true;
      print('✅ تم تهيئة VoiceRecorderService بنجاح');
    } catch (e) {
      print('❌ فشل في تهيئة VoiceRecorderService: $e');
      _isInitialized = false;
      throw Exception('فشل في تهيئة المسجل: $e');
    }
  }

  // إعادة تعيين الحالة
  void _resetState() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _isRecording = false;
    _recordingDuration = Duration.zero;
    _currentRecordingPath = null;
    onRecordingStateChanged?.call(false);
    print('🔄 تم إعادة تعيين حالة VoiceRecorderService');
  }

  // بدء التسجيل
  Future<void> startRecording() async {
    try {
      print('🎤 بدء عملية التسجيل...');
      
      // التحقق من صلاحيات الميكروفون
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        print('❌ صلاحية الميكروفون مرفوضة');
        throw Exception('صلاحية الميكروفون مطلوبة. يرجى السماح بالوصول إلى الميكروفون من إعدادات التطبيق');
      }
      print('✅ تم الحصول على صلاحية الميكروفون');

      // إيقاف أي تسجيل سابق إذا كان موجوداً
      if (_isRecording) {
        print('⚠️ يوجد تسجيل نشط - سيتم إيقافه أولاً');
        try {
          await _recorder.stopRecorder();
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          print('⚠️ خطأ في إيقاف التسجيل السابق: $e');
        }
        _isRecording = false;
        _recordingDuration = Duration.zero;
      }

      // تهيئة المسجل إذا لم يكن مهيأ
      await _initializeRecorder();

      // التحقق من حالة المسجل الفعلية
      if (_isInitialized) {
        try {
          final isActuallyRecording = await _recorder.isRecording;
          print('🔍 حالة المسجل الفعلية: $isActuallyRecording');
          print('🔍 حالة المسجل المحلية: $_isRecording');
          
          if (isActuallyRecording) {
            print('⚠️ المسجل يسجل بالفعل - سيتم إيقافه');
            await _recorder.stopRecorder();
            await Future.delayed(const Duration(milliseconds: 1000));
          }
          
          // إعادة تعيين الحالة المحلية
          _isRecording = false;
          _recordingDuration = Duration.zero;
          _currentRecordingPath = null;
          print('🔄 تم إعادة تعيين حالة VoiceRecorderService');
        } catch (e) {
          print('⚠️ خطأ في التحقق من حالة المسجل: $e');
          // محاولة إعادة تهيئة المسجل
          _isInitialized = false;
          await _initializeRecorder();
          _isRecording = false;
          _recordingDuration = Duration.zero;
          _currentRecordingPath = null;
        }
      }

      // إنشاء مجلد للتسجيلات إذا لم يكن موجوداً
      final directory = await getTemporaryDirectory();
      final recordingsDir = Directory('${directory.path}/recordings');
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
        print('📁 تم إنشاء مجلد التسجيلات: ${recordingsDir.path}');
      }

      // إنشاء اسم الملف
      final fileName = 'voice_${_uuid.v4()}.aac';
      _currentRecordingPath = path.join(recordingsDir.path, fileName);

      print('📁 مسار التسجيل: $_currentRecordingPath');

      // التحقق من أن المسجل جاهز
      if (!_isInitialized) {
        print('⚠️ المسجل غير مهيأ، سيتم إعادة التهيئة...');
        await _initializeRecorder();
      }

      // بدء التسجيل
      try {
        print('🎤 بدء التسجيل الفعلي...');
        await _recorder.startRecorder(
          toFile: _currentRecordingPath!,
          codec: Codec.aacADTS,
          bitRate: 128000,
          sampleRate: 44100,
        );
        
        // التحقق من أن التسجيل بدأ فعلياً
        await Future.delayed(const Duration(milliseconds: 300));
        final isActuallyRecording = await _recorder.isRecording;
        if (!isActuallyRecording) {
          throw Exception('فشل في بدء التسجيل - المسجل لا يسجل');
        }
        
        _isRecording = true;
        onRecordingStateChanged?.call(true);
        _recordingDuration = Duration.zero;

        // بدء عداد المدة
        _startDurationTimer();
        
        print('✅ بدء التسجيل بنجاح');
      } catch (e) {
        print('❌ خطأ في بدء التسجيل الفعلي: $e');
        _isRecording = false;
        _recordingDuration = Duration.zero;
        _currentRecordingPath = null;
        throw Exception('فشل في بدء التسجيل: $e');
      }
    } catch (e) {
      _resetState();
      print('❌ فشل في بدء التسجيل: $e');
      throw Exception('فشل في بدء التسجيل: $e');
    }
  }

  // إيقاف التسجيل
  Future<String?> stopRecording() async {
    try {
      print('⏹️ إيقاف التسجيل...');
      
      if (!_isRecording) {
        print('⚠️ لا يوجد تسجيل نشط');
        return null;
      }

      // إيقاف التسجيل
      await _recorder.stopRecorder();
      _isRecording = false;
      onRecordingStateChanged?.call(false);

      // التحقق من وجود الملف
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          final fileSize = await file.length();
          
          // إذا كان الملف صغير جداً، نحذفه
          if (fileSize < 1000) { // أقل من 1KB
            await file.delete();
            _currentRecordingPath = null;
            print('⚠️ تم حذف التسجيل (حجم صغير جداً)');
            return null;
          }

          print('✅ تم حفظ التسجيل: $_currentRecordingPath (${fileSize} bytes)');
          return _currentRecordingPath;
        }
      }

      print('⚠️ لم يتم العثور على ملف التسجيل');
      return null;
    } catch (e) {
      _resetState();
      print('❌ فشل في إيقاف التسجيل: $e');
      throw Exception('فشل في إيقاف التسجيل: $e');
    }
  }

  // إلغاء التسجيل
  Future<void> cancelRecording() async {
    try {
      print('❌ إلغاء التسجيل...');
      
      if (_isRecording) {
        await _recorder.stopRecorder();
      }

      // حذف الملف إذا كان موجوداً
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
        _currentRecordingPath = null;
      }

      _resetState();
      print('✅ تم إلغاء التسجيل');
    } catch (e) {
      _resetState();
      print('❌ فشل في إلغاء التسجيل: $e');
      throw Exception('فشل في إلغاء التسجيل: $e');
    }
  }

  // بدء عداد المدة
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _recordingDuration = Duration.zero;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRecording) {
        _recordingDuration += const Duration(seconds: 1);
      } else {
        timer.cancel();
      }
    });
  }

  // تنسيق المدة
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // الحصول على مستوى الصوت
  Future<double> getAmplitude() async {
    try {
      if (_isRecording) {
        // flutter_sound لا يوفر مستوى الصوت مباشرة
        // نستخدم قيمة افتراضية
        return 0.5;
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // التحقق من حالة التسجيل
  Future<bool> isRecordingState() async {
    try {
      if (!_isInitialized) return false;
      return _recorder.isRecording;
    } catch (e) {
      return false;
    }
  }

  // إعادة تعيين الحالة
  void resetState() {
    _resetState();
  }

  // تنظيف الموارد
  void dispose() {
    _durationTimer?.cancel();
    _durationTimer = null;
    if (_isInitialized) {
      _recorder.closeRecorder();
      _isInitialized = false;
      print('🧹 تم تنظيف VoiceRecorderService');
    }
  }
}
