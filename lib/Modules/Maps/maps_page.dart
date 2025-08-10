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
import 'widgets/distance_filter_widget.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  static const CameraPosition _kDefaultLocation = CameraPosition(
    target: LatLng(24.7136, 46.6753), // الرياض
    zoom: 12.0,
  );

  CameraPosition _currentPosition = _kDefaultLocation;
  Set<Marker> _markers = {};
  List<ArtisanModel> _artisans = [];
  bool _isLoading = true;
  String _selectedCraftType = 'all';
  double _maxDistance = 20.0; // المسافة القصوى بالكيلومتر


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
    await _getCurrentLocation();
    await _loadArtisans();
    _createMarkers();
    setState(() {
      _isLoading = false;
    });
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

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 14.0,
        );
      });

      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(_currentPosition));
    } catch (e) {
      // التعامل مع الأخطاء صامتاً واستخدام الموقع الافتراضي
    }
  }

  Future<void> _loadArtisans() async {
    // محاكاة تحميل بيانات الحرفيين من Firebase
    await Future.delayed(const Duration(milliseconds: 500));
    
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
          description: 'نجار محترف',
          latitude: 24.7136,
          longitude: 46.6753,
          address: 'الرياض، المملكة العربية السعودية',
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
          description: 'كهربائي محترف',
          latitude: 24.7200,
          longitude: 46.6800,
          address: 'الرياض، المملكة العربية السعودية',
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
          description: 'سباك ماهر',
          latitude: 24.7100,
          longitude: 46.6700,
          address: 'الرياض، المملكة العربية السعودية',
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
          description: 'صباغ محترف',
          latitude: 24.7080,
          longitude: 46.6850,
          address: 'الرياض، المملكة العربية السعودية',
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
          description: 'ميكانيكي سيارات',
          latitude: 24.7250,
          longitude: 46.6600,
          address: 'الرياض، المملكة العربية السعودية',
          rating: 4.9,
          reviewCount: 298,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ArtisanModel(
          id: '6',
          name: 'فيصل المطيري',
          email: 'faisal@example.com',
          phone: '+966557890123',
          profileImageUrl: '',
          craftType: 'carpenter',
          yearsOfExperience: 7,
          description: 'نجار أثاث',
          latitude: 24.7000,
          longitude: 46.6950,
          address: 'الرياض، المملكة العربية السعودية',
          rating: 4.5,
          reviewCount: 67,
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
          title: AppLocalizations.of(context)?.translate('current_location') ?? 'موقعك الحالي',
        ),
      ),
    );

    // إضافة علامات الحرفيين
    for (ArtisanModel artisan in _getFilteredArtisans()) {
      markers.add(
        Marker(
          markerId: MarkerId(artisan.id),
          position: LatLng(artisan.latitude, artisan.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerColor(artisan.craftType)),
          infoWindow: InfoWindow(
            title: artisan.name,
            snippet: '${AppLocalizations.of(context)?.translate(artisan.craftType)} • ${artisan.rating} ⭐',
            onTap: () => _selectArtisan(artisan),
          ),
          onTap: () => _selectArtisan(artisan),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  List<ArtisanModel> _getFilteredArtisans() {
    List<ArtisanModel> filtered = _artisans;
    
    // فلترة حسب نوع الحرفة
    if (_selectedCraftType != 'all') {
      filtered = filtered.where((artisan) => artisan.craftType == _selectedCraftType).toList();
    }
    
    // فلترة حسب المسافة
    filtered = filtered.where((artisan) {
      double distance = _calculateDistance(
        _currentPosition.target.latitude,
        _currentPosition.target.longitude,
        artisan.latitude,
        artisan.longitude,
      );
      return distance <= _maxDistance;
    }).toList();
    
    // ترتيب حسب المسافة
    filtered.sort((a, b) {
      double distanceA = _calculateDistance(
        _currentPosition.target.latitude,
        _currentPosition.target.longitude,
        a.latitude,
        a.longitude,
      );
      double distanceB = _calculateDistance(
        _currentPosition.target.latitude,
        _currentPosition.target.longitude,
        b.latitude,
        b.longitude,
      );
      return distanceA.compareTo(distanceB);
    });
    
    return filtered;
  }

  // حساب المسافة بين نقطتين (صيغة Haversine)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // نصف قطر الأرض بالكيلومتر
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (pi / 180);
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

  void _selectArtisan(ArtisanModel artisan) {
    _showArtisanBottomSheet(artisan);
  }

  void _showDistanceFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DistanceFilterWidget(
        currentDistance: _maxDistance,
        onDistanceChanged: (newDistance) {
          setState(() {
            _maxDistance = newDistance;
          });
          _createMarkers();
        },
      ),
    );
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
                                AppLocalizations.of(context)?.translate(artisan.craftType) ?? artisan.craftType,
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
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(
                          Icons.directions_car_rounded,
                          size: 16.w,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${_calculateDistance(
                            _currentPosition.target.latitude,
                            _currentPosition.target.longitude,
                            artisan.latitude,
                            artisan.longitude,
                          ).toStringAsFixed(1)} كم من موقعك',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context).colorScheme.outline,
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
                              AppLocalizations.of(context)?.translate('message') ?? '',
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
                              AppLocalizations.of(context)?.translate('view_profile') ?? '',
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
          AppLocalizations.of(context)?.translate('maps') ?? '',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showDistanceFilter,
            icon: Icon(
              Icons.tune_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          IconButton(
            onPressed: _getCurrentLocation,
            icon: Icon(
              Icons.my_location_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: _currentPosition,
                  markers: _markers,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
                _buildFilterChips(),
                _buildArtisanCounter(),
                _buildLegend(),
              ],
            ),
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
                  craftType == 'all' 
                      ? AppLocalizations.of(context)?.translate('all_crafts') ?? 'الكل'
                      : AppLocalizations.of(context)?.translate(craftType) ?? craftType,
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

  Widget _buildLegend() {
    return Positioned(
      bottom: 16.h,
      right: 16.w,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'دليل الألوان',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            _buildLegendItem('موقعك', BitmapDescriptor.hueBlue),
            _buildLegendItem('نجار', BitmapDescriptor.hueOrange),
            _buildLegendItem('كهربائي', BitmapDescriptor.hueYellow),
            _buildLegendItem('سباك', BitmapDescriptor.hueBlue),
            _buildLegendItem('صباغ', BitmapDescriptor.hueGreen),
            _buildLegendItem('ميكانيكي', BitmapDescriptor.hueRed),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, double hue) {
    Color color;
    switch (hue) {
      case BitmapDescriptor.hueBlue:
        color = Colors.blue;
        break;
      case BitmapDescriptor.hueOrange:
        color = Colors.orange;
        break;
      case BitmapDescriptor.hueYellow:
        color = Colors.yellow[700]!;
        break;
      case BitmapDescriptor.hueGreen:
        color = Colors.green;
        break;
      case BitmapDescriptor.hueRed:
        color = Colors.red;
        break;
      default:
        color = Colors.purple;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
} 