import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Utilities/app_constants.dart';
import '../../Utilities/performance_helper.dart';
import '../../core/Language/locales.dart';
import '../../Models/artisan_model.dart';
import '../../providers/simple_auth_provider.dart';
import '../../providers/chat_provider.dart';

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
    'hvac',
    'satellite',
    'internet',
    'tiler',
    'locksmith',
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
        return const Color(0xFFFF6D00);
      case 'electrician':
        return const Color(0xFFFFC107);
      case 'plumber':
        return const Color(0xFF1976D2);
      case 'painter':
        return const Color(0xFF2E7D32);
      case 'mechanic':
        return const Color(0xFFD32F2F);
      case 'hvac':
        return const Color(0xFF00BCD4);
      case 'satellite':
        return const Color(0xFF9C27B0);
      case 'internet':
        return const Color(0xFF03A9F4);
      case 'tiler':
        return const Color(0xFFE91E63);
      case 'locksmith':
        return const Color(0xFF7B1FA2);
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
    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    // التحقق من أن المستخدم الحالي ليس صاحب الحساب
    final bool isOwner = currentUser != null && 
                        currentUser.artisanId != null && 
                        currentUser.artisanId == artisan.id;
    
    return Row(
      children: [
        // زر الاتصال - يظهر فقط إذا لم يكن المستخدم صاحب الحساب
        if (!isOwner) ...[
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
        ],
        // زر الملف - يظهر دائماً
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
      case 'hvac':
        return Icons.ac_unit;
      case 'satellite':
        return Icons.satellite;
      case 'internet':
        return Icons.wifi;
      case 'tiler':
        return Icons.square_foot;
      case 'locksmith':
        return Icons.lock;
      default:
        return Icons.construction;
    }
  }

  Future<void> _makePhoneCall(ArtisanModel artisan) async {
    if (artisan.phone.isEmpty) {
      if (!mounted) return;
      try {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('رقم الهاتف غير متوفر'),
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
              content: Text('لا يمكن فتح تطبيق الاتصال'),
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
            content: Text('فشل في الاتصال: ${e.toString()}'),
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
            content: Text('يجب تسجيل الدخول لإرسال رسالة'),
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
              content: Text('فشل في إنشاء المحادثة'),
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
            content: Text('فشل في فتح المحادثة: ${e.toString()}'),
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