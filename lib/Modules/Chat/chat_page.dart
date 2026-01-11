import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[300],
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[300],
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)?.translate('chat') ?? 'المحادثات',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [],
      ),
      body: authProvider.isLoggedIn 
          ? _buildLoggedInContent(context, chatProvider)
          : _buildNotLoggedInContent(context),
    );
  }

  Widget _buildLoggedInContent(BuildContext context, ChatProvider chatProvider) {
    // Initialize chat provider if user is logged in
    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      // Always re-initialize if user data has changed (important for artisans)
      if (chatProvider.currentUser == null || 
          chatProvider.currentUser!.id != authProvider.currentUser!.id ||
          chatProvider.currentUser!.artisanId != authProvider.currentUser!.artisanId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print('🔄 [ChatPage] Initializing ChatProvider with user: ${authProvider.currentUser!.id}');
          print('🔄 [ChatPage] User type: ${authProvider.currentUser!.userType}');
          print('🔄 [ChatPage] Artisan ID: ${authProvider.currentUser!.artisanId ?? 'null'}');
          chatProvider.initialize(authProvider.currentUser!);
        });
      }
    }

    // Use Consumer to listen to ChatProvider updates
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            if (authProvider.currentUser != null) {
              // Refresh chat rooms
              chatProvider.refreshChatRooms();
              // Wait a bit for the stream to update
              await Future.delayed(const Duration(milliseconds: 500));
            }
          },
          child: chatProvider.isLoading
              ? _buildLoadingContent(context)
              : chatProvider.chatRooms.isEmpty
                  ? _buildEmptyContent(context)
                  : _buildChatRoomsList(context, chatProvider),
        );
      },
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
        ],
      ),
    );
  }

  Widget _buildChatRoomsList(BuildContext context, ChatProvider chatProvider) {
    // Use getFilteredChatRooms to ensure we only show rooms where user is a participant
    final filteredRooms = chatProvider.getFilteredChatRooms();
    
    print('📋 [ChatPage] Building chat rooms list with ${filteredRooms.length} rooms');
    
    // CRITICAL: Use effectiveUserId from ChatProvider (artisanId for artisans, userId for regular users)
    // This ensures that ChatRoomTile can correctly identify the other participant
    String currentUserId = chatProvider.effectiveUserId;
    
    print('═══════════════════════════════════════════════════════');
    print('🔍 [ChatPage] BUILDING CHAT ROOMS LIST');
    print('🔍 [ChatPage] ChatProvider currentUser: ${chatProvider.currentUser?.id ?? 'null'} (name: ${chatProvider.currentUser?.name ?? 'null'})');
    print('🔍 [ChatPage] ChatProvider effectiveUserId: "$currentUserId"');
    print('🔍 [ChatPage] User type: ${chatProvider.currentUser?.userType ?? 'unknown'}');
    print('🔍 [ChatPage] Artisan ID: ${chatProvider.currentUser?.artisanId ?? 'null'}');
    print('🔍 [ChatPage] Number of rooms: ${filteredRooms.length}');
    print('═══════════════════════════════════════════════════════');
    
    if (currentUserId.isEmpty) {
      print('❌ [ChatPage] ERROR: effectiveUserId is empty!');
      return Center(
        child: Text(
          'لا يمكن تحديد المستخدم الحالي',
          style: TextStyle(
            fontSize: 16.sp,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(AppConstants.padding),
      itemCount: filteredRooms.length,
      itemBuilder: (context, index) {
        final room = filteredRooms[index];
        print('🔍 [ChatPage] Building tile ${index + 1}/${filteredRooms.length}');
        print('🔍 [ChatPage] Room ID: ${room.id}');
        print('🔍 [ChatPage] Room Participant1: ${room.participant1Id}');
        print('🔍 [ChatPage] Room Participant2: ${room.participant2Id}');
        print('🔍 [ChatPage] Current User ID: $currentUserId');
        return ChatRoomTile(
          room: room,
          currentUserId: currentUserId,
          onTap: () async {
            // Show loading indicator
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            );
            
            try {
              await chatProvider.openChatRoom(room.id);
              
              // Close loading dialog
              if (context.mounted) {
                Navigator.of(context).pop();
              }
              
              // Navigate to chat room
              if (context.mounted && chatProvider.currentRoom != null) {
                context.push('/chat-room');
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)?.translate('failed_to_open_chat') ?? 'فشل في فتح المحادثة'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } catch (e) {
              // Close loading dialog
              if (context.mounted) {
                Navigator.of(context).pop();
              }
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${AppLocalizations.of(context)?.translate('failed_to_open_chat') ?? 'فشل في فتح المحادثة'}: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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
              title: Text(AppLocalizations.of(context)?.translate('delete_chat_title') ?? 'حذف المحادثة'),
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
        title: Text(AppLocalizations.of(context)?.translate('delete_chat_title') ?? 'حذف المحادثة'),
        content: Text(AppLocalizations.of(context)?.translate('delete_chat_confirmation') ?? 'هل أنت متأكد من حذف هذه المحادثة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.translate('cancel') ?? 'إلغاء'),
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