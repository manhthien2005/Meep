# MỤC LỤC

| Mục | Tiêu đề | Trang |
|---|---|---|
| **1** | **Đặt vấn đề** | … |
| 1.1 | Mục đích, yêu cầu dự án | … |
| 1.2 | Xác định phạm vi hệ thống | … |
| 1.2.1 | Kiến trúc hệ thống | … |
| 1.2.2 | Phạm vi chức năng | … |
| 1.2.3 | Phạm vi triển khai | … |
| 1.3 | Khảo sát các hệ thống tương tự | … |
| 1.3.1 | Các ứng dụng cùng phân khúc | … |
| 1.3.2 | Định vị khác biệt của Meep | … |
| **2** | **Cơ sở lý thuyết** | … |
| 2.1 | Khái niệm về Lập trình Mobile | … |
| 2.1.1 | Lập trình theo hướng Native | … |
| 2.1.2 | Lập trình theo hướng Hybrid | … |
| 2.1.3 | Lập trình theo hướng Cross-platform | … |
| 2.2 | Khái niệm và lý do chọn Flutter | … |
| 2.3 | Khái niệm và lý do chọn Firebase | … |
| 2.4 | Kiến trúc ứng dụng theo mô hình ba lớp với Riverpod | … |
| 2.5 | Home-screen Widget trên nền tảng Android | … |
| **3** | **Mô tả các yêu cầu chức năng của hệ thống** | … |
| 3.1 | Chức năng Xác thực người dùng | … |
| 3.2 | Chức năng Quản lý bạn bè | … |
| 3.3 | Chức năng Chụp ảnh và đăng bài | … |
| 3.4 | Chức năng Bảng tin (Feed) | … |
| 3.5 | Chức năng Thả cảm xúc (Reaction) | … |
| 3.6 | Chức năng Thông báo đẩy (Notification) | … |
| 3.7 | Chức năng Hồ sơ cá nhân | … |
| 3.8 | Chức năng Không gian chung (Space) | … |
| 3.9 | Chức năng Nhật ký (Diary) | … |
| 3.10 | Chức năng Trò chuyện (Chat) | … |
| 3.11 | Chức năng Home-screen Widget Android | … |
| 3.12 | Chức năng Cài đặt (Settings) | … |
| 3.13 | Chức năng Streak / Kỷ niệm | … |
| **4** | **Cơ sở dữ liệu** | … |
| 4.1 | Tổng quan mô hình dữ liệu Firestore | … |
| 4.2 | Collection `users` | … |
| 4.3 | Collection `usernames` | … |
| 4.4 | Collection `posts` | … |
| 4.5 | Collection `friendships` | … |
| 4.6 | Collection `friend_requests` | … |
| 4.7 | Collection `blocks` | … |
| 4.8 | Collection `spaces` | … |
| 4.9 | Collection `space_members` | … |
| 4.10 | Collection `conversations` | … |
| 4.11 | Collection `diary` | … |
| **5** | **Hiện thực ứng dụng** | … |
| 5.1 | Màn hình Khởi động và Xác thực người dùng | … |
| 5.2 | Màn hình Chụp ảnh và đăng bài | … |
| 5.3 | Màn hình Bảng tin và xem dạng lưới | … |
| 5.4 | Màn hình Quản lý bạn bè | … |
| 5.5 | Màn hình Thả cảm xúc | … |
| 5.6 | Màn hình Thông báo | … |
| 5.7 | Màn hình Hồ sơ cá nhân | … |
| 5.8 | Màn hình Không gian chung | … |
| 5.9 | Màn hình Nhật ký | … |
| 5.10 | Màn hình Trò chuyện | … |
| 5.11 | Home-screen Widget trên Android | … |
| 5.12 | Màn hình Cài đặt | … |
| **6** | **Kết luận** | … |
| 6.1 | Kết quả đạt được | … |
| 6.2 | Hạn chế của hệ thống | … |
| 6.3 | Hướng phát triển trong tương lai | … |
| **PL** | **PHỤ LỤC** | … |
| A | Bảng phân công công việc | … |
| B | Bằng chứng làm việc nhóm | … |
| C | Mã nguồn dự án | … |

---

# MỤC LỤC HÌNH ẢNH

> *Ghi chú: Danh sách hình bên dưới phản ánh các minh họa dự kiến cho từng chương. Số thứ tự hình và số trang sẽ được cập nhật chính xác sau khi hoàn thiện wireframe (chương 3), sơ đồ cơ sở dữ liệu (chương 4) và ảnh chụp màn hình thực tế (chương 5).*

| Hình | Tên | Trang |
|---|---|---|
| Hình 1 | Sơ đồ kiến trúc tổng quan của hệ thống Meep | … |
| Hình 2 | Mô hình kiến trúc ba lớp `data` – `application` – `presentation` | … |
| Hình 3 | Cơ chế hoạt động của Home-screen Widget trên Android | … |
| Hình 4 | Mô hình Use Case tổng quát của người dùng | … |
| Hình 5 | Wireframe chức năng Xác thực người dùng | … |
| Hình 6 | Wireframe chức năng Quản lý bạn bè | … |
| Hình 7 | Wireframe chức năng Chụp ảnh và đăng bài | … |
| Hình 8 | Wireframe chức năng Bảng tin | … |
| Hình 9 | Wireframe chức năng Thả cảm xúc | … |
| Hình 10 | Wireframe chức năng Thông báo đẩy | … |
| Hình 11 | Wireframe chức năng Hồ sơ cá nhân | … |
| Hình 12 | Wireframe chức năng Không gian chung | … |
| Hình 13 | Wireframe chức năng Nhật ký | … |
| Hình 14 | Wireframe chức năng Trò chuyện | … |
| Hình 15 | Wireframe chức năng Home-screen Widget | … |
| Hình 16 | Wireframe chức năng Cài đặt | … |
| Hình 17 | Wireframe chức năng Streak / Kỷ niệm | … |
| Hình 18 | Sơ đồ quan hệ giữa các collection trong Firestore | … |
| Hình 19 | Giao diện màn hình Khởi động và Xác thực người dùng | … |
| Hình 20 | Giao diện màn hình Chụp ảnh và đăng bài | … |
| Hình 21 | Giao diện màn hình Bảng tin và xem dạng lưới | … |
| Hình 22 | Giao diện màn hình Quản lý bạn bè | … |
| Hình 23 | Giao diện màn hình Thả cảm xúc | … |
| Hình 24 | Giao diện màn hình Thông báo | … |
| Hình 25 | Giao diện màn hình Hồ sơ cá nhân | … |
| Hình 26 | Giao diện màn hình Không gian chung | … |
| Hình 27 | Giao diện màn hình Nhật ký | … |
| Hình 28 | Giao diện màn hình Trò chuyện | … |
| Hình 29 | Giao diện Home-screen Widget trên Android | … |
| Hình 30 | Giao diện màn hình Cài đặt | … |
| Hình 31 | Hình ảnh buổi họp trực tiếp của nhóm thực hiện đề tài (1) | … |
| Hình 32 | Hình ảnh buổi họp trực tiếp của nhóm thực hiện đề tài (2) | … |

---

# MỤC LỤC BẢNG BIỂU

| Bảng | Tên | Trang |
|---|---|---|
| Bảng 1.1 | So sánh tiêu chí định vị của Meep với Locket và BeReal | … |
| Bảng 2.1 | So sánh các tiêu chí kỹ thuật giữa Flutter và React Native | … |
| Bảng 2.2 | So sánh giữa Firebase (BaaS) và phương án Backend truyền thống | … |
| Bảng 3.1 | Các bước thực hiện chức năng Đăng ký tài khoản bằng email và mật khẩu | … |
| Bảng 3.2 | Các bước thực hiện chức năng Đăng ký hoặc đăng nhập bằng tài khoản Google | … |
| Bảng 3.3 | Các bước thực hiện chức năng Đăng nhập bằng email và mật khẩu | … |
| Bảng 3.4 | Các bước thực hiện chức năng Khôi phục mật khẩu | … |
| Bảng 3.5 | Các bước thực hiện chức năng Mở và xem danh sách bạn bè | … |
| Bảng 3.6 | Các bước thực hiện chức năng Tìm kiếm và gửi lời mời kết bạn | … |
| Bảng 3.7 | Các bước thực hiện chức năng Xử lý lời mời kết bạn nhận được | … |
| Bảng 3.8 | Các bước thực hiện chức năng Hủy kết bạn | … |
| Bảng 3.9 | Các bước thực hiện chức năng Chia sẻ liên kết mời sử dụng ứng dụng | … |
| Bảng 3.10 | Các bước thực hiện chức năng Chụp ảnh từ camera của thiết bị | … |
| Bảng 3.11 | Các bước thực hiện chức năng Đăng bài kể từ màn hình Xem trước ảnh | … |
| Bảng 3.12 | Các bước thực hiện chức năng Lưu ảnh vào thư viện thiết bị | … |
| Bảng 3.13 | Các bước thực hiện chức năng Hiển thị bảng tin | … |
| Bảng 3.14 | Các bước thực hiện chức năng Lọc bảng tin theo bạn bè | … |
| Bảng 3.15 | Các bước thực hiện chức năng Xem bảng tin ở chế độ dạng lưới | … |
| Bảng 3.16 | Các bước thực hiện chức năng Chia sẻ và xóa bài đăng | … |
| Bảng 3.17 | Các bước thực hiện chức năng Thả, thay đổi và thu hồi cảm xúc | … |
| Bảng 3.18 | Các bước thực hiện chức năng Xem danh sách những người đã thả cảm xúc | … |
| Bảng 3.19 | Các bước thực hiện chức năng Quản lý thẻ định danh thiết bị | … |
| Bảng 3.20 | Các loại sự kiện thông báo được hệ thống hỗ trợ | … |
| Bảng 3.21 | Các bước thực hiện chức năng Hiển thị thông báo | … |
| Bảng 3.22 | Các bước thực hiện chức năng Xem lịch sử thông báo trong ứng dụng | … |
| Bảng 3.23 | Các bước thực hiện chức năng Xem trang cá nhân | … |
| Bảng 3.24 | Các bước thực hiện chức năng Chỉnh sửa thông tin cá nhân | … |
| Bảng 3.25 | Các bước thực hiện chức năng Chia sẻ trang cá nhân | … |
| Bảng 3.26 | Các bước thực hiện chức năng Xem hồ sơ của bạn bè | … |
| Bảng 3.27 | Các bước thực hiện chức năng Tạo Space mới | … |
| Bảng 3.28 | Các bước thực hiện chức năng Đăng ảnh vào Space và xem bảng tin của Space | … |
| Bảng 3.29 | Các bước thực hiện chức năng Trò chuyện nhóm trong Space | … |
| Bảng 3.30 | Các bước thực hiện chức năng Quản lý thành viên và Space | … |
| Bảng 3.31 | Các bước thực hiện chức năng Mở Nhật ký và xem danh sách | … |
| Bảng 3.32 | Các bước thực hiện chức năng Tạo bản nhật ký mới | … |
| Bảng 3.33 | Các bước thực hiện chức năng Xem bản nhật ký đã tạo | … |
| Bảng 3.34 | Các bước thực hiện chức năng Tìm kiếm nhật ký | … |
| Bảng 3.35 | Các bước thực hiện chức năng Mở danh sách các cuộc trò chuyện | … |
| Bảng 3.36 | Các bước thực hiện chức năng Bắt đầu và tiếp tục trò chuyện một-một | … |
| Bảng 3.37 | Các bước thực hiện chức năng Quản lý cuộc trò chuyện một-một | … |
| Bảng 3.38 | Các bước thực hiện chức năng Thêm Widget vào màn hình chính | … |
| Bảng 3.39 | Các bước thực hiện chức năng Hiển thị ảnh trên Widget | … |
| Bảng 3.40 | Các bước thực hiện chức năng Mở ứng dụng từ Widget | … |
| Bảng 3.41 | Các bước thực hiện chức năng Mở bottom sheet Cài đặt và sử dụng các lối tắt nhanh | … |
| Bảng 3.42 | Các bước thực hiện chức năng Quản lý tài khoản đã chặn | … |
| Bảng 3.43 | Các bước thực hiện chức năng Điều chỉnh Quyền riêng tư và dữ liệu | … |
| Bảng 3.44 | Các bước thực hiện chức năng Đăng xuất khỏi tài khoản | … |
| Bảng 3.45 | Các bước thực hiện chức năng Xóa tài khoản | … |
| Bảng 3.46 | Các bước thực hiện chức năng Xem lịch các ngày đã đăng bài theo tháng | … |
| Bảng 3.47 | Các bước thực hiện chức năng Xem chi tiết ảnh theo ngày | … |
| Bảng 3.48 | Các bước thực hiện chức năng Chia sẻ và quản lý ảnh từ giao diện Kỷ niệm | … |
| Bảng 4.1 | Tổng quan các collection chính trong hệ thống Meep | … |
| Bảng 4.2 | Cấu trúc dữ liệu của một tài liệu trong collection `users` | … |
| Bảng 4.3 | Các subcollection thuộc tài liệu `users/{uid}` | … |
| Bảng 4.4 | Cấu trúc dữ liệu của một tài liệu trong collection `usernames` | … |
| Bảng 4.5 | Cấu trúc dữ liệu của một tài liệu trong collection `posts` | … |
| Bảng 4.6 | Cấu trúc dữ liệu của một tài liệu trong subcollection `posts/{postId}/reactions` | … |
| Bảng 4.7 | Cấu trúc dữ liệu của một tài liệu trong collection `friendships` | … |
| Bảng 4.8 | Cấu trúc dữ liệu của một tài liệu trong collection `friend_requests` | … |
| Bảng 4.9 | Cấu trúc dữ liệu của một tài liệu trong collection `blocks` | … |
| Bảng 4.10 | Cấu trúc dữ liệu của một tài liệu trong collection `spaces` | … |
| Bảng 4.11 | Cấu trúc dữ liệu của một tài liệu trong subcollection `space_members/{spaceId}/members/{uid}` | … |
| Bảng 4.12 | Cấu trúc dữ liệu của một tài liệu trong collection `conversations` | … |
| Bảng 4.13 | Cấu trúc dữ liệu của một tài liệu trong subcollection `conversations/{conversationId}/messages` | … |
| Bảng 4.14 | Cấu trúc dữ liệu của một tài liệu trong collection `diary` | … |
| Bảng 4.15 | Cấu trúc của một khối nội dung trong trường `content` của bản nhật ký | … |
| Bảng A.1 | Phân công công việc theo mô-đun | … |
| Bảng A.2 | Các công việc bổ sung ngoài phạm vi mô-đun chính | … |

---

# DANH MỤC TỪ VIẾT TẮT

Bảng dưới đây liệt kê các từ viết tắt và thuật ngữ kỹ thuật bằng tiếng Anh đã được sử dụng trong báo cáo, kèm theo nguyên văn và mô tả ngắn gọn nhằm hỗ trợ người đọc tra cứu.

| Viết tắt | Nguyên văn (tiếng Anh) | Mô tả ngắn |
|---|---|---|
| AAB | Android App Bundle | Định dạng gói cài đặt mới do Google Play hỗ trợ. |
| ADR | Architecture Decision Record | Tài liệu ghi lại các quyết định kiến trúc trong dự án. |
| AOT | Ahead-of-Time (compilation) | Cơ chế biên dịch mã nguồn thành mã máy trước khi thực thi. |
| API | Application Programming Interface | Giao diện lập trình ứng dụng. |
| APK | Android Package Kit | Định dạng gói cài đặt ứng dụng Android. |
| APNs | Apple Push Notification service | Dịch vụ thông báo đẩy của Apple dành cho iOS. |
| BaaS | Backend-as-a-Service | Mô hình cung cấp các dịch vụ máy chủ dưới dạng dịch vụ đám mây. |
| BE | Back-end | Tầng máy chủ của ứng dụng. |
| CD | Continuous Delivery / Continuous Deployment | Quy trình triển khai liên tục. |
| CI | Continuous Integration | Quy trình tích hợp mã nguồn liên tục. |
| DOM | Document Object Model | Mô hình đối tượng tài liệu, dùng trong các ứng dụng web. |
| ERD | Entity Relationship Diagram | Sơ đồ thực thể – mối quan hệ. |
| FCM | Firebase Cloud Messaging | Dịch vụ gửi thông báo đẩy của Firebase. |
| FE | Front-end | Tầng giao diện người dùng của ứng dụng. |
| GIF | Graphics Interchange Format | Định dạng ảnh động phổ biến. |
| GPS | Global Positioning System | Hệ thống định vị toàn cầu. |
| HTML | HyperText Markup Language | Ngôn ngữ đánh dấu siêu văn bản. |
| IDE | Integrated Development Environment | Môi trường phát triển tích hợp. |
| MIME | Multipurpose Internet Mail Extensions | Tiêu chuẩn mô tả định dạng tệp truyền qua Internet. |
| MVP | Minimum Viable Product | Phiên bản sản phẩm tối thiểu khả dụng. |
| NoSQL | Not Only SQL | Nhóm các cơ sở dữ liệu phi quan hệ. |
| OAuth | Open Authorization | Giao thức ủy quyền mở dùng cho đăng nhập qua bên thứ ba. |
| OS | Operating System | Hệ điều hành. |
| PNG | Portable Network Graphics | Định dạng ảnh tĩnh hỗ trợ nén không mất mát. |
| SDK | Software Development Kit | Bộ công cụ phát triển phần mềm. |
| SRS | Software Requirements Specification | Tài liệu đặc tả yêu cầu phần mềm. |
| UI | User Interface | Giao diện người dùng. |
| UID | User Identifier | Mã định danh người dùng. |
| URL | Uniform Resource Locator | Địa chỉ định vị tài nguyên trên Internet. |
| UX | User Experience | Trải nghiệm người dùng. |
| 2FA | Two-Factor Authentication | Xác thực hai yếu tố. |
