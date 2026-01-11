import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../Models/craft_model.dart';
import '../../core/Language/locales.dart';
import '../../services/craft_service.dart';
import '../../services/media_service.dart';
import '../../core/Language/app_languages.dart';
import '../../Utilities/app_constants.dart';

class AdminCraftsManagementScreen extends StatefulWidget {
  const AdminCraftsManagementScreen({super.key});

  @override
  State<AdminCraftsManagementScreen> createState() => _AdminCraftsManagementScreenState();
}

class _AdminCraftsManagementScreenState extends State<AdminCraftsManagementScreen> {
  final CraftService _craftService = CraftService();
  final Uuid _uuid = const Uuid();
  
  List<CraftModel> _crafts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCrafts();
  }

  Future<void> _loadCrafts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final crafts = await _craftService.getAllCrafts(activeOnly: false);
      if (mounted) {
        setState(() {
          _crafts = crafts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'خطأ في تحميل الحرف: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addCraft() async {
    final result = await showDialog<CraftModel>(
      context: context,
      builder: (context) => _CraftEditDialog(
        craft: null,
        languageCode: Provider.of<AppLanguage>(context, listen: false).appLang.name,
      ),
    );

    if (result != null) {
      try {
        await _craftService.addCraft(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.translate('craft_added_success') ?? 'تم إضافة الحرفة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCrafts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)?.translate('craft_add_failed') ?? 'خطأ في إضافة الحرفة'}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editCraft(CraftModel craft) async {
    final result = await showDialog<CraftModel>(
      context: context,
      builder: (context) => _CraftEditDialog(
        craft: craft,
        languageCode: Provider.of<AppLanguage>(context, listen: false).appLang.name,
      ),
    );

    if (result != null) {
      try {
        await _craftService.updateCraft(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.translate('craft_updated_success') ?? 'تم تحديث الحرفة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCrafts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)?.translate('craft_update_failed') ?? 'خطأ في تحديث الحرفة'}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteCraft(CraftModel craft) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.translate('confirm_delete') ?? 'تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الحرفة "${craft.getDisplayName('ar')}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)?.translate('cancel') ?? 'إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)?.translate('delete') ?? 'حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _craftService.deleteCraft(craft.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.translate('craft_deleted_success') ?? 'تم حذف الحرفة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCrafts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)?.translate('craft_delete_failed') ?? 'خطأ في حذف الحرفة'}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Provider.of<AppLanguage>(context, listen: false).appLang.name;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة أنواع الحرف'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCrafts,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red, fontSize: 16.sp),
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: _loadCrafts,
                        child: Text(AppLocalizations.of(context)?.translate('retry') ?? 'إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : _crafts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.category_outlined, size: 64.sp, color: Colors.grey),
                          SizedBox(height: 16.h),
                          Text(
                            'لا توجد حرف',
                            style: TextStyle(fontSize: 18.sp, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCrafts,
                      child: ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        itemCount: _crafts.length,
                        itemBuilder: (context, index) {
                          final craft = _crafts[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 12.h),
                            child: ListTile(
                              leading: craft.iconUrl != null && craft.iconUrl!.isNotEmpty
                                  ? Container(
                                      width: 50.w,
                                      height: 50.h,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8.r),
                                        border: Border.all(
                                          color: craft.isActive
                                              ? Theme.of(context).colorScheme.primary
                                              : Colors.grey,
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6.r),
                                        child: CachedNetworkImage(
                                          imageUrl: craft.iconUrl!,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => CircleAvatar(
                                            backgroundColor: craft.isActive
                                                ? Theme.of(context).colorScheme.primary
                                                : Colors.grey,
                                            child: Text(
                                              '${craft.order}',
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : CircleAvatar(
                                      backgroundColor: craft.isActive
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.grey,
                                      child: Text(
                                        '${craft.order}',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                              title: Text(
                                craft.getDisplayName(languageCode),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                  decoration: craft.isActive
                                      ? null
                                      : TextDecoration.lineThrough,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4.h),
                                  Text(
                                    'القيمة: ${craft.value}',
                                    style: TextStyle(fontSize: 12.sp),
                                  ),
                                  Text(
                                    'عربي: ${craft.arabicName} | English: ${craft.englishName}',
                                    style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                                  ),
                                  if (!craft.isActive)
                                    Padding(
                                      padding: EdgeInsets.only(top: 4.h),
                                      child: Text(
                                        'غير نشط',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    color: Colors.blue,
                                    onPressed: () => _editCraft(craft),
                                    tooltip: 'تعديل',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    onPressed: () => _deleteCraft(craft),
                                    tooltip: 'حذف',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCraft,
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)?.translate('add_new_craft') ?? 'إضافة حرفة جديدة'),
      ),
    );
  }
}

/// Dialog لإضافة/تعديل حرفة
class _CraftEditDialog extends StatefulWidget {
  final CraftModel? craft;
  final String languageCode;

  const _CraftEditDialog({
    required this.craft,
    required this.languageCode,
  });

  @override
  State<_CraftEditDialog> createState() => _CraftEditDialogState();
}

class _CraftEditDialogState extends State<_CraftEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _arabicController = TextEditingController();
  final _englishController = TextEditingController();
  final _orderController = TextEditingController();
  bool _isActive = true;
  String? _iconUrl;
  bool _isUploadingIcon = false;
  final Uuid _uuid = const Uuid();
  final MediaService _mediaService = MediaService();

  @override
  void initState() {
    super.initState();
    if (widget.craft != null) {
      _valueController.text = widget.craft!.value;
      _arabicController.text = widget.craft!.translations['ar'] ?? '';
      _englishController.text = widget.craft!.translations['en'] ?? '';
      _orderController.text = widget.craft!.order.toString();
      _isActive = widget.craft!.isActive;
      _iconUrl = widget.craft!.iconUrl;
    } else {
      _orderController.text = '1';
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _arabicController.dispose();
    _englishController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    try {
      setState(() {
        _isUploadingIcon = true;
      });

      final iconUrl = await _mediaService.uploadCraftIcon();
      
      if (iconUrl != null) {
        setState(() {
          _iconUrl = iconUrl;
          _isUploadingIcon = false;
        });
      } else {
        setState(() {
          _isUploadingIcon = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploadingIcon = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في رفع الأيقونة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeIcon() {
    setState(() {
      _iconUrl = null;
    });
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final craft = CraftModel(
        id: widget.craft?.id ?? _uuid.v4(),
        value: _valueController.text.trim(),
        translations: {
          'ar': _arabicController.text.trim(),
          'en': _englishController.text.trim(),
        },
        order: int.tryParse(_orderController.text) ?? 0,
        isActive: _isActive,
        iconUrl: _iconUrl,
        createdAt: widget.craft?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      Navigator.of(context).pop(craft);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.craft == null ? 'إضافة حرفة جديدة' : 'تعديل حرفة'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // أيقونة الحرفة
              Container(
                margin: EdgeInsets.only(bottom: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أيقونة الحرفة',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        // عرض الأيقونة
                        if (_iconUrl != null)
                          Container(
                            width: 80.w,
                            height: 80.h,
                            margin: EdgeInsets.only(left: 8.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: CachedNetworkImage(
                                imageUrl: _iconUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.error,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        // زر اختيار الأيقونة
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isUploadingIcon ? null : _pickIcon,
                            icon: _isUploadingIcon
                                ? SizedBox(
                                    width: 16.w,
                                    height: 16.h,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(Icons.add_photo_alternate),
                            label: Text(_iconUrl == null ? 'اختر أيقونة' : 'تغيير الأيقونة'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                          ),
                        ),
                        // زر حذف الأيقونة
                        if (_iconUrl != null)
                          IconButton(
                            onPressed: _removeIcon,
                            icon: Icon(Icons.delete, color: Colors.red),
                            tooltip: 'حذف الأيقونة',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              
              // القيمة (Value)
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'القيمة (Value)',
                  hintText: 'مثال: carpenter',
                  prefixIcon: Icon(Icons.code),
                ),
                enabled: widget.craft != null ? false : true, // لا يمكن تعديل القيمة للحرف الموجودة
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'القيمة مطلوبة';
                  }
                  if (value.contains(' ')) {
                    return 'القيمة يجب ألا تحتوي على مسافات';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              
              // الترجمة العربية
              TextFormField(
                controller: _arabicController,
                decoration: InputDecoration(
                  labelText: 'الترجمة العربية',
                  hintText: AppLocalizations.of(context)?.translate('example_craft_name') ?? 'مثال: عطل نجارة',
                  prefixIcon: Icon(Icons.translate),
                ),
                textDirection: TextDirection.rtl,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الترجمة العربية مطلوبة';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              
              // الترجمة الإنجليزية
              TextFormField(
                controller: _englishController,
                decoration: const InputDecoration(
                  labelText: 'الترجمة الإنجليزية',
                  hintText: 'مثال: Carpentry Problem',
                  prefixIcon: Icon(Icons.language),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الترجمة الإنجليزية مطلوبة';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              
              // الترتيب
              TextFormField(
                controller: _orderController,
                decoration: const InputDecoration(
                  labelText: 'الترتيب',
                  hintText: 'مثال: 1',
                  prefixIcon: Icon(Icons.sort),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الترتيب مطلوب';
                  }
                  if (int.tryParse(value) == null) {
                    return 'يجب أن يكون رقم';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              
              // حالة النشاط
              SwitchListTile(
                title: Text(AppLocalizations.of(context)?.translate('active') ?? 'نشط'),
                subtitle: Text(AppLocalizations.of(context)?.translate('craft_will_appear') ?? 'الحرفة ستظهر في التطبيق'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)?.translate('cancel') ?? 'إلغاء'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(AppLocalizations.of(context)?.translate('save') ?? 'حفظ'),
        ),
      ],
    );
  }
}

