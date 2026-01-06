import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/Language/locales.dart';

/// Widget للخطوة الثالثة: التفاصيل الإضافية
class Step3AdditionalDetailsWidget extends StatelessWidget {
  final TextEditingController descriptionController;
  final Widget voiceRecordingSection;
  final Widget scheduledDateSection;

  const Step3AdditionalDetailsWidget({
    super.key,
    required this.descriptionController,
    required this.voiceRecordingSection,
    required this.scheduledDateSection,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context)?.translate('additional_details') ?? 'تفاصيل إضافية',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context)?.translate('additional_details_description') ?? 
            'أضف وصفاً تفصيلياً للمشكلة (اختياري)',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          SizedBox(height: 12.h),
          
          // Description Text Field
          TextField(
            controller: descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)?.translate('write_detailed_description') ?? 
              'اكتب وصفاً تفصيلياً للمشكلة...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          SizedBox(height: 12.h),
          
          // Voice Recording Section
          voiceRecordingSection,
          SizedBox(height: 12.h),
          
          // Scheduled Date Section
          scheduledDateSection,
        ],
      ),
    );
  }
}







