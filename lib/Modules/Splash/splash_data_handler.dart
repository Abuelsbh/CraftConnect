import 'package:dartz/dartz.dart';
import 'package:fast_http/core/API/generic_request.dart';
import 'package:fast_http/core/API/request_method.dart';
import 'package:fast_http/core/Error/exceptions.dart';
import 'package:fast_http/core/Error/failures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Utilities/api_end_point.dart';
import '../../Models/user_model.dart';
import '../../Models/artisan_model.dart';
import '../../Models/review_model.dart';

class SplashDataHandler{
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static Future<Either<Failure,UserModel>> getCurrentUser()async{
    try {
      UserModel response = await GenericRequest<UserModel>(
        method: RequestApi.get(url: APIEndPoint.test),
        fromMap: (data)=> UserModel.fromJson(data),
      ).getObject();
      return Right(response);
    } on ServerException catch (failure) {
      return Left(ServerFailure(failure.errorMessageModel));
    }
  }

  // إضافة بيانات الحرفيين إلى Firebase
  static Future<void> addSampleArtisansToFirebase() async {
    try {
      print('🚀 بدء إضافة بيانات الحرفيين إلى Firebase...');
      
      final List<Map<String, dynamic>> artisansData = [
        {
          "id": "artisan_001",
          "name": "محمد أحمد السعيد",
          "email": "mohamed.ahmed@example.com",
          "phone": "+966501234567",
          "profileImageUrl": "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_001%2Fprofile.jpg?alt=media",
          "craftType": "carpenter",
          "yearsOfExperience": 12,
          "description": "نجار محترف متخصص في صناعة الأثاث المنزلي والمكتبي بأعلى معايير الجودة. خبرة 12 سنة في مجال النجارة مع التركيز على التصاميم العصرية والكلاسيكية. أعمل على جميع أنواع الأخشاب الطبيعية والصناعية.",
          "latitude": 24.7136,
          "longitude": 46.6753,
          "address": "حي الملز، شارع الأمير فيصل، الرياض، المملكة العربية السعودية",
          "rating": 4.8,
          "reviewCount": 156,
          "galleryImages": [
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_001%2Fgallery%2Fwork1.jpg?alt=media",
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_001%2Fgallery%2Fwork2.jpg?alt=media",
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_001%2Fgallery%2Fwork3.jpg?alt=media",
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_001%2Fgallery%2Fwork4.jpg?alt=media"
          ],
          "isAvailable": true,
          "createdAt": "2024-01-15T10:30:00.000Z",
          "updatedAt": "2024-12-19T14:20:00.000Z"
        },
        {
          "id": "artisan_002",
          "name": "سعد محمد العتيبي",
          "email": "saad.mohamed@example.com",
          "phone": "+966509876543",
          "profileImageUrl": "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_002%2Fprofile.jpg?alt=media",
          "craftType": "electrician",
          "yearsOfExperience": 8,
          "description": "كهربائي معتمد لجميع أنواع التمديدات والصيانة الكهربائية. متخصص في الأنظمة الذكية والطاقة الشمسية. أعمل مع الشركات والمنازل مع ضمان شامل على جميع الأعمال.",
          "latitude": 24.7200,
          "longitude": 46.6800,
          "address": "حي العليا، طريق الملك عبدالعزيز، الرياض، المملكة العربية السعودية",
          "rating": 4.9,
          "reviewCount": 203,
          "galleryImages": [
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_002%2Fgallery%2Fwork1.jpg?alt=media",
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_002%2Fgallery%2Fwork2.jpg?alt=media",
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_002%2Fgallery%2Fwork3.jpg?alt=media"
          ],
          "isAvailable": true,
          "createdAt": "2024-02-20T09:15:00.000Z",
          "updatedAt": "2024-12-19T15:30:00.000Z"
        },
        {
          "id": "artisan_003",
          "name": "عبدالله سالم القحطاني",
          "email": "abdullah.salem@example.com",
          "phone": "+966555123456",
          "profileImageUrl": "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_003%2Fprofile.jpg?alt=media",
          "craftType": "plumber",
          "yearsOfExperience": 6,
          "description": "سباك ماهر متخصص في تسليك المجاري وتمديدات المياه والصحي وإصلاح التسريبات. أعمل على جميع أنواع الأنابيب والمواسير مع ضمان الجودة.",
          "latitude": 24.7100,
          "longitude": 46.6700,
          "address": "حي السليمانية، شارع التخصصي، الرياض، المملكة العربية السعودية",
          "rating": 4.6,
          "reviewCount": 89,
          "galleryImages": [
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_003%2Fgallery%2Fwork1.jpg?alt=media",
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_003%2Fgallery%2Fwork2.jpg?alt=media"
          ],
          "isAvailable": true,
          "createdAt": "2024-03-10T11:45:00.000Z",
          "updatedAt": "2024-12-19T16:45:00.000Z"
        },
        {
          "id": "artisan_004",
          "name": "خالد العتيبي الصباغ",
          "email": "khalid.alotaibi@example.com",
          "phone": "+966556789012",
          "profileImageUrl": "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_004%2Fprofile.jpg?alt=media",
          "craftType": "painter",
          "yearsOfExperience": 10,
          "description": "صباغ محترف متخصص في الدهانات الداخلية والخارجية بأحدث التقنيات والألوان العصرية. أعمل على جميع أنواع الأسطح مع ضمان النظافة والدقة.",
          "latitude": 24.7080,
          "longitude": 46.6850,
          "address": "حي الربوة، شارع العروبة، الرياض، المملكة العربية السعودية",
          "rating": 4.7,
          "reviewCount": 134,
          "galleryImages": [
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_004%2Fgallery%2Fwork1.jpg?alt=media",
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_004%2Fgallery%2Fwork2.jpg?alt=media",
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_004%2Fgallery%2Fwork3.jpg?alt=media",
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_004%2Fgallery%2Fwork4.jpg?alt=media",
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_004%2Fgallery%2Fwork5.jpg?alt=media"
          ],
          "isAvailable": true,
          "createdAt": "2024-01-25T08:20:00.000Z",
          "updatedAt": "2024-12-19T17:15:00.000Z"
        },
        {
          "id": "artisan_005",
          "name": "أحمد القحطاني الميكانيكي",
          "email": "ahmed.alqhtani@example.com",
          "phone": "+966554321098",
          "profileImageUrl": "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_005%2Fprofile.jpg?alt=media",
          "craftType": "mechanic",
          "yearsOfExperience": 15,
          "description": "ميكانيكي سيارات متخصص في جميع أنواع السيارات - صيانة وإصلاح وقطع غيار أصلية. خبرة 15 سنة في مجال السيارات مع ضمان شامل.",
          "latitude": 24.7250,
          "longitude": 46.6600,
          "address": "حي الشفا، شارع الأمير سلمان، الرياض، المملكة العربية السعودية",
          "rating": 4.9,
          "reviewCount": 298,
          "galleryImages": [
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_005%2Fgallery%2Fwork1.jpg?alt=media",
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_005%2Fgallery%2Fwork2.jpg?alt=media",
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_005%2Fgallery%2Fwork3.jpg?alt=media"
          ],
          "isAvailable": true,
          "createdAt": "2024-02-05T12:30:00.000Z",
          "updatedAt": "2024-12-19T18:00:00.000Z"
        },
        {
          "id": "artisan_006",
          "name": "فيصل الدوسري النجار",
          "email": "faisal.aldossary@example.com",
          "phone": "+966558888999",
          "profileImageUrl": "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_006%2Fprofile.jpg?alt=media",
          "craftType": "carpenter",
          "yearsOfExperience": 5,
          "description": "نجار متمرس في أعمال الديكورات الخشبية وتفصيل الخزائن والأبواب حسب الطلب. متخصص في التصاميم العصرية والكلاسيكية.",
          "latitude": 24.7300,
          "longitude": 46.6900,
          "address": "حي النخيل، شارع صلاح الدين، الرياض، المملكة العربية السعودية",
          "rating": 4.5,
          "reviewCount": 67,
          "galleryImages": [
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_006%2Fgallery%2Fwork1.jpg?alt=media",
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_006%2Fgallery%2Fwork2.jpg?alt=media"
          ],
          "isAvailable": true,
          "createdAt": "2024-04-15T10:00:00.000Z",
          "updatedAt": "2024-12-19T19:30:00.000Z"
        },
        {
          "id": "artisan_007",
          "name": "ماجد السعدون الكهربائي",
          "email": "majed.alsadoun@example.com",
          "phone": "+966557777888",
          "profileImageUrl": "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_007%2Fprofile.jpg?alt=media",
          "craftType": "electrician",
          "yearsOfExperience": 9,
          "description": "كهربائي معتمد - تركيب وصيانة الأنظمة الكهربائية الذكية والطاقة الشمسية. متخصص في أنظمة الأمان والمراقبة.",
          "latitude": 24.7050,
          "longitude": 46.6950,
          "address": "حي الورود، شارع الوشم، الرياض، المملكة العربية السعودية",
          "rating": 4.7,
          "reviewCount": 123,
          "galleryImages": [
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_007%2Fgallery%2Fwork1.jpg?alt=media",
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_007%2Fgallery%2Fwork2.jpg?alt=media",
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_007%2Fgallery%2Fwork3.jpg?alt=media"
          ],
          "isAvailable": true,
          "createdAt": "2024-03-20T14:15:00.000Z",
          "updatedAt": "2024-12-19T20:15:00.000Z"
        },
        {
          "id": "artisan_008",
          "name": "علي الحمادي السباك",
          "email": "ali.alhamadi@example.com",
          "phone": "+966553333444",
          "profileImageUrl": "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_008%2Fprofile.jpg?alt=media",
          "craftType": "plumber",
          "yearsOfExperience": 7,
          "description": "سباك محترف متخصص في تمديدات المياه والصحي وإصلاح التسريبات. أعمل على جميع أنواع الأنابيب مع ضمان الجودة.",
          "latitude": 24.7150,
          "longitude": 46.6650,
          "address": "حي الشميسي، شارع الملك فهد، الرياض، المملكة العربية السعودية",
          "rating": 4.4,
          "reviewCount": 78,
          "galleryImages": [
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_008%2Fgallery%2Fwork1.jpg?alt=media",
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_008%2Fgallery%2Fwork2.jpg?alt=media"
          ],
          "isAvailable": true,
          "createdAt": "2024-05-10T09:30:00.000Z",
          "updatedAt": "2024-12-19T21:00:00.000Z"
        },
        {
          "id": "artisan_009",
          "name": "يوسف المطيري الصباغ",
          "email": "yousef.almutairi@example.com",
          "phone": "+966552222333",
          "profileImageUrl": "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_009%2Fprofile.jpg?alt=media",
          "craftType": "painter",
          "yearsOfExperience": 8,
          "description": "صباغ ماهر متخصص في الدهانات الداخلية والخارجية. أعمل على جميع أنواع الأسطح مع أحدث التقنيات والألوان.",
          "latitude": 24.7180,
          "longitude": 46.6880,
          "address": "حي النزهة، شارع الملك عبدالله، الرياض، المملكة العربية السعودية",
          "rating": 4.6,
          "reviewCount": 95,
          "galleryImages": [
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_009%2Fgallery%2Fwork1.jpg?alt=media",
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_009%2Fgallery%2Fwork2.jpg?alt=media",
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_009%2Fgallery%2Fwork3.jpg?alt=media"
          ],
          "isAvailable": true,
          "createdAt": "2024-06-05T11:20:00.000Z",
          "updatedAt": "2024-12-19T22:30:00.000Z"
        },
        {
          "id": "artisan_010",
          "name": "عبدالرحمن الشمري الميكانيكي",
          "email": "abdulrahman.alshamri@example.com",
          "phone": "+966551111222",
          "profileImageUrl": "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_010%2Fprofile.jpg?alt=media",
          "craftType": "mechanic",
          "yearsOfExperience": 12,
          "description": "ميكانيكي محترف متخصص في صيانة وإصلاح السيارات. خبرة 12 سنة في مجال السيارات مع ضمان شامل على جميع الأعمال.",
          "latitude": 24.7220,
          "longitude": 46.6620,
          "address": "حي الملقا، شارع الأمير محمد، الرياض، المملكة العربية السعودية",
          "rating": 4.8,
          "reviewCount": 167,
          "galleryImages": [
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_010%2Fgallery%2Fwork1.jpg?alt=media",
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_010%2Fgallery%2Fwork2.jpg?alt=media",
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_010%2Fgallery%2Fwork3.jpg?alt=media",
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/artisans%2Fartisan_010%2Fgallery%2Fwork4.jpg?alt=media"
          ],
          "isAvailable": true,
          "createdAt": "2024-02-15T13:45:00.000Z",
          "updatedAt": "2024-12-19T23:15:00.000Z"
        }
      ];

      // إضافة الحرفيين إلى Firebase
      for (final artisanData in artisansData) {
        await _firestore.collection('artisans').doc(artisanData['id']).set(artisanData);
        print('✅ تم إضافة الحرفي: ${artisanData['name']}');
      }

      print('🎉 تم إضافة جميع الحرفيين بنجاح!');
    } catch (e) {
      print('❌ خطأ في إضافة الحرفيين: $e');
    }
  }

  // إضافة بيانات التقييمات إلى Firebase
  static Future<void> addSampleReviewsToFirebase() async {
    try {
      print('🚀 بدء إضافة بيانات التقييمات إلى Firebase...');
      
      final List<Map<String, dynamic>> reviewsData = [
        {
          "id": "review_001",
          "artisanId": "artisan_001",
          "userId": "user_001",
          "userName": "أحمد محمد",
          "userProfileImage": "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/users%2Fuser_001%2Fprofile.jpg?alt=media",
          "rating": 5.0,
          "comment": "عمل ممتاز وجودة عالية. أنصح بالتعامل معه بشدة. قام بعمل خزانة مطبخ رائعة وبسعر معقول.",
          "images": [
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/reviews%2Freview_001%2Fimage1.jpg?alt=media"
          ],
          "createdAt": "2024-12-15T10:30:00.000Z",
          "updatedAt": "2024-12-15T10:30:00.000Z"
        },
        {
          "id": "review_002",
          "artisanId": "artisan_001",
          "userId": "user_002",
          "userName": "فاطمة علي",
          "userProfileImage": "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/users%2Fuser_002%2Fprofile.jpg?alt=media",
          "rating": 4.5,
          "comment": "حرفي محترف ومخلص في عمله. سأتعامل معه مرة أخرى. قام بتصميم طاولة طعام جميلة.",
          "images": [],
          "createdAt": "2024-12-10T14:20:00.000Z",
          "updatedAt": "2024-12-10T14:20:00.000Z"
        },
        {
          "id": "review_003",
          "artisanId": "artisan_002",
          "userId": "user_003",
          "userName": "سارة أحمد",
          "userProfileImage": "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/users%2Fuser_003%2Fprofile.jpg?alt=media",
          "rating": 5.0,
          "comment": "كهربائي ممتاز ومحترف. قام بإصلاح جميع المشاكل الكهربائية في المنزل بسرعة ودقة.",
          "images": [],
          "createdAt": "2024-12-18T09:15:00.000Z",
          "updatedAt": "2024-12-18T09:15:00.000Z"
        },
        {
          "id": "review_004",
          "artisanId": "artisan_003",
          "userId": "user_004",
          "userName": "عبدالله سالم",
          "userProfileImage": "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/users%2Fuser_004%2Fprofile.jpg?alt=media",
          "rating": 4.6,
          "comment": "سباك ماهر ومحترف. قام بإصلاح مشكلة تسريب المياه بسرعة.",
          "images": [],
          "createdAt": "2024-12-16T13:20:00.000Z",
          "updatedAt": "2024-12-16T13:20:00.000Z"
        },
        {
          "id": "review_005",
          "artisanId": "artisan_004",
          "userId": "user_005",
          "userName": "نورا خالد",
          "userProfileImage": "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/users%2Fuser_005%2Fprofile.jpg?alt=media",
          "rating": 4.7,
          "comment": "صباغ ممتاز. قام بطلاء المنزل بألوان جميلة ونظيفة.",
          "images": [
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/reviews%2Freview_005%2Fimage1.jpg?alt=media",
            "https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/reviews%2Freview_005%2Fimage2.jpg?alt=media"
          ],
          "createdAt": "2024-12-14T15:40:00.000Z",
          "updatedAt": "2024-12-14T15:40:00.000Z"
        }
      ];

      // إضافة التقييمات إلى Firebase
      for (final reviewData in reviewsData) {
        await _firestore.collection('reviews').doc(reviewData['id']).set(reviewData);
        print('✅ تم إضافة التقييم: ${reviewData['id']}');
      }

      print('🎉 تم إضافة جميع التقييمات بنجاح!');
    } catch (e) {
      print('❌ خطأ في إضافة التقييمات: $e');
    }
  }

  // دالة رئيسية لإضافة جميع البيانات
  static Future<void> addAllSampleDataToFirebase() async {
    try {
      print('🚀 بدء إضافة جميع البيانات إلى Firebase...');
      
      await addSampleArtisansToFirebase();
      await addSampleReviewsToFirebase();
      
      print('🎉 تم إضافة جميع البيانات بنجاح!');
    } catch (e) {
      print('❌ خطأ في إضافة البيانات: $e');
    }
  }

  // دالة للتحقق من وجود البيانات
  static Future<bool> checkIfDataExists() async {
    try {
      final artisansSnapshot = await _firestore.collection('artisans').limit(1).get();
      return artisansSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ خطأ في التحقق من البيانات: $e');
      return false;
    }
  }
}