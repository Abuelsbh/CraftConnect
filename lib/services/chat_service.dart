import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import '../Models/chat_model.dart';
import '../Models/user_model.dart';
import '../Models/artisan_model.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final Uuid _uuid = const Uuid();

  // Stream controllers
  final StreamController<List<ChatRoom>> _chatRoomsController = 
      StreamController<List<ChatRoom>>.broadcast();
  final StreamController<List<ChatMessage>> _messagesController = 
      StreamController<List<ChatMessage>>.broadcast();

  // Streams
  Stream<List<ChatRoom>> get chatRoomsStream => _chatRoomsController.stream;
  Stream<List<ChatMessage>> get messagesStream => _messagesController.stream;

  // Database references
  DatabaseReference get _chatRoomsRef => _database.ref('chat_rooms');
  DatabaseReference get _messagesRef => _database.ref('messages');
  DatabaseReference get _usersRef => _database.ref('users');

  // Create or get chat room between two users
  Future<ChatRoom> createOrGetChatRoom(String userId1, String userId2) async {
    try {
      // Sort user IDs to ensure consistent room ID
      final sortedIds = [userId1, userId2]..sort();
      final roomId = '${sortedIds[0]}_${sortedIds[1]}';

      // Check if room exists
      final roomSnapshot = await _chatRoomsRef.child(roomId).get();
      
      if (roomSnapshot.exists) {
        // Room exists, return it
        final roomData = roomSnapshot.value as Map<dynamic, dynamic>;
        return ChatRoom.fromJson(Map<String, dynamic>.from(roomData));
      } else {
        // Create new room
        final newRoom = ChatRoom(
          id: roomId,
          participant1Id: sortedIds[0],
          participant2Id: sortedIds[1],
        );

        await _chatRoomsRef.child(roomId).set(newRoom.toJson());
        return newRoom;
      }
    } catch (e) {
      throw Exception('فشل في إنشاء غرفة الدردشة: $e');
    }
  }

  // Send message
  Future<void> sendMessage(ChatMessage message) async {
    try {
      final messageId = _uuid.v4();
      final messageWithId = message.copyWith(id: messageId);
      
      // Save message
      await _messagesRef.child(messageId).set(messageWithId.toJson());
      
      // Update chat room with last message
      await _updateChatRoomLastMessage(message);
      
      // Mark message as read if sender is viewing the chat
      await _markMessageAsRead(messageId, message.senderId);
    } catch (e) {
      throw Exception('فشل في إرسال الرسالة: $e');
    }
  }

  // Send text message
  Future<void> sendTextMessage(String senderId, String receiverId, String content) async {
    final message = ChatMessage(
      id: '',
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      timestamp: DateTime.now(),
      type: MessageType.text,
    );
    await sendMessage(message);
  }

  // Send image message
  Future<void> sendImageMessage(String senderId, String receiverId, String imageUrl, {String? caption}) async {
    final message = ChatMessage(
      id: '',
      senderId: senderId,
      receiverId: receiverId,
      content: caption ?? '',
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
      type: MessageType.image,
    );
    await sendMessage(message);
  }

  // Send file message
  Future<void> sendFileMessage(String senderId, String receiverId, String fileUrl, String fileName, String fileSize) async {
    final message = ChatMessage(
      id: '',
      senderId: senderId,
      receiverId: receiverId,
      content: fileName,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      timestamp: DateTime.now(),
      type: MessageType.file,
    );
    await sendMessage(message);
  }

  // Send location message
  Future<void> sendLocationMessage(String senderId, String receiverId, LocationData locationData) async {
    final message = ChatMessage(
      id: '',
      senderId: senderId,
      receiverId: receiverId,
      content: locationData.address ?? 'الموقع',
      locationData: locationData,
      timestamp: DateTime.now(),
      type: MessageType.location,
    );
    await sendMessage(message);
  }

  // Send voice message
  Future<void> sendVoiceMessage(String senderId, String receiverId, String voiceUrl, int duration) async {
    final message = ChatMessage(
      id: '',
      senderId: senderId,
      receiverId: receiverId,
      content: 'رسالة صوتية',
      voiceUrl: voiceUrl,
      voiceDuration: duration,
      timestamp: DateTime.now(),
      type: MessageType.voice,
    );
    await sendMessage(message);
  }

  // Get messages for a chat room
  Stream<List<ChatMessage>> getMessagesForRoom(String roomId) {
    return _messagesRef
        .orderByChild('timestamp')
        .onValue
        .map((event) {
          final messages = <ChatMessage>[];
          if (event.snapshot.value != null) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            for (final entry in data.entries) {
              final message = ChatMessage.fromJson(
                Map<String, dynamic>.from(entry.value),
              );
              // Filter messages for this room
              if (_isMessageInRoom(message, roomId)) {
                messages.add(message);
              }
            }
          }
          // Sort by timestamp
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return messages;
        });
  }

  // Get chat rooms for a user
  Stream<List<ChatRoom>> getChatRoomsForUser(String userId) {
    return _chatRoomsRef
        .orderByChild('lastMessageTime')
        .onValue
        .map((event) {
          final rooms = <ChatRoom>[];
          if (event.snapshot.value != null) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            for (final entry in data.entries) {
              final room = ChatRoom.fromJson(
                Map<String, dynamic>.from(entry.value),
              );
              // Filter rooms for this user
              if (room.participant1Id == userId || room.participant2Id == userId) {
                rooms.add(room);
              }
            }
          }
          // Sort by last message time (newest first)
          rooms.sort((a, b) {
            if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
            if (a.lastMessageTime == null) return 1;
            if (b.lastMessageTime == null) return -1;
            return b.lastMessageTime!.compareTo(a.lastMessageTime!);
          });
          return rooms;
        });
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId, String userId) async {
    try {
      await _markMessageAsRead(messageId, userId);
    } catch (e) {
      throw Exception('فشل في تحديث حالة الرسالة: $e');
    }
  }

  // Mark all messages in room as read
  Future<void> markAllMessagesAsRead(String roomId, String userId) async {
    try {
      final messagesSnapshot = await _messagesRef.get();
      if (messagesSnapshot.value != null) {
        final data = messagesSnapshot.value as Map<dynamic, dynamic>;
        for (final entry in data.entries) {
          final message = ChatMessage.fromJson(
            Map<String, dynamic>.from(entry.value),
          );
          if (_isMessageInRoom(message, roomId) && 
              message.receiverId == userId && 
              !message.isRead) {
            await _messagesRef
                .child(entry.key)
                .child('isRead')
                .set(true);
          }
        }
      }
    } catch (e) {
      throw Exception('فشل في تحديث حالة الرسائل: $e');
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _messagesRef.child(messageId).remove();
    } catch (e) {
      throw Exception('فشل في حذف الرسالة: $e');
    }
  }

  // Delete chat room
  Future<void> deleteChatRoom(String roomId) async {
    try {
      // Delete room
      await _chatRoomsRef.child(roomId).remove();
      
      // Delete all messages in the room
      final messagesSnapshot = await _messagesRef.get();
      if (messagesSnapshot.value != null) {
        final data = messagesSnapshot.value as Map<dynamic, dynamic>;
        for (final entry in data.entries) {
          final message = ChatMessage.fromJson(
            Map<String, dynamic>.from(entry.value),
          );
          if (_isMessageInRoom(message, roomId)) {
            await _messagesRef.child(entry.key).remove();
          }
        }
      }
    } catch (e) {
      throw Exception('فشل في حذف غرفة الدردشة: $e');
    }
  }

  // Get user info for chat
  Future<UserModel?> getUserInfo(String userId) async {
    try {
      final snapshot = await _usersRef.child(userId).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return UserModel.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get artisan info for chat
  Future<ArtisanModel?> getArtisanInfo(String artisanId) async {
    try {
      final snapshot = await _database.ref('artisans').child(artisanId).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return ArtisanModel.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Helper methods
  bool _isMessageInRoom(ChatMessage message, String roomId) {
    final sortedIds = [message.senderId, message.receiverId]..sort();
    final messageRoomId = '${sortedIds[0]}_${sortedIds[1]}';
    return messageRoomId == roomId;
  }

  Future<void> _updateChatRoomLastMessage(ChatMessage message) async {
    final sortedIds = [message.senderId, message.receiverId]..sort();
    final roomId = '${sortedIds[0]}_${sortedIds[1]}';
    
    await _chatRoomsRef.child(roomId).update({
      'lastMessage': message.content,
      'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
      'hasUnreadMessages': true,
    });
  }

  Future<void> _markMessageAsRead(String messageId, String userId) async {
    await _messagesRef
        .child(messageId)
        .child('isRead')
        .set(true);
  }

  // Dispose streams
  void dispose() {
    _chatRoomsController.close();
    _messagesController.close();
  }
} 