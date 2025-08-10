import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';
import '../../providers/simple_auth_provider.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<SimpleAuthProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)?.translate('chat') ?? 'المحادثات',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: authProvider.isLoggedIn 
          ? _buildLoggedInContent(context)
          : _buildNotLoggedInContent(context),
    );
  }

  Widget _buildLoggedInContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 80.w,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          SizedBox(height: AppConstants.padding),
          Text(
            'لا توجد محادثات',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: AppConstants.smallPadding),
          Text(
            'ابدأ محادثة مع الحرفيين لطلب خدماتهم',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.padding),
          ElevatedButton.icon(
            onPressed: () {
              context.push('/search');
            },
            icon: Icon(Icons.search_rounded, size: 20.w),
            label: Text(
              'البحث عن حرفيين',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 12.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedInContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 80.w,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          SizedBox(height: AppConstants.padding),
          Text(
            'يجب تسجيل الدخول أولاً',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: AppConstants.smallPadding),
          Text(
            'سجل دخولك للبدء في المحادثة مع الحرفيين',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.padding),
          ElevatedButton(
            onPressed: () {
              context.push('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 32.w,
                vertical: 12.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)?.translate('login') ?? 'تسجيل الدخول',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 