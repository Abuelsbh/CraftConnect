import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../Models/user_model.dart';
import '../Utilities/shared_preferences.dart';
import '../providers/artisan_provider.dart';

class SimpleAuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoggedIn = false;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  SimpleAuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    // تحقق من حالة تسجيل الدخول المحفوظة
    _checkSavedLogin();

    // استمع لتغيرات حالة Firebase Auth لتحديث الحالة المحلية
    _auth.authStateChanges().listen((fb.User? user) async {
      if (user != null) {
        // قام المستخدم بتسجيل الدخول
        _isLoggedIn = true;
        await _loadUserFromFirestore(user.uid);
      } else {
        // لا يوجد مستخدم
        _isLoggedIn = false;
        _currentUser = null;
        await _clearUserData();
      }
      notifyListeners();
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // تحميل بيانات المستخدم من Firestore
  Future<void> _loadUserFromFirestore(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        // تحقق من أن البيانات صحيحة قبل التحويل
        if (data is Map<String, dynamic>) {
          try {
            _currentUser = UserModel.fromJson({
              'id': doc.id,
              ...data,
            });
          } catch (parseError) {
            if (kDebugMode) {
              print('خطأ في تحليل بيانات المستخدم: $parseError');
            }
            // في حالة فشل التحليل، استخدم بيانات Firebase Auth
            final firebaseUser = _auth.currentUser;
            if (firebaseUser != null) {
              _currentUser = _mapFirebaseUserToUserModel(firebaseUser);
            }
          }
        } else {
          if (kDebugMode) {
            print('بيانات المستخدم ليست من النوع المتوقع: ${data.runtimeType}');
          }
          // استخدم بيانات Firebase Auth
          final firebaseUser = _auth.currentUser;
          if (firebaseUser != null) {
            _currentUser = _mapFirebaseUserToUserModel(firebaseUser);
          }
        }
      } else {
        // إذا لم تكن البيانات موجودة في Firestore، قم بإنشائها
        final firebaseUser = _auth.currentUser;
        if (firebaseUser != null) {
          _currentUser = _mapFirebaseUserToUserModel(firebaseUser);
          try {
            await _saveUserToFirestore(_currentUser!);
          } catch (saveError) {
            if (kDebugMode) {
              print('تحذير: فشل في حفظ البيانات في Firestore: $saveError');
            }
            // لا نوقف العملية إذا فشل الحفظ
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطأ في تحميل بيانات المستخدم من Firestore: $e');
      }
      // في حالة الخطأ، استخدم بيانات Firebase Auth
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        _currentUser = _mapFirebaseUserToUserModel(firebaseUser);
      }
    }
  }

  // حفظ بيانات المستخدم في Firestore
  Future<void> _saveUserToFirestore(UserModel user) async {
    try {
      final userData = user.toJson();
      // تحقق من أن البيانات صحيحة قبل الحفظ
      if (userData is Map<String, dynamic>) {
        await _firestore.collection('users').doc(user.id).set(userData);
      } else {
        if (kDebugMode) {
          print('تحذير: بيانات المستخدم ليست من النوع المتوقع للحفظ: ${userData.runtimeType}');
        }
        // لا نوقف العملية، فقط نسجل التحذير
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطأ في حفظ بيانات المستخدم في Firestore: $e');
      }
      // لا نوقف العملية، فقط نسجل الخطأ
    }
  }

  // تحديث بيانات المستخدم في Firestore
  Future<void> updateUserData(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toJson());
      _currentUser = user;
      await _saveUserLocally();
      notifyListeners();
    } catch (e) {
      _setError('فشل في تحديث البيانات: ${e.toString()}');
    }
  }

  // إعادة تحميل بيانات المستخدم من Firestore
  Future<void> reloadUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await _loadUserFromFirestore(firebaseUser.uid);
      notifyListeners();
    }
  }

  // تسجيل الدخول بالبريد/كلمة المرور
  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        _setError('تعذر تسجيل الدخول.');
        return false;
      }

      try {
        // تحميل بيانات المستخدم من Firestore
        await _loadUserFromFirestore(user.uid);
      } catch (e) {
        if (kDebugMode) {
          print('تحذير: فشل في تحميل البيانات من Firestore: $e');
        }
        // في حالة الفشل، استخدم بيانات Firebase Auth الأساسية
        try {
          _currentUser = _mapFirebaseUserToUserModel(user);
        } catch (mapError) {
          if (kDebugMode) {
            print('خطأ في تحويل بيانات المستخدم: $mapError');
          }
          _setError('خطأ في تحميل بيانات المستخدم');
          return false;
        }
      }
      
      _isLoggedIn = true;
      
      if (rememberMe) {
        try {
          await _saveUserLocally();
        } catch (e) {
          if (kDebugMode) {
            print('تحذير: فشل في حفظ البيانات محلياً: $e');
          }
          // لا نوقف العملية إذا فشل حفظ البيانات محلياً
        }
      }
      return true;
    } on fb.FirebaseAuthException catch (e) {
      _setError(_firebaseErrorToArabic(e));
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('خطأ غير متوقع في تسجيل الدخول: $e');
      }
      _setError('حدث خطأ غير متوقع: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // تسجيل حساب حرفي بالبيانات الأساسية فقط
  Future<bool> registerArtisanBasic({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      // إنشاء حساب Firebase Auth
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        _setError('فشل إنشاء الحساب');
        return false;
      }

      try {
        // تحديث اسم العرض في Firebase Auth
        await user.updateDisplayName(name);
        await user.reload();
      } catch (e) {
        if (kDebugMode) {
          print('تحذير: فشل في تحديث اسم العرض: $e');
        }
      }

      // إنشاء معرف فريد للحرفي
      final artisanId = DateTime.now().millisecondsSinceEpoch.toString();

      // إنشاء نموذج المستخدم
      try {
        _currentUser = UserModel(
          id: user.uid,
          name: name,
          email: email,
          phone: phone,
          profileImageUrl: '',
          token: '',
          userType: 'artisan',
          artisanId: artisanId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } catch (e) {
        if (kDebugMode) {
          print('خطأ في إنشاء نموذج المستخدم: $e');
        }
        _setError('خطأ في إنشاء بيانات المستخدم');
        return false;
      }

      try {
        // حفظ بيانات المستخدم في Firestore
        await _saveUserToFirestore(_currentUser!);
        
        // إنشاء سجل حرفي أساسي مع قيم افتراضية
        final artisanData = {
          'id': artisanId,
          'name': name,
          'email': email,
          'phone': phone,
          'profileImageUrl': '',
          'craftType': 'carpenter', // قيمة افتراضية
          'yearsOfExperience': 1, // قيمة افتراضية
          'description': '', // سيتم ملؤه لاحقاً
          'latitude': 0.0, // سيتم تحديثه لاحقاً
          'longitude': 0.0, // سيتم تحديثه لاحقاً
          'address': '', // سيتم ملؤه لاحقاً
          'rating': 0.0,
          'reviewCount': 0,
          'galleryImages': <String>[],
          'skills': <String>[],
          'isAvailable': false, // غير متاح حتى يكمل البيانات
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        // حفظ بيانات الحرفي في Firestore
        await _firestore.collection('artisans').doc(artisanId).set(artisanData);
        
      } catch (e) {
        if (kDebugMode) {
          print('تحذير: فشل في حفظ البيانات في Firestore: $e');
        }
        // لا نوقف العملية إذا فشل حفظ البيانات في Firestore
      }
      
      _isLoggedIn = true;
      try {
        await _saveUserLocally();
      } catch (e) {
        if (kDebugMode) {
          print('تحذير: فشل في حفظ البيانات محلياً: $e');
        }
      }
      return true;
    } on fb.FirebaseAuthException catch (e) {
      _setError(_firebaseErrorToArabic(e));
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('خطأ غير متوقع في إنشاء الحساب: $e');
      }
      _setError('حدث خطأ في إنشاء الحساب: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // تسجيل حساب جديد
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    String userType = 'user',
    String? craftType,
    String? description,
    int? yearsOfExperience,
    double? latitude,
    double? longitude,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        _setError('فشل إنشاء الحساب');
        return false;
      }

      try {
        // تحديث اسم العرض في Firebase Auth
        await user.updateDisplayName(name);
        await user.reload();
      } catch (e) {
        if (kDebugMode) {
          print('تحذير: فشل في تحديث اسم العرض: $e');
        }
        // لا نوقف العملية إذا فشل تحديث اسم العرض
      }

      // إنشاء نموذج المستخدم
      try {
        _currentUser = UserModel(
          id: user.uid,
          name: name,
          email: email,
          phone: phone,
          profileImageUrl: user.photoURL ?? '',
          token: '',
          userType: userType,
          artisanId: null, // سيتم تحديثه لاحقاً إذا كان حرفي
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } catch (e) {
        if (kDebugMode) {
          print('خطأ في إنشاء نموذج المستخدم: $e');
        }
        _setError('خطأ في إنشاء بيانات المستخدم');
        return false;
      }

      try {
        // حفظ بيانات المستخدم في Firestore
        await _saveUserToFirestore(_currentUser!);
        
        // إذا كان المستخدم حرفي، قم بتسجيله كحرفي
        if (userType == 'artisan' && craftType != null && description != null && yearsOfExperience != null) {
          try {
            // إنشاء مزود الحرفيين مؤقتاً
            final artisanProvider = ArtisanProvider();
            final success = await artisanProvider.registerArtisan(
              name: name,
              email: email,
              phone: phone,
              craftType: craftType,
              yearsOfExperience: yearsOfExperience,
              description: description,
              latitude: latitude,
              longitude: longitude,
            );
            
            if (success && artisanProvider.currentArtisan != null) {
              // تحديث معرف الحرفي في بيانات المستخدم
              _currentUser = _currentUser!.copyWith(
                artisanId: artisanProvider.currentArtisan!.id,
              );
              await _saveUserToFirestore(_currentUser!);
            }
          } catch (e) {
            if (kDebugMode) {
              print('تحذير: فشل في تسجيل الحرفي: $e');
            }
            // لا نوقف العملية إذا فشل تسجيل الحرفي
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('تحذير: فشل في حفظ البيانات في Firestore: $e');
        }
        // لا نوقف العملية إذا فشل حفظ البيانات في Firestore
      }
      
      _isLoggedIn = true;
      try {
        await _saveUserLocally();
      } catch (e) {
        if (kDebugMode) {
          print('تحذير: فشل في حفظ البيانات محلياً: $e');
        }
        // لا نوقف العملية إذا فشل حفظ البيانات محلياً
      }
      return true;
    } on fb.FirebaseAuthException catch (e) {
      _setError(_firebaseErrorToArabic(e));
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('خطأ غير متوقع في إنشاء الحساب: $e');
      }
      _setError('حدث خطأ في إنشاء الحساب: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // تسجيل الدخول مع Google
  Future<bool> loginWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);

      // محاولة تسجيل الخروج أولاً للتأكد من عدم وجود جلسة قديمة
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        if (kDebugMode) {
          print('تحذير: فشل في تسجيل الخروج من Google: $e');
        }
      }

      // بدء عملية تسجيل الدخول مع Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // المستخدم ألغى العملية
        _setError('تم إلغاء عملية تسجيل الدخول');
        return false;
      }

      // الحصول على بيانات المصادقة من Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // التحقق من وجود idToken
      if (googleAuth.idToken == null) {
        _setError('فشل في الحصول على بيانات المصادقة من Google. يرجى التأكد من إضافة SHA-1 في Firebase Console');
        return false;
      }

      // إنشاء بيانات اعتماد Firebase من بيانات Google
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // تسجيل الدخول إلى Firebase باستخدام بيانات اعتماد Google
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        _setError('فشل في تسجيل الدخول مع Google');
        return false;
      }

      // التحقق من وجود المستخدم في Firestore
      final userExists = await userExistsInFirestore(user.uid);
      
      if (!userExists) {
        // إنشاء حساب جديد للمستخدم
        _currentUser = UserModel(
          id: user.uid,
          name: user.displayName ?? 'مستخدم',
          email: user.email ?? '',
          phone: user.phoneNumber ?? '',
          profileImageUrl: user.photoURL ?? '',
          token: '',
          userType: 'user',
          artisanId: null,
          createdAt: user.metadata.creationTime ?? DateTime.now(),
          updatedAt: user.metadata.lastSignInTime ?? DateTime.now(),
        );
        
        // حفظ بيانات المستخدم في Firestore
        try {
          await _saveUserToFirestore(_currentUser!);
        } catch (e) {
          if (kDebugMode) {
            print('تحذير: فشل في حفظ البيانات في Firestore: $e');
          }
          // لا نوقف العملية إذا فشل حفظ البيانات في Firestore
        }
      } else {
        // تحميل بيانات المستخدم من Firestore
        try {
          await _loadUserFromFirestore(user.uid);
        } catch (e) {
          if (kDebugMode) {
            print('تحذير: فشل في تحميل البيانات من Firestore: $e');
          }
          // في حالة الفشل، استخدم بيانات Firebase Auth الأساسية
          try {
            _currentUser = _mapFirebaseUserToUserModel(user);
          } catch (mapError) {
            if (kDebugMode) {
              print('خطأ في تحويل بيانات المستخدم: $mapError');
            }
            _setError('خطأ في تحميل بيانات المستخدم');
            return false;
          }
        }
      }

      _isLoggedIn = true;
      
      // حفظ البيانات محلياً
      try {
        await _saveUserLocally();
      } catch (e) {
        if (kDebugMode) {
          print('تحذير: فشل في حفظ البيانات محلياً: $e');
        }
        // لا نوقف العملية إذا فشل حفظ البيانات محلياً
      }

      return true;
    } on fb.FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Firebase Auth Exception: ${e.code} - ${e.message}');
      }
      _setError(_firebaseErrorToArabic(e));
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('خطأ غير متوقع في تسجيل الدخول مع Google: $e');
        print('نوع الخطأ: ${e.runtimeType}');
      }
      
      // معالجة خاصة لخطأ ApiException: 10
      if (e.toString().contains('ApiException: 10') || e.toString().contains('sign_in_failed')) {
        _setError('خطأ في إعدادات Google Sign-In. يرجى التأكد من:\n1. إضافة SHA-1 fingerprint في Firebase Console\n2. تفعيل Google Sign-In في Firebase Authentication\n3. التأكد من تطابق package name');
      } else {
        _setError('حدث خطأ غير متوقع: ${e.toString()}');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // تسجيل الخروج
  Future<void> logout() async {
    try {
      _setLoading(true);
      // تسجيل الخروج من Firebase
      await _auth.signOut();
      // تسجيل الخروج من Google
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        if (kDebugMode) {
          print('تحذير: فشل في تسجيل الخروج من Google: $e');
        }
        // لا نوقف العملية إذا فشل تسجيل الخروج من Google
      }
      await _clearUserData();
      _currentUser = null;
      _isLoggedIn = false;
    } catch (e) {
      _setError('فشل في تسجيل الخروج: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // إعادة تعيين كلمة المرور
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _setError(null);
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on fb.FirebaseAuthException catch (e) {
      _setError(_firebaseErrorToArabic(e));
      return false;
    } catch (e) {
      _setError('فشل في إرسال رابط إعادة تعيين كلمة المرور: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // حفظ بيانات المستخدم محلياً
  Future<void> _saveUserLocally() async {
    if (_currentUser != null) {
      await SharedPref.saveCurrentUser(user: _currentUser!);
    }
  }

  // مسح بيانات المستخدم المحلية
  Future<void> _clearUserData() async {
    await SharedPref.logout();
  }

  // تحقق من حالة تسجيل الدخول المحفوظة
  Future<void> _checkSavedLogin() async {
    try {
      final savedUser = SharedPref.getCurrentUser();
      if (savedUser != null) {
        _currentUser = savedUser;
        _isLoggedIn = true;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطأ في تحميل بيانات المستخدم المحفوظة: $e');
      }
    }
  }

  // تحقق من صحة البريد الإلكتروني
  bool isEmailValid(String email) {
    return RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}').hasMatch(email);
  }

  // تحقق من قوة كلمة المرور
  bool isPasswordStrong(String password) {
    return password.length >= 8 &&
           password.contains(RegExp(r'[A-Z]')) &&
           password.contains(RegExp(r'[a-z]')) &&
           password.contains(RegExp(r'[0-9]'));
  }

  // تحقق من صحة رقم الهاتف
  bool isPhoneValid(String phone) {
    return RegExp(r'^[0-9]{10,15}$').hasMatch(phone.replaceAll(RegExp(r'[^\d]'), ''));
  }

  UserModel _mapFirebaseUserToUserModel(fb.User user) {
    try {
      return UserModel(
        id: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        phone: user.phoneNumber ?? '',
        profileImageUrl: user.photoURL ?? '',
        token: '',
        createdAt: user.metadata.creationTime ?? DateTime.now(),
        updatedAt: user.metadata.lastSignInTime ?? DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('خطأ في تحويل بيانات Firebase User: $e');
      }
      // إرجاع نموذج افتراضي في حالة الخطأ
      return UserModel(
        id: user.uid,
        name: user.displayName ?? 'مستخدم',
        email: user.email ?? '',
        phone: user.phoneNumber ?? '',
        profileImageUrl: user.photoURL ?? '',
        token: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  String _firebaseErrorToArabic(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'بريد إلكتروني غير صحيح';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'user-not-found':
        return 'المستخدم غير موجود';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً. يجب أن تكون 6 أحرف على الأقل';
      case 'operation-not-allowed':
        return 'العملية غير مسموح بها';
      case 'too-many-requests':
        return 'تم تجاوز الحد الأقصى للمحاولات. حاول مرة أخرى لاحقاً';
      case 'network-request-failed':
        return 'فشل في الاتصال بالشبكة. تحقق من اتصالك بالإنترنت';
      case 'invalid-verification-code':
        return 'رمز التحقق غير صحيح';
      case 'invalid-verification-id':
        return 'معرف التحقق غير صحيح';
      case 'quota-exceeded':
        return 'تم تجاوز الحد المسموح. حاول مرة أخرى لاحقاً';
      default:
        return 'خطأ في المصادقة: ${e.message ?? e.code}';
    }
  }

  // تحقق من وجود المستخدم في Firestore
  Future<bool> userExistsInFirestore(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // حذف حساب المستخدم
  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _setError(null);

      final user = _auth.currentUser;
      if (user == null) {
        _setError('لا يوجد مستخدم مسجل');
        return false;
      }

      // حذف البيانات من Firestore
      await _firestore.collection('users').doc(user.uid).delete();
      
      // حذف الحساب من Firebase Auth
      await user.delete();
      
      // مسح البيانات المحلية
      await _clearUserData();
      _currentUser = null;
      _isLoggedIn = false;
      
      return true;
    } on fb.FirebaseAuthException catch (e) {
      _setError(_firebaseErrorToArabic(e));
      return false;
    } catch (e) {
      _setError('فشل في حذف الحساب: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
} 