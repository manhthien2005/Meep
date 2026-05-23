# CHƯƠNG 1. ĐẶT VẤN ĐỀ

Chương này trình bày bối cảnh dẫn đến việc lựa chọn đề tài, mục đích và các yêu cầu mà hệ thống cần đáp ứng, đồng thời xác định rõ phạm vi của hệ thống cả về kiến trúc, chức năng lẫn nền tảng triển khai. Ngoài ra, chương cũng thực hiện khảo sát ngắn gọn một số ứng dụng cùng phân khúc đang phổ biến trên thị trường, từ đó định vị những điểm khác biệt mà ứng dụng **Meep** hướng tới.

---

## 1.1. Mục đích, yêu cầu dự án

### Bối cảnh và lý do chọn đề tài

Trong những năm gần đây, mạng xã hội đã trở thành một phần không thể thiếu trong đời sống của người dùng trẻ. Các nền tảng phổ biến như **Facebook**, **Instagram** hay **TikTok** cho phép chia sẻ hình ảnh, video tới một lượng lớn người theo dõi, kèm theo hệ thống thuật toán đề xuất nội dung trên quy mô công khai. Tuy nhiên, đi cùng với sự mở rộng đó là những áp lực không nhỏ về hình ảnh cá nhân, về việc phải duy trì một "phiên bản trau chuốt" của bản thân trước cộng đồng, cũng như nguy cơ lộ thông tin riêng tư khi mọi bài đăng đều có khả năng tiếp cận tới những người không quen biết.

Bên cạnh các mạng xã hội đại chúng, một xu hướng mới đã hình thành xoay quanh nhu cầu **chia sẻ khoảnh khắc đời thường trong phạm vi nhóm bạn bè thân thiết**, thay vì chia sẻ công khai. Các ứng dụng như **Locket** hay **BeReal** đã chứng minh sự quan tâm thực tế của người dùng đối với mô hình này. Tuy vậy, các ứng dụng nêu trên vẫn còn một số giới hạn nhất định: tập trung chủ yếu vào một hình thức tương tác duy nhất (chỉ ảnh trên widget hoặc chỉ thông báo chụp đồng thời hai mặt camera), thiếu các không gian phụ trợ giúp người dùng lưu giữ kỷ niệm theo nhiều cách khác nhau, và chưa khai thác triệt để khả năng của các tiện ích nền tảng như **Home-screen Widget** trên thiết bị Android.

Xuất phát từ thực tế đó, đề tài **Meep — Ứng dụng chia sẻ ảnh cho bạn bè thân thiết** được lựa chọn nhằm xây dựng một ứng dụng di động hướng đến đối tượng người dùng trẻ, ưu tiên trải nghiệm chia sẻ ảnh thân mật, riêng tư trong một mạng lưới bạn bè hai chiều đã được xác lập, đồng thời mở rộng thêm các không gian lưu trữ và tương tác mới mà các ứng dụng tương tự hiện chưa cung cấp đầy đủ.

### Mục đích của hệ thống

Hệ thống được xây dựng nhằm cung cấp cho người dùng một không gian chia sẻ hình ảnh khép kín, nơi mỗi bài đăng chỉ hiển thị với những người bạn đã được chấp nhận kết bạn hai chiều, không tồn tại khái niệm theo dõi công khai như các mạng xã hội truyền thống. Bên cạnh tính năng chia sẻ ảnh cốt lõi, hệ thống còn cung cấp các chức năng mở rộng bao gồm **không gian chung (Space)** dành cho từng nhóm bạn, **nhật ký cá nhân (Diary)** để ghi lại cảm xúc theo ngày, **trò chuyện trực tiếp (Chat)** và đặc biệt là **Home-screen Widget trên Android** — cho phép người dùng nhìn thấy ngay những khoảnh khắc mới nhất từ bạn bè ngay trên màn hình chính của thiết bị mà không cần mở ứng dụng.

Thông qua hệ thống này, người dùng có thể duy trì sự kết nối thường xuyên với những người bạn thân nhất trong một môi trường riêng tư, an toàn về thông tin, đồng thời tích lũy được một "cuốn nhật ký hình ảnh" có giá trị lưu giữ kỷ niệm theo thời gian.

### Yêu cầu của dự án

Trên cơ sở mục đích đã xác định, hệ thống cần đáp ứng được hai nhóm yêu cầu chính: nhóm **yêu cầu về chức năng** và nhóm **yêu cầu phi chức năng**.

**Yêu cầu về chức năng** bao gồm các nhóm chức năng cốt lõi mà hệ thống phải cung cấp cho người dùng:

- Quản lý tài khoản: cho phép người dùng đăng ký, đăng nhập bằng email/mật khẩu hoặc tài khoản Google, đăng nhập tự động khi mở lại ứng dụng và khôi phục mật khẩu khi cần thiết.
- Quản lý bạn bè: tìm kiếm, gửi và nhận lời mời kết bạn, chấp nhận hoặc từ chối lời mời, hiển thị danh sách bạn bè theo cơ chế kết bạn hai chiều.
- Chụp ảnh và đăng bài: hỗ trợ chụp ảnh trực tiếp từ camera, đính kèm chú thích, lựa chọn nhóm bạn nhận được bài đăng và gửi đi.
- Bảng tin (Feed): hiển thị các bài đăng mới nhất từ bạn bè theo thứ tự thời gian, hỗ trợ lọc theo từng người bạn và chế độ xem dạng lưới.
- Tương tác với bài đăng: cho phép người dùng thả cảm xúc dạng biểu tượng và xem danh sách những người đã tương tác.
- Thông báo đẩy: gửi thông báo tới người dùng khi có bạn đăng bài mới, có lời mời kết bạn hoặc có hoạt động tương tác liên quan.
- Hồ sơ cá nhân: hiển thị và chỉnh sửa thông tin cá nhân, xem hồ sơ của bạn bè trong mạng lưới.
- Không gian chung (Space) cho từng nhóm bạn bè, **Nhật ký (Diary)** ghi cảm xúc theo ngày, **Trò chuyện (Chat)** một-một xuất phát từ bài đăng.
- Home-screen Widget Android: hiển thị ảnh mới nhất từ bạn bè ngay trên màn hình chính của thiết bị.
- Cài đặt tài khoản: chặn người dùng, đăng xuất và xóa tài khoản.

**Yêu cầu phi chức năng** bao gồm các đặc tính chất lượng mà hệ thống cần bảo đảm trong quá trình vận hành:

- **Tính bảo mật và quyền riêng tư:** dữ liệu hình ảnh và thông tin cá nhân của người dùng phải được bảo vệ chặt chẽ. Mỗi bài đăng chỉ được hiển thị cho những người bạn hợp lệ; không có cơ chế chia sẻ công khai. Toàn bộ thao tác đọc và ghi dữ liệu phải đi qua tầng xác thực và tầng luật bảo mật của máy chủ.
- **Tính khả dụng:** giao diện được thiết kế tối giản, các thao tác chính (chụp ảnh, đăng bài, xem bảng tin, kết bạn) phải thực hiện được trong số lượng bước nhỏ nhất.
- **Tính ổn định và hiệu năng:** hệ thống phản hồi nhanh, đặc biệt là quá trình tải bảng tin và đồng bộ ảnh lên dịch vụ lưu trữ trên đám mây.
- **Tính mở rộng:** kiến trúc ứng dụng cho phép bổ sung các chức năng mới (ví dụ hỗ trợ thêm nền tảng iOS, bổ sung tính năng chụp ảnh hai camera) mà không phải viết lại các thành phần đã có.
- **Tính nhất quán dữ liệu:** dữ liệu trên ứng dụng di động và Home-screen Widget phải được đồng bộ tự động trong khoảng thời gian hợp lý sau khi có bài đăng mới.
- **Yêu cầu triển khai:** hệ thống chạy ổn định trên các thiết bị Android phổ biến tại thời điểm thực hiện đề tài, hỗ trợ phiên bản hệ điều hành Android **[CẦN BỔ SUNG: phiên bản tối thiểu — ví dụ Android 8.0 trở lên]**.

Có thể thấy rằng, các yêu cầu trên vừa đảm bảo cho hệ thống đáp ứng được mục đích ban đầu, vừa đặt nền tảng cho việc lựa chọn công nghệ và kiến trúc phù hợp được trình bày ở các chương tiếp theo.

---

## 1.2. Xác định phạm vi hệ thống

Trên cơ sở mục đích và các yêu cầu đã trình bày ở mục 1.1, phạm vi của hệ thống được xác định một cách cụ thể trên ba phương diện: kiến trúc tổng thể, danh sách chức năng được đưa vào phiên bản MVP và nền tảng triển khai dự kiến. Việc giới hạn phạm vi một cách rõ ràng giúp định hướng quá trình hiện thực hóa hệ thống, đồng thời tạo điều kiện thuận lợi cho việc đánh giá kết quả ở các giai đoạn sau.

### 1.2.1. Kiến trúc hệ thống

Hệ thống **Meep** được thiết kế theo mô hình **client – server**, trong đó vai trò của tầng client do ứng dụng di động đảm nhiệm, còn tầng server được xây dựng trên nền tảng dịch vụ đám mây **Firebase**. Bên cạnh đó, một thành phần đặc thù của hệ thống là **Home-screen Widget** được hiện thực hóa bằng mã nguồn gốc (native) trên Android, nhằm hiển thị nội dung ngay trên màn hình chính của thiết bị mà không cần mở ứng dụng.

Một cách tổng quát, hệ thống bao gồm ba thành phần chính sau đây:

- **Ứng dụng di động (Mobile Client):** được phát triển bằng **Flutter** với ngôn ngữ **Dart**, đảm nhiệm toàn bộ phần giao diện người dùng và xử lý nghiệp vụ phía client. Ứng dụng được tổ chức theo kiến trúc ba lớp gồm tầng **dữ liệu (data)**, tầng **ứng dụng (application)** và tầng **giao diện (presentation)**, với **Riverpod** đóng vai trò là cơ chế quản lý trạng thái và tiêm phụ thuộc xuyên suốt các lớp.
- **Hệ thống dịch vụ máy chủ (Backend Services) trên Firebase:** cung cấp các dịch vụ nền tảng dùng chung cho toàn bộ hệ thống, bao gồm **Firebase Authentication** để xác thực người dùng, **Cloud Firestore** làm cơ sở dữ liệu hướng tài liệu (NoSQL), **Cloud Storage** để lưu trữ tệp ảnh, **Cloud Functions** để xử lý các tác vụ phía máy chủ như phân phối bài đăng tới bảng tin của bạn bè và phát thông báo, và **Firebase Cloud Messaging (FCM)** để gửi thông báo đẩy tới thiết bị người dùng.
- **Home-screen Widget Android:** là thành phần native được viết bằng **Kotlin**, hoạt động độc lập với ứng dụng chính. Widget này định kỳ đồng bộ dữ liệu ảnh mới nhất thông qua một tác vụ nền (**WorkManager**) và hiển thị trực tiếp trên màn hình chính của thiết bị Android.

Luồng tương tác cơ bản giữa các thành phần diễn ra như sau: người dùng thao tác trên ứng dụng di động, các thao tác được tầng **data** chuyển thành lệnh đọc hoặc ghi dữ liệu tới Firebase. Khi có một bài đăng mới được tạo, **Cloud Functions** sẽ tự động kích hoạt để ghi nhận sự kiện và phát thông báo qua **Firebase Cloud Messaging** tới các thiết bị của bạn bè. Song song với luồng đó, **Home-screen Widget** trên thiết bị Android sẽ định kỳ truy vấn dữ liệu mới và cập nhật ảnh hiển thị trên màn hình chính, đảm bảo người dùng luôn nhìn thấy khoảnh khắc gần nhất từ bạn bè ngay khi mở thiết bị.

> **Hình 1.** Sơ đồ kiến trúc tổng quan của hệ thống Meep.
> *[CẦN BỔ SUNG: chèn sơ đồ kiến trúc — gồm 3 khối Mobile Client (Flutter), Backend Services (Firebase: Auth, Firestore, Storage, Functions, FCM) và Home-screen Widget (Kotlin + WorkManager), kèm các mũi tên thể hiện luồng dữ liệu giữa các khối.]*

### 1.2.2. Phạm vi chức năng

Trong khuôn khổ của đề tài, hệ thống tập trung vào việc xây dựng các chức năng cốt lõi cần thiết để vận hành một ứng dụng chia sẻ ảnh khép kín trong nhóm bạn bè thân thiết. Các chức năng được lựa chọn dựa trên nguyên tắc đảm bảo trải nghiệm cơ bản tương đương với những ứng dụng cùng phân khúc, đồng thời bổ sung những điểm khác biệt riêng của Meep.

**Các chức năng nằm trong phạm vi của phiên bản MVP** bao gồm:

- **Xác thực người dùng:** đăng ký, đăng nhập bằng email/mật khẩu hoặc tài khoản Google, đăng nhập tự động khi mở lại ứng dụng và khôi phục mật khẩu qua email.
- **Quản lý bạn bè:** tìm kiếm người dùng theo tên người dùng, gửi và nhận lời mời kết bạn, chấp nhận hoặc từ chối lời mời, hiển thị danh sách bạn bè theo cơ chế hai chiều.
- **Chụp ảnh và đăng bài:** chụp ảnh trực tiếp từ camera của thiết bị, đính kèm chú thích (caption), lựa chọn nhóm bạn nhận bài và đăng tải lên hệ thống.
- **Bảng tin (Feed):** hiển thị các bài đăng mới nhất từ bạn bè theo thứ tự thời gian, hỗ trợ lọc theo từng người bạn và xem dạng lưới (grid view).
- **Thả cảm xúc (Reaction):** cho phép người dùng thả biểu tượng cảm xúc trên bài đăng của bạn bè và xem danh sách những người đã thả cảm xúc.
- **Thông báo đẩy (Push Notification):** gửi thông báo tới người dùng khi có bài đăng mới, lời mời kết bạn hoặc hoạt động tương tác liên quan tới mình.
- **Hồ sơ cá nhân (Profile):** hiển thị và chỉnh sửa thông tin cá nhân, xem hồ sơ của bạn bè trong mạng lưới.
- **Không gian chung (Space):** không gian riêng được tạo ra cho một nhóm bạn bè, dùng để chia sẻ nội dung trong phạm vi nhóm.
- **Nhật ký (Diary):** cho phép người dùng ghi lại cảm xúc theo từng ngày, kèm theo chế độ riêng tư hoặc chia sẻ với bạn bè.
- **Trò chuyện (Chat):** hỗ trợ trao đổi tin nhắn dạng một-một xuất phát từ một bài đăng cụ thể.
- **Home-screen Widget Android:** hiển thị ảnh mới nhất từ bạn bè ngay trên màn hình chính của thiết bị Android, tự động cập nhật theo chu kỳ.
- **Cài đặt tài khoản:** chặn người dùng, đăng xuất khỏi tài khoản và yêu cầu xóa tài khoản.
- **Streak / Kỷ niệm:** xem lại lịch sử các bài đăng theo dạng lịch tháng và xem chi tiết ảnh theo từng ngày.

**Các chức năng nằm ngoài phạm vi của phiên bản MVP** bao gồm: chụp ảnh đồng thời hai camera (dual camera), đăng video, hiệu ứng nhãn dán cho chú thích, trò chuyện theo nhóm trong Space, đánh giá – báo cáo người dùng, và một số chức năng nâng cao khác. Những chức năng này được dự kiến đưa vào các giai đoạn phát triển tiếp theo sau khi MVP đã được hoàn thiện và đánh giá.

### 1.2.3. Phạm vi triển khai

Về mặt nền tảng triển khai, hệ thống được giới hạn ở phạm vi **thiết bị di động chạy hệ điều hành Android** trong phiên bản MVP. Quyết định này xuất phát từ một số yếu tố thực tế liên quan đến nguồn lực thực hiện đề tài, thời gian phát triển và đặc thù của thành phần chủ lực **Home-screen Widget** vốn yêu cầu hai mã nguồn gốc riêng biệt nếu triển khai trên cả hai nền tảng iOS và Android.

Cụ thể, phạm vi triển khai của hệ thống được xác định như sau:

- **Nền tảng client:** ứng dụng được triển khai trên hệ điều hành **Android**, được phát triển bằng **Flutter** và biên dịch sang gói cài đặt **APK/AAB** thông qua công cụ chuẩn của Flutter. Phiên bản hệ điều hành tối thiểu mà ứng dụng hỗ trợ là **[CẦN BỔ SUNG: Android — ví dụ Android 8.0 (API 26) trở lên]**.
- **Native widget:** **Home-screen Widget** chỉ được hiện thực hóa bằng mã nguồn **Kotlin** cho nền tảng Android, sử dụng cơ chế **AppWidget** của hệ điều hành và **WorkManager** để đồng bộ dữ liệu nền theo chu kỳ.
- **Phương thức xác thực:** hỗ trợ hai phương thức là **email/mật khẩu** và **Google Sign-In** thông qua Firebase Authentication; phương thức Apple Sign-In không được đưa vào phiên bản MVP.
- **Thông báo đẩy:** chỉ triển khai trên kênh **Firebase Cloud Messaging** dành cho Android; không thiết lập **APNs** dành cho iOS.
- **Backend:** toàn bộ tầng máy chủ đặt trên nền tảng đám mây **Firebase**, không triển khai máy chủ tự quản lý (self-hosted).
- **Hỗ trợ nền tảng iOS:** mã nguồn Flutter được giữ ở trạng thái có thể đa nền tảng, tuy nhiên việc đóng gói, kiểm thử và phát hành trên **iOS** được lùi lại sau giai đoạn MVP. Lý do và phạm vi của quyết định này được trình bày chi tiết trong tài liệu kiến trúc tương ứng của dự án.

Từ những phân tích trên, có thể nhận thấy phạm vi triển khai đã được xác định một cách thực tế, vừa phù hợp với khả năng của nhóm thực hiện, vừa đảm bảo người dùng có thể trải nghiệm đầy đủ các chức năng cốt lõi của hệ thống trên thiết bị Android trong giai đoạn MVP.

---

## 1.3. Khảo sát các hệ thống tương tự

Trước khi đi vào thiết kế chi tiết, việc khảo sát các ứng dụng đã có trên thị trường thuộc cùng phân khúc là một bước cần thiết. Mục đích của khảo sát này không phải để liệt kê đầy đủ các sản phẩm cạnh tranh, mà để xác định được những điểm mạnh mà các ứng dụng đi trước đã chứng minh được giá trị, đồng thời nhận diện những giới hạn mà hệ thống mới có thể bổ sung. Trên cơ sở đó, mục 1.3.2 sẽ định vị rõ vị trí mà ứng dụng Meep mong muốn lấp vào trong phân khúc chia sẻ ảnh dành cho bạn bè thân thiết.

### 1.3.1. Các ứng dụng cùng phân khúc

Trong vài năm gần đây, một số ứng dụng nước ngoài đã đạt được mức độ phổ biến nhất định khi khai thác mô hình chia sẻ ảnh thân mật trong nhóm bạn bè, thay vì chia sẻ công khai như các mạng xã hội đại chúng. Trong phạm vi đề tài, hai ứng dụng tiêu biểu được lựa chọn để khảo sát là **Locket** và **BeReal**.

**Locket** là ứng dụng cho phép người dùng chia sẻ ảnh trực tiếp tới Home-screen Widget trên điện thoại của bạn bè. Người dùng chụp một bức ảnh trong ứng dụng và gửi đi; ảnh sẽ xuất hiện gần như tức thì trên widget ở màn hình chính của những người bạn được chọn. Điểm mạnh của Locket nằm ở việc khai thác triệt để tiện ích widget như một kênh hiển thị nội dung không gây gián đoạn, giúp người dùng nhìn thấy khoảnh khắc của bạn bè mỗi khi mở thiết bị mà không cần thao tác mở ứng dụng. Tuy nhiên, ứng dụng tập trung gần như hoàn toàn vào mô hình widget – ảnh, và chưa cung cấp các không gian phụ trợ khác như nhật ký cá nhân, không gian dành cho nhóm bạn cụ thể hay trao đổi tin nhắn trực tiếp xuất phát từ bài đăng.

**BeReal** đi theo một hướng tiếp cận khác. Mỗi ngày, ứng dụng phát đi một thông báo ngẫu nhiên kêu gọi tất cả người dùng cùng chụp một bức ảnh trong một khoảng thời gian giới hạn (khoảng hai phút), đồng thời sử dụng cả hai camera trước và sau để ghi nhận khoảnh khắc một cách "chân thật". Mô hình này tạo ra một trải nghiệm chia sẻ đồng bộ và mang tính cộng đồng cao trong nhóm bạn bè. Tuy nhiên, BeReal lại đặt ra một quy chế cứng về thời điểm và tần suất chia sẻ — mỗi người chỉ đăng được một bài đúng trong khung giờ quy định mỗi ngày — và không khai thác sâu kênh hiển thị Home-screen Widget trên Android.

Có thể thấy rằng, mỗi ứng dụng đều có thế mạnh riêng nhưng đồng thời cũng để lại những khoảng trống nhất định: Locket khai thác tốt widget nhưng thiếu các không gian phụ trợ; BeReal mang lại trải nghiệm chia sẻ đồng bộ nhưng lại bó buộc người dùng vào một khung giờ cố định. Đây chính là cơ sở để hệ thống mới đặt ra hướng tiếp cận cân bằng và mở rộng hơn.

### 1.3.2. Định vị khác biệt của Meep

Trên cơ sở khảo sát hai ứng dụng nêu trên, hệ thống **Meep** được thiết kế nhằm kế thừa những điểm mạnh đã được kiểm chứng đồng thời khắc phục những khoảng trống còn tồn tại. Định vị của Meep được xác định dựa trên bốn điểm khác biệt chính.

Thứ nhất, **Meep cung cấp đồng thời nhiều không gian lưu trữ và tương tác trong cùng một ứng dụng**. Bên cạnh bảng tin (Feed) và Home-screen Widget vốn là hai kênh trình bày ảnh chính, hệ thống còn cung cấp **Không gian chung (Space)** dành riêng cho từng nhóm bạn, **Nhật ký (Diary)** để ghi lại cảm xúc theo từng ngày, và **Trò chuyện (Chat)** xuất phát trực tiếp từ một bài đăng cụ thể. Cách tiếp cận này giúp người dùng có thể lựa chọn hình thức chia sẻ phù hợp với từng tình huống, thay vì bị bó buộc vào một mô hình duy nhất.

Thứ hai, **Home-screen Widget trên Android được khai thác như một thành phần chủ lực của hệ thống**, không chỉ đơn thuần là tiện ích phụ. Widget hoạt động độc lập với ứng dụng chính, được đồng bộ định kỳ thông qua **WorkManager** để đảm bảo luôn hiển thị ảnh mới nhất từ bạn bè ngay trên màn hình chính của thiết bị.

Thứ ba, **mạng lưới bạn bè của Meep được tổ chức theo cơ chế hai chiều và khép kín**. Không tồn tại khái niệm theo dõi công khai, không có chế độ tài khoản công cộng. Mỗi bài đăng chỉ được hiển thị cho những người đã được chấp nhận kết bạn lẫn nhau, đảm bảo cho người dùng một không gian chia sẻ riêng tư và đáng tin cậy.

Thứ tư, **trải nghiệm sử dụng linh hoạt, không áp đặt quy chế cứng** về thời điểm chia sẻ. Người dùng có thể đăng bài bất cứ lúc nào, lựa chọn nhóm bạn nhận bài cụ thể và xem lại lịch sử các khoảnh khắc đã chia sẻ thông qua chức năng Streak / Kỷ niệm.

Bảng dưới đây tóm lược một số tiêu chí chính giúp phân biệt định vị của Meep so với hai ứng dụng đã khảo sát:

**Bảng 1.1.** So sánh tiêu chí định vị của Meep với Locket và BeReal.

| Tiêu chí | Locket | BeReal | Meep |
|---|---|---|---|
| Kênh hiển thị chính | Home-screen Widget | Bảng tin trong ứng dụng | Bảng tin + Home-screen Widget |
| Khung giờ chia sẻ | Bất kỳ | Cố định, một lần/ngày | Bất kỳ |
| Camera | Camera đơn | Đồng thời hai camera | Camera đơn (đa camera được dự kiến sau MVP) |
| Mạng lưới bạn bè | Hai chiều, khép kín | Hai chiều, khép kín | Hai chiều, khép kín |
| Không gian nhóm (Space) | Không có | Không có | Có |
| Nhật ký cá nhân (Diary) | Không có | Không có | Có |
| Trò chuyện trực tiếp (Chat) | Không có | Không có | Có (một-một, theo bài đăng) |
| Xem lại lịch sử dạng lịch | Không có | Hạn chế | Có (Streak / Kỷ niệm) |

Từ những phân tích trên, có thể thấy rằng Meep được định vị là một hệ thống chia sẻ ảnh thân thiết với phạm vi chức năng rộng hơn so với các ứng dụng cùng phân khúc, đồng thời vẫn duy trì được tinh thần riêng tư và linh hoạt vốn là thế mạnh của mô hình chia sẻ trong nhóm bạn bè khép kín. Đây cũng chính là cơ sở để chương 2 đi vào trình bày các công nghệ và kiến trúc được lựa chọn để hiện thực hóa hệ thống.
