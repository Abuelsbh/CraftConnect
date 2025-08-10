import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:template_2025/Modules/Maps/complete_maps_page.dart';
import '../../Utilities/app_constants.dart';
import '../../Utilities/performance_helper.dart';
import '../../core/Language/locales.dart';
import '../../models/craft_model.dart';
import '../Chat/chat_page.dart';
import '../Maps/optimized_maps_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; // الحفاظ على الحالة

  final PageController _pageController = PageController();
  int _currentIndex = 0;
  int _selectedCategoryIndex = 0;

  // متحكمات الرسوم المتحركة
  late AnimationController _bottomNavAnimationController;
  late Animation<double> _bottomNavAnimation;

  // Sample data
  final List<CraftCategory> _craftCategories = [
    const CraftCategory(
      id: 'all',
      nameKey: 'all_crafts',
      icon: Icons.apps_rounded,
      count: 45,
    ),
    ...AppConstants.craftTypes.map((craft) => CraftCategory(
          id: craft,
          nameKey: craft,
          icon: _getCraftIcon(craft),
          count: (15 + craft.length) % 12 + 3,
        )),
  ];

  final List<CraftModel> _sampleCrafts = [
    const CraftModel(
      id: 'carpenter',
      name: 'Carpenter',
      nameKey: 'carpenter',
      iconPath: '',
      description: 'Wood working and furniture crafting',
      artisanCount: 24,
      category: 'construction',
      averageRating: 4.8,
    ),
    const CraftModel(
      id: 'electrician',
      name: 'Electrician',
      nameKey: 'electrician',
      iconPath: '',
      description: 'Electrical installations and repairs',
      artisanCount: 18,
      category: 'utilities',
      averageRating: 4.7,
    ),
    const CraftModel(
      id: 'plumber',
      name: 'Plumber',
      nameKey: 'plumber',
      iconPath: '',
      description: 'Plumbing services and maintenance',
      artisanCount: 15,
      category: 'utilities',
      averageRating: 4.6,
    ),
    const CraftModel(
      id: 'painter',
      name: 'Painter',
      nameKey: 'painter',
      iconPath: '',
      description: 'Interior and exterior painting',
      artisanCount: 21,
      category: 'decoration',
      averageRating: 4.5,
    ),
    const CraftModel(
      id: 'mechanic',
      name: 'Mechanic',
      nameKey: 'mechanic',
      iconPath: '',
      description: 'Automotive repair and maintenance',
      artisanCount: 12,
      category: 'automotive',
      averageRating: 4.9,
    ),
  ];

  static IconData _getCraftIcon(String craft) {
    switch (craft) {
      case 'carpenter':
        return Icons.handyman; // أيقونة أوضح للنجار
      case 'electrician':
        return Icons.electrical_services; // كهربائي
      case 'plumber':
        return Icons.plumbing; // سباك
      case 'painter':
        return Icons.brush; // صباغ
      case 'mechanic':
        return Icons.build_circle; // ميكانيكي
      case 'tailor':
        return Icons.design_services; // خياط
      case 'blacksmith':
        return Icons.hardware; // حداد
      case 'welder':
        return Icons.precision_manufacturing; // لحام
      case 'mason':
        return Icons.architecture; // بناء
      case 'gardener':
        return Icons.eco; // بستاني
      default:
        return Icons.construction; // افتراضي
    }
  }

  void _onBottomNavTapped(int index) {
    if (index != _currentIndex) {
      _pageController.animateToPage(
        index,
        duration: AppConstants.animationDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  void _onCategorySelected(int index) {
    setState(() {
      _selectedCategoryIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    PerformanceHelper.optimizeMemory();
  }

  void _initializeAnimations() {
    _bottomNavAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _bottomNavAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bottomNavAnimationController,
      curve: Curves.easeOutQuart,
    ));

    _bottomNavAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // مطلوب لـ AutomaticKeepAliveClientMixin
    
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // تعطيل السحب
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          _buildHomePage(),
          const ChatPage(),
          const CompleteMapsPage(),
          _buildPlaceholderPage('Profile'),
          _buildPlaceholderPage('Submit Request'),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  @override
  void dispose() {
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
          _buildSliverCategoryFilter(),
          _buildSliverSearchBar(),
          _buildSliverCraftsList(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120.h,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.5 + (0.5 * value),
                            child: Container(
                              width: 50.w,
                              height: 50.w,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.handyman_rounded,
                                color: Colors.white,
                                size: 25.w,
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 15.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TweenAnimationBuilder<Offset>(
                              duration: const Duration(milliseconds: 600),
                              tween: Tween(begin: const Offset(50, 0), end: Offset.zero),
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: value,
                                  child: Text(
                                    'مرحباً بك',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 2.h),
                            TweenAnimationBuilder<Offset>(
                              duration: const Duration(milliseconds: 800),
                              tween: Tween(begin: const Offset(80, 0), end: Offset.zero),
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: value,
                                  child: Text(
                                    'ابحث عن الحرفي المناسب',
                                    style: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1000),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: IconButton(
                              onPressed: () {
                                // TODO: إعدادات
                              },
                              icon: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  Icons.settings_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20.w,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
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
                        'ابحث عن حرفي أو خدمة...',
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
          );
        },
      ),
    );
  }

  Widget _buildSliverCategoryFilter() {
    return SliverToBoxAdapter(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 800),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: Container(
                height: 120.h,
                margin: EdgeInsets.only(top: 10.h),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: PerformanceHelper.optimizedScrollPhysics,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: _craftCategories.length,
                  cacheExtent: PerformanceHelper.defaultCacheExtent.toDouble(),
                  itemBuilder: (context, index) {
                    final category = _craftCategories[index];
                    final isSelected = _selectedCategoryIndex == index;
                    
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 200 + (index * 100)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, animValue, child) {
                        return Transform.scale(
                          scale: 0.8 + (0.2 * animValue),
                          child: Opacity(
                            opacity: animValue,
                            child: _buildCategoryCard(category, index, isSelected),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(CraftCategory category, int index, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 100.w,
        margin: EdgeInsets.only(right: 12.w),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSelected 
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05)),
              blurRadius: isSelected ? 12 : 6,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.all(isSelected ? 12.w : 10.w),
              decoration: BoxDecoration(
                color: (isSelected ? Colors.white.withValues(alpha: 0.2) : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                category.icon,
                size: isSelected ? 28.w : 24.w,
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              AppLocalizations.of(context)?.translate(category.nameKey) ?? '',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (category.count > 0) ...[
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: (isSelected ? Colors.white.withValues(alpha: 0.2) : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${category.count}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSliverCraftsList() {
    final filteredCrafts = _selectedCategoryIndex == 0 
        ? _sampleCrafts 
        : _sampleCrafts.where((craft) => 
            craft.id == _craftCategories[_selectedCategoryIndex].id).toList();

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      sliver: SliverList(
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
      ),
    );
  }

  Widget _buildEnhancedCraftCard(CraftModel craft, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/craft-details/${craft.id}'),
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Hero(
                  tag: 'craft_${craft.id}',
                  child: Container(
                    width: 70.w,
                    height: 70.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getCraftColor(craft.id),
                          _getCraftColor(craft.id).withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18.r),
                      boxShadow: [
                        BoxShadow(
                          color: _getCraftColor(craft.id).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getCraftIcon(craft.id),
                      color: Colors.white,
                      size: 35.w,
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.translate(craft.nameKey) ?? '',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: _getCraftColor(craft.id).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people_rounded,
                                  size: 14.w,
                                  color: _getCraftColor(craft.id),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '${craft.artisanCount} حرفي',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: _getCraftColor(craft.id),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 14.w,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '${craft.averageRating}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'متوفر الآن في منطقتك',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Theme.of(context).colorScheme.outline,
                  size: 16.w,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCraftColor(String craftId) {
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
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.handyman_rounded,
              color: Colors.white,
              size: 24.w,
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
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.search_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.notifications_outlined,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 110.h,
      padding: EdgeInsets.symmetric(vertical: AppConstants.smallPadding),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _craftCategories.length,
        padding: EdgeInsets.symmetric(horizontal: AppConstants.padding),
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              horizontalOffset: 50.0,
              child: FadeInAnimation(
                child: Padding(
                  padding: EdgeInsets.only(right: AppConstants.smallPadding),
                  child: _buildCategoryCardOld(_craftCategories[index], index),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCardOld(CraftCategory category, int index) {
    final isSelected = _selectedCategoryIndex == index;
    
    return GestureDetector(
      onTap: () => _onCategorySelected(index),
      child: AnimatedContainer(
        duration: AppConstants.animationDuration,
        width: 80.w,
        padding: EdgeInsets.all(AppConstants.smallPadding),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: (isSelected 
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.05)),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppConstants.smallPadding),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.15)
                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                category.icon,
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
                size: 22.w,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              AppLocalizations.of(context)?.translate(category.nameKey) ?? '',
              style: TextStyle(
                fontSize: 11.sp,
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCraftsList() {
    return Container(
      padding: EdgeInsets.all(AppConstants.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedCategoryIndex == 0
                    ? AppLocalizations.of(context)?.translate('all_crafts') ?? ''
                    : AppLocalizations.of(context)?.translate(_craftCategories[_selectedCategoryIndex].nameKey) ?? '',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  AppLocalizations.of(context)?.translate('view_all') ?? '',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.smallPadding),
          Expanded(
            child: AnimationLimiter(
              child: ListView.builder(
                itemCount: _sampleCrafts.length,
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: AppConstants.smallPadding),
                          child: _buildCraftCard(_sampleCrafts[index]),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCraftCard(CraftModel craft) {
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
                          onTap: () {
                    context.push('/craft-details/${craft.id}');
                  },
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: EdgeInsets.all(AppConstants.padding),
          child: Row(
            children: [
              Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Icon(
                  _getCraftIcon(craft.id),
                  size: 30.w,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: AppConstants.padding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.translate(craft.nameKey) ?? '',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      craft.description,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(
                          Icons.people_rounded,
                          size: 16.w,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${craft.artisanCount} ${AppLocalizations.of(context)?.translate('artisans_available') ?? ''}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16.w,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderPage(String title) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '$title Coming Soon',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'This feature will be available in Phase 2',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final navItems = [
      BottomNavItem(icon: Icons.home_filled, labelKey: 'home'),
      BottomNavItem(icon: Icons.chat_bubble_rounded, labelKey: 'chat'),
      BottomNavItem(icon: Icons.location_on_rounded, labelKey: 'maps'),
      BottomNavItem(icon: Icons.person_2_rounded, labelKey: 'profile'),
      BottomNavItem(icon: Icons.work_rounded, labelKey: 'submit_request'),
    ];

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
              (index) => _buildNavItem(navItems[index], index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BottomNavItem item, int index) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => _onBottomNavTapped(index),
      child: AnimatedContainer(
        duration: AppConstants.animationDuration,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16.w : 12.w,
          vertical: 8.h,
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
            AnimatedContainer(
              duration: AppConstants.animationDuration,
              child: Icon(
                item.icon,
                size: isSelected ? 26.w : 24.w,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
            SizedBox(height: 2.h),
            AnimatedDefaultTextStyle(
              duration: AppConstants.animationDuration,
              style: TextStyle(
                fontSize: isSelected ? 10.sp : 9.sp,
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