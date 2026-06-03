import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة لتشغيل صوت الإشعار عند استلام رسالة جديدة
class NotificationSoundService {
  static final NotificationSoundService _instance = NotificationSoundService._internal();
  factory NotificationSoundService() => _instance;
  NotificationSoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  DateTime? _lastPlayedAt;
  final List<String> _recentlyPlayedKeys = [];
  static const _minIntervalBetweenSounds = Duration(seconds: 10);
  static const _maxRecentKeys = 30;

  /// تشغيل صوت الإشعار مع مفتاح فريد لمنع التكرار (مرة واحدة لكل رسالة/محادثة)
  Future<void> playNotificationSound({String? key}) async {
    // منع التشغيل لنفس المفتاح (نفس الرسالة أو نفس تحديث المحادثة)
    final effectiveKey = key ?? DateTime.now().millisecondsSinceEpoch.toString();
    if (_recentlyPlayedKeys.contains(effectiveKey)) return;

    if (_isPlaying) return;
    final now = DateTime.now();
    if (_lastPlayedAt != null &&
        now.difference(_lastPlayedAt!) < _minIntervalBetweenSounds) {
      return;
    }
    _isPlaying = true;
    _lastPlayedAt = now;
    _recentlyPlayedKeys.add(effectiveKey);
    if (_recentlyPlayedKeys.length > _maxRecentKeys) {
      _recentlyPlayedKeys.removeAt(0);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('sound_enabled') == false) {
        _isPlaying = false;
        return;
      }

      await _audioPlayer.play(AssetSource('Audio/notification.mp3'));
      await _audioPlayer.onPlayerComplete.first;

      _isPlaying = false;
    } catch (e) {
      _isPlaying = false;
    }
  }

  /// إيقاف الصوت إذا كان قيد التشغيل
  Future<void> stop() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        _isPlaying = false;
      }
    } catch (e) {
      print('❌ [NotificationSoundService] خطأ في إيقاف الصوت: $e');
    }
  }

  /// تنظيف الموارد عند الحاجة
  void dispose() {
    _audioPlayer.dispose();
  }
}
