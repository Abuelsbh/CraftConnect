import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';
import '../../Models/artisan_model.dart';

class CompleteMapsPage extends StatefulWidget {
  const CompleteMapsPage({super.key});

  @override
  State<CompleteMapsPage> createState() => _CompleteMapsPageState();
}

class _CompleteMapsPageState extends State<CompleteMapsPage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  
  // موقع الرياض الافتراضي
  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(24.7136, 46.6753),
    zoom: 12.0,
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
      _createMarkers();
      
      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'خطأ في تحميل الخريطة: ${e.toString()}';
      });
      
      // حتى لو حدث خطأ، نعرض البيانات مع الموقع الافتراضي
      _userLocation = _defaultLocation.target;
      await _loadArtisansData();
      _createMarkers();
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
      print('خطأ في فحص صلاحيات الموقع: $e');
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
          zoom: 14.0,
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
      print('فشل في الحصول على الموقع: $e');
      // استخدام الموقع الافتراضي عند الفشل
      _userLocation = _defaultLocation.target;
    }
  }

  Future<void> _loadArtisansData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // جلب جميع الحرفيين من Firebase
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('artisans')
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

      print('تم تحميل ${artisans.length} حرفي من Firebase');
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'فشل في تحميل بيانات الحرفيين: $e';
      });
      print('خطأ في تحميل بيانات الحرفيين: $e');
    }
  }

  void _createMarkers() {
    Set<Marker> markers = {};

    // إضافة علامة الموقع الحالي للمستخدم
    if (_userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'موقعك الحالي',
            snippet: _locationPermissionGranted ? 'تم تحديد موقعك بدقة' : 'الموقع الافتراضي - الرياض',
          ),
        ),
      );
    }

    // إضافة علامات الحرفيين المفلترة
    final filteredArtisans = _getFilteredArtisans();
    for (int i = 0; i < filteredArtisans.length; i++) {
      final artisan = filteredArtisans[i];
      final distance = _calculateDistance(artisan);
      
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
                          child: Icon(
                            _getCraftIcon(artisan.craftType),
                            size: 40.w,
                            color: _getCraftColor(artisan.craftType),
                          ),
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
                      ],
                    ),
                    
                    SizedBox(height: AppConstants.padding),
                    
                    // وصف الحرفي
                    Text(
                      'الوصف',
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
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _makePhoneCall(artisan);
                            },
                            icon: Icon(Icons.phone_rounded, size: 18.w),
                            label: Text(
                              'اتصال',
                              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _getCraftColor(artisan.craftType),
                              side: BorderSide(color: _getCraftColor(artisan.craftType), width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                          ),
                        ),
                        SizedBox(width: AppConstants.smallPadding),
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
                              backgroundColor: _getCraftColor(artisan.craftType),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                          ),
                        ),
                        SizedBox(width: AppConstants.smallPadding),
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
                  ],
                ),
              ),
            ),
          ],
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
      default:
        return Icons.construction; // افتراضي
    }
  }

  void _makePhoneCall(ArtisanModel artisan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('اتصال بـ ${artisan.name} - ${artisan.phone}'),
        backgroundColor: _getCraftColor(artisan.craftType),
        action: SnackBarAction(
          label: 'إغلاق',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _sendMessage(ArtisanModel artisan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('فتح محادثة مع ${artisan.name}'),
        backgroundColor: _getCraftColor(artisan.craftType),
        action: SnackBarAction(
          label: 'إغلاق',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
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
              _createMarkers();
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
              label: Text('إعادة المحاولة'),
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
                onSelected: (selected) {
                  setState(() {
                    _selectedCraftType = craftType;
                  });
                  _createMarkers();
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