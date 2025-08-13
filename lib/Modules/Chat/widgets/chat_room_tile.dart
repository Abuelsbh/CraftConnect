import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../Models/chat_model.dart';
import '../../../Models/user_model.dart';
import '../../../Utilities/app_constants.dart';

class ChatRoomTile extends StatelessWidget {
  final ChatRoom room;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ChatRoomTile({
    super.key,
    required this.room,
    required this.currentUserId,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              _buildAvatar(context),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    SizedBox(height: 4.h),
                    _buildLastMessage(context),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              _buildTimeAndBadge(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _getOtherParticipantInfo(),
      builder: (context, snapshot) {
        String? imageUrl;
        String name = 'مستخدم';
        
        if (snapshot.hasData && snapshot.data != null) {
          imageUrl = snapshot.data!.profileImageUrl;
          name = snapshot.data!.name;
        }

        return CircleAvatar(
          radius: 24.r,
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
          child: imageUrl == null || imageUrl.isEmpty
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _getOtherParticipantInfo(),
      builder: (context, snapshot) {
        String name = 'مستخدم';
        bool isOnline = false;

        if (snapshot.hasData && snapshot.data != null) {
          name = snapshot.data!.name;
          // TODO: Implement online status
          isOnline = false;
        }

        return Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isOnline)
              Container(
                width: 8.w,
                height: 8.w,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLastMessage(BuildContext context) {
    if (room.lastMessage == null) {
      return Text(
        'لا توجد رسائل',
        style: TextStyle(
          fontSize: 14.sp,
          color: Theme.of(context).colorScheme.outline,
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            room.lastMessage!,
            style: TextStyle(
              fontSize: 14.sp,
              color: room.hasUnreadMessages
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.outline,
              fontWeight: room.hasUnreadMessages ? FontWeight.w500 : FontWeight.normal,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeAndBadge(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (room.lastMessageTime != null)
          Text(
            _formatTime(room.lastMessageTime!),
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        SizedBox(height: 4.h),
        if (room.unreadCount > 0)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              room.unreadCount > 99 ? '99+' : room.unreadCount.toString(),
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Future<UserModel?> _getOtherParticipantInfo() async {
    // Get the other participant ID
    final otherId = room.participant1Id == currentUserId
        ? room.participant2Id
        : room.participant1Id;
    
    // This would typically come from a service
    // For now, we'll return null and handle it in the UI
    return null;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return DateFormat('dd/MM').format(time);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}س';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}د';
    } else {
      return 'الآن';
    }
  }
} 