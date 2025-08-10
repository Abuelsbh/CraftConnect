import 'package:equatable/equatable.dart';

class CraftModel extends Equatable {
  final String id;
  final String name;
  final String nameKey;
  final String iconPath;
  final String description;
  final int artisanCount;
  final String category;
  final double averageRating;

  const CraftModel({
    required this.id,
    required this.name,
    required this.nameKey,
    required this.iconPath,
    required this.description,
    required this.artisanCount,
    required this.category,
    required this.averageRating,
  });

  factory CraftModel.fromJson(Map<String, dynamic> json) {
    return CraftModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameKey: json['nameKey'] ?? json['name'] ?? '',
      iconPath: json['iconPath'] ?? '',
      description: json['description'] ?? '',
      artisanCount: json['artisanCount'] ?? 0,
      category: json['category'] ?? '',
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameKey': nameKey,
      'iconPath': iconPath,
      'description': description,
      'artisanCount': artisanCount,
      'category': category,
      'averageRating': averageRating,
    };
  }

  CraftModel copyWith({
    String? id,
    String? name,
    String? nameKey,
    String? iconPath,
    String? description,
    int? artisanCount,
    String? category,
    double? averageRating,
  }) {
    return CraftModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameKey: nameKey ?? this.nameKey,
      iconPath: iconPath ?? this.iconPath,
      description: description ?? this.description,
      artisanCount: artisanCount ?? this.artisanCount,
      category: category ?? this.category,
      averageRating: averageRating ?? this.averageRating,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        nameKey,
        iconPath,
        description,
        artisanCount,
        category,
        averageRating,
      ];
} 