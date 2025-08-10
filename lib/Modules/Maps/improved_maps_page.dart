import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';
import '../../models/artisan_model.dart';

class ImprovedMapsPage extends StatefulWidget {
  const ImprovedMapsPage({super.key});

  @override
  State<ImprovedMapsPage> createState() => _ImprovedMapsPageState();
}

class _ImprovedMapsPageState extends State<ImprovedMapsPage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  
  // الموقع الافتراضي (الرياض)
  static const CameraPosition _kDefaultLocation = CameraPosition(
    target: LatLng(24.7136, 46.6753),
    zoom: 12.0,
  );

  CameraPosition _currentPosition = _kDefaultLocation;
  Set<Marker> _markers = {};
  List<ArtisanModel> _artisans = [];
  bool _isLoading = true;
  bool _locationPermissionGranted = false;
  String? _errorMessage;
  String _selectedCraftType = 'all';

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
      // تحقق من صلاحيات الموقع أولاً
      await _checkLocationPermission();
      
      // تحميل البيانات التجريبية
      await _loadSampleData();
      
      // محاولة الحصول على الموقع الحالي
      if (_locationPermissionGranted) {
        await _getCurrentLocation();
      }
      
      // إنشاء العلامات
      _createMarkers();
      
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'خطأ في تحميل الخريطة: ${e.toString()}';
      });
      
      // حتى لو حدث خطأ، نعرض البيانات التجريبية
      await _loadSampleData();
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
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!_locationPermissionGranted) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 14.0,
        );
      });

      // تحريك الكاميرا للموقع الجديد
      if (_controller.isCompleted) {
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newCameraPosition(_currentPosition));
      }
    } catch (e) {
      // استخدام الموقع الافتراضي عند الفشل
      print('فشل في الحصول على الموقع: $e');
    }
  }

  Future<void> _loadSampleData() async {
    // محاكاة تأخير تحميل البيانات
    await Future.delayed(const Duration(milliseconds: 800));
    
    setState(() {
      _artisans = [
        ArtisanModel(
          id: '1',
          name: 'محمد أحمد',
          email: 'mohamed@example.com',
          phone: '+966501234567',
          profileImageUrl: '',
          craftType: 'carpenter',
          yearsOfExperience: 8,
          description: 'نجار محترف متخصص في الأثاث المنزلي والمكتبي',
          latitude: 29.875587,
          longitude: 31.290857,
          address: 'حي الملز، الرياض',
          rating: 4.8,
          reviewCount: 156,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ArtisanModel(
          id: '2',
          name: 'سعد محمد',
          email: 'saad@example.com',
          phone: '+966509876543',
          profileImageUrl: '',
          craftType: 'electrician',
          yearsOfExperience: 12,
          description: 'كهربائي محترف - تمديدات وصيانة كهربائية',
          latitude: 29.878743,
          longitude: 31.289677,
          address: 'حي العليا، الرياض',
          rating: 4.9,
          reviewCount: 203,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ArtisanModel(
          id: '3',
          name: 'عبدالله سالم',
          email: 'abdullah@example.com',
          phone: '+966555123456',
          profileImageUrl: '',
          craftType: 'plumber',
          yearsOfExperience: 6,
          description: 'سباك ماهر - تسليك وتمديدات صحية',
          latitude: 24.7100,
          longitude: 46.6700,
          address: 'حي السليمانية، الرياض',
          rating: 4.6,
          reviewCount: 89,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ArtisanModel(
          id: '4',
          name: 'خالد العتيبي',
          email: 'khalid@example.com',
          phone: '+966556789012',
          profileImageUrl: '',
          craftType: 'painter',
          yearsOfExperience: 10,
          description: 'صباغ محترف - دهانات داخلية وخارجية',
          latitude: 24.7080,
          longitude: 46.6850,
          address: 'حي الربوة، الرياض',
          rating: 4.7,
          reviewCount: 134,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ArtisanModel(
          id: '5',
          name: 'أحمد القحطاني',
          email: 'ahmed@example.com',
          phone: '+966554321098',
          profileImageUrl: '',
          craftType: 'mechanic',
          yearsOfExperience: 15,
          description: 'ميكانيكي سيارات متخصص في جميع الأنواع',
          latitude: 24.7250,
          longitude: 46.6600,
          address: 'حي الشفا، الرياض',
          rating: 4.9,
          reviewCount: 298,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    });
  }

  void _createMarkers() {
    Set<Marker> markers = {};

    // إضافة علامة الموقع الحالي
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: _currentPosition.target,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: 'موقعك الحالي',
          snippet: _locationPermissionGranted ? 'تم تحديد موقعك' : 'الموقع الافتراضي',
        ),
      ),
    );

    // إضافة علامات الحرفيين المفلترة
    final filteredArtisans = _getFilteredArtisans();
    for (ArtisanModel artisan in filteredArtisans) {
      markers.add(
        Marker(
          markerId: MarkerId(artisan.id),
          position: LatLng(artisan.latitude, artisan.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerColor(artisan.craftType)),
          infoWindow: InfoWindow(
            title: artisan.name,
            snippet: '${_getCraftNameArabic(artisan.craftType)} • ${artisan.rating} ⭐',
            onTap: () => _showArtisanBottomSheet(artisan),
          ),
          onTap: () => _showArtisanBottomSheet(artisan),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  List<ArtisanModel> _getFilteredArtisans() {
    if (_selectedCraftType == 'all') {
      return _artisans;
    }
    return _artisans.where((artisan) => artisan.craftType == _selectedCraftType).toList();
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

  void _showArtisanBottomSheet(ArtisanModel artisan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            // مقبض السحب
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.symmetric(vertical: 8.h),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80.w,
                          height: 80.w,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            size: 40.w,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        SizedBox(width: AppConstants.padding),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                artisan.name,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                _getCraftNameArabic(artisan.craftType),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 16.w,
                                    color: Colors.amber,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    '${artisan.rating}',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    '(${artisan.reviewCount})',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppConstants.padding),
                    Text(
                      artisan.description,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppConstants.padding),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 16.w,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            artisan.address,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // TODO: فتح الدردشة
                            },
                            icon: Icon(Icons.chat_rounded, size: 18.w),
                            label: Text(
                              'رسالة',
                              style: TextStyle(fontSize: 14.sp),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.primary,
                              side: BorderSide(color: Theme.of(context).colorScheme.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
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
                              'الملف الشخصي',
                              style: TextStyle(fontSize: 14.sp),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'الخرائط',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _getCurrentLocation,
            icon: Icon(
              Icons.my_location_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'موقعي الحالي',
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
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
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
            if (!_locationPermissionGranted) ...[
              SizedBox(height: AppConstants.smallPadding),
              Text(
                'سيتم استخدام الموقع الافتراضي',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
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
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: _currentPosition,
          markers: _markers,
          onMapCreated: (GoogleMapController controller) {
            if (!_controller.isCompleted) {
              _controller.complete(controller);
            }
          },
          myLocationEnabled: _locationPermissionGranted,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
          rotateGesturesEnabled: true,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          tiltGesturesEnabled: true,
        ),
        _buildFilterChips(),
        _buildArtisanCounter(),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Positioned(
      top: 16.h,
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
            return Container(
              margin: EdgeInsets.only(right: 8.w),
              child: FilterChip(
                label: Text(
                  craftType == 'all' ? 'الكل' : _getCraftNameArabic(craftType),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCraftType = craftType;
                  });
                  _createMarkers();
                },
                backgroundColor: Colors.white,
                selectedColor: Theme.of(context).colorScheme.primary,
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildArtisanCounter() {
    final filteredCount = _getFilteredArtisans().length;
    
    return Positioned(
      top: 80.h,
      left: 16.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_rounded,
              size: 16.w,
              color: Colors.white,
            ),
            SizedBox(width: 6.w),
            Text(
              '$filteredCount حرفي',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 