import 'dart:async';
import 'package:flutter/foundation.dart';
import '../Models/chat_model.dart';
import '../Models/user_model.dart';
import '../Models/artisan_model.dart';
import '../services/chat_service.dart';
import '../services/notification_sound_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final NotificationSoundService _notificationSoundService = NotificationSoundService();
  
  // State
  List<ChatRoom> _chatRooms = [];
  List<ChatMessage> _currentMessages = [];
  ChatRoom? _currentRoom;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<ChatRoom>>? _chatRoomsSubscription;
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;
  int _previousMessagesCount = 0; // لتتبع عدد الرسائل السابق
  String? _previousLastMessageId; // لتتبع آخر رسالة في الشات الحالي
  bool _isInitialLoad = true; // للتحقق من أن هذا هو التحميل الأول للرسائل
  final List<String> _playedMessageIds = []; // لتجنب تكرار الصوت لنفس الرسالة
  final Map<String, DateTime> _playedRoomTimes = {}; // roomId -> آخر وقت شغلنا فيه الصوت

  /// اسم المرسل المعلّق لعرضه في الواجهة (يُمسح بعد العرض)
  String? _pendingNotificationSenderName;
  String? get pendingNotificationSenderName => _pendingNotificationSenderName;
  void clearPendingNotification() {
    _pendingNotificationSenderName = null;
    notifyListeners();
  }

  // Getters
  List<ChatRoom> get chatRooms => _chatRooms;

  /// هل يوجد أي محادثة بها رسائل غير مقروءة للمستخدم الحالي؟
  bool get hasAnyUnreadMessages {
    final effectiveUserId = _getEffectiveUserId();
    if (effectiveUserId.isEmpty) return false;
    return getFilteredChatRooms().any((room) {
      if (!room.hasUnreadMessages) return false;
      if (room.lastMessageSenderId == null || room.lastMessageSenderId!.isEmpty) return true;
      return room.lastMessageSenderId!.trim() != effectiveUserId.trim();
    });
  }
  List<ChatMessage> get currentMessages => _currentMessages;
  ChatRoom? get currentRoom => _currentRoom;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize chat provider
  void initialize(UserModel user) {
    _currentUser = user;
    _loadChatRooms();
  }

  // Refresh chat rooms manually
  void refreshChatRooms() {
    if (_currentUser != null) {
      _loadChatRooms();
    }
  }

  // Get the effective user ID for chat (artisanId for artisans, userId for regular users)
  String _getEffectiveUserId() {
    if (_currentUser == null) {
      print('❌ [ChatProvider] _getEffectiveUserId: _currentUser is null');
      return '';
    }
    
    print('═══════════════════════════════════════════════════════');
    print('🔍 [ChatProvider] Determining effective user ID');
    print('🔍 [ChatProvider] User ID: ${_currentUser!.id}');
    print('🔍 [ChatProvider] User Type: ${_currentUser!.userType}');
    print('🔍 [ChatProvider] Artisan ID: ${_currentUser!.artisanId ?? 'null'}');
    print('🔍 [ChatProvider] User Name: ${_currentUser!.name}');
    print('🔍 [ChatProvider] User Email: ${_currentUser!.email}');
    
    // If user is an artisan and has artisanId, use artisanId for chat
    // This is because messages are sent to artisan.id, not user.id
    if (_currentUser!.userType == 'artisan') {
      if (_currentUser!.artisanId != null && _currentUser!.artisanId!.isNotEmpty) {
        final artisanId = _currentUser!.artisanId!.trim();
        print('✅ [ChatProvider] User is artisan, using artisanId: $artisanId (instead of userId: ${_currentUser!.id})');
        print('═══════════════════════════════════════════════════════');
        return artisanId;
      } else {
        print('⚠️ [ChatProvider] WARNING: User is artisan but artisanId is null or empty!');
        print('⚠️ [ChatProvider] Falling back to userId: ${_currentUser!.id}');
        print('═══════════════════════════════════════════════════════');
        // Fallback to userId if artisanId is not set
        return _currentUser!.id.trim();
      }
    }
    
    // For regular users, use their userId
    print('✅ [ChatProvider] User is regular user, using userId: ${_currentUser!.id}');
    print('═══════════════════════════════════════════════════════');
    return _currentUser!.id.trim();
  }

  // Public getter for effective user ID (used by UI to determine if message is from current user)
  String get effectiveUserId => _getEffectiveUserId();

  // Load chat rooms for current user
  void _loadChatRooms() {
    if (_currentUser == null) return;

    final effectiveUserId = _getEffectiveUserId();
    if (effectiveUserId.isEmpty) {
      print('❌ [ChatProvider] Cannot load chat rooms: effective user ID is empty');
      _setError('لا يمكن تحديد معرف المستخدم');
      _setLoading(false);
      return;
    }

    _setLoading(true);
    _chatRoomsSubscription?.cancel();
    
    print('📥 [ChatProvider] Loading chat rooms for effective user ID: $effectiveUserId');
    print('📥 [ChatProvider] User type: ${_currentUser!.userType}');
    print('📥 [ChatProvider] User ID: ${_currentUser!.id}');
    print('📥 [ChatProvider] Artisan ID: ${_currentUser!.artisanId ?? 'null'}');
    
    _chatRoomsSubscription = _chatService
        .getChatRoomsForUser(effectiveUserId)
        .listen(
      (rooms) {
        // التحقق من وجود رسائل جديدة في أي محادثة
        _checkForNewMessagesInRooms(rooms);
        
        _chatRooms = rooms;
        _setLoading(false);
        print('✅ [ChatProvider] Loaded ${rooms.length} chat rooms');
        notifyListeners();
      },
      onError: (error) {
        _setError('فشل في تحميل المحادثات: $error');
        _setLoading(false);
        print('❌ [ChatProvider] Error loading chat rooms: $error');
      },
    );
  }

  // Get filtered chat rooms based on user type
  List<ChatRoom> getFilteredChatRooms() {
    if (_currentUser == null) return [];
    
    // Use effective user ID (artisanId for artisans, userId for regular users)
    final effectiveUserId = _getEffectiveUserId();
    if (effectiveUserId.isEmpty) return [];
    
    // CRITICAL: Filter rooms to ensure current user is actually a participant
    // This is a safety check even though getChatRoomsForUser should already filter
    return _chatRooms.where((room) {
      final participant1Id = room.participant1Id.trim();
      final participant2Id = room.participant2Id.trim();
      
      // Only include rooms where effective user ID is a participant
      final isParticipant = participant1Id == effectiveUserId || participant2Id == effectiveUserId;
      
      if (!isParticipant) {
        print('⚠️ [ChatProvider] Filtered out room ${room.id} - effective user ID $effectiveUserId is not a participant (participants: $participant1Id, $participant2Id)');
      }
      
      return isParticipant;
    }).toList();
  }

  // Open chat room
  Future<void> openChatRoom(String roomId) async {
    try {
      if (_currentUser == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }
      
      // Use effective user ID (artisanId for artisans, userId for regular users)
      final effectiveUserId = _getEffectiveUserId();
      if (effectiveUserId.isEmpty) {
        throw Exception('لا يمكن تحديد معرف المستخدم');
      }
      
      // Don't set global loading state to avoid blocking the UI
      // The caller will show a local loading indicator
      
      // Try to find the room in local list first
      ChatRoom? room;
      try {
        room = _chatRooms.firstWhere((r) => r.id == roomId);
      } catch (e) {
        // Room not in local list, fetch from database
        print('Room not found in local list, fetching from database: $roomId');
        room = await _chatService.getChatRoomById(roomId);
        
        if (room == null) {
          throw Exception('المحادثة غير موجودة');
        }
      }
      
      // CRITICAL: Verify that current user is a participant in this room
      final participant1Id = room.participant1Id.trim();
      final participant2Id = room.participant2Id.trim();
      final isParticipant = participant1Id == effectiveUserId || participant2Id == effectiveUserId;
      
      if (!isParticipant) {
        print('❌ [ChatProvider] Security check failed: Effective user ID $effectiveUserId is not a participant in room $roomId (participants: $participant1Id, $participant2Id)');
        throw Exception('ليس لديك صلاحية للوصول إلى هذه المحادثة');
      }
      
      // Add to local list if not exists
      if (!_chatRooms.any((r) => r.id == roomId)) {
        _chatRooms.add(room);
        notifyListeners();
      }
      
      _currentRoom = room;
      notifyListeners(); // Notify that currentRoom is set
      
      // إعادة تعيين عدد الرسائل السابق عند فتح شات جديد
      _previousMessagesCount = 0;
      _previousLastMessageId = null;
      _isInitialLoad = true; // هذا هو التحميل الأول للرسائل
      
      // Load messages and wait for first batch
      _messagesSubscription?.cancel();
      
      // Use Completer to wait for first messages load
      final completer = Completer<void>();
      bool hasReceivedFirstMessages = false;
      
      _messagesSubscription = _chatService
          .getMessagesForRoom(roomId)
          .listen(
        (messages) {
          // التحقق من وجود رسالة جديدة (بعد التحميل الأول)
          if (!_isInitialLoad) {
            _checkAndPlayNotificationSound(messages);
          } else {
            // هذا هو التحميل الأول، تحديث المتغيرات دون تشغيل الصوت
            _previousMessagesCount = messages.length;
            _previousLastMessageId = messages.isNotEmpty ? messages.last.id : null;
            _isInitialLoad = false;
          }
          
          _currentMessages = messages;
          if (!hasReceivedFirstMessages) {
            hasReceivedFirstMessages = true;
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
          notifyListeners();
        },
        onError: (error) {
          _setError('فشل في تحميل الرسائل: $error');
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
      );

      // Wait for first messages to load (with shorter timeout for better UX)
      try {
        await completer.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            // If timeout, continue anyway - messages will load via stream
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
        );
      } catch (e) {
        // Continue even if there's an error
        print('Warning: Error waiting for messages: $e');
        if (!completer.isCompleted) {
          completer.complete();
        }
      }

      // Mark messages as read (don't wait for it to complete)
      if (_currentUser != null) {
        final effectiveUserId = _getEffectiveUserId();
        if (effectiveUserId.isNotEmpty) {
          _chatService.markAllMessagesAsRead(roomId, effectiveUserId).catchError((e) {
            print('Warning: Failed to mark messages as read: $e');
          });
        }
      }
      
      notifyListeners();
    } catch (e) {
      _setError('فشل في فتح المحادثة: $e');
      _currentRoom = null;
      _currentMessages.clear();
      notifyListeners();
      rethrow; // Re-throw to let caller handle the error
    }
  }

  // Send text message
  Future<void> sendTextMessage(String content) async {
    if (_currentUser == null || _currentRoom == null) {
      _setError('يجب تسجيل الدخول أولاً');
      return;
    }

    try {
      final effectiveUserId = _getEffectiveUserId();
      if (effectiveUserId.isEmpty) {
        _setError('لا يمكن تحديد معرف المستخدم');
        return;
      }

      final receiverId = _currentRoom!.participant1Id == effectiveUserId
          ? _currentRoom!.participant2Id
          : _currentRoom!.participant1Id;

      await _chatService.sendTextMessage(effectiveUserId, receiverId, content);
      
      // Refresh chat rooms list to show updated last message
      refreshChatRooms();
    } catch (e) {
      _setError('فشل في إرسال الرسالة: $e');
    }
  }

  // Send image message
  Future<void> sendImageMessage(String imageUrl, {String? caption}) async {
    if (_currentUser == null || _currentRoom == null) {
      _setError('يجب تسجيل الدخول أولاً');
      return;
    }

    try {
      final effectiveUserId = _getEffectiveUserId();
      if (effectiveUserId.isEmpty) {
        _setError('لا يمكن تحديد معرف المستخدم');
        return;
      }

      final receiverId = _currentRoom!.participant1Id == effectiveUserId
          ? _currentRoom!.participant2Id
          : _currentRoom!.participant1Id;

      await _chatService.sendImageMessage(effectiveUserId, receiverId, imageUrl, caption: caption);
      
      // Refresh chat rooms list to show updated last message
      refreshChatRooms();
    } catch (e) {
      _setError('فشل في إرسال الصورة: $e');
    }
  }

  // Send file message
  Future<void> sendFileMessage(String fileUrl, String fileName, String fileSize) async {
    if (_currentUser == null || _currentRoom == null) {
      _setError('يجب تسجيل الدخول أولاً');
      return;
    }

    try {
      final effectiveUserId = _getEffectiveUserId();
      if (effectiveUserId.isEmpty) {
        _setError('لا يمكن تحديد معرف المستخدم');
        return;
      }

      final receiverId = _currentRoom!.participant1Id == effectiveUserId
          ? _currentRoom!.participant2Id
          : _currentRoom!.participant1Id;

      await _chatService.sendFileMessage(effectiveUserId, receiverId, fileUrl, fileName, fileSize);
      
      // Refresh chat rooms list to show updated last message
      refreshChatRooms();
    } catch (e) {
      _setError('فشل في إرسال الملف: $e');
    }
  }

  // Send location message
  Future<void> sendLocationMessage(LocationData locationData) async {
    if (_currentUser == null || _currentRoom == null) {
      _setError('يجب تسجيل الدخول أولاً');
      return;
    }

    try {
      final effectiveUserId = _getEffectiveUserId();
      if (effectiveUserId.isEmpty) {
        _setError('لا يمكن تحديد معرف المستخدم');
        return;
      }

      final receiverId = _currentRoom!.participant1Id == effectiveUserId
          ? _currentRoom!.participant2Id
          : _currentRoom!.participant1Id;

      await _chatService.sendLocationMessage(effectiveUserId, receiverId, locationData);
      
      // Refresh chat rooms list to show updated last message
      refreshChatRooms();
    } catch (e) {
      _setError('فشل في إرسال الموقع: $e');
    }
  }

  // Send voice message
  Future<void> sendVoiceMessage(String voiceUrl, int duration) async {
    if (_currentUser == null || _currentRoom == null) {
      _setError('يجب تسجيل الدخول أولاً');
      return;
    }

    try {
      final effectiveUserId = _getEffectiveUserId();
      if (effectiveUserId.isEmpty) {
        _setError('لا يمكن تحديد معرف المستخدم');
        return;
      }

      final receiverId = _currentRoom!.participant1Id == effectiveUserId
          ? _currentRoom!.participant2Id
          : _currentRoom!.participant1Id;

      await _chatService.sendVoiceMessage(effectiveUserId, receiverId, voiceUrl, duration);
      
      // Refresh chat rooms list to show updated last message
      refreshChatRooms();
    } catch (e) {
      _setError('فشل في إرسال الرسالة الصوتية: $e');
    }
  }

  // Legacy method for backward compatibility
  Future<void> sendMessage(String content, {String? imageUrl, MessageType type = MessageType.text}) async {
    if (type == MessageType.image && imageUrl != null) {
      await sendImageMessage(imageUrl, caption: content);
    } else {
      await sendTextMessage(content);
    }
  }

  // Create new chat room
  Future<void> createChatRoom(String otherUserId) async {
    if (_currentUser == null) {
      _setError('يجب تسجيل الدخول أولاً');
      return;
    }

    try {
      final effectiveUserId = _getEffectiveUserId();
      if (effectiveUserId.isEmpty) {
        _setError('لا يمكن تحديد معرف المستخدم');
        return;
      }

      _setLoading(true);
      final room = await _chatService.createOrGetChatRoom(effectiveUserId, otherUserId);
      
      // Add to chat rooms if not exists
      if (!_chatRooms.any((r) => r.id == room.id)) {
        _chatRooms.add(room);
        notifyListeners();
      }
      
      _setLoading(false);
    } catch (e) {
      _setError('فشل في إنشاء المحادثة: $e');
      _setLoading(false);
    }
  }

  // Create chat room and return it
  Future<ChatRoom?> createChatRoomAndReturn(String otherUserId) async {
    if (_currentUser == null) {
      _setError('يجب تسجيل الدخول أولاً');
      return null;
    }

    try {
      final effectiveUserId = _getEffectiveUserId();
      if (effectiveUserId.isEmpty) {
        _setError('لا يمكن تحديد معرف المستخدم');
        return null;
      }

      _setLoading(true);
      final room = await _chatService.createOrGetChatRoom(effectiveUserId, otherUserId);
      
      // Add to chat rooms if not exists
      if (!_chatRooms.any((r) => r.id == room.id)) {
        _chatRooms.add(room);
        notifyListeners();
      }
      
      _setLoading(false);
      return room;
    } catch (e) {
      _setError('فشل في إنشاء المحادثة: $e');
      _setLoading(false);
      return null;
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _chatService.deleteMessage(messageId);
    } catch (e) {
      _setError('فشل في حذف الرسالة: $e');
    }
  }

  // Delete chat room
  Future<void> deleteChatRoom(String roomId) async {
    try {
      _setLoading(true);
      await _chatService.deleteChatRoom(roomId);
      
      // Remove from local list
      _chatRooms.removeWhere((room) => room.id == roomId);
      
      // Close current room if it's the deleted one
      if (_currentRoom?.id == roomId) {
        _currentRoom = null;
        _currentMessages.clear();
        _messagesSubscription?.cancel();
      }
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('فشل في حذف المحادثة: $e');
      _setLoading(false);
    }
  }

  // Get participant info
  Future<UserModel?> getParticipantInfo(String participantId) async {
    try {
      return await _chatService.getUserInfo(participantId);
    } catch (e) {
      return null;
    }
  }

  // Get artisan info
  Future<ArtisanModel?> getArtisanInfo(String artisanId) async {
    try {
      return await _chatService.getArtisanInfo(artisanId);
    } catch (e) {
      return null;
    }
  }

  // Get other participant info for current room
  Future<UserModel?> getOtherParticipantInfo() async {
    if (_currentRoom == null || _currentUser == null) {
      print('Warning: currentRoom or currentUser is null');
      return null;
    }
    
    // Use effective user ID (artisanId for artisans, userId for regular users)
    final effectiveUserId = _getEffectiveUserId();
    if (effectiveUserId.isEmpty) {
      print('Warning: Effective user ID is empty');
      return null;
    }
    
    // Determine the other participant ID
    String otherId;
    if (_currentRoom!.participant1Id == effectiveUserId) {
      otherId = _currentRoom!.participant2Id;
    } else if (_currentRoom!.participant2Id == effectiveUserId) {
      otherId = _currentRoom!.participant1Id;
    } else {
      // Current user is not in this room, use the first participant as fallback
      print('Warning: Effective user ID is not a participant in this room');
      otherId = _currentRoom!.participant1Id.isNotEmpty 
          ? _currentRoom!.participant1Id 
          : _currentRoom!.participant2Id;
    }
    
    if (otherId.isEmpty) {
      print('Warning: Other participant ID is empty');
      return null;
    }
    
    print('Getting other participant info: $otherId (effective user ID: $effectiveUserId)');
    
    // Try to get user info first
    final userInfo = await getParticipantInfo(otherId);
    if (userInfo != null && userInfo.name.isNotEmpty) {
      print('Found user: ${userInfo.name}');
      return userInfo;
    }
    
    // If user not found, try to get artisan info
    final artisanInfo = await getArtisanInfo(otherId);
    if (artisanInfo != null && artisanInfo.name.isNotEmpty) {
      print('Found artisan: ${artisanInfo.name}');
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
    
    print('Warning: Could not find user or artisan with ID: $otherId');
    return null;
  }

  // Close current chat room
  void closeCurrentRoom() {
    _currentRoom = null;
    _currentMessages.clear();
    _messagesSubscription?.cancel();
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// التحقق من وجود رسالة جديدة وتشغيل الصوت (للشات الحالي)
  void _checkAndPlayNotificationSound(List<ChatMessage> messages) {
    if (_currentUser == null || messages.isEmpty) {
      return;
    }

    final effectiveUserId = _getEffectiveUserId();
    if (effectiveUserId.isEmpty) {
      return;
    }

    // التحقق من وجود رسالة جديدة
    if (messages.length > _previousMessagesCount || 
        (messages.isNotEmpty && messages.last.id != _previousLastMessageId)) {
      
      // الحصول على آخر رسالة
      final lastMessage = messages.last;
      
      // التحقق من أن الرسالة ليست من المستخدم الحالي (رسالة واردة)
      final normalizedSenderId = lastMessage.senderId.trim();
      final normalizedCurrentUserId = effectiveUserId.trim();
      
      if (normalizedSenderId != normalizedCurrentUserId) {
        // تجنب تكرار الصوت لنفس الرسالة
        if (!_playedMessageIds.contains(lastMessage.id)) {
          _playedMessageIds.add(lastMessage.id);
          if (_playedMessageIds.length > 50) {
            _playedMessageIds.removeAt(0);
          }
          _notificationSoundService.playNotificationSound(key: lastMessage.id);
          _showNotificationWithSenderName(normalizedSenderId);
        }
      }
      
      // تحديث المتغيرات
      _previousMessagesCount = messages.length;
      _previousLastMessageId = messages.last.id;
    }
  }

  /// عرض إشعار مع اسم المرسل
  Future<void> _showNotificationWithSenderName(String senderId) async {
    try {
      var senderName = (await getParticipantInfo(senderId))?.name;
      senderName ??= (await getArtisanInfo(senderId))?.name;
      _pendingNotificationSenderName = senderName ?? 'مستخدم';
      notifyListeners();
    } catch (_) {
      _pendingNotificationSenderName = 'مستخدم';
      notifyListeners();
    }
  }

  /// التحقق من وجود رسائل جديدة في أي محادثة (من خارج الشات الحالي)
  void _checkForNewMessagesInRooms(List<ChatRoom> rooms) {
    if (_currentUser == null || rooms.isEmpty) {
      return;
    }

    final effectiveUserId = _getEffectiveUserId();
    if (effectiveUserId.isEmpty) {
      return;
    }

    // البحث عن محادثات بها رسائل غير مقروءة للمستخدم الحالي (المرسل الآخر أرسل)
    // والتأكد من أنها ليست الشات الحالي المفتوح
    for (final room in rooms) {
      final hasUnreadForMe = room.hasUnreadMessages &&
          (room.lastMessageSenderId == null || room.lastMessageSenderId!.trim() != effectiveUserId.trim());
      if (hasUnreadForMe && 
          room.id != _currentRoom?.id &&
          room.lastMessageTime != null) {
        
        final lastMessageTime = room.lastMessageTime!;
        final lastPlayedForRoom = _playedRoomTimes[room.id];
        
        // تجنب تكرار الصوت لنفس المحادثة (رسالة جديدة فعلاً)
        final isNewMessage = lastPlayedForRoom == null || 
            lastMessageTime.isAfter(lastPlayedForRoom);
        
        if (!isNewMessage) continue;
        
        // إذا كان هناك شات حالي مفتوح، تحقق من أن الرسالة الجديدة أحدث من آخر رسالة في الشات الحالي
        if (_currentRoom != null && _currentMessages.isNotEmpty) {
          final lastMessageInCurrentChat = _currentMessages.last;
          if (!lastMessageTime.isAfter(lastMessageInCurrentChat.timestamp)) {
            continue;
          }
        }
        
        // رسالة جديدة في محادثة أخرى
        _playedRoomTimes[room.id] = lastMessageTime;
        if (_playedRoomTimes.length > 30) {
          final keys = _playedRoomTimes.keys.toList();
          for (var i = 0; i < keys.length - 30; i++) {
            _playedRoomTimes.remove(keys[i]);
          }
        }
        final soundKey = '${room.id}_${lastMessageTime.millisecondsSinceEpoch}';
        _notificationSoundService.playNotificationSound(key: soundKey);
        
        // الحصول على اسم المرسل (المشارك الآخر في المحادثة)
        final otherId = room.participant1Id == effectiveUserId
            ? room.participant2Id
            : room.participant1Id;
        _showNotificationWithSenderName(otherId);
        break; // شغل الصوت مرة واحدة فقط
      }
    }
  }

  // Dispose
  @override
  void dispose() {
    _chatRoomsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
} 