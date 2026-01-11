import 'package:flutter/material.dart';
import '../Models/fault_report_model.dart';
import '../services/fault_service.dart';

class FaultProvider extends ChangeNotifier {
  final FaultService _faultService = FaultService();
  
  List<FaultReportModel> _faultReports = [];
  bool _isLoading = false;
  String? _error;

  List<FaultReportModel> get faultReports => _faultReports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // تحميل تقارير الأعطال للمستخدم الحالي
  Future<void> loadUserFaultReports() async {
    _setLoading(true);
    _clearError();

    try {
      _faultReports = await _faultService.getUserFaultReports();
      notifyListeners();
    } catch (e) {
      _setError('خطأ في تحميل تقارير الأعطال: $e');
    } finally {
      _setLoading(false);
    }
  }

  // تحميل جميع تقارير الأعطال (للمديرين)
  Future<void> loadAllFaultReports() async {
    _setLoading(true);
    _clearError();

    try {
      _faultReports = await _faultService.getAllFaultReports();
      notifyListeners();
    } catch (e) {
      _setError('خطأ في تحميل تقارير الأعطال: $e');
    } finally {
      _setLoading(false);
    }
  }

  // تحميل الأعطال المناسبة للحرفي حسب نوع حرفته
  Future<void> loadArtisanFaultReports(String craftType, {String? artisanId}) async {
    _setLoading(true);
    _clearError();

    try {
      print('🔧 تحميل أعطال للحرفي من نوع: $craftType');
      if (artisanId != null) {
        print('   - معرف الحرفي للتصفية: $artisanId');
      }
      
      // تحويل نوع الحرفة إلى نوع العطل المقابل
      final faultType = _convertCraftTypeToFaultType(craftType);
      print('🔄 نوع الحرفة: $craftType -> نوع العطل: $faultType');
      
      if (faultType != null) {
        _faultReports = await _faultService.getFaultReportsByType(faultType, excludeArtisanId: artisanId);
        print('✅ تم تحميل ${_faultReports.length} عطل للحرفي');
        notifyListeners();
      } else {
        print('⚠️ لا يوجد نوع عطل مطابق لنوع الحرفة: $craftType');
        _faultReports = [];
        notifyListeners();
      }
    } catch (e) {
      print('❌ خطأ في تحميل تقارير الأعطال: $e');
      _setError('خطأ في تحميل تقارير الأعطال: $e');
    } finally {
      _setLoading(false);
    }
  }

  // تحويل نوع الحرفة إلى نوع العطل المقابل
  String? _convertCraftTypeToFaultType(String craftType) {
    // التحقق من أن craftType ليس فارغاً
    if (craftType.isEmpty) {
      print('⚠️ نوع الحرفة فارغ');
      return null;
    }
    
    // بعض أنواع الحرف تحتاج تحويل خاص
    // لأن أسماء الحرف قد تختلف عن أسماء أنواع الأعطال
    final conversionMap = {
      'electrician': 'electrical',
      'plumber': 'plumbing',
    };
    
    // إذا كان هناك تحويل خاص، استخدمه
    if (conversionMap.containsKey(craftType)) {
      print('🔄 تحويل خاص: $craftType -> ${conversionMap[craftType]}');
      return conversionMap[craftType];
    }
    
    // لجميع الحالات الأخرى، استخدم craftType مباشرة
    // لأن معظم الحرف تستخدم نفس القيمة في faultType
    // وهذا يسمح للحرف الجديدة بالعمل تلقائياً دون تعديل الكود
    print('✅ استخدام نوع الحرفة مباشرة: $craftType');
    return craftType;
  }

  // إنشاء تقرير عطل جديد
  Future<bool> createFaultReport({
    required String faultType,
    required String serviceType,
    required String description,
    List<String>? imagePaths,
    String? voiceRecordingPath,
    String? videoPath,
    bool isScheduled = false,
    DateTime? scheduledDate,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      print('🔄 بدء إنشاء تقرير العطل في Provider...');
      
      final faultReport = await _faultService.createFaultReport(
        faultType: faultType,
        serviceType: serviceType,
        description: description,
        imagePaths: imagePaths,
        voiceRecordingPath: voiceRecordingPath,
        videoPath: videoPath,
        isScheduled: isScheduled,
        scheduledDate: scheduledDate,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );

      if (faultReport != null) {
        _faultReports.insert(0, faultReport);
        notifyListeners();
        print('✅ تم إنشاء تقرير العطل بنجاح في Provider');
        return true;
      } else {
        _setError('فشل في إنشاء تقرير العطل');
        print('❌ فشل في إنشاء تقرير العطل في Provider');
        return false;
      }
    } catch (e) {
      _setError('خطأ في إنشاء تقرير العطل: $e');
      print('❌ خطأ في إنشاء تقرير العطل في Provider: $e');
      return false;
    } finally {
      _setLoading(false);
      print(' انتهى إنشاء تقرير العطل في Provider');
    }
  }

  // تحديث حالة العطل
  Future<bool> updateFaultStatus(String faultId, String status, {String? assignedArtisanId, String? notes}) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _faultService.updateFaultStatus(
        faultId,
        status,
        assignedArtisanId: assignedArtisanId,
        notes: notes,
      );

      if (success) {
        // تحديث التقرير في القائمة المحلية
        final index = _faultReports.indexWhere((report) => report.id == faultId);
        if (index != -1) {
          _faultReports[index] = _faultReports[index].copyWith(
            status: status,
            assignedArtisanId: assignedArtisanId,
            notes: notes,
            updatedAt: DateTime.now(),
          );
          notifyListeners();
        }
        return true;
      } else {
        _setError('فشل في تحديث حالة العطل');
        return false;
      }
    } catch (e) {
      _setError('خطأ في تحديث حالة العطل: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // حذف تقرير عطل
  Future<bool> deleteFaultReport(String faultId) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _faultService.deleteFaultReport(faultId);
      
      if (success) {
        _faultReports.removeWhere((report) => report.id == faultId);
        notifyListeners();
        return true;
      } else {
        _setError('فشل في حذف تقرير العطل');
        return false;
      }
    } catch (e) {
      _setError('خطأ في حذف تقرير العطل: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // الحصول على تقرير عطل محدد
  FaultReportModel? getFaultReport(String faultId) {
    try {
      return _faultReports.firstWhere((report) => report.id == faultId);
    } catch (e) {
      return null;
    }
  }

  // تحديث التقرير محلياً (للتحديثات السريعة)
  void updateReportLocally(FaultReportModel updatedReport) {
    final index = _faultReports.indexWhere((report) => report.id == updatedReport.id);
    if (index != -1) {
      _faultReports[index] = updatedReport;
      notifyListeners();
    }
  }

  // تحديث حالة تفعيل العطل
  Future<bool> updateFaultActiveStatus(String faultId, bool isActive) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _faultService.updateFaultActiveStatus(faultId, isActive);
      
      if (success) {
        // تحديث التقرير في القائمة المحلية
        final index = _faultReports.indexWhere((report) => report.id == faultId);
        if (index != -1) {
          _faultReports[index] = _faultReports[index].copyWith(
            isActive: isActive,
            updatedAt: DateTime.now(),
          );
          notifyListeners();
        }
        return true;
      } else {
        _setError('فشل في تحديث حالة العطل');
        return false;
      }
    } catch (e) {
      _setError('خطأ في تحديث حالة العطل: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // رفض التقرير من قبل الحرفي
  Future<bool> declineFaultReport(String faultId, String artisanId) async {
    _clearError();

    try {
      final success = await _faultService.declineFaultReport(faultId, artisanId);
      
      if (success) {
        // إزالة التقرير من القائمة المحلية
        _faultReports.removeWhere((report) => report.id == faultId);
        notifyListeners();
        return true;
      } else {
        _setError('فشل في رفض التقرير');
        return false;
      }
    } catch (e) {
      _setError('خطأ في رفض التقرير: $e');
      return false;
    }
  }

  // تحديث تقرير عطل موجود
  Future<bool> updateFaultReport({
    required String faultId,
    String? faultType,
    String? serviceType,
    String? description,
    List<String>? imagePaths,
    String? voiceRecordingPath,
    String? videoPath,
    bool? isScheduled,
    DateTime? scheduledDate,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      print('🔄 بدء تحديث تقرير العطل في Provider...');
      
      final updatedReport = await _faultService.updateFaultReport(
        faultId: faultId,
        faultType: faultType,
        serviceType: serviceType,
        description: description,
        imagePaths: imagePaths,
        voiceRecordingPath: voiceRecordingPath,
        videoPath: videoPath,
        isScheduled: isScheduled,
        scheduledDate: scheduledDate,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );

      if (updatedReport != null) {
        // تحديث التقرير في القائمة المحلية
        final index = _faultReports.indexWhere((report) => report.id == faultId);
        if (index != -1) {
          _faultReports[index] = updatedReport;
        } else {
          _faultReports.insert(0, updatedReport);
        }
        notifyListeners();
        print('✅ تم تحديث تقرير العطل بنجاح في Provider');
        return true;
      } else {
        _setError('فشل في تحديث تقرير العطل');
        print('❌ فشل في تحديث تقرير العطل في Provider');
        return false;
      }
    } catch (e) {
      _setError('خطأ في تحديث تقرير العطل: $e');
      print('❌ خطأ في تحديث تقرير العطل في Provider: $e');
      return false;
    } finally {
      _setLoading(false);
      print('انتهى تحديث تقرير العطل في Provider');
    }
  }

  // تصفية التقارير حسب الحالة
  List<FaultReportModel> getFaultReportsByStatus(String status) {
    return _faultReports.where((report) => report.status == status).toList();
  }

  // تصفية التقارير حسب نوع العطل
  List<FaultReportModel> getFaultReportsByType(String faultType) {
    return _faultReports.where((report) => report.faultType == faultType).toList();
  }

  // تصفية التقارير المجدولة
  List<FaultReportModel> getScheduledFaultReports() {
    return _faultReports.where((report) => report.isScheduled).toList();
  }

  // إحصائيات التقارير
  Map<String, int> getFaultReportsStats() {
    final stats = <String, int>{};
    
    for (final status in FaultStatus.values) {
      stats[status.value] = _faultReports.where((report) => report.status == status.value).length;
    }
    
    return stats;
  }

  // مسح البيانات
  void clearData() {
    _faultReports.clear();
    _clearError();
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
