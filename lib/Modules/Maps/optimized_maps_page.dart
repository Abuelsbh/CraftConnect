import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../Utilities/app_constants.dart';
import '../../Utilities/performance_helper.dart';
import '../../core/Language/locales.dart';
import '../../Models/artisan_model.dart';

class OptimizedMapsPage extends StatefulWidget {
  const OptimizedMapsPage({super.key});

  @override
  State<OptimizedMapsPage> createState() => _OptimizedMapsPageState();
}

class _OptimizedMapsPageState extends State<OptimizedMapsPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  
  @override
  bool get wantKeepAlive => true; // الحفاظ على الحالة لتحسين الأداء

  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  
  // موقع الرياض الافتراضي
  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(24.7136, 46.6753),
    zoom: 13.0,
  );

  CameraPosition _currentPosition = _defaultLocation;
  Set<Marker> _markers = {};
  List<ArtisanModel> _artisans = [];
  bool _isLoading = false;
  bool _locationPermissionGranted = false;
  String? _errorMessage;
  String _selectedCraftType = 'all';
  LatLng? _userLocation;

  // متحكمات الرسوم المتحركة
  late AnimationController _fabAnimationController;
  late AnimationController _filterAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<Offset> _filterAnimation;

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
    _initializeAnimations();
    PerformanceHelper.deferredExecution(() async {
      await _initializeMap();
    });
  }

  void _initializeAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    _filterAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeOutBack,
    ));
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
        _userLocation = _defaultLocation.target;
      }
      
      // إنشاء العلامات على الخريطة
      await _createMarkers();
      
      setState(() {
        _isLoading = false;
      });

      // تشغيل الرسوم المتحركة
      _fabAnimationController.forward();
      _filterAnimationController.forward();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'خطأ في تحميل الخريطة: ${e.toString()}';
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
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!_locationPermissionGranted) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _userLocation = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _currentPosition = CameraPosition(
          target: _userLocation!,
          zoom: 15.0,
        );
      });

      // تحريك الكاميرا للموقع الجديد بسلاسة
      if (_controller.isCompleted) {
        final GoogleMapController controller = await _controller.future;
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(_currentPosition)
        );
      }
    } catch (e) {
      _userLocation = _defaultLocation.target;
    }
  }

  Future<void> _loadArtisansData() async {
    // تحميل البيانات في الخلفية
    await PerformanceHelper.deferredExecution(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _artisans = [
          ArtisanModel(
            id: '1',
            name: 'محمد أحمد النجار',
            email: 'mohamed@example.com',
            phone: '+966501234567',
            profileImageUrl: '',
            craftType: 'carpenter',
            yearsOfExperience: 8,
            description: 'نجار محترف متخصص في صناعة الأثاث المنزلي والمكتبي',
            latitude: 24.7156,
            longitude: 46.6773,
            address: 'حي الملز، شارع الأمير فيصل، الرياض',
            rating: 4.8,
            reviewCount: 156,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ArtisanModel(
            id: '2',
            name: 'سعد محمد الكهربائي',
            email: 'saad@example.com',
            phone: '+966509876543',
            profileImageUrl: '',
            craftType: 'electrician',
            yearsOfExperience: 12,
            description: 'كهربائي محترف - تمديدات كهربائية وصيانة',
            latitude: 29.878743,
            longitude: 31.289677,
            address: 'حي العليا، طريق الملك عبدالعزيز، الرياض',
            rating: 4.9,
            reviewCount: 203,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ArtisanModel(
            id: '3',
            name: 'عبدالله سالم السباك',
            email: 'abdullah@example.com',
            phone: '+966555123456',
            profileImageUrl: '',
            craftType: 'plumber',
            yearsOfExperience: 6,
            description: 'سباك ماهر متخصص في تسليك المجاري وتمديدات المياه',
            latitude: 24.7100,
            longitude: 46.6700,
            address: 'حي السليمانية، شارع التخصصي، الرياض',
            rating: 4.6,
            reviewCount: 89,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ArtisanModel(
            id: '4',
            name: 'خالد العتيبي الصباغ',
            email: 'khalid@example.com',
            phone: '+966556789012',
            profileImageUrl: '',
            craftType: 'painter',
            yearsOfExperience: 10,
            description: 'صباغ محترف متخصص في الدهانات الداخلية والخارجية',
            latitude: 24.7080,
            longitude: 46.6850,
            address: 'حي الربوة، شارع العروبة، الرياض',
            rating: 4.7,
            reviewCount: 134,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ArtisanModel(
            id: '5',
            name: 'أحمد القحطاني الميكانيكي',
            email: 'ahmed@example.com',
            phone: '+966554321098',
            profileImageUrl: '',
            craftType: 'mechanic',
            yearsOfExperience: 15,
            description: 'ميكانيكي سيارات متخصص في جميع أنواع السيارات',
            latitude: 24.7250,
            longitude: 46.6600,
            address: 'حي الشفا، شارع الأمير سلمان، الرياض',
            rating: 4.9,
            reviewCount: 298,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
      });
    });
  }

  Future<void> _createMarkers() async {
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
            snippet: _locationPermissionGranted ? 'تم تحديد موقعك بدقة' : 'الموقع الافتراضي',
          ),
        ),
      );
    }

    // إضافة علامات الحرفيين المفلترة
    final filteredArtisans = _getFilteredArtisans();
    for (final artisan in filteredArtisans) {
      final distance = _calculateDistance(artisan);
      
      markers.add(
        Marker(
          markerId: MarkerId(artisan.id),
          position: LatLng(artisan.latitude, artisan.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerColor(artisan.craftType)),
          infoWindow: InfoWindow(
            title: artisan.name,
            snippet: '${_getCraftNameArabic(artisan.craftType)} • ${artisan.rating} ⭐',
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
    ) / 1000;
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
        return const Color(0xFFFF6D00);
      case 'electrician':
        return const Color(0xFFFFC107);
      case 'plumber':
        return const Color(0xFF1976D2);
      case 'painter':
        return const Color(0xFF2E7D32);
      case 'mechanic':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF7B1FA2);
    }
  }

  void _showArtisanBottomSheet(ArtisanModel artisan, double distance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildArtisanBottomSheet(artisan, distance),
    );
  }

  Widget _buildArtisanBottomSheet(ArtisanModel artisan, double distance) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // مقبض السحب المحسن
          Container(
            width: 50.w,
            height: 5.h,
            margin: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3.r),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              physics: PerformanceHelper.optimizedScrollPhysics,
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // معلومات الحرفي مع رسوم متحركة
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: Opacity(
                          opacity: value,
                          child: _buildArtisanHeader(artisan, distance),
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // وصف الحرفي
                  _buildAnimatedSection(
                    delay: 200,
                    child: _buildDescription(artisan),
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  // معلومات الموقع
                  _buildAnimatedSection(
                    delay: 400,
                    child: _buildLocationInfo(artisan, distance),
                  ),
                  
                  SizedBox(height: 30.h),
                  
                  // أزرار التواصل
                  _buildAnimatedSection(
                    delay: 600,
                    child: _buildActionButtons(artisan),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSection({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildArtisanHeader(ArtisanModel artisan, double distance) {
    return Row(
      children: [
        // صورة الحرفي المحسنة
        Hero(
          tag: 'artisan_${artisan.id}',
          child: Container(
            width: 90.w,
            height: 90.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getCraftColor(artisan.craftType).withValues(alpha: 0.8),
                  _getCraftColor(artisan.craftType),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: _getCraftColor(artisan.craftType).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              _getCraftIcon(artisan.craftType),
              size: 45.w,
              color: Colors.white,
            ),
          ),
        ),
        
        SizedBox(width: 16.w),
        
        // تفاصيل الحرفي
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                artisan.name,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 6.h),
              
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: _getCraftColor(artisan.craftType).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: _getCraftColor(artisan.craftType).withValues(alpha: 0.3),
                  ),
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
              
              SizedBox(height: 10.h),
              
              // التقييم والخبرة في صف واحد
              Row(
                children: [
                  _buildRatingChip(artisan),
                  SizedBox(width: 8.w),
                  _buildExperienceChip(artisan),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingChip(ArtisanModel artisan) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14.w, color: Colors.amber),
          SizedBox(width: 2.w),
          Text(
            '${artisan.rating}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.amber[700],
            ),
          ),
          Text(
            ' (${artisan.reviewCount})',
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.amber[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceChip(ArtisanModel artisan) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.work_history_rounded,
            size: 12.w,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: 4.w),
          Text(
            '${artisan.yearsOfExperience} سنوات',
            style: TextStyle(
              fontSize: 10.sp,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(ArtisanModel artisan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نبذة عن الحرفي',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            artisan.description,
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo(ArtisanModel artisan, double distance) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  artisan.address,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Theme.of(context).colorScheme.onSurface,
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
                color: Theme.of(context).colorScheme.primary,
                size: 20.w,
              ),
              SizedBox(width: 8.w),
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
        ],
      ),
    );
  }

  Widget _buildActionButtons(ArtisanModel artisan) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.phone_rounded,
            label: 'اتصال',
            color: _getCraftColor(artisan.craftType),
            isOutlined: true,
            onTap: () {
              Navigator.pop(context);
              _makePhoneCall(artisan);
            },
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildActionButton(
            icon: Icons.chat_rounded,
            label: 'رسالة',
            color: _getCraftColor(artisan.craftType),
            onTap: () {
              Navigator.pop(context);
              _sendMessage(artisan);
            },
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildActionButton(
            icon: Icons.person_rounded,
            label: 'الملف',
            color: Theme.of(context).colorScheme.primary,
            onTap: () {
              Navigator.pop(context);
              context.push('/artisan-profile/${artisan.id}');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            color: isOutlined ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: color,
              width: isOutlined ? 2 : 0,
            ),
            boxShadow: isOutlined ? null : [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isOutlined ? color : Colors.white,
                size: 20.w,
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isOutlined ? color : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCraftIcon(String craftType) {
    switch (craftType) {
      case 'carpenter':
        return Icons.handyman;
      case 'electrician':
        return Icons.electrical_services;
      case 'plumber':
        return Icons.plumbing;
      case 'painter':
        return Icons.brush;
      case 'mechanic':
        return Icons.build_circle;
      default:
        return Icons.construction;
    }
  }

  void _makePhoneCall(ArtisanModel artisan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('اتصال بـ ${artisan.name}'),
        backgroundColor: _getCraftColor(artisan.craftType),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }

  void _sendMessage(ArtisanModel artisan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('فتح محادثة مع ${artisan.name}'),
        backgroundColor: _getCraftColor(artisan.craftType),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // مطلوب لـ AutomaticKeepAliveClientMixin
    
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
          ScaleTransition(
            scale: _fabAnimation,
            child: IconButton(
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
          ),
          ScaleTransition(
            scale: _fabAnimation,
            child: IconButton(
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
        // الخريطة المحسنة
        GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: _currentPosition,
          markers: _markers,
          onMapCreated: (GoogleMapController controller) {
            if (!_controller.isCompleted) {
              _controller.complete(controller);
            }
          },
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          rotateGesturesEnabled: true,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          tiltGesturesEnabled: false, // تعطيل للأداء
          buildingsEnabled: false, // تعطيل للأداء
          trafficEnabled: false, // تعطيل للأداء
          indoorViewEnabled: false, // تعطيل للأداء
          padding: EdgeInsets.only(
            top: 80.h,
            bottom: 100.h,
          ),
        ),
        
        // فلاتر أنواع الحرف مع رسوم متحركة
        SlideTransition(
          position: _filterAnimation,
          child: _buildFilterChips(),
        ),
        
        // معلومات الخريطة
        ScaleTransition(
          scale: _fabAnimation,
          child: _buildMapInfo(),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 2),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * 2 * 3.14159,
                child: Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 30.w,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 20.h),
          Text(
            'جارٍ تحميل الخريطة...',
            style: TextStyle(
              fontSize: 16.sp,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.5 + (0.5 * value),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 80.w,
                    color: Colors.red.withValues(alpha: 0.7),
                  ),
                );
              },
            ),
            SizedBox(height: 20.h),
            Text(
              'خطأ في تحميل الخريطة',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30.h),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initializeMap();
              },
              icon: Icon(Icons.refresh_rounded, size: 20.w),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 15.h),
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
      top: 16.h,
      left: 16.w,
      right: 16.w,
      child: Container(
        height: 50.h,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: PerformanceHelper.optimizedScrollPhysics,
          itemCount: _craftTypes.length,
          cacheExtent: PerformanceHelper.defaultCacheExtent.toDouble(),
          itemBuilder: (context, index) {
            final craftType = _craftTypes[index];
            final isSelected = _selectedCraftType == craftType;
            final count = craftType == 'all' 
                ? _artisans.length 
                : _artisans.where((a) => a.craftType == craftType).length;
            
            return Container(
              margin: EdgeInsets.only(right: 8.w),
              child: TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 200 + (index * 100)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: Opacity(
                      opacity: value,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCraftType = craftType;
                            });
                            _createMarkers();
                          },
                          borderRadius: BorderRadius.circular(25.r),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(25.r),
                              border: Border.all(
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isSelected 
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.black).withValues(alpha: 0.1),
                                  blurRadius: isSelected ? 8 : 4,
                                  offset: Offset(0, isSelected ? 3 : 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  craftType == 'all' ? 'الكل' : _getCraftNameArabic(craftType),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: (isSelected ? Colors.white : Theme.of(context).colorScheme.primary).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
      bottom: 20.h,
      left: 20.w,
      right: 20.w,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20.w,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'يظهر $filteredCount حرفي في المنطقة',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Icon(
                        _locationPermissionGranted ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
                        color: _locationPermissionGranted ? Colors.green : Colors.orange,
                        size: 14.w,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _locationPermissionGranted ? 'موقع دقيق' : 'موقع تقريبي',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: _locationPermissionGranted ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _filterAnimationController.dispose();
    PerformanceHelper.cleanupResources();
    super.dispose();
  }
} 