import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../Utilities/app_constants.dart';
import '../../providers/chat_provider.dart';
import '../../Models/chat_model.dart';
import '../../Models/user_model.dart';
import '../../providers/simple_auth_provider.dart';
import 'widgets/message_bubble.dart';
import 'widgets/chat_input.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ScrollController _scrollController = ScrollController();
  UserModel? _otherParticipant;

  @override
  void initState() {
    super.initState();
    _loadOtherParticipantInfo();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadOtherParticipantInfo() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final otherParticipant = await chatProvider.getOtherParticipantInfo();
    if (mounted) {
      setState(() {
        _otherParticipant = otherParticipant;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<SimpleAuthProvider>(context);

    if (chatProvider.currentRoom == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('المحادثة'),
        ),
        body: Center(
          child: Text('لا توجد محادثة مفتوحة'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context, chatProvider),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(context, chatProvider),
          ),
          _buildChatInput(context, chatProvider),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ChatProvider chatProvider) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 1,
      leading: IconButton(
        onPressed: () {
          chatProvider.closeCurrentRoom();
          context.pop();
        },
        icon: Icon(
          Icons.arrow_back_rounded,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      title: Row(
        children: [
          _buildParticipantAvatar(context),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _otherParticipant?.name ?? 'مستخدم',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  'متصل الآن', // TODO: Implement online status
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            _showChatOptions(context, chatProvider);
          },
          icon: Icon(
            Icons.more_vert_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantAvatar(BuildContext context) {
    return CircleAvatar(
      radius: 18.r,
      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      backgroundImage: _otherParticipant?.profileImageUrl != null && _otherParticipant!.profileImageUrl.isNotEmpty
          ? NetworkImage(_otherParticipant!.profileImageUrl)
          : null,
      child: _otherParticipant?.profileImageUrl == null || _otherParticipant!.profileImageUrl.isEmpty
          ? Text(
              (_otherParticipant?.name.isNotEmpty == true
                      ? _otherParticipant!.name[0]
                      : '?')
                  .toUpperCase(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : null,
    );
  }

  Widget _buildMessagesList(BuildContext context, ChatProvider chatProvider) {
    if (chatProvider.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (chatProvider.currentMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64.w,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              'لا توجد رسائل بعد',
              style: TextStyle(
                fontSize: 16.sp,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'ابدأ المحادثة بإرسال رسالة',
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(AppConstants.padding),
      itemCount: chatProvider.currentMessages.length,
      itemBuilder: (context, index) {
        final message = chatProvider.currentMessages[index];
        final isMe = message.senderId == chatProvider.currentUser?.id;
        
        // Auto scroll to bottom for new messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (index == chatProvider.currentMessages.length - 1) {
            _scrollToBottom();
          }
        });

        return MessageBubble(
          message: message,
          isMe: isMe,
          showTime: _shouldShowTime(index, chatProvider.currentMessages),
          onLongPress: () {
            _showMessageOptions(context, chatProvider, message);
          },
        );
      },
    );
  }

  Widget _buildChatInput(BuildContext context, ChatProvider chatProvider) {
    return ChatInput(
      onSendMessage: (message) async {
        await chatProvider.sendMessage(message);
      },
      onSendImage: (imagePath) async {
        // TODO: Implement image upload and sending
        await chatProvider.sendMessage(
          'صورة',
          imageUrl: imagePath,
          type: MessageType.image,
        );
      },
    );
  }

  bool _shouldShowTime(int index, List<ChatMessage> messages) {
    if (index == 0) return true;
    
    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];
    
    final difference = currentMessage.timestamp.difference(previousMessage.timestamp);
    return difference.inMinutes >= 5;
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showChatOptions(BuildContext context, ChatProvider chatProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(AppConstants.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.block_rounded, color: Colors.red),
              title: Text('حظر المستخدم'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement block user
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_rounded, color: Colors.red),
              title: Text('حذف المحادثة'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, chatProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context, ChatProvider chatProvider, ChatMessage message) {
    final isMe = message.senderId == chatProvider.currentUser?.id;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(AppConstants.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMe)
              ListTile(
                leading: Icon(Icons.delete_rounded, color: Colors.red),
                title: Text('حذف الرسالة'),
                onTap: () {
                  Navigator.pop(context);
                  chatProvider.deleteMessage(message.id);
                },
              ),
            ListTile(
              leading: Icon(Icons.copy_rounded),
              title: Text('نسخ النص'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم نسخ النص')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ChatProvider chatProvider) {
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
              chatProvider.deleteChatRoom(chatProvider.currentRoom!.id);
              context.pop();
            },
            child: Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 