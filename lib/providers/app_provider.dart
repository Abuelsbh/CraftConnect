import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/artisan_model.dart';
import '../models/craft_model.dart';
import '../models/user_model.dart';

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
    // محاكاة تحميل الحرف من Firebase
    await Future.delayed(const Duration(milliseconds: 500));
    
    _crafts = [
      CraftModel(
        id: 'carpenter',
        name: 'نجار',
        nameKey: 'carpenter',
        iconPath: 'assets/icons/carpenter.svg',
        description: 'صناعة وإصلاح الأثاث الخشبي',
        artisanCount: 45,
        category: 'construction',
        averageRating: 4.8,
      ),
      CraftModel(
        id: 'electrician',
        name: 'كهربائي',
        nameKey: 'electrician',
        iconPath: 'assets/icons/electrician.svg',
        description: 'تركيب وصيانة الأنظمة الكهربائية',
        artisanCount: 38,
        category: 'maintenance',
        averageRating: 4.7,
      ),
      CraftModel(
        id: 'plumber',
        name: 'سباك',
        nameKey: 'plumber',
        iconPath: 'assets/icons/plumber.svg',
        description: 'تركيب وصيانة أنظمة السباكة',
        artisanCount: 32,
        category: 'maintenance',
        averageRating: 4.6,
      ),
      CraftModel(
        id: 'painter',
        name: 'رسام',
        nameKey: 'painter',
        iconPath: 'assets/icons/painter.svg',
        description: 'طلاء وديكور المنازل والمباني',
        artisanCount: 28,
        category: 'decoration',
        averageRating: 4.5,
      ),
      CraftModel(
        id: 'mechanic',
        name: 'ميكانيكي',
        nameKey: 'mechanic',
        iconPath: 'assets/icons/mechanic.svg',
        description: 'إصلاح وصيانة السيارات',
        artisanCount: 41,
        category: 'automotive',
        averageRating: 4.9,
      ),
    ];
  }

  Future<void> _loadArtisans() async {
    // محاكاة تحميل الحرفيين من Firebase
    await Future.delayed(const Duration(milliseconds: 800));
    
    _artisans = [
      ArtisanModel(
        id: '1',
        name: 'محمد أحمد السعيد',
        email: 'mohamed.ahmed@example.com',
        phone: '+966501234567',
        profileImageUrl: '',
        craftType: 'carpenter',
        yearsOfExperience: 12,
        description: 'نجار محترف متخصص في صناعة الأثاث المنزلي والمكتبي بأعلى معايير الجودة',
        latitude: 24.7136,
        longitude: 46.6753,
        address: 'الرياض، المملكة العربية السعودية',
        rating: 4.8,
        reviewCount: 156,
        galleryImages: [],
        createdAt: DateTime.now().subtract(const Duration(days: 1095)),
        updatedAt: DateTime.now(),
      ),
      ArtisanModel(
        id: '2',
        name: 'سعد محمد العتيبي',
        email: 'saad.mohamed@example.com',
        phone: '+966509876543',
        profileImageUrl: '',
        craftType: 'electrician',
        yearsOfExperience: 8,
        description: 'كهربائي معتمد لجميع أنواع التمديدات والصيانة الكهربائية',
        latitude: 24.7200,
        longitude: 46.6800,
        address: 'الرياض، المملكة العربية السعودية',
        rating: 4.9,
        reviewCount: 203,
        galleryImages: [],
        createdAt: DateTime.now().subtract(const Duration(days: 800)),
        updatedAt: DateTime.now(),
      ),
      ArtisanModel(
        id: '3',
        name: 'عبدالله سالم',
        email: 'abdullah.salem@example.com',
        phone: '+966555123456',
        profileImageUrl: '',
        craftType: 'plumber',
        yearsOfExperience: 6,
        description: 'سباك ماهر في تركيب وصيانة جميع أنواع السباكة',
        latitude: 24.7100,
        longitude: 46.6700,
        address: 'الرياض، المملكة العربية السعودية',
        rating: 4.6,
        reviewCount: 89,
        galleryImages: [],
        createdAt: DateTime.now().subtract(const Duration(days: 400)),
        updatedAt: DateTime.now(),
      ),
    ];
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