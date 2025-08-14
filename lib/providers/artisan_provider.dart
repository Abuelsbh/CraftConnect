import 'dart:io';
import 'package:flutter/material.dart';
import '../Models/artisan_model.dart';
import '../services/artisan_service.dart';

class ArtisanProvider extends ChangeNotifier {
  final ArtisanService _artisanService = ArtisanService();
  
  List<ArtisanModel> _artisans = [];
  List<ArtisanModel> _filteredArtisans = [];
  ArtisanModel? _currentArtisan;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCraftType = 'all';

  // Getters
  List<ArtisanModel> get artisans => _artisans;
  List<ArtisanModel> get filteredArtisans => _filteredArtisans;
  ArtisanModel? get currentArtisan => _currentArtisan;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCraftType => _selectedCraftType;

  // تسجيل حرفي جديد
  Future<bool> registerArtisan({
    required String name,
    required String email,
    required String phone,
    required String craftType,
    required int yearsOfExperience,
    required String description,
    String? profileImagePath,
    List<String>? galleryImagePaths,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // التحقق من وجود الملفات قبل البدء
      if (profileImagePath != null) {
        final profileFile = File(profileImagePath);
        if (!await profileFile.exists()) {
          throw Exception('ملف الصورة الشخصية غير موجود');
        }
      }

      if (galleryImagePaths != null) {
        for (String imagePath in galleryImagePaths) {
          final galleryFile = File(imagePath);
          if (!await galleryFile.exists()) {
            throw Exception('أحد ملفات المعرض غير موجود');
          }
        }
      }

      final artisan = await _artisanService.registerArtisan(
        name: name,
        email: email,
        phone: phone,
        craftType: craftType,
        yearsOfExperience: yearsOfExperience,
        description: description,
        profileImagePath: profileImagePath,
        galleryImagePaths: galleryImagePaths,
      );

      if (artisan != null) {
        _currentArtisan = artisan;
        _artisans.add(artisan);
        _filterArtisans();
        _setLoading(false);
        return true;
      }

      _setLoading(false);
      return false;
    } catch (e) {
      String errorMessage = 'فشل في تسجيل الحرفي';
      
      if (e.toString().contains('فشل في رفع الصورة')) {
        errorMessage = 'فشل في رفع الصور. تأكد من اتصالك بالإنترنت وحاول مرة أخرى.';
      } else if (e.toString().contains('يجب تسجيل الدخول')) {
        errorMessage = 'يجب تسجيل الدخول أولاً';
      } else if (e.toString().contains('فشل في الحصول على الموقع')) {
        errorMessage = 'فشل في الحصول على موقعك. تأكد من تفعيل خدمة الموقع.';
      } else if (e.toString().contains('ملف')) {
        errorMessage = e.toString();
      } else {
        errorMessage = 'فشل في تسجيل الحرفي: $e';
      }
      
      _setError(errorMessage);
      _setLoading(false);
      return false;
    }
  }

  // جلب جميع الحرفيين
  Future<void> loadAllArtisans() async {
    try {
      _setLoading(true);
      _clearError();

      final artisans = await _artisanService.getAllArtisans();
      _artisans = artisans;
      _filterArtisans();

      _setLoading(false);
    } catch (e) {
      _setError('فشل في جلب الحرفيين: $e');
      _setLoading(false);
    }
  }

  // جلب الحرفيين حسب النوع
  Future<void> loadArtisansByCraftType(String craftType) async {
    try {
      _setLoading(true);
      _clearError();

      final artisans = await _artisanService.getArtisansByCraftType(craftType);
      _artisans = artisans;
      _filterArtisans();

      _setLoading(false);
    } catch (e) {
      _setError('فشل في جلب الحرفيين: $e');
      _setLoading(false);
    }
  }

  // البحث عن الحرفيين حسب الموقع
  Future<void> searchArtisansByLocation({
    required double latitude,
    required double longitude,
    required double radiusInKm,
    String? craftType,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final artisans = await _artisanService.searchArtisansByLocation(
        latitude: latitude,
        longitude: longitude,
        radiusInKm: radiusInKm,
        craftType: craftType,
      );

      _artisans = artisans;
      _filterArtisans();

      _setLoading(false);
    } catch (e) {
      _setError('فشل في البحث عن الحرفيين: $e');
      _setLoading(false);
    }
  }

  // تحديث بيانات الحرفي
  Future<bool> updateArtisan(ArtisanModel artisan) async {
    try {
      _setLoading(true);
      _clearError();

      await _artisanService.updateArtisan(artisan);

      // تحديث القائمة المحلية
      final index = _artisans.indexWhere((a) => a.id == artisan.id);
      if (index != -1) {
        _artisans[index] = artisan;
      }

      // تحديث الحرفي الحالي إذا كان هو نفسه
      if (_currentArtisan?.id == artisan.id) {
        _currentArtisan = artisan;
      }

      _filterArtisans();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('فشل في تحديث الحرفي: $e');
      _setLoading(false);
      return false;
    }
  }

  // حذف الحرفي
  Future<bool> deleteArtisan(String artisanId) async {
    try {
      _setLoading(true);
      _clearError();

      await _artisanService.deleteArtisan(artisanId);

      // إزالة من القائمة المحلية
      _artisans.removeWhere((a) => a.id == artisanId);

      // إزالة من الحرفي الحالي إذا كان هو نفسه
      if (_currentArtisan?.id == artisanId) {
        _currentArtisan = null;
      }

      _filterArtisans();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('فشل في حذف الحرفي: $e');
      _setLoading(false);
      return false;
    }
  }

  // اختيار نوع الحرفة للتصفية
  void selectCraftType(String craftType) {
    _selectedCraftType = craftType;
    _filterArtisans();
    notifyListeners();
  }

  // تصفية الحرفيين حسب النوع المحدد
  void _filterArtisans() {
    if (_selectedCraftType == 'all') {
      _filteredArtisans = List.from(_artisans);
    } else {
      _filteredArtisans = _artisans
          .where((artisan) => artisan.craftType == _selectedCraftType)
          .toList();
    }
    notifyListeners();
  }

  // تعيين الحرفي الحالي
  void setCurrentArtisan(ArtisanModel? artisan) {
    _currentArtisan = artisan;
    notifyListeners();
  }

  // تعيين حالة التحميل
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // تعيين رسالة الخطأ
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  // مسح رسالة الخطأ
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // مسح جميع البيانات
  void clearData() {
    _artisans.clear();
    _filteredArtisans.clear();
    _currentArtisan = null;
    _selectedCraftType = 'all';
    _errorMessage = null;
    notifyListeners();
  }

  // الحصول على عدد الحرفيين حسب النوع
  int getArtisanCountByType(String craftType) {
    if (craftType == 'all') {
      return _artisans.length;
    }
    return _artisans.where((a) => a.craftType == craftType).length;
  }

  // الحصول على الحرفيين المتاحين فقط
  List<ArtisanModel> get availableArtisans {
    return _artisans.where((a) => a.isAvailable).toList();
  }

  // الحصول على الحرفيين حسب التقييم
  List<ArtisanModel> getArtisansByRating(double minRating) {
    return _artisans.where((a) => a.rating >= minRating).toList();
  }

  // الحصول على الحرفيين حسب الخبرة
  List<ArtisanModel> getArtisansByExperience(int minYears) {
    return _artisans.where((a) => a.yearsOfExperience >= minYears).toList();
  }

  // الحصول على حرفي بواسطة المعرف
  Future<ArtisanModel?> getArtisanById(String artisanId) async {
    try {
      _setLoading(true);
      _clearError();

      final artisan = await _artisanService.getArtisanById(artisanId);
      _setLoading(false);
      return artisan;
    } catch (e) {
      _setError('فشل في جلب بيانات الحرفي: $e');
      _setLoading(false);
      return null;
    }
  }
} 