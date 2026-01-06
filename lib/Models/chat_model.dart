import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String senderId;
  final String receiverId;
  final String roomId; // Added for efficient filtering (will be calculated if not provided)
  final String content;
  final String? imageUrl;
  final String? fileUrl;
  final String? fileName;
  final String? fileSize;
  final String? voiceUrl;
  final int? voiceDuration;
  final LocationData? locationData;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.roomId = '', // Will be calculated if not provided
    required this.content,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.voiceUrl,
    this.voiceDuration,
    this.locationData,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Calculate roomId if not present (for backward compatibility)
    String roomId = json['roomId'] ?? '';
    if (roomId.isEmpty) {
      final senderId = (json['senderId'] ?? '').toString().trim();
      final receiverId = (json['receiverId'] ?? '').toString().trim();
      if (senderId.isNotEmpty && receiverId.isNotEmpty) {
        final sortedIds = [senderId, receiverId]..sort();
        roomId = '${sortedIds[0]}_${sortedIds[1]}';
      }
    }
    
    return ChatMessage(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      roomId: roomId,
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'],
      fileUrl: json['fileUrl'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      voiceUrl: json['voiceUrl'],
      voiceDuration: json['voiceDuration'],
      locationData: json['locationData'] != null 
          ? LocationData.fromJson(Map<String, dynamic>.from(json['locationData']))
          : null,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      isRead: json['isRead'] ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type'] ?? 'text'}',
        orElse: () => MessageType.text,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'roomId': roomId,
      'content': content,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'voiceUrl': voiceUrl,
      'voiceDuration': voiceDuration,
      'locationData': locationData?.toJson(),
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'type': type.toString().split('.').last,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? roomId,
    String? content,
    String? imageUrl,
    String? fileUrl,
    String? fileName,
    String? fileSize,
    String? voiceUrl,
    int? voiceDuration,
    LocationData? locationData,
    DateTime? timestamp,
    bool? isRead,
    MessageType? type,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      roomId: roomId ?? this.roomId,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      voiceUrl: voiceUrl ?? this.voiceUrl,
      voiceDuration: voiceDuration ?? this.voiceDuration,
      locationData: locationData ?? this.locationData,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [
    id, 
    senderId, 
    receiverId, 
    roomId,
    content, 
    imageUrl, 
    fileUrl, 
    fileName, 
    fileSize, 
    voiceUrl, 
    voiceDuration, 
    locationData, 
    timestamp, 
    isRead, 
    type
  ];
}

class ChatRoom extends Equatable {
  final String id;
  final String participant1Id;
  final String participant2Id;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final bool hasUnreadMessages;
  final int unreadCount;
  final String? participant1Name;
  final String? participant2Name;
  final String? participant1Image;
  final String? participant2Image;

  const ChatRoom({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    this.lastMessage,
    this.lastMessageTime,
    this.hasUnreadMessages = false,
    this.unreadCount = 0,
    this.participant1Name,
    this.participant2Name,
    this.participant1Image,
    this.participant2Image,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] ?? '',
      participant1Id: json['participant1Id'] ?? '',
      participant2Id: json['participant2Id'] ?? '',
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastMessageTime'])
          : null,
      hasUnreadMessages: json['hasUnreadMessages'] ?? false,
      unreadCount: json['unreadCount'] ?? 0,
      participant1Name: json['participant1Name'],
      participant2Name: json['participant2Name'],
      participant1Image: json['participant1Image'],
      participant2Image: json['participant2Image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participant1Id': participant1Id,
      'participant2Id': participant2Id,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
      'hasUnreadMessages': hasUnreadMessages,
      'unreadCount': unreadCount,
      'participant1Name': participant1Name,
      'participant2Name': participant2Name,
      'participant1Image': participant1Image,
      'participant2Image': participant2Image,
    };
  }

  ChatRoom copyWith({
    String? id,
    String? participant1Id,
    String? participant2Id,
    String? lastMessage,
    DateTime? lastMessageTime,
    bool? hasUnreadMessages,
    int? unreadCount,
    String? participant1Name,
    String? participant2Name,
    String? participant1Image,
    String? participant2Image,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      participant1Id: participant1Id ?? this.participant1Id,
      participant2Id: participant2Id ?? this.participant2Id,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      hasUnreadMessages: hasUnreadMessages ?? this.hasUnreadMessages,
      unreadCount: unreadCount ?? this.unreadCount,
      participant1Name: participant1Name ?? this.participant1Name,
      participant2Name: participant2Name ?? this.participant2Name,
      participant1Image: participant1Image ?? this.participant1Image,
      participant2Image: participant2Image ?? this.participant2Image,
    );
  }

  @override
  List<Object?> get props => [
        id,
        participant1Id,
        participant2Id,
        lastMessage,
        lastMessageTime,
        hasUnreadMessages,
        unreadCount,
        participant1Name,
        participant2Name,
        participant1Image,
        participant2Image,
      ];
}

enum MessageType {
  text,
  image,
  file,
  location,
  voice,
}

class LocationData extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;
  final String? placeName;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.placeName,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      address: json['address'],
      placeName: json['placeName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'placeName': placeName,
    };
  }

  @override
  List<Object?> get props => [latitude, longitude, address, placeName];
} 