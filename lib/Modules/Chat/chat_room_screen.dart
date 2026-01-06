import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
      _scrollToBottom();
    });
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadOtherParticipantInfo() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    if (chatProvider.currentRoom != null) {
      try {
        // Load other participant info using ChatProvider
        final participantInfo = await chatProvider.getOtherParticipantInfo();
        if (mounted) {
          setState(() {
            _otherParticipant = participantInfo;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _otherParticipant = null;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Builder(
              builder: (context) {
                final imageProvider = _getImageProvider(_otherParticipant?.profileImageUrl);
                if (imageProvider != null) {
                  return CircleAvatar(
                    radius: 18.r,
                    backgroundImage: imageProvider,
                    onBackgroundImageError: (exception, stackTrace) {
                      // Handle image loading errors silently
                      // The fallback child will be shown
                    },
                    child: null,
                  );
                } else {
                  return CircleAvatar(
                    radius: 18.r,
                    child: const Icon(Icons.person, size: 20),
                  );
                }
              },
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
        // Get effective user ID from ChatProvider (artisanId for artisans, userId for regular users)
        // This is critical: when artisan sends a message, senderId is artisanId, not userId
        String currentUserId = chatProvider.effectiveUserId;
        
        if (currentUserId.isEmpty) {
          print('⚠️ [ChatRoomScreen] Warning: effectiveUserId is empty');
        } else {
          print('✅ [ChatRoomScreen] Using effectiveUserId: $currentUserId (userType: ${chatProvider.currentUser?.userType ?? 'unknown'})');
        }
        
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

        // Group messages by date
        final groupedMessages = _groupMessagesByDate(chatProvider.currentMessages);
        
        // Scroll to bottom when messages change
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
        
        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(16.w),
          itemCount: groupedMessages.length,
          itemBuilder: (context, index) {
            final dateGroup = groupedMessages[index];
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date header
                _buildDateHeader(context, dateGroup.date),
                SizedBox(height: 8.h),
                // Messages for this date - group consecutive messages from same sender
                ..._buildMessageGroup(dateGroup.messages, currentUserId),
                SizedBox(height: 8.h),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateHeader(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);
    
    String dateText;
    if (messageDate == today) {
      dateText = 'اليوم';
    } else if (messageDate == yesterday) {
      dateText = 'أمس';
    } else {
      // Format date in Arabic
      final formatter = DateFormat('EEEE، d MMMM yyyy', 'ar');
      dateText = formatter.format(date);
    }
    
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          dateText,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  List<DateMessageGroup> _groupMessagesByDate(List<ChatMessage> messages) {
    if (messages.isEmpty) return [];
    
    final groups = <DateMessageGroup>[];
    DateTime? currentDate;
    List<ChatMessage> currentGroup = [];
    
    for (final message in messages) {
      final messageDate = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day,
      );
      
      if (currentDate == null || !_isSameDay(currentDate, messageDate)) {
        // Save previous group if exists
        if (currentDate != null && currentGroup.isNotEmpty) {
          groups.add(DateMessageGroup(date: currentDate, messages: currentGroup));
        }
        // Start new group
        currentDate = messageDate;
        currentGroup = [message];
      } else {
        currentGroup.add(message);
      }
    }
    
    // Add last group
    if (currentDate != null && currentGroup.isNotEmpty) {
      groups.add(DateMessageGroup(date: currentDate, messages: currentGroup));
    }
    
    return groups;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  ImageProvider? _getImageProvider(String? imageData) {
    if (imageData == null || imageData.isEmpty) {
      return null;
    }

    // Check if it's a URL
    if (imageData.startsWith('http://') || imageData.startsWith('https://')) {
      return NetworkImage(imageData);
    }

    // Try to decode as base64
    try {
      final imageBytes = base64Decode(imageData);
      if (imageBytes.isNotEmpty) {
        return MemoryImage(imageBytes);
      }
    } catch (e) {
      // If decoding fails, it might be an invalid base64 string
      // Try as URL anyway
      try {
        return NetworkImage(imageData);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  List<Widget> _buildMessageGroup(List<ChatMessage> messages, String currentUserId) {
    if (messages.isEmpty) return [];
    
    final widgets = <Widget>[];
    ChatMessage? previousMessage;
    
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      // Normalize IDs for comparison (trim and handle case sensitivity)
      final normalizedSenderId = message.senderId.trim();
      final normalizedCurrentUserId = currentUserId.trim();
      final isMe = normalizedSenderId == normalizedCurrentUserId;
      
      // Determine if we should show time
      bool showTime = false;
      if (previousMessage == null) {
        // First message in group
        showTime = true;
      } else {
        // Show time if different sender or more than 5 minutes gap
        final timeDiff = message.timestamp.difference(previousMessage.timestamp);
        if (previousMessage.senderId != message.senderId || timeDiff.inMinutes > 5) {
          showTime = true;
        }
      }
      
      // Determine spacing
      double topMargin = 0;
      if (previousMessage != null && previousMessage.senderId == message.senderId) {
        // Same sender, reduce spacing
        topMargin = 2.h;
      } else {
        // Different sender, normal spacing
        topMargin = 8.h;
      }
      
      widgets.add(
        Container(
          margin: EdgeInsets.only(top: topMargin),
          child: MessageBubble(
            message: message,
            isMe: isMe,
            showTime: showTime,
            onLongPress: () => _showMessageOptions(context, message),
          ),
        ),
      );
      
      previousMessage = message;
    }
    
    return widgets;
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

// Helper class to group messages by date
class DateMessageGroup {
  final DateTime date;
  final List<ChatMessage> messages;
  
  DateMessageGroup({
    required this.date,
    required this.messages,
  });
} 