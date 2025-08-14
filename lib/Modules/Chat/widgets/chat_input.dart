import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../Utilities/app_constants.dart';
import '../../../core/Language/locales.dart';
import '../../../providers/chat_provider.dart';
import '../../../services/media_service.dart';
import '../../../services/voice_recorder_service.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(String)? onSendImage;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.onSendImage,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final MediaService _mediaService = MediaService();
  final VoiceRecorderService _voiceRecorder = VoiceRecorderService();
  
  bool _isComposing = false;
  bool _isRecording = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    _voiceRecorder.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isComposing = _messageController.text.trim().isNotEmpty;
    });
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.sendTextMessage(text.trim());
      _messageController.clear();
      setState(() {
        _isComposing = false;
      });
    } catch (e) {
      _showErrorSnackBar('فشل في إرسال الرسالة: $e');
    }
  }

  void _handleSendPressed() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      _handleSubmitted(text);
    }
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildAttachmentOptions(context),
    );
  }

  Widget _buildAttachmentOptions(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.photo_rounded, color: Theme.of(context).colorScheme.primary),
            title: Text(AppLocalizations.of(context)?.translate('image_from_gallery') ?? 'صورة من المعرض'),
            onTap: () {
              Navigator.pop(context);
              _pickImageFromGallery();
            },
          ),
          ListTile(
            leading: Icon(Icons.camera_alt_rounded, color: Theme.of(context).colorScheme.primary),
            title: Text(AppLocalizations.of(context)?.translate('take_photo') ?? 'التقاط صورة'),
            onTap: () {
              Navigator.pop(context);
              _takePhoto();
            },
          ),
          ListTile(
            leading: Icon(Icons.attach_file_rounded, color: Theme.of(context).colorScheme.primary),
            title: Text(AppLocalizations.of(context)?.translate('send_file') ?? 'ملف'),
            onTap: () {
              Navigator.pop(context);
              _pickFile();
            },
          ),
          ListTile(
            leading: Icon(Icons.location_on_rounded, color: Theme.of(context).colorScheme.primary),
            title: Text(AppLocalizations.of(context)?.translate('send_location') ?? 'إرسال الموقع'),
            onTap: () {
              Navigator.pop(context);
              _sendLocation();
            },
          ),
          ListTile(
            leading: Icon(Icons.mic_rounded, color: Theme.of(context).colorScheme.primary),
            title: Text(AppLocalizations.of(context)?.translate('record_voice') ?? 'تسجيل صوتي'),
            onTap: () {
              Navigator.pop(context);
              _startVoiceRecording();
            },
          ),
        ],
      ),
    );
  }

  void _pickImageFromGallery() async {
    try {
      setState(() => _isUploading = true);
      
      print('📸 بدء اختيار صورة من المعرض...');
      final imageUrl = await _mediaService.uploadImageFromGallery();
      
      if (imageUrl != null && mounted) {
        print('📤 إرسال الصورة في المحادثة...');
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        await chatProvider.sendImageMessage(imageUrl);
        print('✅ تم إرسال الصورة بنجاح!');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إرسال الصورة بنجاح'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('❌ لم يتم اختيار صورة');
      }
    } catch (e) {
      print('❌ خطأ في رفع الصورة: $e');
      if (mounted) {
        _showErrorSnackBar('فشل في رفع الصورة: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _takePhoto() async {
    try {
      setState(() => _isUploading = true);
      
      print('📸 بدء التقاط صورة من الكاميرا...');
      final imageUrl = await _mediaService.uploadImageFromCamera();
      
      if (imageUrl != null && mounted) {
        print('📤 إرسال الصورة في المحادثة...');
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        await chatProvider.sendImageMessage(imageUrl);
        print('✅ تم إرسال الصورة بنجاح!');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إرسال الصورة بنجاح'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('❌ لم يتم التقاط صورة');
      }
    } catch (e) {
      print('❌ خطأ في التقاط الصورة: $e');
      if (mounted) {
        _showErrorSnackBar('فشل في التقاط الصورة: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _pickFile() async {
    try {
      setState(() => _isUploading = true);
      
      print('📁 بدء اختيار ملف...');
      final fileData = await _mediaService.uploadFile();
      
      if (fileData != null && mounted) {
        print('📤 إرسال الملف في المحادثة...');
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        await chatProvider.sendFileMessage(
          fileData['url']!,
          fileData['name']!,
          fileData['size']!,
        );
        print('✅ تم إرسال الملف بنجاح!');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم إرسال الملف: ${fileData['name']}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('❌ لم يتم اختيار ملف');
        if (mounted) {
          _showErrorSnackBar('لم يتم اختيار ملف');
        }
      }
    } catch (e) {
      print('❌ خطأ في رفع الملف: $e');
      if (mounted) {
        _showErrorSnackBar('فشل في رفع الملف: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _sendLocation() async {
    try {
      setState(() => _isUploading = true);
      
      print('📍 بدء الحصول على الموقع الحالي...');
      final locationData = await _mediaService.getCurrentLocation();
      
      if (locationData != null && mounted) {
        print('📤 إرسال الموقع في المحادثة...');
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        await chatProvider.sendLocationMessage(locationData);
        print('✅ تم إرسال الموقع بنجاح!');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إرسال الموقع بنجاح'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('❌ لم يتم الحصول على الموقع');
        if (mounted) {
          _showErrorSnackBar('فشل في الحصول على الموقع');
        }
      }
    } catch (e) {
      print('❌ خطأ في الحصول على الموقع: $e');
      if (mounted) {
        _showErrorSnackBar('فشل في الحصول على الموقع: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _startVoiceRecording() async {
    try {
      await _voiceRecorder.startRecording();
      setState(() => _isRecording = true);
      
      // عرض نافذة التسجيل
      _showRecordingDialog();
    } catch (e) {
      _showErrorSnackBar('فشل في بدء التسجيل: $e');
    }
  }

  void _stopVoiceRecording() async {
    try {
      final audioPath = await _voiceRecorder.stopRecording();
      setState(() => _isRecording = false);
      
      if (audioPath != null) {
        setState(() => _isUploading = true);
        
        print('🎤 بدء رفع الرسالة الصوتية...');
        final voiceUrl = await _mediaService.uploadVoiceMessage(audioPath);
        
        if (voiceUrl != null && mounted) {
          print('📤 إرسال الرسالة الصوتية في المحادثة...');
          final chatProvider = Provider.of<ChatProvider>(context, listen: false);
          final duration = _voiceRecorder.recordingDuration.inSeconds;
          await chatProvider.sendVoiceMessage(voiceUrl, duration);
          print('✅ تم إرسال الرسالة الصوتية بنجاح!');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم إرسال الرسالة الصوتية (${duration}s)'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          print('❌ فشل في رفع الرسالة الصوتية');
          if (mounted) {
            _showErrorSnackBar('فشل في رفع الرسالة الصوتية');
          }
        }
      } else {
        print('❌ لم يتم تسجيل رسالة صوتية');
      }
    } catch (e) {
      print('❌ خطأ في إرسال الرسالة الصوتية: $e');
      if (mounted) {
        _showErrorSnackBar('فشل في إرسال الرسالة الصوتية: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _cancelVoiceRecording() async {
    try {
      await _voiceRecorder.cancelRecording();
      setState(() => _isRecording = false);
    } catch (e) {
      _showErrorSnackBar('فشل في إلغاء التسجيل: $e');
    }
  }

  void _showRecordingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildRecordingDialog(context),
    );
  }

  Widget _buildRecordingDialog(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)?.translate('recording') ?? 'تسجيل...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic_rounded,
            size: 48.w,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(height: 16.h),
          StreamBuilder<Duration>(
            stream: Stream.periodic(const Duration(seconds: 1), (_) => _voiceRecorder.recordingDuration),
            builder: (context, snapshot) {
              return Text(
                _voiceRecorder.formatDuration(snapshot.data ?? Duration.zero),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _cancelVoiceRecording();
          },
          child: Text(AppLocalizations.of(context)?.translate('cancel') ?? 'إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _stopVoiceRecording();
          },
          child: Text(AppLocalizations.of(context)?.translate('stop_recording') ?? 'إيقاف التسجيل'),
        ),
      ],
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildAttachmentButton(context),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildTextField(context),
            ),
            SizedBox(width: 8.w),
            _buildSendButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: IconButton(
        onPressed: _isUploading ? null : _handleAttachmentPressed,
        icon: _isUploading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : Icon(
                Icons.attach_file_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20.w,
              ),
        constraints: BoxConstraints(
          minWidth: 40.w,
          minHeight: 40.h,
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Stack(
        children: [
          TextField(
            controller: _messageController,
            focusNode: _focusNode,
            textInputAction: TextInputAction.send,
            enabled: !_isUploading,
            onSubmitted: _handleSubmitted,
            decoration: InputDecoration(
              hintText: _isUploading ? 'جاري الرفع...' : 'اكتب رسالة...',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 14.sp,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
            ),
            maxLines: null,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (_isUploading)
            Positioned(
              right: 12.w,
              top: 0,
              bottom: 0,
              child: Center(
                child: SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSendButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _isComposing
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: IconButton(
        onPressed: (_isComposing && !_isUploading) ? _handleSendPressed : null,
        icon: _isUploading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _isComposing ? Colors.white : Theme.of(context).colorScheme.outline,
                ),
              )
            : Icon(
                Icons.send_rounded,
                color: _isComposing
                    ? Colors.white
                    : Theme.of(context).colorScheme.outline,
                size: 20.w,
              ),
        constraints: BoxConstraints(
          minWidth: 40.w,
          minHeight: 40.h,
        ),
      ),
    );
  }
} 