import 'package:equatable/equatable.dart';

/// نموذج الحرفة مع دعم الترجمة
class CraftModel extends Equatable {
  final String id;
  final String value; // القيمة المستخدمة في الكود (مثل: 'carpenter', 'electrical')
  final Map<String, String> translations; // الترجمات: {'ar': 'عطل نجارة', 'en': 'Carpentry Problem'}
  final int order; // ترتيب العرض
  final bool isActive; // هل الحرفة نشطة
  final String? iconUrl; // رابط الأيقونة
  final DateTime createdAt;
  final DateTime updatedAt;

  const CraftModel({
    required this.id,
    required this.value,
    required this.translations,
    this.order = 0,
    this.isActive = true,
    this.iconUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// الحصول على الترجمة حسب اللغة
  String getDisplayName(String languageCode) {
    return translations[languageCode] ?? translations['ar'] ?? value;
  }

  /// الحصول على الترجمة العربية
  String get arabicName => getDisplayName('ar');

  /// الحصول على الترجمة الإنجليزية
  String get englishName => getDisplayName('en');

  factory CraftModel.fromJson(Map<String, dynamic> json, String id) {
    return CraftModel(
      id: id,
      value: json['value'] ?? '',
      translations: Map<String, String>.from(json['translations'] ?? {}),
      order: json['order'] ?? 0,
      isActive: json['isActive'] ?? true,
      iconUrl: json['iconUrl'],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is DateTime
              ? json['createdAt'] as DateTime
              : DateTime.parse(json['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is DateTime
              ? json['updatedAt'] as DateTime
              : DateTime.parse(json['updatedAt'].toString()))
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'translations': translations,
      'order': order,
      'isActive': isActive,
      'iconUrl': iconUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CraftModel copyWith({
    String? id,
    String? value,
    Map<String, String>? translations,
    int? order,
    bool? isActive,
    String? iconUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CraftModel(
      id: id ?? this.id,
      value: value ?? this.value,
      translations: translations ?? this.translations,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      iconUrl: iconUrl ?? this.iconUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        value,
        translations,
        order,
        isActive,
        iconUrl,
        createdAt,
        updatedAt,
      ];
}
