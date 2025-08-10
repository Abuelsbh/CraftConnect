import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user_model.dart';
import '../Utilities/shared_preferences.dart';

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
        _currentUser = _mapFirebaseUserToUserModel(user);
        await _saveUserLocally();
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

      _currentUser = _mapFirebaseUserToUserModel(user);
      _isLoggedIn = true;
      if (rememberMe) {
        await _saveUserLocally();
      }
      return true;
    } on fb.FirebaseAuthException catch (e) {
      _setError(_firebaseErrorToArabic(e));
      return false;
    } catch (e) {
      _setError('حدث خطأ غير متوقع: ${e.toString()}');
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
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // تحديث اسم العرض
      await cred.user?.updateDisplayName(name);
      await cred.user?.reload();

      final user = _auth.currentUser;
      if (user == null) {
        _setError('فشل إنشاء الحساب');
        return false;
      }

      _currentUser = _mapFirebaseUserToUserModel(user).copyWith(
        phone: phone,
      );
      _isLoggedIn = true;
      await _saveUserLocally();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      _setError(_firebaseErrorToArabic(e));
      return false;
    } catch (e) {
      _setError('حدث خطأ في إنشاء الحساب: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // تسجيل الدخول مع Google (placeholder حتى إضافة google_sign_in)
  Future<bool> loginWithGoogle() async {
    try {
      _setLoading(true);
      _setError('خدمة Google Sign In غير مفعلة بعد.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // تسجيل الخروج
  Future<void> logout() async {
    try {
      _setLoading(true);
      await _auth.signOut();
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

  UserModel _mapFirebaseUserToUserModel(fb.User user) {
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
        return 'كلمة المرور ضعيفة';
      case 'operation-not-allowed':
        return 'العملية غير مسموح بها';
      default:
        return 'خطأ في المصادقة: ${e.message ?? e.code}';
    }
  }
} 