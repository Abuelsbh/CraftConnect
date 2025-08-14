import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';
import '../../providers/simple_auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../Models/chat_model.dart';
import 'widgets/chat_room_tile.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<SimpleAuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)?.translate('chat') ?? 'المحادثات',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          if (authProvider.isLoggedIn)
            IconButton(
              onPressed: () {
                // TODO: Add search functionality
                context.push('/search');
              },
              icon: Icon(
                Icons.search_rounded,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
        ],
      ),
      body: authProvider.isLoggedIn 
          ? _buildLoggedInContent(context, chatProvider)
          : _buildNotLoggedInContent(context),
    );
  }

  Widget _buildLoggedInContent(BuildContext context, ChatProvider chatProvider) {
    // Initialize chat provider if user is logged in
    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
    if (authProvider.currentUser != null && chatProvider.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        chatProvider.initialize(authProvider.currentUser!);
      });
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (authProvider.currentUser != null) {
          chatProvider.initialize(authProvider.currentUser!);
        }
      },
      child: chatProvider.isLoading
          ? _buildLoadingContent(context)
          : chatProvider.chatRooms.isEmpty
              ? _buildEmptyContent(context)
              : _buildChatRoomsList(context, chatProvider),
    );
  }

  Widget _buildLoadingContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(height: 16.h),
          Text(
            'جاري تحميل المحادثات...',
            style: TextStyle(
              fontSize: 16.sp,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 80.w,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          SizedBox(height: AppConstants.padding),
          Text(
            'لا توجد محادثات',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: AppConstants.smallPadding),
          Text(
            'ابدأ محادثة مع الحرفيين لطلب خدماتهم',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.padding),
          ElevatedButton.icon(
            onPressed: () {
              context.push('/search');
            },
            icon: Icon(Icons.search_rounded, size: 20.w),
            label: Text(
              'البحث عن حرفيين',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 12.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoomsList(BuildContext context, ChatProvider chatProvider) {
    final filteredRooms = chatProvider.getFilteredChatRooms();
    
    return ListView.builder(
      padding: EdgeInsets.all(AppConstants.padding),
      itemCount: filteredRooms.length,
      itemBuilder: (context, index) {
        final room = filteredRooms[index];
        return ChatRoomTile(
          room: room,
          currentUserId: chatProvider.currentUser?.id ?? '',
          onTap: () async {
            await chatProvider.openChatRoom(room.id);
            if (context.mounted) {
              context.push('/chat-room');
            }
          },
          onLongPress: () {
            _showChatRoomOptions(context, chatProvider, room);
          },
        );
      },
    );
  }

  void _showChatRoomOptions(BuildContext context, ChatProvider chatProvider, ChatRoom room) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(AppConstants.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.delete_rounded, color: Colors.red),
              title: Text('حذف المحادثة'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, chatProvider, room);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ChatProvider chatProvider, ChatRoom room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حذف المحادثة'),
        content: Text('هل أنت متأكد من حذف هذه المحادثة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              chatProvider.deleteChatRoom(room.id);
            },
            child: Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedInContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 80.w,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          SizedBox(height: AppConstants.padding),
          Text(
            'يجب تسجيل الدخول أولاً',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: AppConstants.smallPadding),
          Text(
            'سجل دخولك للبدء في المحادثة مع الحرفيين',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.padding),
          ElevatedButton(
            onPressed: () {
              context.push('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 32.w,
                vertical: 12.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)?.translate('login') ?? 'تسجيل الدخول',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 