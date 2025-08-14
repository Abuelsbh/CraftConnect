import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profileImageUrl;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String token;
  final String userType; // 'user' أو 'artisan'
  final String? artisanId; // معرف الحرفي إذا كان المستخدم حرفي
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImageUrl = '',
    this.latitude,
    this.longitude,
    this.address,
    this.token = '',
    this.userType = 'user',
    this.artisanId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      return UserModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        profileImageUrl: json['profileImageUrl']?.toString() ?? '',
        latitude: _parseDouble(json['latitude']),
        longitude: _parseDouble(json['longitude']),
        address: json['address']?.toString(),
        token: json['token']?.toString() ?? '',
        userType: json['userType']?.toString() ?? 'user',
        artisanId: json['artisanId']?.toString(),
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
      );
    } catch (e) {
      // في حالة الخطأ، إرجاع نموذج افتراضي
      return UserModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        profileImageUrl: json['profileImageUrl']?.toString() ?? '',
        token: json['token']?.toString() ?? '',
        userType: json['userType']?.toString() ?? 'user',
        artisanId: json['artisanId']?.toString(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'token': token,
      'userType': userType,
      'artisanId': artisanId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    double? latitude,
    double? longitude,
    String? address,
    String? token,
    String? userType,
    String? artisanId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      token: token ?? this.token,
      userType: userType ?? this.userType,
      artisanId: artisanId ?? this.artisanId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        profileImageUrl,
        latitude,
        longitude,
        address,
        token,
        userType,
        artisanId,
        createdAt,
        updatedAt,
      ];
} 