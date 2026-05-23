# CHƯƠNG 6. KẾT LUẬN

Chương cuối của báo cáo tổng kết lại quá trình thực hiện đề tài, các kết quả đã đạt được, những hạn chế còn tồn tại của hệ thống ở phiên bản hiện tại và các hướng phát triển có thể được tiếp tục triển khai trong tương lai. Nội dung của chương được xây dựng trên cơ sở đối chiếu giữa các yêu cầu đã được xác định ở chương 1 và kết quả hiện thực hóa thực tế đã được trình bày ở các chương trước đó.

---

## 6.1. Kết quả đạt được

Sau quá trình phân tích, thiết kế và lập trình, nhóm thực hiện đã hoàn thành được phiên bản MVP của hệ thống **Meep — Ứng dụng chia sẻ ảnh cho bạn bè thân thiết** với phạm vi chức năng bao phủ trọn vẹn các nhóm yêu cầu đã được xác định trong chương 1. Hệ thống đã được vận hành thử nghiệm trên thiết bị Android thực tế, các luồng nghiệp vụ cốt lõi đã thông suốt từ khâu đăng ký tài khoản, chụp ảnh và đăng bài, cho tới việc hiển thị bảng tin, tương tác bằng cảm xúc, trò chuyện và cập nhật Home-screen Widget.

Về mặt **chức năng**, phiên bản hiện tại của hệ thống đã đáp ứng đầy đủ các nhóm chức năng bắt buộc, bao gồm: xác thực người dùng bằng email/mật khẩu và Google Sign-In, quản lý mạng lưới bạn bè theo cơ chế hai chiều, chụp ảnh và đăng bài với nhiều dạng chú thích, bảng tin với cơ chế lọc và chế độ xem dạng lưới, thả cảm xúc, thông báo đẩy, hồ sơ cá nhân, không gian chung (Space), nhật ký, trò chuyện, Home-screen Widget trên Android, cài đặt và chức năng Streak / Kỷ niệm cho phép xem lại lịch sử ảnh đã đăng theo dạng lịch tháng.

Về mặt **kỹ thuật**, hệ thống được tổ chức theo kiến trúc ba lớp `data` – `application` – `presentation` ở phía ứng dụng di động với **Flutter** làm công cụ chính, kết hợp với **Riverpod** đóng vai trò quản lý trạng thái và tiêm phụ thuộc. Phía dịch vụ máy chủ sử dụng đầy đủ các thành phần của hệ sinh thái **Firebase**: Firebase Authentication cho xác thực, Cloud Firestore cho cơ sở dữ liệu, Cloud Storage cho lưu trữ ảnh, Cloud Functions cho xử lý logic phía máy chủ, và Firebase Cloud Messaging cho thông báo đẩy. Thành phần đặc thù **Home-screen Widget** được hiện thực hóa bằng mã nguồn gốc **Kotlin** và đồng bộ dữ liệu định kỳ thông qua cơ chế WorkManager của Android. Toàn bộ logic phía máy chủ được viết bằng **TypeScript** trên môi trường Cloud Functions, đảm bảo tính an toàn về kiểu dữ liệu và khả năng bảo trì lâu dài.

Về mặt **quy trình và tổ chức nhóm**, đề tài cũng giúp các thành viên thực hành làm việc nhóm theo mô hình mỗi thành viên phụ trách trọn vẹn một mô-đun từ tầng dữ liệu cho tới tầng giao diện. Mã nguồn được quản lý qua **Git** với quy ước nhánh và quy ước cam kết (commit message) thống nhất, mọi thay đổi đều đi qua quá trình rà soát mã (code review) trước khi được nhập vào nhánh tích hợp. Quy trình phát triển được dẫn dắt bằng các tài liệu đặc tả viết trước (spec-driven development), giúp các thành viên có cơ sở chung khi thực hiện đồng thời nhiều mô-đun độc lập.

Có thể thấy rằng, kết quả đạt được không chỉ giới hạn ở một sản phẩm phần mềm hoàn chỉnh mà còn bao gồm cả kinh nghiệm thực tiễn quý báu mà các thành viên nhóm tích lũy được trong suốt quá trình thực hiện đề tài — từ kỹ năng phân tích yêu cầu, thiết kế kiến trúc, lập trình, kiểm thử cho tới quản lý quy trình phát triển phần mềm.

---

## 6.2. Hạn chế của hệ thống

Bên cạnh những kết quả đạt được, hệ thống vẫn còn tồn tại một số hạn chế nhất định do giới hạn về thời gian thực hiện và nguồn lực của nhóm. Nhóm thực hiện ghi nhận các hạn chế này một cách khách quan để làm cơ sở cho các hướng cải tiến trong các giai đoạn phát triển tiếp theo.

Các hạn chế chính của hệ thống ở phiên bản hiện tại bao gồm:

- **Phạm vi nền tảng triển khai chỉ giới hạn ở Android.** Trong phạm vi MVP, hệ thống không hỗ trợ nền tảng iOS do các yêu cầu về thiết bị phát triển, quy trình phát hành trên kho ứng dụng của Apple và yêu cầu phải xây dựng một mã nguồn gốc riêng cho thành phần Home-screen Widget. Đối tượng người dùng có thiết bị iOS hiện tại chưa thể trải nghiệm hệ thống.
- **Chức năng Streak / Kỷ niệm vẫn đang trong giai đoạn hoàn thiện.** Mặc dù phần khung của chức năng đã được thiết kế, một số khả năng nâng cao như tính toán chuỗi ngày liên tiếp một cách chính xác theo múi giờ địa phương và các thông báo nhắc nhở liên quan tới chuỗi ngày chưa được hoàn thiện đầy đủ ở phiên bản hiện tại.
- **Chưa hỗ trợ chế độ chụp ảnh đồng thời hai camera (dual camera).** Mặc dù lược đồ dữ liệu đã dự phòng các trường tương ứng, phần giao diện và logic xử lý cho chế độ này chưa được hiện thực hóa trong phạm vi MVP.
- **Chưa hỗ trợ chia sẻ video.** Hệ thống hiện chỉ cho phép chia sẻ ảnh tĩnh; các dạng đa phương tiện khác như video ngắn hoặc ảnh động chưa nằm trong phạm vi của phiên bản hiện tại.
- **Chức năng trò chuyện chỉ cho phép khởi tạo từ một bài đăng cụ thể.** Người dùng không thể bắt đầu một cuộc trò chuyện độc lập (không xuất phát từ một ảnh) trong phiên bản hiện tại. Mặc dù đây là một quyết định thiết kế có chủ đích, ràng buộc này có thể gây bất tiện đối với một số tình huống sử dụng thực tế.
- **Trải nghiệm soạn thảo nhật ký còn hạn chế.** Các định dạng văn bản nâng cao như chèn sticker, ảnh động hay các khối tham chiếu giữa các bản nhật ký chưa được hỗ trợ ở phiên bản hiện tại.
- **Thiếu các tính năng cộng đồng nâng cao.** Hệ thống chưa cung cấp các cơ chế đánh giá, báo cáo nội dung hoặc người dùng vi phạm; chưa có cơ chế nhắc nhở định kỳ về thói quen chia sẻ; và chưa có cơ chế kiểm duyệt nội dung tự động.
- **Hệ thống phân tích sử dụng và giám sát chưa được tích hợp.** Việc theo dõi các chỉ số sử dụng thực tế của người dùng, ghi nhận các tình huống xảy ra lỗi và phân tích hiệu năng theo thời gian thực mới ở mức cơ bản, chưa đầy đủ để hỗ trợ một sản phẩm vận hành ở quy mô lớn.
- **Khả năng hoạt động ngoại tuyến (offline) còn hạn chế.** Hệ thống dựa nhiều vào kết nối mạng để vận hành; trong trường hợp người dùng tạm thời mất kết nối, một số chức năng sẽ không thực hiện được hoặc hiển thị trạng thái lỗi.

---

## 6.3. Hướng phát triển trong tương lai

Trên cơ sở những kết quả đã đạt được và các hạn chế đã được nhận diện, nhóm thực hiện đề xuất một số hướng phát triển có thể được triển khai trong các giai đoạn tiếp theo của đề tài. Các hướng phát triển này được sắp xếp theo mức độ ưu tiên giảm dần, từ những hướng có giá trị thiết thực ngay lập tức tới những hướng mang tính mở rộng dài hạn.

Các hướng phát triển được đề xuất bao gồm:

- **Mở rộng hỗ trợ nền tảng iOS.** Đây là hướng phát triển ưu tiên hàng đầu nhằm mở rộng đối tượng người dùng. Việc mở rộng đòi hỏi bổ sung phương thức Apple Sign-In, xây dựng phiên bản Home-screen Widget bằng khung **WidgetKit** trên iOS, cấu hình hệ thống thông báo đẩy thông qua **Apple Push Notification service (APNs)** và thiết lập quy trình phát hành trên App Store. Do toàn bộ mã nguồn ứng dụng đã được xây dựng bằng Flutter ngay từ đầu, phần lớn giao diện và logic nghiệp vụ ở phía client sẽ tái sử dụng được mà không cần viết lại.
- **Hoàn thiện chức năng Streak / Kỷ niệm.** Bổ sung các khả năng nâng cao của chức năng, bao gồm tính toán chính xác chuỗi ngày liên tiếp theo múi giờ địa phương, thông báo nhắc nhở khi người dùng có nguy cơ làm gián đoạn chuỗi ngày, và các giao diện trực quan hơn để thể hiện thành tích của người dùng theo thời gian.
- **Bổ sung chế độ chụp ảnh đồng thời hai camera.** Trên cơ sở lược đồ dữ liệu đã được dự phòng từ trước, hiện thực hóa giao diện và logic xử lý cho chế độ chụp đồng thời camera trước và camera sau — tương tự cách tiếp cận đã được chứng minh thành công trên một số ứng dụng cùng phân khúc.
- **Hỗ trợ chia sẻ video ngắn.** Mở rộng các loại nội dung mà người dùng có thể chia sẻ ra ngoài định dạng ảnh tĩnh, bao gồm video ngắn (tối đa khoảng mười giây) và ảnh động dạng GIF.
- **Mở rộng phạm vi của chức năng Trò chuyện.** Cho phép người dùng khởi tạo cuộc trò chuyện độc lập (không xuất phát từ một bài đăng), bổ sung khả năng gửi ảnh trực tiếp trong tin nhắn, hỗ trợ các tin nhắn dạng âm thanh ngắn (voice message) và các biểu tượng cảm xúc cho từng tin nhắn (message reactions).
- **Bổ sung các chức năng cộng đồng và an toàn nội dung.** Cung cấp cơ chế đánh giá, báo cáo nội dung và người dùng vi phạm; xây dựng quy trình xử lý báo cáo có sự can thiệp của con người kết hợp với các thuật toán tự động lọc nội dung nhạy cảm.
- **Tích hợp hệ thống phân tích sử dụng và giám sát.** Bổ sung các công cụ theo dõi hành vi người dùng (Firebase Analytics), ghi nhận lỗi xảy ra trong thực tế (Crashlytics) và giám sát hiệu năng theo thời gian thực, làm cơ sở cho các quyết định cải tiến sản phẩm dựa trên dữ liệu thực tế.
- **Cải thiện khả năng hoạt động ngoại tuyến.** Mở rộng lớp dữ liệu để hỗ trợ bộ nhớ đệm cục bộ bền vững, cho phép người dùng đọc lại bảng tin và các bài đăng đã từng xem khi không có kết nối mạng, đồng thời lưu các thao tác tạo mới vào hàng đợi để gửi lên máy chủ khi có kết nối trở lại.
- **Đa dạng hóa ngôn ngữ hỗ trợ.** Bổ sung tiếng Anh và một số ngôn ngữ khu vực Đông Nam Á khác bên cạnh tiếng Việt, từ đó mở rộng khả năng tiếp cận của hệ thống tới người dùng quốc tế.
- **Nâng cao các biện pháp bảo mật.** Bổ sung xác thực hai yếu tố (Two-Factor Authentication), cung cấp tùy chọn sao lưu mã hóa các bản nhật ký riêng tư, và cho phép người dùng tự quản lý các phiên đăng nhập trên các thiết bị khác nhau.

---

Tóm lại, hệ thống **Meep — Ứng dụng chia sẻ ảnh cho bạn bè thân thiết** đã được hiện thực hóa thành công ở phiên bản MVP với phạm vi chức năng bao phủ trọn vẹn các nhóm yêu cầu đã đặt ra. Mặc dù vẫn còn một số hạn chế cần khắc phục, đề tài đã đạt được các mục tiêu chính đề ra ban đầu và mở ra nhiều hướng phát triển tiếp theo. Quá trình thực hiện đề tài cũng mang lại cho các thành viên nhóm những kinh nghiệm thực tiễn có giá trị, là nền tảng quan trọng cho quá trình học tập và phát triển nghề nghiệp trong lĩnh vực Công nghệ thông tin.
