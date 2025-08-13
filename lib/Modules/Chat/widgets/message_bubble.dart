import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../Models/chat_model.dart';
import '../../../Utilities/app_constants.dart';

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
          left: isMe ? 50.w : 0,
          right: isMe ? 0 : 50.w,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
            : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16.r).copyWith(
          bottomLeft: isMe ? Radius.circular(16.r) : Radius.circular(4.r),
          bottomRight: isMe ? Radius.circular(4.r) : Radius.circular(16.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
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
        ClipRRect(
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
        if (message.content.isNotEmpty) ...[
          SizedBox(height: 8.h),
          _buildTextMessage(context),
        ],
      ],
    );
  }

  Widget _buildFileMessage(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.w),
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
          Icon(
            Icons.attach_file_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 20.w,
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMessage(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.w),
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
          Icon(
            Icons.location_on_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 20.w,
          ),
          SizedBox(width: 8.w),
          Text(
            'الموقع',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
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
    } else if (messageDate == today.subtract(Duration(days: 1))) {
      return 'أمس';
    } else {
      return DateFormat('dd/MM').format(time);
    }
  }
} 