import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../Models/chat_model.dart';
import '../../../Models/user_model.dart';
import '../../../Models/artisan_model.dart';
import '../../../Utilities/app_constants.dart';
import '../../../services/chat_service.dart';

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      elevation: 1,
      color: isDarkMode ? Colors.grey[800] : Colors.white,
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

        ImageProvider? imageProvider = _getImageProvider(imageUrl);

        if (imageProvider != null) {
          return CircleAvatar(
            radius: 24.r,
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            backgroundImage: imageProvider,
            onBackgroundImageError: (exception, stackTrace) {
              // Handle image loading errors silently
              // The fallback child will be shown
            },
            child: null,
          );
        } else {
          return CircleAvatar(
            radius: 24.r,
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }
      },
    );
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
    try {
      // Normalize IDs (trim whitespace and convert to lowercase for comparison)
      final normalizedCurrentUserId = currentUserId.trim().toLowerCase();
      final normalizedParticipant1Id = room.participant1Id.trim().toLowerCase();
      final normalizedParticipant2Id = room.participant2Id.trim().toLowerCase();
      
      // Keep original IDs for fetching (case-sensitive)
      final originalParticipant1Id = room.participant1Id.trim();
      final originalParticipant2Id = room.participant2Id.trim();
      final originalCurrentUserId = currentUserId.trim();
      
      // Validate currentUserId
      if (normalizedCurrentUserId.isEmpty) {
        print('❌ [ChatRoomTile] Warning: currentUserId is empty');
        return null;
      }
      
      // Validate room participants
      if (normalizedParticipant1Id.isEmpty && normalizedParticipant2Id.isEmpty) {
        print('❌ [ChatRoomTile] Warning: Room has no participants');
        return null;
      }
      
      print('═══════════════════════════════════════════════════════');
      print('🔍 [ChatRoomTile] DETERMINING OTHER PARTICIPANT');
      print('🔍 [ChatRoomTile] Room ID: ${room.id}');
      print('🔍 [ChatRoomTile] Participant1 ID (original): "$originalParticipant1Id"');
      print('🔍 [ChatRoomTile] Participant2 ID (original): "$originalParticipant2Id"');
      print('🔍 [ChatRoomTile] Current User ID (original): "$originalCurrentUserId"');
      print('🔍 [ChatRoomTile] Participant1 ID (normalized): "$normalizedParticipant1Id"');
      print('🔍 [ChatRoomTile] Participant2 ID (normalized): "$normalizedParticipant2Id"');
      print('🔍 [ChatRoomTile] Current User ID (normalized): "$normalizedCurrentUserId"');
      
      final chatService = ChatService();
      
      // Determine the other participant ID with strict comparison
      String? otherParticipantId;
      bool isCurrentUserParticipant1 = false;
      bool isCurrentUserParticipant2 = false;
      
      // Check if current user is participant1 (case-insensitive comparison)
      if (normalizedParticipant1Id == normalizedCurrentUserId) {
        isCurrentUserParticipant1 = true;
        otherParticipantId = originalParticipant2Id; // Use original ID for fetching
        print('✅ [ChatRoomTile] ✓ Current user IS participant1');
        print('✅ [ChatRoomTile] ✓ Other participant IS participant2: "$otherParticipantId"');
      }
      // Check if current user is participant2 (case-insensitive comparison)
      else if (normalizedParticipant2Id == normalizedCurrentUserId) {
        isCurrentUserParticipant2 = true;
        otherParticipantId = originalParticipant1Id; // Use original ID for fetching
        print('✅ [ChatRoomTile] ✓ Current user IS participant2');
        print('✅ [ChatRoomTile] ✓ Other participant IS participant1: "$otherParticipantId"');
      }
      // Current user is not in this room - this should not happen
      else {
        print('⚠️ [ChatRoomTile] ⚠️ ERROR: Current user is NOT a participant in this room!');
        print('⚠️ [ChatRoomTile] Comparison results:');
        print('⚠️ [ChatRoomTile]   participant1 == currentUser: ${normalizedParticipant1Id == normalizedCurrentUserId}');
        print('⚠️ [ChatRoomTile]   participant2 == currentUser: ${normalizedParticipant2Id == normalizedCurrentUserId}');
        print('⚠️ [ChatRoomTile] This room should not be shown to this user!');
        return null;
      }
      
      if (otherParticipantId == null || otherParticipantId.isEmpty) {
        print('❌ [ChatRoomTile] ❌ ERROR: Other participant ID is empty!');
        return null;
      }
      
      // CRITICAL CHECK: Ensure otherParticipantId is NOT the same as currentUserId
      if (otherParticipantId.toLowerCase() == normalizedCurrentUserId) {
        print('❌ [ChatRoomTile] ❌ CRITICAL ERROR: Other participant ID is the same as current user ID!');
        print('❌ [ChatRoomTile] This would show the current user instead of the other participant');
        print('❌ [ChatRoomTile] Current: "$originalCurrentUserId"');
        print('❌ [ChatRoomTile] Other: "$otherParticipantId"');
        return null;
      }
      
      print('🔍 [ChatRoomTile] Fetching info for other participant: "$otherParticipantId"');
      
      // Try to get user info first
      print('🔍 [ChatRoomTile] Attempting to get user info...');
      final userInfo = await chatService.getUserInfo(otherParticipantId);
      print('🔍 [ChatRoomTile] getUserInfo result: ${userInfo != null ? "Found user: ${userInfo.name} (ID: ${userInfo.id})" : "User not found"}');
      
      if (userInfo != null && userInfo.id.isNotEmpty && userInfo.name.isNotEmpty) {
        // CRITICAL CHECK: Verify the fetched user ID matches the expected other participant ID
        final fetchedUserIdNormalized = userInfo.id.trim().toLowerCase();
        final expectedOtherIdNormalized = otherParticipantId.trim().toLowerCase();
        
        if (fetchedUserIdNormalized != expectedOtherIdNormalized) {
          print('❌ [ChatRoomTile] ❌ CRITICAL ERROR: Fetched user ID does not match expected other participant ID!');
          print('❌ [ChatRoomTile] Expected: "$otherParticipantId" (normalized: "$expectedOtherIdNormalized")');
          print('❌ [ChatRoomTile] Got: "${userInfo.id}" (normalized: "$fetchedUserIdNormalized")');
          print('❌ [ChatRoomTile] Name: "${userInfo.name}"');
          return null;
        }
        
        // Triple check: make sure we didn't get the current user's info by mistake
        if (fetchedUserIdNormalized == normalizedCurrentUserId) {
          print('❌ [ChatRoomTile] ❌ CRITICAL ERROR: Got current user info instead of other participant!');
          print('❌ [ChatRoomTile] User ID: "${userInfo.id}", Name: "${userInfo.name}"');
          print('❌ [ChatRoomTile] Current User ID: "$originalCurrentUserId"');
          print('❌ [ChatRoomTile] Expected other participant ID: "$otherParticipantId"');
          return null;
        }
        
        print('✅ [ChatRoomTile] ✓✓✓ SUCCESS: Found other participant user!');
        print('✅ [ChatRoomTile] Name: "${userInfo.name}"');
        print('✅ [ChatRoomTile] ID: "${userInfo.id}"');
        print('✅ [ChatRoomTile] Verified: ID matches expected other participant');
        print('═══════════════════════════════════════════════════════');
        return userInfo;
      }
      
      // If user not found, try to get artisan info
      print('🔍 [ChatRoomTile] User not found, attempting to get artisan info...');
      final artisanInfo = await chatService.getArtisanInfo(otherParticipantId);
      print('🔍 [ChatRoomTile] getArtisanInfo result: ${artisanInfo != null ? "Found artisan: ${artisanInfo.name} (ID: ${artisanInfo.id})" : "Artisan not found"}');
      
      if (artisanInfo != null && artisanInfo.id.isNotEmpty && artisanInfo.name.isNotEmpty) {
        // CRITICAL CHECK: Verify the fetched artisan ID matches the expected other participant ID
        final fetchedArtisanIdNormalized = artisanInfo.id.trim().toLowerCase();
        final expectedOtherIdNormalized = otherParticipantId.trim().toLowerCase();
        
        if (fetchedArtisanIdNormalized != expectedOtherIdNormalized) {
          print('❌ [ChatRoomTile] ❌ CRITICAL ERROR: Fetched artisan ID does not match expected other participant ID!');
          print('❌ [ChatRoomTile] Expected: "$otherParticipantId" (normalized: "$expectedOtherIdNormalized")');
          print('❌ [ChatRoomTile] Got: "${artisanInfo.id}" (normalized: "$fetchedArtisanIdNormalized")');
          print('❌ [ChatRoomTile] Name: "${artisanInfo.name}"');
          return null;
        }
        
        // Triple check: make sure we didn't get the current user's info by mistake
        if (fetchedArtisanIdNormalized == normalizedCurrentUserId) {
          print('❌ [ChatRoomTile] ❌ CRITICAL ERROR: Got current user artisan info instead of other participant!');
          print('❌ [ChatRoomTile] Artisan ID: "${artisanInfo.id}", Name: "${artisanInfo.name}"');
          print('❌ [ChatRoomTile] Current User ID: "$originalCurrentUserId"');
          print('❌ [ChatRoomTile] Expected other participant ID: "$otherParticipantId"');
          return null;
        }
        
        print('✅ [ChatRoomTile] ✓✓✓ SUCCESS: Found other participant artisan!');
        print('✅ [ChatRoomTile] Name: "${artisanInfo.name}"');
        print('✅ [ChatRoomTile] ID: "${artisanInfo.id}"');
        print('✅ [ChatRoomTile] Verified: ID matches expected other participant');
        print('═══════════════════════════════════════════════════════');
        // Convert ArtisanModel to UserModel for display
        return UserModel(
          id: artisanInfo.id,
          name: artisanInfo.name,
          email: artisanInfo.email,
          phone: artisanInfo.phone,
          profileImageUrl: artisanInfo.profileImageUrl,
          createdAt: artisanInfo.createdAt,
          updatedAt: artisanInfo.updatedAt,
        );
      }
      
      print('❌ [ChatRoomTile] ❌ ERROR: Could not find user or artisan with ID: "$otherParticipantId"');
      print('═══════════════════════════════════════════════════════');
      return null;
    } catch (e, stackTrace) {
      print('❌ [ChatRoomTile] ❌ EXCEPTION: Error getting other participant info: $e');
      print('❌ [ChatRoomTile] Stack trace: $stackTrace');
      print('═══════════════════════════════════════════════════════');
      return null;
    }
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