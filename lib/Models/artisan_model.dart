import 'package:equatable/equatable.dart';

class ArtisanModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profileImageUrl;
  final String craftType;
  final int yearsOfExperience;
  final String description;
  final double latitude;
  final double longitude;
  final String address;
  final double rating;
  final int reviewCount;
  final List<String> galleryImages;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ArtisanModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImageUrl,
    required this.craftType,
    required this.yearsOfExperience,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.galleryImages = const [],
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ArtisanModel.fromJson(Map<String, dynamic> json) {
    return ArtisanModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      craftType: json['craftType'] ?? '',
      yearsOfExperience: json['yearsOfExperience'] ?? 0,
      description: json['description'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      galleryImages: List<String>.from(json['galleryImages'] ?? []),
      isAvailable: json['isAvailable'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'craftType': craftType,
      'yearsOfExperience': yearsOfExperience,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'rating': rating,
      'reviewCount': reviewCount,
      'galleryImages': galleryImages,
      'isAvailable': isAvailable,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ArtisanModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    String? craftType,
    int? yearsOfExperience,
    String? description,
    double? latitude,
    double? longitude,
    String? address,
    double? rating,
    int? reviewCount,
    List<String>? galleryImages,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ArtisanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      craftType: craftType ?? this.craftType,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      galleryImages: galleryImages ?? this.galleryImages,
      isAvailable: isAvailable ?? this.isAvailable,
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
        craftType,
        yearsOfExperience,
        description,
        latitude,
        longitude,
        address,
        rating,
        reviewCount,
        galleryImages,
        isAvailable,
        createdAt,
        updatedAt,
      ];
} 