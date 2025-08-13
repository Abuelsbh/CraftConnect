import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../Models/chat_model.dart';
import '../../../Models/user_model.dart';
import '../../../providers/chat_provider.dart';
import '../../../core/Language/locales.dart';
import 'widgets/message_bubble.dart';
import 'widgets/chat_input.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  UserModel? _otherParticipant;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOtherParticipantInfo();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadOtherParticipantInfo() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    if (chatProvider.currentRoom != null) {
      // Load other participant info
      // This would typically come from a service
      setState(() {
        _otherParticipant = null; // Placeholder
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundImage: _otherParticipant?.profileImageUrl != null
                  ? NetworkImage(_otherParticipant!.profileImageUrl!)
                  : null,
              child: _otherParticipant?.profileImageUrl == null
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _otherParticipant?.name ?? 'مستخدم',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'متصل الآن',
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
            onPressed: () => _showChatOptions(context),
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(context),
          ),
          ChatInput(
            onSendMessage: (text) {
              // سيتم التعامل مع الإرسال داخل ChatInput
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.currentMessages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 64.w,
                  color: Theme.of(context).colorScheme.outline,
                ),
                SizedBox(height: 16.h),
                Text(
                  AppLocalizations.of(context)?.translate('no_messages') ?? 'لا توجد رسائل',
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
          padding: EdgeInsets.all(16.w),
          itemCount: chatProvider.currentMessages.length,
          itemBuilder: (context, index) {
            final message = chatProvider.currentMessages[index];
            final isMe = message.senderId == chatProvider.currentUser?.id;
            final showTime = index == 0 ||
                index > 0 &&
                    !_isSameDay(
                      message.timestamp,
                      chatProvider.currentMessages[index - 1].timestamp,
                    );

            return MessageBubble(
              message: message,
              isMe: isMe,
              showTime: showTime,
              onLongPress: () => _showMessageOptions(context, message),
            );
          },
        );
      },
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: Text(
                AppLocalizations.of(context)?.translate('delete_chat') ?? 'حذف المحادثة',
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded),
              title: Text(
                AppLocalizations.of(context)?.translate('block_user') ?? 'حظر المستخدم',
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement block user
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context, ChatMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: Text(
                AppLocalizations.of(context)?.translate('copy_text') ?? 'نسخ النص',
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement copy text
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: Text(
                AppLocalizations.of(context)?.translate('delete_message') ?? 'حذف الرسالة',
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(message.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteChat() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    if (chatProvider.currentRoom != null) {
      chatProvider.deleteChatRoom(chatProvider.currentRoom!.id);
      context.pop();
    }
  }

  void _deleteMessage(String messageId) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.deleteMessage(messageId);
  }
} 