import 'dart:async';
import 'package:flutter/foundation.dart';
import '../Models/chat_model.dart';
import '../Models/user_model.dart';
import '../Models/artisan_model.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  
  // State
  List<ChatRoom> _chatRooms = [];
  List<ChatMessage> _currentMessages = [];
  ChatRoom? _currentRoom;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<ChatRoom>>? _chatRoomsSubscription;
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;

  // Getters
  List<ChatRoom> get chatRooms => _chatRooms;
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

  // Load chat rooms for current user
  void _loadChatRooms() {
    if (_currentUser == null) return;

    _setLoading(true);
    _chatRoomsSubscription?.cancel();
    
    _chatRoomsSubscription = _chatService
        .getChatRoomsForUser(_currentUser!.id)
        .listen(
      (rooms) {
        _chatRooms = rooms;
        _setLoading(false);
        notifyListeners();
      },
      onError: (error) {
        _setError('فشل في تحميل المحادثات: $error');
        _setLoading(false);
      },
    );
  }

  // Open chat room
  Future<void> openChatRoom(String roomId) async {
    try {
      _setLoading(true);
      
      // Find the room
      final room = _chatRooms.firstWhere((r) => r.id == roomId);
      _currentRoom = room;
      
      // Load messages
      _messagesSubscription?.cancel();
      _messagesSubscription = _chatService
          .getMessagesForRoom(roomId)
          .listen(
        (messages) {
          _currentMessages = messages;
          notifyListeners();
        },
        onError: (error) {
          _setError('فشل في تحميل الرسائل: $error');
        },
      );

      // Mark messages as read
      if (_currentUser != null) {
        await _chatService.markAllMessagesAsRead(roomId, _currentUser!.id);
      }
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('فشل في فتح المحادثة: $e');
      _setLoading(false);
    }
  }

  // Send text message
  Future<void> sendTextMessage(String content) async {
    if (_currentUser == null || _currentRoom == null) {
      _setError('يجب تسجيل الدخول أولاً');
      return;
    }

    try {
      final receiverId = _currentRoom!.participant1Id == _currentUser!.id
          ? _currentRoom!.participant2Id
          : _currentRoom!.participant1Id;

      await _chatService.sendTextMessage(_currentUser!.id, receiverId, content);
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
      final receiverId = _currentRoom!.participant1Id == _currentUser!.id
          ? _currentRoom!.participant2Id
          : _currentRoom!.participant1Id;

      await _chatService.sendImageMessage(_currentUser!.id, receiverId, imageUrl, caption: caption);
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
      final receiverId = _currentRoom!.participant1Id == _currentUser!.id
          ? _currentRoom!.participant2Id
          : _currentRoom!.participant1Id;

      await _chatService.sendFileMessage(_currentUser!.id, receiverId, fileUrl, fileName, fileSize);
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
      final receiverId = _currentRoom!.participant1Id == _currentUser!.id
          ? _currentRoom!.participant2Id
          : _currentRoom!.participant1Id;

      await _chatService.sendLocationMessage(_currentUser!.id, receiverId, locationData);
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
      final receiverId = _currentRoom!.participant1Id == _currentUser!.id
          ? _currentRoom!.participant2Id
          : _currentRoom!.participant1Id;

      await _chatService.sendVoiceMessage(_currentUser!.id, receiverId, voiceUrl, duration);
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
      _setLoading(true);
      final room = await _chatService.createOrGetChatRoom(_currentUser!.id, otherUserId);
      
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
      _setLoading(true);
      final room = await _chatService.createOrGetChatRoom(_currentUser!.id, otherUserId);
      
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
    if (_currentRoom == null || _currentUser == null) return null;
    
    final otherId = _currentRoom!.participant1Id == _currentUser!.id
        ? _currentRoom!.participant2Id
        : _currentRoom!.participant1Id;
    
    return await getParticipantInfo(otherId);
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

  // Dispose
  @override
  void dispose() {
    _chatRoomsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
} 