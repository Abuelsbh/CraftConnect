import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';
import '../../Models/artisan_model.dart';
import '../../providers/simple_auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/favorite_provider.dart';

class CompleteMapsPage extends StatefulWidget {
  const CompleteMapsPage({super.key});

  @override
  State<CompleteMapsPage> createState() => _CompleteMapsPageState();
}

class _CompleteMapsPageState extends State<CompleteMapsPage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  
  // موقع الكويت الافتراضي
  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(29.3759, 47.9774),
    zoom: 6.0,
  );

  CameraPosition _currentPosition = _defaultLocation;
  Set<Marker> _markers = {};
  List<ArtisanModel> _artisans = [];
  bool _isLoading = true;
  bool _locationPermissionGranted = false;
  String? _errorMessage;
  String _selectedCraftType = 'all';
  LatLng? _userLocation;

  final List<String> _craftTypes = [
    'all',
    'carpenter',
    'electrician',
    'plumber',
    'painter',
    'mechanic',
    'hvac',
    'satellite',
    'internet',
    'tiler',
    'locksmith',
  ];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // تحقق من صلاحيات الموقع
      await _checkLocationPermission();
      
      // تحميل بيانات الحرفيين
      await _loadArtisansData();
      
      // محاولة الحصول على الموقع الحالي
      if (_locationPermissionGranted) {
        await _getCurrentLocation();
      } else {
        // استخدام الموقع الافتراضي
        _userLocation = _defaultLocation.target;
      }
      
      // إنشاء العلامات على الخريطة
      await _createMarkers();
      
      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '${AppLocalizations.of(context)?.translate('location_error') ?? 'خطأ في تحميل الخريطة'}: ${e.toString()}';
      });
      
      // حتى لو حدث خطأ، نعرض البيانات مع الموقع الافتراضي
      _userLocation = _defaultLocation.target;
      await _loadArtisansData();
      await _createMarkers();
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationPermissionGranted = false;
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      _locationPermissionGranted = (permission == LocationPermission.whileInUse || 
                                   permission == LocationPermission.always);
    } catch (e) {
      _locationPermissionGranted = false;
      print('${AppLocalizations.of(context)?.translate('location_permission_check_error') ?? 'خطأ في فحص صلاحيات الموقع'}: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!_locationPermissionGranted) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      ); 

      _userLocation = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _currentPosition = CameraPosition(
          target: _userLocation!,
          zoom: 16.0, // تكبير الخريطة على الموقع
        );
      });

      // تحريك الكاميرا للموقع الجديد
      if (_controller.isCompleted) {
        final GoogleMapController controller = await _controller.future;
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(_currentPosition)
        );
      }
    } catch (e) {
      print('${AppLocalizations.of(context)?.translate('failed_to_get_current_location') ?? 'فشل في الحصول على الموقع'}: $e');
      // استخدام الموقع الافتراضي عند الفشل
      _userLocation = _defaultLocation.target;
    }
  }

  Future<void> _loadArtisansData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // جلب الحرفيين المتاحين فقط من Firebase
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('artisans')
          .where('isAvailable', isEqualTo: true)
          .get();

      final List<ArtisanModel> artisans = [];
      
      for (var doc in querySnapshot.docs) {
        try {
          final artisanData = doc.data() as Map<String, dynamic>;
          final artisan = ArtisanModel.fromJson(artisanData);
          artisans.add(artisan);
        } catch (e) {
          print('خطأ في تحويل بيانات الحرفي ${doc.id}: $e');
        }
      }

      setState(() {
        _artisans = artisans;
        _isLoading = false;
      });

      print('${AppLocalizations.of(context)?.translate('artisans_loaded') ?? 'تم تحميل'} ${artisans.length} ${AppLocalizations.of(context)?.translate('artisan') ?? 'حرفي'} ${AppLocalizations.of(context)?.translate('from_firebase') ?? 'من Firebase'}');
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '${AppLocalizations.of(context)?.translate('failed_to_load_artisans') ?? 'فشل في تحميل بيانات الحرفيين'}: $e';
      });
      print('خطأ في تحميل بيانات الحرفيين: $e');
    }
  }

  // دالة لإنشاء أيقونة مخصصة بدلاً من الدبوس (الأيقونة فقط بدون خلفية)
  Future<BitmapDescriptor> _createCustomMarkerIcon({
    required Color color,
    IconData? icon,
    double size = 50.0, // تصغير حجم الأيقونة
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // رسم الأيقونة فقط بدون خلفية
    if (icon != null) {
      final textStyle = TextStyle(
        fontSize: size * 0.8, // جعل الأيقونة أكبر
        fontFamily: icon.fontFamily,
        fontFamilyFallback: icon.fontPackage != null ? [icon.fontPackage!] : null,
        color: color, // استخدام لون الحرفة
        fontWeight: FontWeight.bold,
      );
      
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      // رسم الأيقونة في المنتصف
      textPainter.paint(
        canvas,
        Offset(
          (size - textPainter.width) / 2,
          (size - textPainter.height) / 2,
        ),
      );
    }

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  Future<void> _createMarkers() async {
    Set<Marker> markers = {};

    // إنشاء أيقونة مخصصة للموقع الحالي
    if (_userLocation != null) {
      final customIcon = await _createCustomMarkerIcon(
        color: Colors.blue,
        icon: Icons.person,
      );
      
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userLocation!,
          icon: customIcon,
          infoWindow: InfoWindow(
            title: 'موقعك الحالي',
            snippet: _locationPermissionGranted ? 'تم تحديد موقعك بدقة' : 'الموقع الافتراضي - الكويت',
          ),
        ),
      );
    }

    // إضافة علامات الحرفيين المفلترة
    final filteredArtisans = _getFilteredArtisans();
    for (int i = 0; i < filteredArtisans.length; i++) {
      final artisan = filteredArtisans[i];
      final distance = _calculateDistance(artisan);
      
      // استخدام الدبوس القياسي بلون الحرفة
      markers.add(
        Marker(
          markerId: MarkerId(artisan.id),
          position: LatLng(artisan.latitude, artisan.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerColor(artisan.craftType)),
          infoWindow: InfoWindow(
            title: artisan.name,
            snippet: '${_getCraftNameArabic(artisan.craftType)} • ${artisan.rating} ⭐ • ${distance.toStringAsFixed(1)} كم',
            onTap: () => _showArtisanBottomSheet(artisan, distance),
          ),
          onTap: () => _showArtisanBottomSheet(artisan, distance),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  List<ArtisanModel> _getFilteredArtisans() {
    List<ArtisanModel> filtered = _selectedCraftType == 'all' 
        ? _artisans 
        : _artisans.where((artisan) => artisan.craftType == _selectedCraftType).toList();
    
    // ترتيب حسب المسافة
    if (_userLocation != null) {
      filtered.sort((a, b) {
        double distanceA = _calculateDistance(a);
        double distanceB = _calculateDistance(b);
        return distanceA.compareTo(distanceB);
      });
    }
    
    return filtered;
  }

  double _calculateDistance(ArtisanModel artisan) {
    if (_userLocation == null) return 0.0;
    
    return Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      artisan.latitude,
      artisan.longitude,
    ) / 1000; // تحويل من متر إلى كيلومتر
  }

  double _getMarkerColor(String craftType) {
    switch (craftType) {
      case 'carpenter':
        return BitmapDescriptor.hueOrange;
      case 'electrician':
        return BitmapDescriptor.hueYellow;
      case 'plumber':
        return BitmapDescriptor.hueBlue;
      case 'painter':
        return BitmapDescriptor.hueGreen;
      case 'mechanic':
        return BitmapDescriptor.hueRed;
      case 'hvac':
        return BitmapDescriptor.hueCyan;
      case 'satellite':
        return BitmapDescriptor.hueMagenta;
      case 'internet':
        return BitmapDescriptor.hueAzure;
      case 'tiler':
        return BitmapDescriptor.hueRose;
      case 'locksmith':
        return BitmapDescriptor.hueViolet;
      default:
        return BitmapDescriptor.hueViolet;
    }
  }

  String _getCraftNameArabic(String craftType) {
    switch (craftType) {
      case 'carpenter':
        return 'نجار';
      case 'electrician':
        return 'كهربائي';
      case 'plumber':
        return 'سباك';
      case 'painter':
        return 'صباغ';
      case 'mechanic':
        return 'ميكانيكي';
      case 'hvac':
        return 'تكييف';
      case 'satellite':
        return 'ستالايت';
      case 'internet':
        return 'إنترنت';
      case 'tiler':
        return 'بلاط';
      case 'locksmith':
        return 'أقفال';
      default:
        return craftType;
    }
  }

  Color _getCraftColor(String craftType) {
    switch (craftType) {
      case 'carpenter':
        return const Color(0xFFFF6D00); // برتقالي غامق جميل
      case 'electrician':
        return const Color(0xFFFFC107); // أصفر ذهبي
      case 'plumber':
        return const Color(0xFF1976D2); // أزرق مميز
      case 'painter':
        return const Color(0xFF2E7D32); // أخضر غامق أنيق
      case 'mechanic':
        return const Color(0xFFD32F2F); // أحمر واضح
      case 'hvac':
        return const Color(0xFF00BCD4); // سماوي
      case 'satellite':
        return const Color(0xFF9C27B0); // بنفسجي
      case 'internet':
        return const Color(0xFF03A9F4); // أزرق فاتح
      case 'tiler':
        return const Color(0xFFE91E63); // وردي
      case 'locksmith':
        return const Color(0xFF7B1FA2); // بنفسجي مميز
      default:
        return const Color(0xFF7B1FA2); // بنفسجي مميز
    }
  }

  void _showArtisanBottomSheet(ArtisanModel artisan, double distance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // مقبض السحب
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // زر المفضلة في أعلى اليسار

                    // معلومات الحرفي الأساسية
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // صورة الحرفي
                        Container(
                          width: 80.w,
                          height: 80.w,
                          decoration: BoxDecoration(
                            color: _getCraftColor(artisan.craftType).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: _getCraftColor(artisan.craftType).withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: _buildArtisanProfileImage(artisan),
                        ),
                        SizedBox(width: AppConstants.padding),
                        
                        // تفاصيل الحرفي
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // اسم الحرفي
                              Text(
                                artisan.name,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              
                              // نوع الحرفة
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: _getCraftColor(artisan.craftType).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  _getCraftNameArabic(artisan.craftType),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: _getCraftColor(artisan.craftType),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              
                              // التقييم والخبرة
                              Row(
                                children: [
                                  // التقييم
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        size: 16.w,
                                        color: Colors.amber,
                                      ),
                                      SizedBox(width: 2.w),
                                      Text(
                                        '${artisan.rating}',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        ' (${artisan.reviewCount})',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: 12.w),
                                  
                                  // سنوات الخبرة
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.work_history_rounded,
                                        size: 14.w,
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        '${artisan.yearsOfExperience} سنوات',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        Builder(
                          builder: (context) {
                            final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
                            final favoriteProvider = Provider.of<FavoriteProvider>(context, listen: false);
                            final currentUser = authProvider.currentUser;

                            // تهيئة المفضلة للمستخدم إذا كان مسجل
                            if (currentUser != null) {
                              favoriteProvider.initForUser(currentUser.id);
                            }

                            // التحقق من أن المستخدم الحالي ليس صاحب الحساب
                            final bool isOwner = currentUser != null &&
                                currentUser.artisanId != null &&
                                currentUser.artisanId == artisan.id;

                            if (isOwner || !authProvider.isLoggedIn) {
                              return SizedBox.shrink();
                            }

                            return Align(
                              alignment: Alignment.topLeft,
                              child: Consumer<FavoriteProvider>(
                                builder: (context, favProvider, _) {
                                  final isFav = favProvider.isFavorite(artisan.id);
                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () async {
                                        try {
                                          final nowFav = await favProvider.toggleFavorite(artisan.id);
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                nowFav
                                                    ? 'تمت إضافة الحرفي إلى المفضلة'
                                                    : 'تمت إزالة الحرفي من المفضلة',
                                              ),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        } catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('${AppLocalizations.of(context)?.translate('favorite_updated_failed') ?? 'فشل في تحديث المفضلة'}: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(20.r),
                                      child: Container(
                                        width: 40.w,
                                        height: 40.w,
                                        decoration: BoxDecoration(
                                          color: isFav
                                              ? Colors.red.withValues(alpha: 0.1)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(20.r),
                                          border: Border.all(
                                            color: isFav ? Colors.red : Colors.grey.withValues(alpha: 0.3),
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                          color: isFav ? Colors.red : Colors.grey,
                                          size: 24.w,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    
                    SizedBox(height: AppConstants.padding),
                    
                    // وصف الحرفي
                    Text(
                      AppLocalizations.of(context)?.translate('description_label') ?? 'الوصف',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      artisan.description,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: AppConstants.padding),
                    
                    // الموقع والمسافة
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 16.w,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            artisan.address,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(
                          Icons.directions_car_rounded,
                          size: 16.w,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${distance.toStringAsFixed(1)} كم من موقعك',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // أزرار التواصل
                    Builder(
                      builder: (context) {
                        final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
                        final favoriteProvider = Provider.of<FavoriteProvider>(context, listen: false);
                        final currentUser = authProvider.currentUser;
                        
                        // تهيئة المفضلة للمستخدم إذا كان مسجل
                        if (currentUser != null) {
                          favoriteProvider.initForUser(currentUser.id);
                        }
                        
                        // التحقق من أن المستخدم الحالي ليس صاحب الحساب
                        final bool isOwner = currentUser != null && 
                                            currentUser.artisanId != null && 
                                            currentUser.artisanId == artisan.id;
                        
                        return Column(
                          children: [
                            // صف الأزرار: رسالة والملف
                            Row(
                              children: [
                                // زر الرسالة - يظهر فقط إذا لم يكن المستخدم صاحب الحساب
                                if (!isOwner) ...[
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _sendMessage(artisan);
                                      },
                                      icon: Icon(Icons.chat_rounded, size: 18.w),
                                      label: Text(
                                        'رسالة',
                                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _getCraftColor(artisan.craftType).withValues(alpha: 0.8),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                        padding: EdgeInsets.symmetric(vertical: 12.h),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: AppConstants.smallPadding),
                                ],
                                // زر الملف - يظهر دائماً
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      context.push('/artisan-profile/${artisan.id}');
                                    },
                                    icon: Icon(Icons.person_rounded, size: 18.w),
                                    label: Text(
                                      'الملف',
                                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                      padding: EdgeInsets.symmetric(vertical: 12.h),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // زر الاتصال - يظهر فقط إذا لم يكن المستخدم صاحب الحساب - يأخذ العرض الكامل
                            if (!isOwner) ...[
                              SizedBox(height: AppConstants.smallPadding),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _makePhoneCall(artisan);
                                  },
                                  icon: Icon(Icons.phone_rounded, size: 18.w),
                                  label: Text(
                                    'اتصال',
                                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _getCraftColor(artisan.craftType),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                    padding: EdgeInsets.symmetric(vertical: 12.h),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtisanProfileImage(ArtisanModel artisan) {
    final imageUrl = artisan.profileImageUrl;
    
    // التحقق من وجود الصورة
    if (imageUrl == null || imageUrl.isEmpty || imageUrl.trim().isEmpty) {
      return Container(
        width: 80.w,
        height: 80.w,
        color: Colors.grey[200],
        child: Icon(
          Icons.person_rounded,
          size: 40.w,
          color: _getCraftColor(artisan.craftType),
        ),
      );
    }
    
    final trimmedUrl = imageUrl.trim();
    
    // التحقق إذا كانت الصورة base64
    if (trimmedUrl.startsWith('data:image') || 
        (trimmedUrl.length > 100 && !trimmedUrl.startsWith('http'))) {
      try {
        String base64String = trimmedUrl;
        if (base64String.contains(',')) {
          base64String = base64String.split(',')[1];
        }
        final imageBytes = base64Decode(base64String);
        return ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: Image.memory(
            imageBytes,
            width: 80.w,
            height: 80.w,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 80.w,
              height: 80.w,
              color: Colors.grey[200],
              child: Icon(
                Icons.person_rounded,
                size: 40.w,
                color: _getCraftColor(artisan.craftType),
              ),
            ),
          ),
        );
      } catch (e) {
        // إذا فشل فك التشفير، نعرض أيقونة افتراضية
        return Container(
          width: 80.w,
          height: 80.w,
          color: Colors.grey[200],
          child: Icon(
            Icons.person_rounded,
            size: 40.w,
            color: _getCraftColor(artisan.craftType),
          ),
        );
      }
    }
    
    // إذا كانت URL عادية
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: CachedNetworkImage(
        imageUrl: trimmedUrl,
        width: 80.w,
        height: 80.w,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 80.w,
          height: 80.w,
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getCraftColor(artisan.craftType),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 80.w,
          height: 80.w,
          color: Colors.grey[200],
          child: Icon(
            Icons.person_rounded,
            size: 40.w,
            color: _getCraftColor(artisan.craftType),
          ),
        ),
      ),
    );
  }

  IconData _getCraftIcon(String craftType) {
    switch (craftType) {
      case 'carpenter':
        return Icons.handyman; // نجار
      case 'electrician':
        return Icons.electrical_services; // كهربائي
      case 'plumber':
        return Icons.plumbing; // سباك
      case 'painter':
        return Icons.brush; // صباغ
      case 'mechanic':
        return Icons.build_circle; // ميكانيكي
      case 'hvac':
        return Icons.ac_unit; // تكييف
      case 'satellite':
        return Icons.satellite; // ستالايت
      case 'internet':
        return Icons.wifi; // إنترنت
      case 'tiler':
        return Icons.square_foot; // بلاط
      case 'locksmith':
        return Icons.lock; // أقفال
      default:
        return Icons.construction; // افتراضي
    }
  }

  Future<void> _makePhoneCall(ArtisanModel artisan) async {
    if (artisan.phone.isEmpty) {
      if (!mounted) return;
      try {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.translate('phone_not_available') ?? 'رقم الهاتف غير متوفر'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
        );
      } catch (e) {
        if (kDebugMode) {
          print('Could not show snackbar: $e');
        }
      }
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: artisan.phone);
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (!mounted) return;
        try {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.translate('cannot_open_call_app') ?? 'لا يمكن فتح تطبيق الاتصال'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            print('Could not show snackbar: $e');
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      try {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.translate('call_failed') ?? 'فشل في الاتصال'}: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
        );
      } catch (err) {
        if (kDebugMode) {
          print('Could not show snackbar: $err');
        }
      }
    }
  }

  Future<void> _sendMessage(ArtisanModel artisan) async {
    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // التحقق من تسجيل الدخول
    if (!authProvider.isLoggedIn) {
      if (!mounted) return;
      try {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.translate('login_required_to_message') ?? 'يجب تسجيل الدخول لإرسال رسالة'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            action: SnackBarAction(
              label: 'تسجيل الدخول',
              textColor: Colors.white,
              onPressed: () {
                context.push('/login');
              },
            ),
          ),
        );
      } catch (e) {
        if (kDebugMode) {
          print('Could not show snackbar: $e');
        }
      }
      return;
    }

    try {
      // إنشاء غرفة دردشة مع الحرفي
      final room = await chatProvider.createChatRoomAndReturn(artisan.id);

      if (room != null) {
        // فتح غرفة الدردشة
        await chatProvider.openChatRoom(room.id);

        if (mounted) {
          context.push('/chat-room');
        }
      } else {
        if (!mounted) return;
        try {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.translate('chat_creation_failed_error') ?? 'فشل في إنشاء المحادثة'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            print('Could not show snackbar: $e');
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      try {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.translate('failed_to_open_chat') ?? 'فشل في فتح المحادثة'}: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
        );
      } catch (err) {
        if (kDebugMode) {
          print('Could not show snackbar: $err');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'خريطة الحرفيين',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await _getCurrentLocation();
              await _createMarkers();
            },
            icon: Icon(
              Icons.my_location_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'تحديد موقعي',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _initializeMap();
            },
            icon: Icon(
              Icons.refresh_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'تحديث الخريطة',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingView();
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    return Stack(
      children: [
        // الخريطة
        GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: _currentPosition,
          markers: _markers,
          onMapCreated: (GoogleMapController controller) {
            if (!_controller.isCompleted) {
              _controller.complete(controller);
            }
          },
          myLocationEnabled: false, // نستخدم marker مخصص بدلاً من ذلك
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
          rotateGesturesEnabled: true,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          tiltGesturesEnabled: true,
          padding: EdgeInsets.only(
            top: 80.h, // مساحة للفلاتر
            bottom: 120.h, // مساحة للمعلومات
          ),
        ),
        
        // فلاتر أنواع الحرف
        _buildFilterChips(),
        
        // معلومات الخريطة
       // _buildMapInfo(),
        
        // أسطورة الألوان
       // _buildLegend(),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: AppConstants.padding),
          Text(
            'جارٍ تحميل الخريطة...',
            style: TextStyle(
              fontSize: 16.sp,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: AppConstants.smallPadding),
          Text(
            'يتم تحديد موقعك وتحميل بيانات الحرفيين',
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64.w,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            SizedBox(height: AppConstants.padding),
            Text(
              'خطأ في تحميل الخريطة',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: AppConstants.smallPadding),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.padding),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initializeMap();
              },
              icon: Icon(Icons.refresh_rounded, size: 20.w),
              label: Text(AppLocalizations.of(context)?.translate('retry') ?? 'إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Positioned(
      bottom: 16.h,
      left: 16.w,
      right: 16.w,
      child: Container(
        height: 50.h,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _craftTypes.length,
          itemBuilder: (context, index) {
            final craftType = _craftTypes[index];
            final isSelected = _selectedCraftType == craftType;
            final count = craftType == 'all' 
                ? _artisans.length 
                : _artisans.where((a) => a.craftType == craftType).length;
            
            // الحصول على لون الحرفة
            final craftColor = craftType == 'all' 
                ? Theme.of(context).colorScheme.primary 
                : _getCraftColor(craftType);
            
            return Container(
              margin: EdgeInsets.only(right: 8.w),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      craftType == 'all' ? 'الكل' : _getCraftNameArabic(craftType),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isSelected ? Colors.white : craftColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: (isSelected ? Colors.white : craftColor).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isSelected ? Colors.white : craftColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) async {
                  setState(() {
                    _selectedCraftType = craftType;
                  });
                  await _createMarkers();
                },
                backgroundColor: isSelected ? craftColor : craftColor.withValues(alpha: 0.1),
                selectedColor: craftColor,
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? craftColor : craftColor.withValues(alpha: 0.5),
                  width: 2,
                ),
                elevation: isSelected ? 4 : 2,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMapInfo() {
    final filteredCount = _getFilteredArtisans().length;
    
    return Positioned(
      bottom: 16.h,
      left: 16.w,
      right: 16.w,
      child: Container(
        padding: EdgeInsets.all(AppConstants.padding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 20.w,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'يظهر $filteredCount حرفي في المنطقة',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (_locationPermissionGranted) ...[
              Icon(
                Icons.gps_fixed_rounded,
                color: Colors.green,
                size: 16.w,
              ),
              SizedBox(width: 4.w),
              Text(
                'موقع دقيق',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              Icon(
                Icons.gps_off_rounded,
                color: Colors.orange,
                size: 16.w,
              ),
              SizedBox(width: 4.w),
              Text(
                'موقع تقريبي',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Positioned(
      top: 80.h,
      left: 16.w,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  color: Colors.blue,
                  size: 12.w,
                ),
                SizedBox(width: 6.w),
                Text(
                  'موقعك',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            ..._craftTypes.where((type) => type != 'all').map((type) {
              return Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      color: _getCraftColor(type),
                      size: 12.w,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      _getCraftNameArabic(type),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
} 