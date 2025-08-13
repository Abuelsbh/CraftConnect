import 'dart:convert';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/Font/font_provider.dart';
import '../core/Theme/theme_model.dart';
import '../Models/user_model.dart';

class SharedPref{

	static SharedPreferences get prefs => GetIt.instance.get<SharedPreferences>();
	static const String _language = "language_code";
	static const String _currentUserKey = "currentUser";
	static const String _themeKey = "theme";
	static const String _fontSizeKey = "font_size";
	static const String _fontFamilyKey = "font_family";



	static UserModel? getCurrentUser(){
		try{
			final raw = prefs.getString(_currentUserKey);
			if(raw == null) return null;
			final decoded = json.decode(raw);
			if(decoded is Map<String,dynamic>){
				return UserModel.fromJson(decoded);
			}
			return null;
		}catch(e){
			// تجنب كسر التشغيل بسبب أخطاء طبقة Pigeon/المنصة
			return null;
		}
	}

	static Future<bool> saveCurrentUser({required UserModel user})async{
		try{
			return await prefs.setString(_currentUserKey, json.encode(user.toJson()));
		}catch(e){
			// تجنب إسقاط التطبيق إذا فشل التخزين
			return false;
		}
	}

	static bool isLogin()=> prefs.getString(_currentUserKey) != null;

	static Future<void> logout() async{
		try{
			await prefs.remove(_currentUserKey);
		}catch(_){
			// تجاهل
		}
	}

	static ThemeModel? getTheme(){
		try{
			final raw = prefs.getString(_themeKey);
			if(raw == null) return null;
			return ThemeModel.fromJson(json.decode(raw));
		}catch(_){
			return null;
		}
	}
	static Future<void> setTheme({required ThemeModel theme})async{
		try{
			await prefs.setString(_themeKey,json.encode(theme.toJson()));
		}catch(_){
			// تجاهل
		}
	}

	static double? getFontSizeScale(){
		try{
			return prefs.getDouble(_fontSizeKey);
		}catch(_){
			return null;
		}
	}
	static Future<void> setFontSizeScale({required double fontSizeScale})async{
		try{
			await prefs.setDouble(_fontSizeKey,fontSizeScale);
		}catch(_){
			// تجاهل
		}
	}


	static Future setFontFamily({required FontFamilyTypes fontFamily}) async{
		try{
			return await prefs.setInt(_fontFamilyKey, fontFamily.index);
		}catch(_){
			return false;
		}
	}
	static FontFamilyTypes?  getFontFamily(){
		try{
			final v = prefs.getInt(_fontFamilyKey);
			return v == null?null:FontFamilyTypes.values[v];
		}catch(_){
			return null;
		}
	}


	static String? getLanguage() {
		try{
			return prefs.getString(_language);
		}catch(_){
			return null;
		}
	}

	static Future<void> setLanguage({required String lang})async{
		try{
			await prefs.setString(_language,lang);
		}catch(_){
			// تجاهل
		}
	}



}