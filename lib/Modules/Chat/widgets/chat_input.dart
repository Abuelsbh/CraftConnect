import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../Utilities/app_constants.dart';

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
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isComposing = _messageController.text.trim().isNotEmpty;
    });
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    
    widget.onSendMessage(text.trim());
    _messageController.clear();
    setState(() {
      _isComposing = false;
    });
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
            title: Text('صورة من المعرض'),
            onTap: () {
              Navigator.pop(context);
              _pickImageFromGallery();
            },
          ),
          ListTile(
            leading: Icon(Icons.camera_alt_rounded, color: Theme.of(context).colorScheme.primary),
            title: Text('التقاط صورة'),
            onTap: () {
              Navigator.pop(context);
              _takePhoto();
            },
          ),
          ListTile(
            leading: Icon(Icons.attach_file_rounded, color: Theme.of(context).colorScheme.primary),
            title: Text('ملف'),
            onTap: () {
              Navigator.pop(context);
              _pickFile();
            },
          ),
          ListTile(
            leading: Icon(Icons.location_on_rounded, color: Theme.of(context).colorScheme.primary),
            title: Text('إرسال الموقع'),
            onTap: () {
              Navigator.pop(context);
              _sendLocation();
            },
          ),
        ],
      ),
    );
  }

  void _pickImageFromGallery() {
    // TODO: Implement image picker from gallery
    // For now, we'll just send a placeholder message
    widget.onSendImage?.call('gallery_image_path');
  }

  void _takePhoto() {
    // TODO: Implement camera functionality
    // For now, we'll just send a placeholder message
    widget.onSendImage?.call('camera_image_path');
  }

  void _pickFile() {
    // TODO: Implement file picker
    // For now, we'll just send a placeholder message
    widget.onSendMessage('ملف مرفق');
  }

  void _sendLocation() {
    // TODO: Implement location sharing
    // For now, we'll just send a placeholder message
    widget.onSendMessage('الموقع الحالي');
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
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: IconButton(
        onPressed: _handleAttachmentPressed,
        icon: Icon(
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
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: TextField(
        controller: _messageController,
        focusNode: _focusNode,
        textInputAction: TextInputAction.send,
        onSubmitted: _handleSubmitted,
        decoration: InputDecoration(
          hintText: 'اكتب رسالة...',
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
    );
  }

  Widget _buildSendButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _isComposing
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: IconButton(
        onPressed: _isComposing ? _handleSendPressed : null,
        icon: Icon(
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