import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:template_2025/Modules/Maps/complete_maps_page.dart';
import '../../Utilities/app_constants.dart';
import '../../Utilities/performance_helper.dart';
import '../../core/Language/locales.dart';
import '../../generated/assets.dart';
import '../../Models/craft_model.dart';
import '../../providers/artisan_provider.dart';
import '../Chat/chat_page.dart';
import '../../providers/simple_auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../Profile/profile_screen.dart';
import '../FaultReport/fault_reports_screen.dart';
import '../../services/artisan_service.dart';
import '../../services/craft_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  
  @override
  bool get wantKeepAlive => true; // الحفاظ على الحالة

  final PageController _pageController = PageController();
  int _currentIndex = 0;
  int _selectedCategoryIndex = 0;

  // متحكمات الرسوم المتحركة
  late AnimationController _bottomNavAnimationController;
  late Animation<double> _bottomNavAnimation;

  // متغيرات جديدة للحرفيين الحقيقيين
  List<CraftModel> _realCrafts = [];
  bool _isLoadingCrafts = true;
  List<CraftCategory> _realCraftCategories = [];
  // خريطة لتخزين عدد الحرفيين لكل حرفة
  Map<String, int> _craftArtisanCounts = {};
  
  // متغير لتتبع آخر وقت تم فيه تحديث الموقع لتجنب التحديثات المتكررة
  DateTime? _lastLocationUpdate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _loadRealArtisans();
    // تحديث موقع الحرفي بعد تهيئة الواجهة مع تأخير قصير للتأكد من تحميل بيانات المستخدم
    // إعادة تعيين آخر تحديث للتأكد من التحديث عند فتح التطبيق
    _lastLocationUpdate = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          print('🔄 initState - تحديث موقع الحرفي عند فتح التطبيق (forceUpdate: true)');
          _updateArtisanLocationIfNeeded(forceUpdate: true);
        }
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // تحديث الموقع عند العودة إلى التطبيق (resume) أو عند فتحه
    if (state == AppLifecycleState.resumed) {
      print('🔄 التطبيق عاد إلى المقدمة - تحديث موقع الحرفي (forceUpdate: true)');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _updateArtisanLocationIfNeeded(forceUpdate: true);
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // تحديث الموقع عند فتح الصفحة (لكن مع تجنب التحديثات المتكررة خلال 30 ثانية)
    // لكن فقط إذا كانت هذه أول مرة أو مر وقت كافٍ
    final shouldUpdate = _lastLocationUpdate == null || 
        DateTime.now().difference(_lastLocationUpdate!) > const Duration(seconds: 30);
    
    if (shouldUpdate) {
      print('🔄 didChangeDependencies - التحقق من تحديث موقع الحرفي');
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _updateArtisanLocationIfNeeded();
        }
      });
    }
  }


  // تحديث موقع الحرفي عند فتح التطبيق
  Future<void> _updateArtisanLocationIfNeeded({bool forceUpdate = false}) async {
    if (!mounted) return;
    
    try {
      print('🔄 التحقق من تحديث موقع الحرفي... (forceUpdate: $forceUpdate)');
      
      // التحقق من الوقت منذ آخر تحديث (ما لم يكن forceUpdate = true)
      if (!forceUpdate && _lastLocationUpdate != null) {
        final timeSinceLastUpdate = DateTime.now().difference(_lastLocationUpdate!);
        if (timeSinceLastUpdate < const Duration(seconds: 30)) {
          print('⏭️ تم التحديث مؤخراً (${timeSinceLastUpdate.inSeconds} ثانية مضت)، تخطي التحديث');
          return;
        }
      }
      
      final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      print('👤 المستخدم الحالي: ${currentUser?.email}');
      print('👤 نوع المستخدم: ${currentUser?.userType}');
      print('👤 معرف الحرفي: ${currentUser?.artisanId}');

      // التحقق من أن المستخدم مسجل دخول وأنه حرفي
      if (currentUser == null) {
        print('⚠️ لا يوجد مستخدم مسجل دخول');
        return;
      }

      if (currentUser.userType != 'artisan') {
        print('ℹ️ المستخدم ليس حرفي، لا حاجة لتحديث الموقع');
        return;
      }

      final artisanService = ArtisanService();
      String? artisanIdToUpdate;

      // محاولة استخدام artisanId أولاً
      if (currentUser.artisanId != null && currentUser.artisanId!.isNotEmpty) {
        artisanIdToUpdate = currentUser.artisanId;
        print('📍 استخدام artisanId: $artisanIdToUpdate');
      } else {
        // إذا لم يكن artisanId موجوداً، جرب البحث باستخدام userId
        print('🔄 artisanId غير موجود، البحث باستخدام userId: ${currentUser.id}');
        final artisan = await artisanService.getArtisanByUserId(currentUser.id);
        if (artisan != null) {
          artisanIdToUpdate = artisan.id;
          print('✅ تم العثور على الحرفي: $artisanIdToUpdate');
        } else {
          print('⚠️ لم يتم العثور على الحرفي');
          return;
        }
      }

      if (artisanIdToUpdate != null) {
        // تحديث موقع الحرفي في Firebase
        await artisanService.updateArtisanLocation(artisanIdToUpdate);
        // تحديث وقت آخر تحديث
        _lastLocationUpdate = DateTime.now();
        print('✅ تم تحديث وقت آخر تحديث: $_lastLocationUpdate');
      } else {
        print('⚠️ لا يوجد معرف حرفي متاح لتحديث الموقع');
      }
    } catch (e, stackTrace) {
      print('❌ خطأ في تحديث موقع الحرفي: $e');
      print('❌ Stack trace: $stackTrace');
      // لا نوقف التطبيق إذا فشل تحديث الموقع
    }
  }

  void _initializeAnimations() {
    _bottomNavAnimationController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );
    
    _bottomNavAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bottomNavAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadRealArtisans() async {
    try {
      setState(() {
        _isLoadingCrafts = true;
      });

      final artisanProvider = Provider.of<ArtisanProvider>(context, listen: false);
      await artisanProvider.loadAllArtisans();

      print('📊 عدد الحرفيين المحملين: ${artisanProvider.artisans.length}');

      // جلب بيانات الحرف من Firebase
      final craftService = CraftService();
      final craftsFromFirebase = await craftService.getAllCrafts(activeOnly: true);
      print('📊 عدد الحرف من Firebase: ${craftsFromFirebase.length}');

      // تحويل بيانات الحرفيين الحقيقيين إلى CraftModel
      final craftsMap = <String, List<dynamic>>{};
      
      for (final artisan in artisanProvider.artisans) {
        // التأكد من أن craftType موجود وليس فارغاً
        final craftType = artisan.craftType.isNotEmpty ? artisan.craftType : 'unknown';
        
        if (!craftsMap.containsKey(craftType)) {
          craftsMap[craftType] = [];
        }
        craftsMap[craftType]!.add(artisan);
      }

      print('📊 عدد أنواع الحرف: ${craftsMap.length}');
      craftsMap.forEach((key, value) {
        print('  - $key: ${value.length} حرفي');
      });

      // حفظ عدد الحرفيين لكل حرفة
      _craftArtisanCounts = {};
      for (final entry in craftsMap.entries) {
        _craftArtisanCounts[entry.key] = entry.value.length;
      }

      // إنشاء CraftModel باستخدام بيانات Firebase إذا كانت متاحة
      _realCrafts = craftsMap.entries.map((entry) {
        final craftType = entry.key;
        
        // البحث عن بيانات الحرفة من Firebase
        CraftModel? craftFromFirebase;
        try {
          craftFromFirebase = craftsFromFirebase.firstWhere(
            (craft) => craft.value == craftType,
          );
        } catch (e) {
          // إذا لم توجد الحرفة في Firebase، استخدم البيانات الافتراضية
          craftFromFirebase = null;
        }
        
        // استخدام بيانات Firebase إذا كانت متاحة، وإلا استخدام البيانات الافتراضية
        if (craftFromFirebase != null) {
          return CraftModel(
            id: craftFromFirebase.id,
            value: craftFromFirebase.value,
            translations: craftFromFirebase.translations.isNotEmpty 
                ? craftFromFirebase.translations 
                : {
                    'ar': _getCraftName(craftType),
                    'en': _getCraftNameEn(craftType),
                  },
            order: craftFromFirebase.order,
            isActive: craftFromFirebase.isActive,
            iconUrl: craftFromFirebase.iconUrl, // استخدام الأيقونة من Firebase
            createdAt: craftFromFirebase.createdAt,
            updatedAt: craftFromFirebase.updatedAt,
          );
        } else {
          // استخدام البيانات الافتراضية
          return CraftModel(
            id: craftType,
            value: craftType,
            translations: {
              'ar': _getCraftName(craftType),
              'en': _getCraftNameEn(craftType),
            },
            order: _getCraftOrder(craftType),
            isActive: true,
            iconUrl: null, // لا توجد أيقونة مخصصة
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      }).toList();

      // إنشاء فئات الحرف الحقيقية
      _realCraftCategories = [
        CraftCategory(
          id: 'all',
          nameKey: 'all_crafts',
          icon: Icons.apps_rounded,
          count: artisanProvider.artisans.length,
        ),
        ...craftsMap.entries.map((entry) {
          return CraftCategory(
            id: entry.key,
            nameKey: entry.key,
            icon: _getCraftIcon(entry.key),
            count: entry.value.length,
          );
        }),
      ];

      setState(() {
        _isLoadingCrafts = false;
      });
    } catch (e, stackTrace) {
      print('❌ خطأ في تحميل الحرفيين: $e');
      print('📍 Stack trace: $stackTrace');
      setState(() {
        _isLoadingCrafts = false;
      });
      // في حالة الخطأ، استخدم قائمة فارغة
      _realCrafts = [];
      _realCraftCategories = [
        const CraftCategory(
          id: 'all',
          nameKey: 'all_crafts',
          icon: Icons.apps_rounded,
          count: 0,
        ),
      ];
    }
  }

  String _getCraftName(String craftType) {
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

  String _getCraftNameEn(String craftType) {
    switch (craftType) {
      case 'carpenter':
        return 'Carpenter';
      case 'electrician':
        return 'Electrician';
      case 'plumber':
        return 'Plumber';
      case 'painter':
        return 'Painter';
      case 'mechanic':
        return 'Mechanic';
      case 'hvac':
        return 'HVAC';
      case 'satellite':
        return 'Satellite';
      case 'internet':
        return 'Internet';
      case 'tiler':
        return 'Tiler';
      case 'locksmith':
        return 'Locksmith';
      default:
        return craftType;
    }
  }

  int _getCraftOrder(String craftType) {
    switch (craftType) {
      case 'carpenter':
        return 1;
      case 'electrician':
        return 2;
      case 'plumber':
        return 3;
      case 'painter':
        return 4;
      case 'mechanic':
        return 5;
      case 'hvac':
        return 6;
      case 'satellite':
        return 7;
      case 'internet':
        return 8;
      case 'tiler':
        return 9;
      case 'locksmith':
        return 10;
      default:
        return 99;
    }
  }


  static IconData _getCraftIcon(String craft) {
    switch (craft) {
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
      case 'tailor':
        return Icons.design_services;
      case 'blacksmith':
        return Icons.hardware;
      case 'welder':
        return Icons.precision_manufacturing;
      case 'mason':
        return Icons.architecture;
      case 'gardener':
        return Icons.eco;
      default:
        return Icons.construction;
    }
  }

  void _onBottomNavTapped(int index) {
    if (index != _currentIndex) {
      final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
      
      // فحص تسجيل الدخول عند الضغط على Profile (index 3) أو التقارير (index 4)
      if (index == 3 || index == 4) {
        if (!authProvider.isLoggedIn || authProvider.currentUser == null) {
          // توجيه المستخدم إلى صفحة تسجيل الدخول
          context.push('/login');
          return;
        }
      }
      
      _pageController.animateToPage(
        index,
        duration: AppConstants.animationDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // مطلوب لـ AutomaticKeepAliveClientMixin
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[300],
      //appBar: _buildAppBar(),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // تعطيل السحب
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          // تحديث الموقع عند العودة إلى صفحة Home (index 0)
          if (index == 0) {
            print('🔄 العودة إلى صفحة Home - تحديث موقع الحرفي');
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _updateArtisanLocationIfNeeded(forceUpdate: false);
              }
            });
          }
        },
        children: [
          Consumer<SimpleAuthProvider>(
            builder: (context, authProvider, _) {
              // فحص نوع المستخدم: حرفي أم مستخدم عادي
              final isArtisan = authProvider.isLoggedIn && 
                               authProvider.currentUser != null && 
                               authProvider.currentUser!.userType == 'artisan';
              
              if (isArtisan) {
                // إذا كان المستخدم حرفي
                return FaultReportsScreen();
              } else {
                // إذا كان المستخدم عادي
                return _buildHomePage();
              }
            },
          ),
          const ChatPage(),
          const CompleteMapsPage(),
          const FaultReportsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bottomNavAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildHomePage() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        physics: PerformanceHelper.optimizedScrollPhysics,
        slivers: [
          _buildSliverAppBar(),
          //_buildSliverCategoryFilter(),
         // SliverToBoxAdapter(child: SizedBox(height: 20.h,)),
          _buildSliverSearchBar(),
          _buildSliverCraftsList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
          
          // فحص تسجيل الدخول
          if (!authProvider.isLoggedIn || authProvider.currentUser == null) {
            // توجيه المستخدم إلى صفحة تسجيل الدخول
            context.push('/login');
            return;
          }
          
          // إذا كان مسجل دخول، انتقل إلى صفحة رفع المشكلة
          context.push('/problem-report-stepper');
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.camera_alt),
        label: Text(
          AppLocalizations.of(context)?.translate('problem_picture') ?? 'صورة المشكلة',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 100.h,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 2.h),
          child: SafeArea(
            child: Row(children: [
              Center(
                child: Container(
                  width: 68.w,
                  height: 68.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.asset(
                      Assets.iconsLogo,
                      width: 68.w,
                      height: 68.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 24.w,),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)?.translate('welcome_greeting') ?? 'مرحبا بك...',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)?.translate('search_artisan_or_service') ?? 'ابحث عن حرفي أو خدمة...',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              )
            ],)
          ),
        ),
      ),
    );
  }

  Widget _buildSliverSearchBar() {
    return SliverToBoxAdapter(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Row(
                  children: [

                    SizedBox(width: 8.w,),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // التنقل إلى صفحة البحث
                            context.push('/search');
                          },
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  color: Theme.of(context).colorScheme.outline,
                                  size: 20.w,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)?.translate('search_artisan_or_service') ?? 'ابحث عن حرفي أو خدمة...',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.all(6.w),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Icon(
                                    Icons.tune_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 16.w,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Consumer<SimpleAuthProvider>(
                      builder: (context, authProvider, _) {
                        if (!authProvider.isLoggedIn) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          margin: EdgeInsets.only(left: 0, right: 12.w),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                context.push('/favorites');
                              },
                              borderRadius: BorderRadius.circular(12.r),
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  Icons.favorite_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24.w,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildSliverCraftsList() {
    if (_isLoadingCrafts) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    final filteredCrafts = _selectedCategoryIndex == 0 
        ? _realCrafts 
        : _realCrafts.where((craft) => 
            craft.id == _realCraftCategories[_selectedCategoryIndex].id).toList();

    if (filteredCrafts.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.handyman_outlined,
                size: 64.w,
                color: Theme.of(context).colorScheme.outline,
              ),
              SizedBox(height: 16.h),
              Text(
                AppLocalizations.of(context)?.translate('no_crafts_available') ?? 'لا توجد حرف متاحة',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final craft = filteredCrafts[index];
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: _buildEnhancedCraftCard(craft, index),
                ),
              );
            },
          );
        },
        childCount: filteredCrafts.length,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,       // 3 cards per row
        mainAxisSpacing: 10,     // vertical space between rows
        crossAxisSpacing: 10,    // horizontal space between cards
        childAspectRatio: 0.7,  // adjust card height
      ),
    );
  }

  Widget _buildEnhancedCraftCard(CraftModel craft, int index) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/craft-details/${craft.value}'),
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with gradient background or custom icon from Firebase
                Hero(
                  tag: 'craft_${craft.id}',
                  child: craft.iconUrl != null && craft.iconUrl!.isNotEmpty
                      ? Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: _getCraftColor(craft.value).withValues(alpha: 0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _getCraftColor(craft.value).withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.r),
                            child: CachedNetworkImage(
                              imageUrl: craft.iconUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 48.w,
                                height: 48.w,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _getCraftColor(craft.value),
                                      _getCraftColor(craft.value).withValues(alpha: 0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 48.w,
                                height: 48.w,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _getCraftColor(craft.value),
                                      _getCraftColor(craft.value).withValues(alpha: 0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Icon(
                                  _getCraftIcon(craft.value),
                                  color: Colors.white,
                                  size: 24.w,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getCraftColor(craft.value),
                                _getCraftColor(craft.value).withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: _getCraftColor(craft.value).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _getCraftIcon(craft.value),
                            color: Colors.white,
                            size: 24.w,
                          ),
                        ),
                ),
                SizedBox(height: 8.h),
                Text(
                  craft.getDisplayName(Localizations.localeOf(context).languageCode),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),

                // Artisan count
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_rounded,
                      size: 14.w,
                      color:  const Color(0xFFAE41EA),
                    ),
                    SizedBox(width: 4.w),

                    Row(
                      children: [
                        Text(
                          '${_craftArtisanCounts[craft.value] ?? 0}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w900,
                            color: _getCraftColor(craft.value),
                          ),
                        ),
                        SizedBox(width: 2.w,),
                        Text(
                          '${AppLocalizations.of(context)?.translate('artisan') ?? 'حرفي'}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color:  const Color(0xFFAE41EA),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCraftColor(String craftId) {
    return Theme.of(context).primaryColor;
    switch (craftId) {
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
      case 'tailor':
        return const Color(0xFF7B1FA2);
      case 'blacksmith':
        return const Color(0xFF424242);
      case 'welder':
        return const Color(0xFFE65100);
      case 'mason':
        return const Color(0xFF5D4037);
      case 'gardener':
        return const Color(0xFF388E3C);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Image.asset(
                Assets.iconsLogo,
                width: 40.w,
                height: 40.h,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            AppLocalizations.of(context)?.translate('app_name') ?? '',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBottomNavigation() {
    return Consumer2<SimpleAuthProvider, ChatProvider>(
      builder: (context, authProvider, chatProvider, _) {
        final isArtisan = authProvider.isLoggedIn && 
                         authProvider.currentUser != null && 
                         authProvider.currentUser!.userType == 'artisan';

        // تهيئة ChatProvider عند تسجيل الدخول لعرض عدد الرسائل غير المقروءة
        if (authProvider.isLoggedIn && authProvider.currentUser != null) {
          if (chatProvider.currentUser == null || 
              chatProvider.currentUser!.id != authProvider.currentUser!.id) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              chatProvider.initialize(authProvider.currentUser!);
            });
          }
        }

        final hasUnreadMessages = chatProvider.hasAnyUnreadMessages;

        // قائمة الأيقونات الكاملة
        final allNavItems = [
          BottomNavItem(icon: Icons.home_filled, labelKey: 'home'),
          BottomNavItem(icon: Icons.chat_bubble_rounded, labelKey: 'chat'),
          BottomNavItem(icon: Icons.location_on_rounded, labelKey: 'maps'),
          BottomNavItem(icon: Icons.assignment_rounded, labelKey: 'fault_reports'),
          BottomNavItem(icon: Icons.person_2_rounded, labelKey: 'profile'),
        ];

        // للحرفيين: فقط Home و Maps
        final artisanNavItems = [
          BottomNavItem(icon: Icons.chat_bubble_rounded, labelKey: 'chat'),
          BottomNavItem(icon: Icons.assignment_rounded, labelKey: 'fault_reports'),
          BottomNavItem(icon: Icons.person_2_rounded, labelKey: 'profile'),
        ];

        final navItems = isArtisan ? artisanNavItems : allNavItems;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: 70.h,
              padding: EdgeInsets.symmetric(horizontal: AppConstants.smallPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  navItems.length,
                  (index) => _buildNavItem(
                    navItems[index],
                    index,
                    isArtisan,
                    showUnreadBadge: navItems[index].labelKey == 'chat' && hasUnreadMessages,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(BottomNavItem item, int index, bool isArtisan, {bool showUnreadBadge = false}) {
    // حساب الفهرس الفعلي في PageView
    int actualIndex;
    if (isArtisan) {
      // للحرفيين: index 0 = Home (0), index 1 = Maps (2)
      actualIndex = index == 0 ? 1 :  index == 1 ? 3 : 4;
    } else {
      // للمستخدمين العاديين: الفهرس كما هو
      actualIndex = index;
    }
    
    final isSelected = _currentIndex == actualIndex;
    
    return GestureDetector(
      onTap: () => _onBottomNavTapped(actualIndex),
      child: AnimatedContainer(
        duration: AppConstants.animationDuration,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16.w : 12.w,
          vertical: 4.h,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: AppConstants.animationDuration,
                  child: Icon(
                    item.icon,
                    size: isSelected ? 22.w : 20.w,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
                if (showUnreadBadge)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 2.h),
            AnimatedDefaultTextStyle(
              duration: AppConstants.animationDuration,
              style: TextStyle(
                fontSize: isSelected ? 8.sp : 7.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
              child: Text(
                AppLocalizations.of(context)?.translate(item.labelKey) ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }


}

class CraftCategory {
  final String id;
  final String nameKey;
  final IconData icon;
  final int count;

  const CraftCategory({
    required this.id,
    required this.nameKey,
    required this.icon,
    required this.count,
  });
}

class BottomNavItem {
  final IconData icon;
  final String labelKey;

  const BottomNavItem({
    required this.icon,
    required this.labelKey,
  });
} 

