# نظام الدردشة - Firebase Realtime Database

## نظرة عامة

تم تطوير نظام الدردشة الكامل باستخدام Firebase Realtime Database لتوفير تجربة محادثة فورية ومتطورة بين المستخدمين والحرفيين.

## المميزات

### ✅ المميزات المكتملة
- **محادثات فورية**: استخدام Firebase Realtime Database للرسائل الفورية
- **واجهة مستخدم حديثة**: تصميم جميل ومتجاوب مع جميع أحجام الشاشات
- **إدارة المحادثات**: إنشاء وحذف وإدارة غرف الدردشة
- **عرض الرسائل**: فقاعات رسائل جميلة مع دعم النصوص والصور
- **حالة الرسائل**: عرض حالة الإرسال والقراءة
- **الوقت والتاريخ**: عرض توقيت الرسائل بشكل ذكي
- **الترجمة**: دعم كامل للعربية والإنجليزية
- **إدارة الحالة**: استخدام Provider لإدارة حالة التطبيق

### 🔄 المميزات المخططة
- **الرسائل الصوتية**: تسجيل وإرسال رسائل صوتية
- **مشاركة الموقع**: إرسال الموقع الحالي
- **رفع الملفات**: إرسال ملفات مختلفة
- **الإشعارات**: إشعارات فورية للرسائل الجديدة
- **البحث في الرسائل**: البحث في محتوى الرسائل
- **حظر المستخدمين**: إمكانية حظر المستخدمين
- **الحالة المتصلة**: عرض حالة الاتصال للمستخدمين

## البنية التقنية

### النماذج (Models)
```
lib/Models/chat_model.dart
├── ChatMessage: نموذج الرسالة
├── ChatRoom: نموذج غرفة الدردشة
└── MessageType: أنواع الرسائل (نص، صورة، ملف، موقع)
```

### الخدمات (Services)
```
lib/services/chat_service.dart
├── إدارة الاتصال بـ Firebase Realtime Database
├── إرسال واستقبال الرسائل
├── إدارة غرف الدردشة
└── تحديث حالة الرسائل
```

### مزودي الحالة (Providers)
```
lib/providers/chat_provider.dart
├── إدارة حالة الدردشة
├── تحميل المحادثات والرسائل
├── إرسال الرسائل
└── إدارة الأخطاء والتحميل
```

### واجهات المستخدم (UI)
```
lib/Modules/Chat/
├── chat_page.dart: صفحة قائمة المحادثات
├── chat_room_screen.dart: شاشة غرفة الدردشة
└── widgets/
    ├── chat_room_tile.dart: عنصر غرفة الدردشة
    ├── message_bubble.dart: فقاعة الرسالة
    └── chat_input.dart: إدخال الدردشة
```

## قاعدة البيانات

### Firebase Realtime Database Structure
```json
{
  "chat_rooms": {
    "user1_user2": {
      "id": "user1_user2",
      "participant1Id": "user1",
      "participant2Id": "user2",
      "lastMessage": "آخر رسالة",
      "lastMessageTime": 1640995200000,
      "hasUnreadMessages": true,
      "unreadCount": 3,
      "participant1Name": "اسم المستخدم الأول",
      "participant2Name": "اسم المستخدم الثاني"
    }
  },
  "messages": {
    "message_id": {
      "id": "message_id",
      "senderId": "user1",
      "receiverId": "user2",
      "content": "محتوى الرسالة",
      "imageUrl": "رابط الصورة (اختياري)",
      "timestamp": 1640995200000,
      "isRead": false,
      "type": "text"
    }
  }
}
```

## الاستخدام

### 1. تهيئة نظام الدردشة
```dart
// في main.dart
ChangeNotifierProvider<ChatProvider>(create: (_) => ChatProvider())
```

### 2. فتح صفحة المحادثات
```dart
context.push('/chat');
```

### 3. إنشاء محادثة جديدة
```dart
final chatProvider = Provider.of<ChatProvider>(context, listen: false);
await chatProvider.createChatRoom(otherUserId);
```

### 4. إرسال رسالة
```dart
await chatProvider.sendMessage('محتوى الرسالة');
```

### 5. فتح غرفة الدردشة
```dart
await chatProvider.openChatRoom(roomId);
context.push('/chat-room');
```

## التكوين

### Firebase Realtime Database Rules
```json
{
  "rules": {
    "chat_rooms": {
      "$roomId": {
        ".read": "auth != null && (data.child('participant1Id').val() == auth.uid || data.child('participant2Id').val() == auth.uid)",
        ".write": "auth != null && (data.child('participant1Id').val() == auth.uid || data.child('participant2Id').val() == auth.uid)"
      }
    },
    "messages": {
      "$messageId": {
        ".read": "auth != null && (data.child('senderId').val() == auth.uid || data.child('receiverId').val() == auth.uid)",
        ".write": "auth != null && data.child('senderId').val() == auth.uid"
      }
    }
  }
}
```

## الأمان

- **المصادقة**: يجب تسجيل الدخول للوصول للمحادثات
- **الصلاحيات**: يمكن للمستخدمين الوصول فقط لمحادثاتهم
- **التحقق**: التحقق من هوية المرسل والمستقبل
- **التشفير**: تشفير البيانات في النقل

## الأداء

- **Streaming**: استخدام Streams للرسائل الفورية
- **Caching**: تخزين مؤقت للرسائل والمحادثات
- **Lazy Loading**: تحميل الرسائل عند الحاجة
- **Optimization**: تحسين استعلامات قاعدة البيانات

## التطوير المستقبلي

### المرحلة التالية
1. **الرسائل الصوتية**: إضافة دعم الرسائل الصوتية
2. **الإشعارات**: إشعارات فورية للرسائل الجديدة
3. **البحث**: البحث في محتوى الرسائل
4. **المرفقات**: دعم أنواع ملفات أكثر

### التحسينات المخططة
1. **التشفير**: تشفير الرسائل من طرف إلى طرف
2. **النسخ الاحتياطي**: نسخ احتياطي للرسائل
3. **الأرشفة**: أرشفة المحادثات القديمة
4. **التصدير**: تصدير المحادثات

## الدعم

لأي استفسارات أو مشاكل تقنية، يرجى التواصل مع فريق التطوير.

---

**تم التطوير بواسطة فريق رابط الحرف**  
**الإصدار**: 1.0.0  
**التاريخ**: 2025 