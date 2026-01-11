import 'package:flutter/foundation.dart';
import '../services/favorite_service.dart';

/// Provider لإدارة حالة المفضلة للمستخدم الحالي
class FavoriteProvider extends ChangeNotifier {
  final FavoriteService _favoriteService = FavoriteService();

  /// معرف المستخدم الحالي (يتم تمريره من الـ Auth عند الحاجة)
  String? _currentUserId;

  /// مجموعة معرفات الحرفيين الموجودين في مفضلة المستخدم
  Set<String> _favoriteArtisanIds = {};

  bool _isLoading = false;
  String? _errorMessage;

  Set<String> get favoriteArtisanIds => _favoriteArtisanIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// تهيئة الـ provider عند توفر مستخدم مسجل
  Future<void> initForUser(String userId) async {
    if (_currentUserId == userId && _favoriteArtisanIds.isNotEmpty) return;

    _currentUserId = userId;
    await _loadFavorites();
  }

  /// مسح البيانات عند تسجيل الخروج
  void clear() {
    _currentUserId = null;
    _favoriteArtisanIds = {};
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _loadFavorites() async {
    if (_currentUserId == null) return;
    try {
      _setLoading(true);
      _errorMessage = null;

      _favoriteArtisanIds =
          await _favoriteService.getUserFavoriteArtisanIds(_currentUserId!);
    } catch (e) {
      _errorMessage = 'فشل في تحميل قائمة المفضلة';
      if (kDebugMode) {
        print('FavoriteProvider load error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// التحقق إذا كان الحرفي في المفضلة
  bool isFavorite(String artisanId) {
    return _favoriteArtisanIds.contains(artisanId);
  }

  /// تبديل حالة المفضلة لحرفي معين
  ///
  /// يتطلب أن يكون هناك مستخدم مسجل (_currentUserId != null)
  Future<bool> toggleFavorite(String artisanId) async {
    if (_currentUserId == null) {
      throw Exception('يجب تسجيل الدخول لإدارة المفضلة');
    }

    try {
      final isNowFavorite = await _favoriteService.toggleFavorite(
        userId: _currentUserId!,
        artisanId: artisanId,
      );

      if (isNowFavorite) {
        _favoriteArtisanIds.add(artisanId);
      } else {
        _favoriteArtisanIds.remove(artisanId);
      }

      notifyListeners();
      return isNowFavorite;
    } catch (e) {
      _errorMessage = 'فشل في تحديث حالة المفضلة';
      if (kDebugMode) {
        print('FavoriteProvider toggle error: $e');
      }
      notifyListeners();
      rethrow;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}















