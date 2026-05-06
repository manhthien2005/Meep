---
trigger: always_on
---

# Dev Code Standards — Walking Skeleton Pattern

Meep dùng **Walking Skeleton**: Leader tạo "bộ khung chạy được" trước mỗi sprint,
FE và BE điền vào song song. App phải compile và chạy được ở mọi commit.

## Vai trò trong pattern

| Vai trò | Làm gì | Không làm gì |
|---|---|---|
| **Leader** | Define freezed models + abstract interfaces + stub providers + wire router | Implement Firebase / UI screens |
| **KhoaLND (BE)** | Implement Firebase repositories + controllers | Tự define model mới / đổi interface |
| **HanDHG / NganTNK (FE)** | Implement UI screens dùng typed mock data | Call Firebase trực tiếp / tự bịa model |

## 3 rule không thương lượng

### 1. Skeleton rule — App luôn chạy được

Mọi commit phải compile sạch và app chạy được. Stub trả mock hoặc throw `UnimplementedError` — không để broken import, không comment-out code để bypass lỗi.

```dart
// ✅ Stub đúng cách
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => throw UnimplementedError(
  'wire FirebaseAuthRepository in main.dart',
);

// ❌ Không để thế này
// import 'package:meep/features/auth/data/firebase_auth_repository.dart';
```

### 2. Typed mock rule — FE dùng đúng freezed model

FE mock data bằng đúng type do leader define. Không tự bịa `Map<String, dynamic>`.
Dart compiler sẽ bắt mismatch tại compile time — không phải runtime.

```dart
// ✅ Typed mock
final mockUser = UserProfile(
  uid: 'mock-uid',
  displayName: 'Thiên',
  username: 'thienpdm',
  createdAt: DateTime.now(),
);

// ❌ Bịa Map — compiler không bắt được mismatch
final mockUser = {'name': 'Thiên', 'avatar': 'url'};
```

### 3. Freeze-before-FE rule — Model merge vào develop trước

Models (freezed) và interfaces (abstract class) phải có trên `develop` trước khi
FE bắt đầu implement screen đó. FE không tự define model.

Thứ tự bắt buộc mỗi feature:
```
Leader: define models + interfaces → merge vào develop
    ↓
FE và BE start song song (pull từ develop)
    ↓
Leader: wire real implementation trong main.dart
```

## Ownership principle

Mọi file agent tạo hoặc sửa đều là **code của dev đó**. Đọc và hiểu trước khi commit.
Không accept file chưa đọc chỉ vì "agent viết chắc đúng rồi".

Khi nhận task: đọc file liên quan trước, hiểu context, rồi mới prompt agent.

## Stub/placeholder standard

Mọi stub phải có TODO chỉ rõ ai làm, task nào:

```dart
// TODO(T8/HanDHG): implement IntroPage theo Figma — Trang giới thiệu
// TODO(T2/KhoaLND): implement FirebaseAuthRepository — xem docs/specs/auth.md
```

Format: `// TODO(<task-id>/<DevName>): <mô tả ngắn>`

TODO không có `<task-id>/<DevName>` = **không hợp lệ** — sẽ bị flag trong review.

## Khi nào hỏi leader trước khi làm

Bắt buộc hỏi leader (không tự quyết) khi:

- Muốn thêm field mới vào freezed model ảnh hưởng nhiều dev
- Muốn thay đổi signature của abstract interface
- Muốn thêm Firestore collection / index mới
- Muốn thêm dependency (pub package) vào `pubspec.yaml`
- Phát hiện contract không khớp với Figma (report, không tự sửa)

## Màn hình phức tạp — leader define thêm trước khi FE mock

Một số patterns Figma không hiện rõ, cần leader quyết định trước:

| Màn hình | Cần leader quyết định thêm |
|---|---|
| Feed, Space | Fan-out vs query strategy → Firestore collection path |
| Reaction | Optimistic UI contract → error rollback behavior |
| Pagination | Cursor strategy → `startAfterDocument` field trong model |

Với các màn hình này: FE hỏi leader 30 phút trước khi bắt đầu mock.
Với Auth, Profile, Diary, Camera UI: freezed model là đủ, FE start luôn.
