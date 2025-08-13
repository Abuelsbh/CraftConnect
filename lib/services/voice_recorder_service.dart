import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecorderService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final Uuid _uuid = const Uuid();
  
  String? _currentRecordingPath;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;

  bool get isRecording => _isRecording;
  Duration get recordingDuration => _recordingDuration;
  String? get currentRecordingPath => _currentRecordingPath;

  // بدء التسجيل
  Future<void> startRecording() async {
    try {
      // التحقق من صلاحيات الميكروفون
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw Exception('صلاحية الميكروفون مطلوبة');
      }

      // إنشاء مجلد للتسجيلات إذا لم يكن موجوداً
      final directory = await getTemporaryDirectory();
      final recordingsDir = Directory('${directory.path}/recordings');
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      // إنشاء اسم الملف
      final fileName = 'voice_${_uuid.v4()}.aac';
      _currentRecordingPath = path.join(recordingsDir.path, fileName);

      // بدء التسجيل
      await _recorder.startRecorder(
        toFile: _currentRecordingPath!,
        codec: Codec.aacADTS,
        bitRate: 128000,
        sampleRate: 44100,
      );

      _isRecording = true;
      _recordingDuration = Duration.zero;

      // بدء عداد المدة
      _startDurationTimer();
    } catch (e) {
      throw Exception('فشل في بدء التسجيل: $e');
    }
  }

  // إيقاف التسجيل
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        return null;
      }

      // إيقاف التسجيل
      await _recorder.stopRecorder();
      _isRecording = false;

      // التحقق من وجود الملف
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          final fileSize = await file.length();
          
          // إذا كان الملف صغير جداً، نحذفه
          if (fileSize < 1000) { // أقل من 1KB
            await file.delete();
            _currentRecordingPath = null;
            return null;
          }

          return _currentRecordingPath;
        }
      }

      return null;
    } catch (e) {
      throw Exception('فشل في إيقاف التسجيل: $e');
    }
  }

  // إلغاء التسجيل
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stopRecorder();
        _isRecording = false;
      }

      // حذف الملف إذا كان موجوداً
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
        _currentRecordingPath = null;
      }

      _recordingDuration = Duration.zero;
    } catch (e) {
      throw Exception('فشل في إلغاء التسجيل: $e');
    }
  }

  // بدء عداد المدة
  void _startDurationTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording) {
        _recordingDuration += const Duration(seconds: 1);
        _startDurationTimer();
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
      return _recorder.isRecording;
    } catch (e) {
      return false;
    }
  }

  // تنظيف الموارد
  void dispose() {
    _recorder.closeRecorder();
  }
} 