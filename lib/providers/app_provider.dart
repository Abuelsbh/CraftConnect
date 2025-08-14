import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../Models/artisan_model.dart';
import '../Models/craft_model.dart';
import '../Models/user_model.dart';

class AppProvider with ChangeNotifier {
  // حالة التطبيق العامة
  bool _isLoading = false;
  String? _errorMessage;
  
  // الموقع الحالي للمستخدم
  Position? _currentPosition;
  
  // بيانات الحرفيين والحرف
  List<ArtisanModel> _artisans = [];
  List<CraftModel> _crafts = [];
  
  // المستخدم الحالي
  UserModel? _currentUser;
  bool _isLoggedIn = false;
  
  // البحث والفلترة
  String _searchQuery = '';
  String _selectedCraftType = 'all';
  double _searchRadius = 10.0; // km
  
  // الحصول على القيم
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Position? get currentPosition => _currentPosition;
  List<ArtisanModel> get artisans => _artisans;
  List<CraftModel> get crafts => _crafts;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  String get searchQuery => _searchQuery;
  String get selectedCraftType => _selectedCraftType;
  double get searchRadius => _searchRadius;

  // الحرفيين المفلترين
  List<ArtisanModel> get filteredArtisans {
    List<ArtisanModel> filtered = _artisans;

    // فلترة حسب نوع الحرفة
    if (_selectedCraftType != 'all') {
      filtered = filtered.where((artisan) => artisan.craftType == _selectedCraftType).toList();
    }

    // فلترة حسب البحث
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((artisan) => 
        artisan.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        artisan.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // ترتيب حسب المسافة إذا كان الموقع متاحاً
    if (_currentPosition != null) {
      filtered.sort((a, b) {
        double distanceA = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          a.latitude,
          a.longitude,
        );
        double distanceB = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          b.latitude,
          b.longitude,
        );
        return distanceA.compareTo(distanceB);
      });
    }

    return filtered;
  }

  // تعيين حالة التحميل
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // تعيين رسالة الخطأ
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // تحديث الموقع الحالي
  void updateCurrentPosition(Position position) {
    _currentPosition = position;
    notifyListeners();
  }

  // تحديث قائمة الحرفيين
  void updateArtisans(List<ArtisanModel> artisans) {
    _artisans = artisans;
    notifyListeners();
  }

  // تحديث قائمة الحرف
  void updateCrafts(List<CraftModel> crafts) {
    _crafts = crafts;
    notifyListeners();
  }

  // تسجيل دخول المستخدم
  void loginUser(UserModel user) {
    _currentUser = user;
    _isLoggedIn = true;
    notifyListeners();
  }

  // تسجيل خروج المستخدم
  void logoutUser() {
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  // تحديث استعلام البحث
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // تحديث نوع الحرفة المحددة
  void updateSelectedCraftType(String craftType) {
    _selectedCraftType = craftType;
    notifyListeners();
  }

  // تحديث نطاق البحث
  void updateSearchRadius(double radius) {
    _searchRadius = radius;
    notifyListeners();
  }

  // إضافة حرفي إلى المفضلة
  void toggleFavoriteArtisan(String artisanId) {
    // TODO: تنفيذ إضافة/إزالة من المفضلة
    notifyListeners();
  }

  // الحصول على الحرفيين القريبين
  List<ArtisanModel> getNearbyArtisans(double maxDistance) {
    if (_currentPosition == null) return _artisans;

    return _artisans.where((artisan) {
      double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        artisan.latitude,
        artisan.longitude,
      ) / 1000; // تحويل إلى كيلومتر

      return distance <= maxDistance;
    }).toList();
  }

  // حساب المسافة إلى حرفي
  double? getDistanceToArtisan(ArtisanModel artisan) {
    if (_currentPosition == null) return null;

    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      artisan.latitude,
      artisan.longitude,
    ) / 1000; // كيلومتر
  }

  // تحميل البيانات الأولية
  Future<void> loadInitialData() async {
    setLoading(true);
    setError(null);

    try {
      // تحميل الحرف
      await _loadCrafts();
      
      // تحميل الحرفيين
      await _loadArtisans();

      // الحصول على الموقع الحالي
      await _getCurrentLocation();

    } catch (e) {
      setError('حدث خطأ في تحميل البيانات: ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }

  Future<void> _loadCrafts() async {
    // تحميل الحرف من Firebase
    try {
      // يمكن إضافة خدمة للحرف هنا
      // final craftService = CraftService();
      // _crafts = await craftService.getAllCrafts();
      
      // في الوقت الحالي، سنترك القائمة فارغة
      _crafts = [];
    } catch (e) {
      _errorMessage = 'فشل في تحميل الحرف: $e';
    }
  }

  Future<void> _loadArtisans() async {
    // تحميل الحرفيين من Firebase
    try {
      // يمكن إضافة خدمة للحرفيين هنا
      // final artisanService = ArtisanService();
      // _artisans = await artisanService.getAllArtisans();
      
      // في الوقت الحالي، سنترك القائمة فارغة
      _artisans = [];
    } catch (e) {
      _errorMessage = 'فشل في تحميل الحرفيين: $e';
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      updateCurrentPosition(position);
    } catch (e) {
      // فشل في الحصول على الموقع، استخدام الموقع الافتراضي
      if (kDebugMode) {
        print('Failed to get location: $e');
      }
    }
  }

  // تحديث معلومات حرفي
  void updateArtisan(ArtisanModel updatedArtisan) {
    int index = _artisans.indexWhere((artisan) => artisan.id == updatedArtisan.id);
    if (index != -1) {
      _artisans[index] = updatedArtisan;
      notifyListeners();
    }
  }

  // إضافة حرفي جديد
  void addArtisan(ArtisanModel artisan) {
    _artisans.add(artisan);
    notifyListeners();
  }

  // حذف حرفي
  void removeArtisan(String artisanId) {
    _artisans.removeWhere((artisan) => artisan.id == artisanId);
    notifyListeners();
  }

  // إعادة تعيين الفلاتر
  void resetFilters() {
    _searchQuery = '';
    _selectedCraftType = 'all';
    _searchRadius = 10.0;
    notifyListeners();
  }

  // البحث المتقدم
  List<ArtisanModel> searchArtisans({
    String? query,
    String? craftType,
    double? minRating,
    int? maxDistance,
  }) {
    List<ArtisanModel> results = _artisans;

    if (query != null && query.isNotEmpty) {
      results = results.where((artisan) =>
        artisan.name.toLowerCase().contains(query.toLowerCase()) ||
        artisan.description.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }

    if (craftType != null && craftType != 'all') {
      results = results.where((artisan) => artisan.craftType == craftType).toList();
    }

    if (minRating != null) {
      results = results.where((artisan) => artisan.rating >= minRating).toList();
    }

    if (maxDistance != null && _currentPosition != null) {
      results = results.where((artisan) {
        double distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          artisan.latitude,
          artisan.longitude,
        ) / 1000;
        return distance <= maxDistance;
      }).toList();
    }

    return results;
  }
} 