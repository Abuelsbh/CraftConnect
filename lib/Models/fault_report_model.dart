import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FaultReportModel extends Equatable {
  final String id;
  final String userId;
  final String faultType;
  final String serviceType;
  final String description;
  final List<String> imageUrls;
  final String? voiceRecordingUrl;
  final String? videoUrl;
  final bool isScheduled;
  final DateTime? scheduledDate;
  final String status;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? assignedArtisanId;
  final String? notes;
  final int viewsCount;
  final bool isActive;

  const FaultReportModel({
    required this.id,
    required this.userId,
    required this.faultType,
    required this.serviceType,
    required this.description,
    required this.imageUrls,
    this.voiceRecordingUrl,
    this.videoUrl,
    required this.isScheduled,
    this.scheduledDate,
    required this.status,
    this.address,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
    this.assignedArtisanId,
    this.notes,
    this.viewsCount = 0,
    this.isActive = true,
  });

  factory FaultReportModel.fromJson(Map<String, dynamic> json) {
    // معالجة createdAt - قد يكون String أو Timestamp من Firestore
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      // محاولة التحويل إذا كان Timestamp من Firestore
      try {
        if (value.runtimeType.toString().contains('Timestamp')) {
          return (value as Timestamp).toDate();
        }
      } catch (e) {
        // تجاهل الخطأ
      }
      return DateTime.now();
    }

    return FaultReportModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      faultType: json['faultType'] ?? '',
      serviceType: json['serviceType'] ?? '',
      description: json['description'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      voiceRecordingUrl: json['voiceRecordingUrl'],
      videoUrl: json['videoUrl'],
      isScheduled: json['isScheduled'] ?? false,
      scheduledDate: json['scheduledDate'] != null 
          ? parseDateTime(json['scheduledDate'])
          : null,
      status: json['status'] ?? 'pending',
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
      assignedArtisanId: json['assignedArtisanId'],
      notes: json['notes'],
      viewsCount: json['viewsCount'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'faultType': faultType,
      'serviceType': serviceType,
      'description': description,
      'imageUrls': imageUrls,
      'voiceRecordingUrl': voiceRecordingUrl,
      'videoUrl': videoUrl,
      'isScheduled': isScheduled,
      'scheduledDate': scheduledDate?.toIso8601String(),
      'status': status,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'assignedArtisanId': assignedArtisanId,
      'notes': notes,
      'viewsCount': viewsCount,
      'isActive': isActive,
    };
  }

  FaultReportModel copyWith({
    String? id,
    String? userId,
    String? faultType,
    String? serviceType,
    String? description,
    List<String>? imageUrls,
    String? voiceRecordingUrl,
    String? videoUrl,
    bool? isScheduled,
    DateTime? scheduledDate,
    String? status,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assignedArtisanId,
    String? notes,
    int? viewsCount,
    bool? isActive,
  }) {
    return FaultReportModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      faultType: faultType ?? this.faultType,
      serviceType: serviceType ?? this.serviceType,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      voiceRecordingUrl: voiceRecordingUrl ?? this.voiceRecordingUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      isScheduled: isScheduled ?? this.isScheduled,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedArtisanId: assignedArtisanId ?? this.assignedArtisanId,
      notes: notes ?? this.notes,
      viewsCount: viewsCount ?? this.viewsCount,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        faultType,
        serviceType,
        description,
        imageUrls,
        voiceRecordingUrl,
        videoUrl,
        isScheduled,
        scheduledDate,
        status,
        address,
        latitude,
        longitude,
        createdAt,
        updatedAt,
        assignedArtisanId,
        notes,
        viewsCount,
        isActive,
      ];
}

enum FaultStatus {
  pending('pending', 'في الانتظار'),
  assigned('assigned', 'تم التعيين'),
  inProgress('inProgress', 'قيد التنفيذ'),
  completed('completed', 'مكتمل'),
  cancelled('cancelled', 'ملغي');

  const FaultStatus(this.value, this.displayName);
  final String value;
  final String displayName;
}

enum FaultType {
  carpenter('carpenter', 'عطل نجارة'),
  electrical('electrical', 'عطل كهربائي'),
  plumbing('plumbing', 'عطل سباكة'),
  painter('painter', 'عطل دهان'),
  mechanic('mechanic', 'عطل ميكانيكي'),
  hvac('hvac', 'عطل تكييف'),
  satellite('satellite', 'عطل ستالايت'),
  internet('internet', 'عطل إنترنت'),
  tiler('tiler', 'عطل بلاط'),
  locksmith('locksmith', 'عطل أقفال');

  const FaultType(this.value, this.displayName);
  final String value;
  final String displayName;
}
