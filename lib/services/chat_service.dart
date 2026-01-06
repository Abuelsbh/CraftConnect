import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../Models/chat_model.dart';
import '../Models/user_model.dart';
import '../Models/artisan_model.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
      // Normalize and sort user IDs to ensure consistent room ID
      final normalizedId1 = userId1.trim();
      final normalizedId2 = userId2.trim();
      final sortedIds = [normalizedId1, normalizedId2]..sort();
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
      // Normalize IDs to ensure consistency
      final normalizedSenderId = message.senderId.trim();
      final normalizedReceiverId = message.receiverId.trim();
      
      // Validate IDs
      if (normalizedSenderId.isEmpty || normalizedReceiverId.isEmpty) {
        throw Exception('معرف المرسل أو المستقبل غير صحيح');
      }
      
      if (normalizedSenderId == normalizedReceiverId) {
        throw Exception('لا يمكن إرسال رسالة لنفسك');
      }
      
      // Ensure chat room exists before sending message
      final room = await createOrGetChatRoom(normalizedSenderId, normalizedReceiverId);
      
      // Calculate roomId for the message
      final sortedIds = [normalizedSenderId, normalizedReceiverId]..sort();
      final roomId = '${sortedIds[0]}_${sortedIds[1]}';
      
      // Verify roomId matches the created room
      if (room.id != roomId) {
        print('⚠️ Warning: Room ID mismatch. Expected: $roomId, Got: ${room.id}');
      }
      
      final messageId = _uuid.v4();
      final messageWithId = message.copyWith(
        id: messageId,
        senderId: normalizedSenderId,
        receiverId: normalizedReceiverId,
        roomId: roomId,
      );
      
      // Save message - always mark as unread initially
      print('💾 [ChatService] Saving message to database');
      print('💾 [ChatService] Message ID: $messageId');
      print('💾 [ChatService] Room ID: $roomId');
      print('💾 [ChatService] Sender: $normalizedSenderId');
      print('💾 [ChatService] Receiver: $normalizedReceiverId');
      
      await _messagesRef.child(messageId).set(messageWithId.toJson());
      print('✅ [ChatService] Message saved successfully');
      
      // Update chat room with last message (mark as unread for receiver only)
      await _updateChatRoomLastMessage(messageWithId);
      print('✅ [ChatService] Chat room updated successfully');
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
    // Normalize roomId for comparison
    final normalizedRoomId = roomId.trim();
    
    if (normalizedRoomId.isEmpty) {
      print('❌ [ChatService] Error: Empty roomId provided to getMessagesForRoom');
      return Stream.value([]);
    }
    
    return _messagesRef
        .orderByChild('timestamp')
        .onValue
        .map((event) {
          final messages = <ChatMessage>[];
          if (event.snapshot.value != null) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            for (final entry in data.entries) {
              try {
                final message = ChatMessage.fromJson(
                  Map<String, dynamic>.from(entry.value),
                );
                
                // First check: Use roomId field if available (more efficient)
                bool isInRoom = false;
                if (message.roomId.isNotEmpty) {
                  isInRoom = message.roomId.trim() == normalizedRoomId;
                } else {
                  // Fallback: Calculate roomId from sender/receiver (backward compatibility)
                  isInRoom = _isMessageInRoom(message, normalizedRoomId);
                }
                
                // Additional validation: Ensure message belongs to this room
                if (isInRoom) {
                  // Double-check by verifying the participants match
                  final normalizedSenderId = message.senderId.trim();
                  final normalizedReceiverId = message.receiverId.trim();
                  
                  // Extract participant IDs from roomId
                  final roomParts = normalizedRoomId.split('_');
                  if (roomParts.length == 2) {
                    final participant1Id = roomParts[0].trim();
                    final participant2Id = roomParts[1].trim();
                    
                    // Verify message participants match room participants
                    final senderMatches = normalizedSenderId == participant1Id || normalizedSenderId == participant2Id;
                    final receiverMatches = normalizedReceiverId == participant1Id || normalizedReceiverId == participant2Id;
                    
                    if (senderMatches && receiverMatches) {
                      messages.add(message);
                    } else {
                      print('⚠️ [ChatService] Rejected message ${message.id} - participants don\'t match room');
                    }
                  } else {
                    // If roomId format is invalid, use the original check
                    messages.add(message);
                  }
                }
              } catch (e) {
                print('❌ [ChatService] Error parsing message: $e');
                continue;
              }
            }
          }
          // Sort by timestamp
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          
          print('📨 [ChatService] Returning ${messages.length} messages for room $normalizedRoomId');
          return messages;
        });
  }

  // Get chat room by ID
  Future<ChatRoom?> getChatRoomById(String roomId) async {
    try {
      final roomSnapshot = await _chatRoomsRef.child(roomId).get();
      if (roomSnapshot.exists) {
        final roomData = roomSnapshot.value as Map<dynamic, dynamic>;
        return ChatRoom.fromJson(Map<String, dynamic>.from(roomData));
      }
      return null;
    } catch (e) {
      print('Error getting chat room by ID: $e');
      return null;
    }
  }

  // Get chat rooms for a user
  Stream<List<ChatRoom>> getChatRoomsForUser(String userId) {
    // Normalize userId for comparison
    final normalizedUserId = userId.trim();
    
    // Validate userId is not empty
    if (normalizedUserId.isEmpty) {
      print('❌ [ChatService] Error: Empty userId provided to getChatRoomsForUser');
      return Stream.value([]);
    }
    
    print('═══════════════════════════════════════════════════════');
    print('🔍 [ChatService] Getting chat rooms for user: $normalizedUserId');
    
    return _chatRoomsRef
        .orderByChild('lastMessageTime')
        .onValue
        .map((event) {
          final rooms = <ChatRoom>[];
          if (event.snapshot.value != null) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            for (final entry in data.entries) {
              try {
                final room = ChatRoom.fromJson(
                  Map<String, dynamic>.from(entry.value),
                );
                
                // Normalize participant IDs for comparison
                final participant1Id = room.participant1Id.trim();
                final participant2Id = room.participant2Id.trim();
                
                // CRITICAL: Only include rooms where user is a participant
                // This is a strict check - both IDs must be non-empty and one must match
                if (participant1Id.isEmpty || participant2Id.isEmpty) {
                  print('⚠️ [ChatService] Skipping room ${room.id} - empty participant IDs');
                  continue;
                }
                
                final isParticipant = participant1Id == normalizedUserId || participant2Id == normalizedUserId;
                
                if (isParticipant) {
                  rooms.add(room);
                  print('✅ [ChatService] Added room ${room.id} for user $normalizedUserId');
                  print('   Room participants: $participant1Id, $participant2Id');
                } else {
                  print('🚫 [ChatService] Rejected room ${room.id} - user $normalizedUserId is not a participant');
                  print('   Room participants: $participant1Id, $participant2Id');
                  print('   Comparison: participant1Id == userId: ${participant1Id == normalizedUserId}');
                  print('   Comparison: participant2Id == userId: ${participant2Id == normalizedUserId}');
                }
              } catch (e) {
                print('❌ [ChatService] Error parsing room: $e');
                continue;
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
          
          print('📊 [ChatService] Returning ${rooms.length} rooms for user $normalizedUserId');
          for (var room in rooms) {
            print('   - Room ${room.id}: participants (${room.participant1Id}, ${room.participant2Id})');
          }
          print('═══════════════════════════════════════════════════════');
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
      final normalizedUserId = userId.trim();
      final normalizedRoomId = roomId.trim();
      
      final messagesSnapshot = await _messagesRef.get();
      if (messagesSnapshot.value != null) {
        final data = messagesSnapshot.value as Map<dynamic, dynamic>;
        for (final entry in data.entries) {
          final message = ChatMessage.fromJson(
            Map<String, dynamic>.from(entry.value),
          );
          // Normalize message IDs for comparison
          final messageReceiverId = message.receiverId.trim();
          final messageSenderId = message.senderId.trim();
          
          // Only mark messages as read if:
          // 1. Message is in this room
          // 2. Current user is the receiver (not the sender)
          // 3. Message is not already read
          if (_isMessageInRoom(message, normalizedRoomId) && 
              messageReceiverId == normalizedUserId && 
              messageSenderId != normalizedUserId &&
              !message.isRead) {
            await _messagesRef
                .child(entry.key)
                .child('isRead')
                .set(true);
          }
        }
        
        // Also clear unread flag for this user in the chat room
        final roomSnapshot = await _chatRoomsRef.child(normalizedRoomId).get();
        if (roomSnapshot.exists) {
          await _chatRoomsRef.child(normalizedRoomId).update({
            'hasUnreadMessages': false,
          });
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
      // Try Firestore first (where users are actually stored)
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        // Convert Firestore Timestamps to ISO strings
        final jsonData = <String, dynamic>{
          'id': doc.id,
          ...data,
        };
        if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
          jsonData['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        if (data['updatedAt'] != null && data['updatedAt'] is Timestamp) {
          jsonData['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
        }
        return UserModel.fromJson(jsonData);
      }
      
      // Fallback to Realtime Database if not found in Firestore
      final snapshot = await _usersRef.child(userId).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return UserModel.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }

  // Get artisan info for chat
  Future<ArtisanModel?> getArtisanInfo(String artisanId) async {
    try {
      // Try Firestore first (where artisans are actually stored)
      final doc = await _firestore.collection('artisans').doc(artisanId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        // Convert Firestore Timestamps to ISO strings
        final jsonData = <String, dynamic>{
          'id': doc.id,
          ...data,
        };
        if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
          jsonData['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        if (data['updatedAt'] != null && data['updatedAt'] is Timestamp) {
          jsonData['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
        }
        return ArtisanModel.fromJson(jsonData);
      }
      
      // Fallback to Realtime Database if not found in Firestore
      final snapshot = await _database.ref('artisans').child(artisanId).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return ArtisanModel.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      print('Error getting artisan info: $e');
      return null;
    }
  }

  // Helper methods
  bool _isMessageInRoom(ChatMessage message, String roomId) {
    // First, try to use roomId field if available
    if (message.roomId.isNotEmpty) {
      return message.roomId.trim() == roomId.trim();
    }
    
    // Fallback: Calculate roomId from sender/receiver (backward compatibility)
    final senderId = message.senderId.trim();
    final receiverId = message.receiverId.trim();
    
    // Validate IDs
    if (senderId.isEmpty || receiverId.isEmpty) {
      print('⚠️ [ChatService] Invalid message: empty sender or receiver ID');
      return false;
    }
    
    final sortedIds = [senderId, receiverId]..sort();
    final messageRoomId = '${sortedIds[0]}_${sortedIds[1]}';
    final normalizedRoomId = roomId.trim();
    
    return messageRoomId == normalizedRoomId;
  }

  Future<void> _updateChatRoomLastMessage(ChatMessage message) async {
    // Normalize IDs
    final senderId = message.senderId.trim();
    final receiverId = message.receiverId.trim();
    final sortedIds = [senderId, receiverId]..sort();
    final roomId = '${sortedIds[0]}_${sortedIds[1]}';
    
    print('📝 [ChatService] Updating chat room last message');
    print('📝 [ChatService] Room ID: $roomId');
    print('📝 [ChatService] Sender: $senderId');
    print('📝 [ChatService] Receiver: $receiverId');
    print('📝 [ChatService] Message content: ${message.content}');
    
    // Check if room exists
    final roomSnapshot = await _chatRoomsRef.child(roomId).get();
    
    if (roomSnapshot.exists) {
      // Room exists, update it
      // Note: hasUnreadMessages will be cleared when receiver opens the chat
      await _chatRoomsRef.child(roomId).update({
        'lastMessage': message.content,
        'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
        'hasUnreadMessages': true, // Receiver will have unread messages
      });
      print('✅ [ChatService] Updated existing chat room: $roomId');
    } else {
      // Room doesn't exist, create it
      final newRoom = ChatRoom(
        id: roomId,
        participant1Id: sortedIds[0],
        participant2Id: sortedIds[1],
        lastMessage: message.content,
        lastMessageTime: message.timestamp,
        hasUnreadMessages: true, // Receiver will have unread messages
      );
      await _chatRoomsRef.child(roomId).set(newRoom.toJson());
      print('✅ [ChatService] Created new chat room: $roomId');
    }
  }

  Future<void> _markMessageAsRead(String messageId, String userId) async {
    // Get the message first to verify the user is the receiver
    final messageSnapshot = await _messagesRef.child(messageId).get();
    if (messageSnapshot.exists) {
      final messageData = messageSnapshot.value as Map<dynamic, dynamic>;
      final message = ChatMessage.fromJson(Map<String, dynamic>.from(messageData));
      
      // Normalize IDs for comparison
      final normalizedUserId = userId.trim();
      final normalizedReceiverId = message.receiverId.trim();
      final normalizedSenderId = message.senderId.trim();
      
      // Only mark as read if the user is the receiver (not the sender)
      if (normalizedReceiverId == normalizedUserId && normalizedSenderId != normalizedUserId) {
        await _messagesRef
            .child(messageId)
            .child('isRead')
            .set(true);
      }
    }
  }

  // Dispose streams
  void dispose() {
    _chatRoomsController.close();
    _messagesController.close();
  }
} 