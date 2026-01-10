import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../../../Models/chat_model.dart';
import '../../../core/Language/locales.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showTime;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showTime = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
          margin: EdgeInsets.only(
            bottom: 8.h,
            // عكس أماكن الرسائل: رسائلك تصبح في الجهة المقابلة لرسائل الطرف الآخر
            left: isMe ? 0 : 10.w,
            right: isMe ? 10.w : 0,
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              if (showTime) _buildTimeStamp(context),
              SizedBox(height: 4.h),
              _buildMessageContent(context),
            ],
          ),
        ),
    );
  }

  Widget _buildTimeStamp(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Text(
        _formatTime(message.timestamp),
        style: TextStyle(
          fontSize: 12.sp,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        color: isMe
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16.r).copyWith(
          bottomLeft: isMe ? Radius.circular(16.r) : Radius.circular(4.r),
          bottomRight: isMe ? Radius.circular(4.r) : Radius.circular(16.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMessageBody(context),
          SizedBox(height: 4.h),
          _buildMessageStatus(context),
        ],
      ),
    );
  }

  Widget _buildMessageBody(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return _buildTextMessage(context);
      case MessageType.image:
        return _buildImageMessage(context);
      case MessageType.file:
        return _buildFileMessage(context);
      case MessageType.location:
        return _buildLocationMessage(context);
      case MessageType.voice:
        return _buildVoiceMessage(context);
    }
  }

  Widget _buildTextMessage(BuildContext context) {
    return Text(
      message.content,
      style: TextStyle(
        fontSize: 14.sp,
        color: isMe
            ? Colors.white
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildImageMessage(BuildContext context) {
    if (message.imageUrl == null) {
      return _buildTextMessage(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showFullScreenImage(context, message.imageUrl!),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Image.network(
              message.imageUrl!,
              width: 200.w,
              height: 150.h,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200.w,
                  height: 150.h,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                );
              },
            ),
          ),
        ),
        if (message.content.isNotEmpty) ...[
          SizedBox(height: 8.h),
          _buildTextMessage(context),
        ],
      ],
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenImagePage(imageUrl: imageUrl),
      ),
    );
  }

  Widget _buildFileMessage(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFile(context),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.attach_file_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 24.w,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.fileName ?? message.content,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (message.fileSize != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      _formatFileSize(int.tryParse(message.fileSize!) ?? 0),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                  SizedBox(height: 4.h),
                  Text(
                    'اضغط لفتح الملف',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Theme.of(context).colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.open_in_new_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 20.w,
            ),
          ],
        ),
      ),
    );
  }

  void _openFile(BuildContext context) async {
    if (message.fileUrl == null || message.fileUrl!.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.translate('file_link_unavailable') ?? 'رابط الملف غير متوفر'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      print('📁 بدء فتح الملف: ${message.fileUrl}');
      
      // عرض مؤشر التحميل
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text('جاري تحميل الملف...'),
                ),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // تحميل الملف من Firebase Storage
      final fileUrl = message.fileUrl!;
      final fileName = message.fileName ?? 'file_${DateTime.now().millisecondsSinceEpoch}';
      
      print('📥 تحميل الملف من: $fileUrl');
      final response = await http.get(Uri.parse(fileUrl));
      
      if (response.statusCode != 200) {
        throw Exception('فشل في تحميل الملف: ${response.statusCode}');
      }

      // الحصول على مجلد التخزين المؤقت
      final tempDir = await getTemporaryDirectory();
      final fileExtension = path.extension(fileName);
      final localFileName = '${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final localFile = File(path.join(tempDir.path, localFileName));
      
      // حفظ الملف محلياً
      await localFile.writeAsBytes(response.bodyBytes);
      print('✅ تم حفظ الملف محلياً: ${localFile.path}');
      
      // فتح الملف باستخدام open_file
      final result = await OpenFile.open(localFile.path);
      
      if (context.mounted) {
        // إغلاق مؤشر التحميل
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        if (result.type == ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم فتح الملف: ${message.fileName ?? "الملف"}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (result.type == ResultType.noAppToOpen) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('لا يوجد تطبيق لفتح هذا النوع من الملفات'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          throw Exception('فشل في فتح الملف: ${result.message}');
        }
      }
    } catch (e) {
      print('❌ خطأ في فتح الملف: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.translate('failed_to_open_file') ?? 'فشل في فتح الملف'}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  Widget _buildLocationMessage(BuildContext context) {
    return GestureDetector(
      onTap: () => _openLocationInMaps(context),
      child: Container(
        width: 250.w,
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة مصغرة للخريطة
            Container(
              width: double.infinity,
              height: 120.h,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Stack(
                children: [
                  // خلفية الخريطة
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.map_rounded,
                      size: 40.w,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  // أيقونة الموقع
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 16.w,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            // معلومات الموقع
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16.w,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    'الموقع',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.open_in_new_rounded,
                  color: Theme.of(context).colorScheme.outline,
                  size: 16.w,
                ),
              ],
            ),
            if (message.locationData?.address != null) ...[
              SizedBox(height: 4.h),
              Text(
                message.locationData!.address!,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.outline,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: 4.h),
            Text(
              'اضغط لفتح في الخرائط',
              style: TextStyle(
                fontSize: 10.sp,
                color: Theme.of(context).colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLocationInMaps(BuildContext context) async {
    if (message.locationData == null) return;
    
    final latitude = message.locationData!.latitude;
    final longitude = message.locationData!.longitude;
    
    // إنشاء رابط جوجل ماب
    final url = 'https://www.google.com/maps?q=$latitude,$longitude';
    
    try {
      print('📍 فتح الموقع في الخرائط: $url');
      
      // محاولة فتح الرابط
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // عرض رسالة نجاح
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.translate('location_opened_maps') ?? 'تم فتح الموقع في الخرائط'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('لا يمكن فتح الرابط');
      }
    } catch (e) {
      print('❌ خطأ في فتح الخرائط: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.translate('failed_to_open_maps') ?? 'فشل في فتح الخرائط'}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildVoiceMessage(BuildContext context) {
    return _VoiceMessagePlayer(
      voiceUrl: message.voiceUrl ?? '',
      duration: message.voiceDuration,
      messageId: message.id,
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildMessageStatus(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isMe) ...[
          Icon(
            message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
            size: 16.w,
            color: message.isRead
                ? Colors.white
                : Colors.white.withValues(alpha: 0.7),
          ),
          SizedBox(width: 4.w),
        ],
        Text(
          _formatTime(message.timestamp),
          style: TextStyle(
            fontSize: 10.sp,
            color: isMe
                ? Colors.white.withValues(alpha: 0.8)
                : Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(time);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'أمس';
    } else {
      return DateFormat('dd/MM').format(time);
    }
  }
}

// صفحة عرض الصورة بالحجم الكامل
class _FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImagePage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          backgroundDecoration: const BoxDecoration(
            color: Colors.black,
          ),
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'فشل في تحميل الصورة',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
          loadingBuilder: (context, event) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }
}

// مشغل رسائل الصوت
class _VoiceMessagePlayer extends StatefulWidget {
  final String voiceUrl;
  final int? duration;
  final String messageId;

  const _VoiceMessagePlayer({
    required this.voiceUrl,
    this.duration,
    required this.messageId,
  });

  @override
  State<_VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<_VoiceMessagePlayer> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed) {
            _position = Duration.zero;
            _isPlaying = false;
          }
        });
      }
    });
  }

  Future<void> _togglePlayPause() async {
    if (widget.voiceUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.translate('voice_message_link_unavailable') ?? 'رابط الرسالة الصوتية غير متوفر'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_position == Duration.zero || _position >= _duration) {
          // بدء التشغيل من البداية
          await _audioPlayer.play(UrlSource(widget.voiceUrl));
        } else {
          // استئناف التشغيل
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      print('❌ خطأ في تشغيل الرسالة الصوتية: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.translate('failed_to_play_voice') ?? 'فشل في تشغيل الرسالة الصوتية'}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayDuration = _duration != Duration.zero 
        ? _duration 
        : (widget.duration != null 
            ? Duration(seconds: widget.duration!) 
            : Duration.zero);

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // زر التشغيل/الإيقاف
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24.w,
              ),
            ),
            SizedBox(width: 12.w),
            // معلومات الرسالة الصوتية
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'رسالة صوتية',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  // شريط التقدم
                  if (displayDuration != Duration.zero) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2.r),
                      child: LinearProgressIndicator(
                        value: _duration != Duration.zero && _duration.inMilliseconds > 0
                            ? _position.inMilliseconds / _duration.inMilliseconds
                            : 0.0,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                        minHeight: 3.h,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        Text(
                          _formatDuration(displayDuration),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ] else if (widget.duration != null) ...[
                    Text(
                      _formatDuration(Duration(seconds: widget.duration!)),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 