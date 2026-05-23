# CHƯƠNG 2. CƠ SỞ LÝ THUYẾT

Chương này trình bày những kiến thức nền tảng được vận dụng trong quá trình thiết kế và hiện thực hóa hệ thống Meep. Trước hết, chương sẽ giới thiệu khái quát về lập trình ứng dụng di động và các hướng tiếp cận phổ biến, từ đó đặt cơ sở để giải thích lý do lựa chọn nền tảng phát triển. Tiếp theo, chương phân tích cụ thể hai công nghệ chủ lực được sử dụng là **Flutter** ở phía ứng dụng di động và **Firebase** ở phía dịch vụ máy chủ. Cuối chương, hai mục bổ sung sẽ trình bày kiến trúc ứng dụng theo mô hình ba lớp được áp dụng cho dự án và cơ sở lý thuyết về **Home-screen Widget** trên nền tảng Android — thành phần đặc thù tạo nên điểm khác biệt của hệ thống.

---

## 2.1. Khái niệm về Lập trình Mobile

Lập trình ứng dụng di động (Mobile Application Development) là lĩnh vực phát triển phần mềm chuyên biệt cho các thiết bị di động như điện thoại thông minh, máy tính bảng và một số dạng thiết bị đeo có khả năng cài đặt ứng dụng. Khác với phần mềm máy tính cá nhân, ứng dụng di động phải vận hành trong điều kiện tài nguyên hạn chế hơn về bộ nhớ, năng lượng và kích thước màn hình, đồng thời phải khai thác hiệu quả các cảm biến đặc trưng của thiết bị như máy ảnh, định vị toàn cầu (GPS), gia tốc kế hay thông báo đẩy.

Hiện nay, việc phát triển ứng dụng di động được thực hiện theo ba hướng tiếp cận phổ biến: **lập trình hướng Native**, **lập trình hướng Hybrid** và **lập trình hướng Cross-platform**. Mỗi hướng tiếp cận mang trong mình những đặc điểm về công nghệ, hiệu năng và chi phí phát triển khác nhau, do đó việc lựa chọn hướng phù hợp cho từng dự án cụ thể là một quyết định mang tính nền tảng. Các mục con dưới đây sẽ lần lượt phân tích đặc điểm, ưu điểm và hạn chế của từng hướng để làm cơ sở cho việc lựa chọn công nghệ được trình bày ở mục 2.2.

### 2.1.1. Lập trình theo hướng Native

Lập trình theo hướng Native là phương pháp phát triển ứng dụng trực tiếp cho từng hệ điều hành di động bằng đúng ngôn ngữ lập trình và bộ công cụ phát triển (SDK) chính thức mà nhà cung cấp hệ điều hành đó đưa ra. Trên nền tảng **Android**, ứng dụng được viết bằng ngôn ngữ **Java** hoặc **Kotlin** kết hợp với **Android SDK**. Trên nền tảng **iOS**, ứng dụng được viết bằng ngôn ngữ **Swift** hoặc **Objective-C** kết hợp với **iOS SDK**.

Ưu điểm nổi bật của hướng tiếp cận này là **hiệu năng tối ưu** và **khả năng tận dụng đầy đủ các tính năng của hệ điều hành**. Ứng dụng Native được biên dịch trực tiếp sang mã máy của nền tảng đích, do đó tốc độ thực thi, độ mượt khi xử lý hình ảnh động và mức tiêu thụ tài nguyên đều ở mức tốt nhất. Bên cạnh đó, lập trình viên có thể truy cập tới gần như mọi giao diện lập trình ứng dụng (API) mà hệ điều hành cung cấp, kể cả những API mới nhất được hãng phát hành. Giao diện người dùng được xây dựng bằng các thành phần gốc cũng mang lại trải nghiệm bản địa tự nhiên cho người dùng cuối.

Tuy nhiên, hướng tiếp cận này lại đặt ra một thách thức lớn về mặt chi phí phát triển. Khi một sản phẩm cần hiện diện trên cả hai nền tảng Android và iOS, nhóm phát triển buộc phải duy trì **hai mã nguồn hoàn toàn độc lập**, với hai bộ công cụ và hai bộ kỹ năng khác nhau. Điều này dẫn tới việc thời gian phát triển, chi phí kiểm thử và công sức bảo trì đều tăng lên đáng kể, đặc biệt là đối với các nhóm phát triển có quy mô nhỏ hoặc dự án có thời lượng hạn chế.

### 2.1.2. Lập trình theo hướng Hybrid

Lập trình theo hướng Hybrid là phương pháp xây dựng ứng dụng di động dựa trên nền tảng công nghệ web. Theo cách tiếp cận này, lập trình viên sử dụng các ngôn ngữ và công nghệ vốn quen thuộc trong môi trường web như **HTML**, **CSS** và **JavaScript** để xây dựng phần giao diện và phần xử lý nghiệp vụ. Toàn bộ phần này sau đó được "đóng gói" bên trong một thành phần hiển thị web (**WebView**) đặt trong một vỏ ứng dụng di động, từ đó tạo thành một ứng dụng có thể cài đặt trên thiết bị. Một số framework tiêu biểu theo hướng tiếp cận này có thể kể đến như **Apache Cordova** và **Ionic**.

Ưu điểm chính của hướng Hybrid nằm ở **khả năng tái sử dụng cao đối với các nhóm phát triển đã có sẵn nền tảng web**. Lập trình viên có thể chia sẻ một phần đáng kể mã nguồn giữa phiên bản web và phiên bản di động, đồng thời chỉ cần duy trì một mã nguồn chung cho nhiều nền tảng. Tốc độ phát triển vì thế thường nhanh hơn so với hướng Native, đặc biệt phù hợp với các ứng dụng có nội dung mang tính tài liệu, biểu mẫu hoặc trình bày thông tin.

Mặc dù vậy, hướng tiếp cận này cũng tồn tại những giới hạn quan trọng. Do ứng dụng vận hành thông qua một lớp WebView trung gian, **hiệu năng nhìn chung kém hơn so với ứng dụng Native**, đặc biệt là trong các tác vụ đòi hỏi xử lý đồ họa, hình ảnh động hoặc tương tác phức tạp với phần cứng. Giao diện người dùng cũng khó đạt được cảm giác bản địa hoàn toàn, và khả năng truy cập tới các API đặc thù của hệ điều hành thường bị giới hạn hoặc phải thông qua các plugin trung gian.

### 2.1.3. Lập trình theo hướng Cross-platform

Lập trình theo hướng Cross-platform là phương pháp cho phép xây dựng một ứng dụng từ một mã nguồn chung và triển khai được trên nhiều nền tảng di động khác nhau. Điểm khác biệt căn bản giữa hướng Cross-platform và hướng Hybrid nằm ở **cơ chế thực thi**: thay vì chạy trong một WebView, ứng dụng Cross-platform được biên dịch hoặc thông dịch trực tiếp sang các thành phần gần với mã native của nền tảng đích, từ đó đạt được hiệu năng cao hơn và trải nghiệm người dùng gần với ứng dụng Native hơn. Các framework tiêu biểu theo hướng tiếp cận này bao gồm **Flutter**, **React Native** và **Xamarin**.

Hướng tiếp cận này được đánh giá là sự cân bằng giữa hai hướng trên. Một mặt, nhóm phát triển chỉ cần duy trì **một mã nguồn duy nhất** cho cả Android và iOS, qua đó giảm đáng kể chi phí phát triển và bảo trì. Mặt khác, hiệu năng và độ mượt của giao diện thường đạt mức gần tương đương với ứng dụng Native, đủ để đáp ứng yêu cầu của phần lớn các ứng dụng di động phổ thông. Đây là lý do hướng tiếp cận Cross-platform đang ngày càng trở thành lựa chọn phổ biến của các nhóm phát triển có quy mô vừa và nhỏ.

Dù vậy, hướng Cross-platform vẫn có những giới hạn nhất định. Trong trường hợp ứng dụng cần khai thác các tính năng đặc thù mà framework chưa hỗ trợ trực tiếp — chẳng hạn như **Home-screen Widget** trên Android hay tiện ích trên màn hình khóa — nhóm phát triển vẫn cần bổ sung thêm một phần mã nguồn gốc cho từng nền tảng. Ngoài ra, kích thước gói cài đặt của ứng dụng Cross-platform thường lớn hơn một chút so với ứng dụng Native do phải đính kèm thư viện chạy của framework.

Từ những phân tích trên, có thể thấy rằng mỗi hướng tiếp cận đều có vị trí phù hợp riêng. Đối với hệ thống Meep, vốn được thực hiện bởi một nhóm phát triển có quy mô nhỏ trong thời lượng giới hạn nhưng vẫn yêu cầu hiệu năng cao và có thành phần native đặc thù (Home-screen Widget), hướng **lập trình Cross-platform** kết hợp với một phần mã nguồn gốc cho Android được lựa chọn làm phương án triển khai chính. Lựa chọn này sẽ được trình bày cụ thể trong mục tiếp theo.

---

## 2.2. Khái niệm và lý do chọn Flutter

### Khái niệm về Flutter

**Flutter** là một bộ công cụ phát triển giao diện người dùng (UI Toolkit) mã nguồn mở do **Google** phát triển và công bố phiên bản chính thức vào năm 2018. Flutter cho phép xây dựng các ứng dụng đa nền tảng từ một mã nguồn duy nhất, bao gồm ứng dụng di động trên Android và iOS, ứng dụng web trên trình duyệt, ứng dụng máy tính trên Windows, macOS và Linux, cũng như một số nền tảng nhúng. Ngôn ngữ lập trình chính được sử dụng trong Flutter là **Dart** — một ngôn ngữ hướng đối tượng, có kiểm tra kiểu (statically-typed) và cũng do Google phát triển.

Điểm đặc trưng tạo nên sự khác biệt của Flutter so với nhiều framework đa nền tảng khác nằm ở **cơ chế kết xuất giao diện**. Thay vì sử dụng các thành phần giao diện gốc của từng hệ điều hành, Flutter sử dụng một bộ máy đồ họa nội tại (engine **Skia** và sau này là **Impeller**) để tự vẽ trực tiếp toàn bộ giao diện của ứng dụng lên màn hình. Nhờ vậy, một bộ giao diện xây dựng trên Flutter có thể hiển thị một cách đồng nhất trên nhiều thiết bị và nền tảng khác nhau, đồng thời tận dụng được sức mạnh của bộ xử lý đồ họa (GPU) để bảo đảm độ mượt.

### Đặc điểm chính của Flutter

Flutter sở hữu một số đặc điểm quan trọng giúp công cụ này trở thành lựa chọn phổ biến cho việc phát triển ứng dụng di động hiện nay:

- **Mô hình widget thống nhất:** trong Flutter, mọi thành phần giao diện đều được biểu diễn dưới dạng các đơn vị gọi là **widget**, từ một nút bấm đơn lẻ cho tới toàn bộ một màn hình. Cách tiếp cận thống nhất này giúp lập trình viên dễ dàng tổ chức, tái sử dụng và mở rộng giao diện.
- **Hot reload:** mọi thay đổi trong mã nguồn được phản ánh gần như tức thì lên ứng dụng đang chạy mà không cần biên dịch lại toàn bộ dự án. Tính năng này rút ngắn đáng kể chu kỳ phát triển và thử nghiệm giao diện.
- **Hiệu năng cao:** mã nguồn Dart được biên dịch trực tiếp sang mã máy của thiết bị theo cơ chế **Ahead-of-Time (AOT)** ở chế độ phát hành, từ đó đạt được hiệu năng gần tương đương với ứng dụng Native.
- **Hệ sinh thái thư viện phong phú:** kho lưu trữ chính thức **pub.dev** cung cấp một số lượng lớn các gói thư viện cho hầu hết các nhu cầu phổ biến, từ kết nối tới dịch vụ đám mây, xử lý ảnh, làm việc với camera cho tới quản lý trạng thái và điều hướng.
- **Hỗ trợ chính thức đối với Firebase:** Google duy trì bộ thư viện **FlutterFire** — tập hợp các gói chính thức kết nối Flutter tới các dịch vụ của Firebase, đảm bảo khả năng tương thích lâu dài.
- **Khả năng tích hợp với mã nguồn gốc:** Flutter cho phép gọi tới mã Kotlin trên Android và Swift trên iOS thông qua cơ chế **Platform Channel**, từ đó hỗ trợ những tính năng đặc thù vượt quá phạm vi của framework, ví dụ như Home-screen Widget.

### Lý do chọn Flutter cho hệ thống Meep

Việc lựa chọn Flutter làm công cụ phát triển chính cho hệ thống Meep dựa trên một số yếu tố thực tế phù hợp với đặc thù của đề tài.

Thứ nhất, **một mã nguồn duy nhất giúp giảm chi phí phát triển cho nhóm sinh viên**. Mặc dù phạm vi MVP chỉ giới hạn ở nền tảng Android (theo mục 1.2.3), việc lựa chọn Flutter ngay từ đầu giúp giữ cho kiến trúc của dự án luôn sẵn sàng mở rộng sang iOS trong tương lai mà không cần viết lại từ đầu.

Thứ hai, **hiệu năng của Flutter phù hợp với đặc tính của một ứng dụng chia sẻ ảnh**. Các thao tác như chụp ảnh, hiển thị bảng tin dạng cuộn vô tận, xem ảnh ở chế độ toàn màn hình hoặc cuộn dạng lưới đều yêu cầu độ mượt cao về mặt đồ họa — điều mà cơ chế tự vẽ giao diện của Flutter có thể đáp ứng tốt.

Thứ ba, **Flutter có sự đồng bộ chặt chẽ với hệ sinh thái Firebase**. Toàn bộ các dịch vụ phía máy chủ mà Meep sử dụng — bao gồm Firebase Authentication, Cloud Firestore, Cloud Storage, Cloud Functions và Firebase Cloud Messaging — đều có thư viện chính thức cho Flutter, giúp rút ngắn đáng kể thời gian tích hợp và bảo trì.

Thứ tư, **Flutter hỗ trợ thuận lợi cho việc tích hợp Home-screen Widget trên Android**. Thông qua gói thư viện `home_widget` và cơ chế Platform Channel, dữ liệu từ Flutter có thể được truyền sang phần mã Kotlin của widget một cách rõ ràng, từ đó hiện thực hóa được thành phần đặc thù tạo nên điểm khác biệt của hệ thống.

Cuối cùng, **Flutter có cộng đồng lập trình viên sử dụng đông đảo và tài liệu hướng dẫn dồi dào**. Đây là yếu tố quan trọng đối với một nhóm sinh viên còn ở giai đoạn học hỏi, giúp việc tra cứu, giải quyết khó khăn và tham khảo các thực hành tốt trở nên dễ dàng hơn.

### So sánh Flutter với React Native

Trong số các framework phát triển ứng dụng theo hướng Cross-platform, **React Native** — do **Meta (Facebook)** phát triển — là một trong những lựa chọn phổ biến và có lịch sử trưởng thành lâu hơn Flutter. Bảng so sánh dưới đây tóm lược một số tiêu chí kỹ thuật chính giữa hai framework, từ đó làm rõ thêm cơ sở của việc lựa chọn Flutter cho hệ thống Meep.

**Bảng 2.1.** So sánh các tiêu chí kỹ thuật giữa Flutter và React Native.

| Tiêu chí | Flutter | React Native |
|---|---|---|
| Đơn vị phát triển | Google | Meta (Facebook) |
| Ngôn ngữ lập trình | Dart | JavaScript / TypeScript |
| Cơ chế kết xuất giao diện | Tự vẽ qua engine đồ họa Skia/Impeller | Cầu nối tới các thành phần Native của hệ điều hành |
| Tính nhất quán giao diện | Đồng nhất giữa các nền tảng | Có thể khác biệt do phụ thuộc thành phần Native |
| Hiệu năng | Cao, biên dịch AOT sang mã máy | Tốt, phụ thuộc cầu nối JavaScript |
| Hỗ trợ Firebase chính thức | Có, qua bộ thư viện **FlutterFire** | Có, qua thư viện cộng đồng **react-native-firebase** |
| Tích hợp Home-screen Widget Android | Có gói chính thức `home_widget` | Yêu cầu cấu hình thủ công nhiều hơn |
| Hot reload | Có | Có |

Có thể thấy rằng, mặc dù cả hai framework đều có khả năng đáp ứng các yêu cầu cơ bản của một ứng dụng chia sẻ ảnh, **Flutter** đem lại lợi thế rõ rệt hơn ở ba khía cạnh chính: tính đồng nhất của giao diện giữa các nền tảng, hiệu năng kết xuất ổn định và khả năng tích hợp Home-screen Widget trên Android. Đây là những yếu tố trực tiếp gắn với đặc thù của hệ thống Meep, qua đó củng cố cơ sở cho việc lựa chọn Flutter làm công cụ phát triển chính.

---

## 2.3. Khái niệm và lý do chọn Firebase

### Khái niệm về Firebase

**Firebase** là một nền tảng phát triển ứng dụng do **Google** cung cấp, được xây dựng theo mô hình **Backend-as-a-Service (BaaS)**. Theo mô hình này, các dịch vụ phía máy chủ thường gặp trong một ứng dụng — bao gồm xác thực người dùng, cơ sở dữ liệu, lưu trữ tệp, thông báo đẩy, máy chủ ứng dụng và lưu trữ tĩnh — được đóng gói sẵn và cung cấp dưới dạng dịch vụ đám mây có thể sử dụng thông qua một bộ thư viện thống nhất (SDK).

Thay vì phải tự xây dựng một hệ thống máy chủ riêng với cơ sở dữ liệu, máy chủ web, dịch vụ lưu trữ tệp và máy chủ thông báo, lập trình viên sử dụng Firebase có thể đăng ký một dự án trên nền tảng này, kết nối ứng dụng tới các dịch vụ tương ứng và bắt đầu phát triển phần nghiệp vụ ngay từ giai đoạn đầu của dự án. Việc vận hành hạ tầng — bao gồm khả năng chịu tải, sao lưu, bảo mật ở mức hệ thống và mở rộng quy mô — được Google trực tiếp đảm nhận và minh bạch hóa thông qua bảng điều khiển quản trị.

### Các dịch vụ Firebase được sử dụng trong hệ thống Meep

Trong khuôn khổ đề tài, hệ thống Meep sử dụng các dịch vụ chính sau đây của Firebase:

- **Firebase Authentication:** dịch vụ xác thực người dùng, hỗ trợ nhiều phương thức đăng nhập khác nhau như email/mật khẩu, tài khoản Google và một số nhà cung cấp khác. Trong Meep, hai phương thức được sử dụng là email/mật khẩu và Google Sign-In.
- **Cloud Firestore:** cơ sở dữ liệu hướng tài liệu (document-oriented NoSQL) hoạt động theo mô hình thời gian thực. Mọi dữ liệu nghiệp vụ của Meep — bao gồm hồ sơ người dùng, bài đăng, mối quan hệ bạn bè, không gian chung, nhật ký và cuộc trò chuyện — đều được lưu trữ và đồng bộ qua dịch vụ này.
- **Cloud Storage for Firebase:** dịch vụ lưu trữ tệp trên đám mây, được sử dụng để lưu các tệp ảnh do người dùng đăng tải.
- **Cloud Functions for Firebase:** môi trường thực thi mã nguồn theo mô hình **serverless** — mã được chạy mỗi khi có một sự kiện cụ thể xảy ra, ví dụ khi một bài đăng mới được tạo. Trong Meep, Cloud Functions đảm nhiệm các tác vụ phía máy chủ như phân phối bài đăng tới bảng tin của bạn bè, gửi thông báo và xử lý các tác vụ chỉ có thể thực thi an toàn trên máy chủ.
- **Firebase Cloud Messaging (FCM):** dịch vụ gửi thông báo đẩy tới thiết bị người dùng. Đây là kênh chính để hệ thống thông báo cho người dùng về các hoạt động mới như có bạn đăng bài, có lời mời kết bạn hoặc có lượt tương tác.
- **Firebase Security Rules:** không phải là một dịch vụ độc lập mà là tầng quy tắc bảo mật được áp dụng trực tiếp trên **Cloud Firestore** và **Cloud Storage**. Các quy tắc này cho phép kiểm soát quyền đọc, ghi của từng tài liệu và tệp ngay tại tầng dữ liệu, qua đó đảm bảo dữ liệu chỉ có thể được truy cập đúng đối tượng.

### Lý do chọn Firebase cho hệ thống Meep

Việc lựa chọn Firebase làm nền tảng máy chủ chính cho hệ thống Meep dựa trên một số yếu tố thực tế phù hợp với đặc thù của đề tài.

Thứ nhất, **mô hình Backend-as-a-Service giúp nhóm phát triển tập trung vào phần nghiệp vụ của ứng dụng**. Toàn bộ các tác vụ hạ tầng như cài đặt máy chủ, cấu hình cơ sở dữ liệu, quản lý chứng chỉ bảo mật và mở rộng quy mô đều được Google đảm nhiệm. Đối với một nhóm sinh viên có thời lượng đồ án hạn chế, đây là lợi thế quan trọng giúp đẩy nhanh tiến độ thực hiện.

Thứ hai, **Cloud Firestore hoạt động theo mô hình thời gian thực phù hợp với đặc tính của một ứng dụng chia sẻ ảnh**. Khi một người bạn đăng một bức ảnh mới, dữ liệu sẽ tự động được đẩy tới ứng dụng của những người bạn khác mà không cần thực hiện các thao tác cập nhật thủ công. Cơ chế này đặc biệt phù hợp với bảng tin (Feed), danh sách bạn bè và cuộc trò chuyện.

Thứ ba, **Cloud Functions cho phép xử lý logic phía máy chủ một cách an toàn mà không cần tự dựng máy chủ riêng**. Các tác vụ nhạy cảm hoặc cần đặc quyền — như phân phối bài đăng tới bảng tin của bạn bè, chấp nhận lời mời kết bạn và gửi thông báo đẩy — được thực thi bên trong môi trường serverless của Google thay vì giao cho ứng dụng phía client.

Thứ tư, **Firebase Security Rules cho phép thực thi cơ chế phân quyền ngay tại tầng dữ liệu**. Việc cấu hình các luật như "chỉ chủ bài đăng hoặc bạn bè của chủ bài đăng mới có quyền đọc bài đăng" được khai báo trực tiếp ở phía Firestore. Cách tiếp cận này đặc biệt phù hợp với một ứng dụng đề cao quyền riêng tư như Meep.

Thứ năm, **Firebase có gói sử dụng miễn phí phù hợp với phạm vi của đồ án sinh viên**. Trong giai đoạn phát triển và trình bày sản phẩm, gói **Spark** miễn phí của Firebase đủ đáp ứng nhu cầu về số lượng người dùng, lượt đọc/ghi dữ liệu và dung lượng lưu trữ.

Cuối cùng, **Firebase có sự tích hợp chặt chẽ với Flutter** thông qua bộ thư viện **FlutterFire** chính thức do Google duy trì. Điều này đảm bảo khả năng tương thích lâu dài giữa hai công nghệ chủ lực của hệ thống.

### So sánh Firebase với giải pháp Backend truyền thống

Một phương án thay thế phổ biến khác là tự xây dựng tầng máy chủ theo mô hình truyền thống, trong đó nhóm phát triển tự lựa chọn ngôn ngữ và framework cho máy chủ ứng dụng (ví dụ **Node.js + Express**, **Spring Boot** hoặc **Django**), tự cấu hình cơ sở dữ liệu quan hệ hoặc phi quan hệ (ví dụ **PostgreSQL**, **MySQL**, **MongoDB**), tự triển khai dịch vụ lưu trữ tệp và tự tích hợp dịch vụ thông báo đẩy. Bảng dưới đây tóm lược một số tiêu chí kỹ thuật chính giúp đối chiếu hai phương án này.

**Bảng 2.2.** So sánh giữa Firebase (BaaS) và phương án Backend truyền thống.

| Tiêu chí | Firebase (BaaS) | Backend truyền thống |
|---|---|---|
| Mô hình triển khai | Dịch vụ đám mây có sẵn | Tự xây dựng và triển khai |
| Cơ sở dữ liệu | Cloud Firestore (NoSQL, thời gian thực) | Tự lựa chọn, ví dụ PostgreSQL hoặc MongoDB |
| Xác thực người dùng | Tích hợp sẵn (Authentication) | Tự xây dựng hoặc tích hợp dịch vụ riêng |
| Lưu trữ tệp | Cloud Storage for Firebase | Tự cấu hình (ví dụ AWS S3, MinIO) |
| Logic phía máy chủ | Cloud Functions theo mô hình serverless | Máy chủ ứng dụng tự triển khai |
| Thông báo đẩy | Firebase Cloud Messaging | Tự tích hợp APNs/FCM hoặc dịch vụ trung gian |
| Phân quyền dữ liệu | Khai báo qua Security Rules | Tự lập trình ở tầng máy chủ |
| Khả năng mở rộng | Tự động theo nhu cầu sử dụng | Cấu hình thủ công, tốn nhiều công sức |
| Mức độ tùy biến | Giới hạn trong khuôn khổ dịch vụ | Tự kiểm soát hoàn toàn |
| Chi phí khởi đầu | Có gói miễn phí cho dự án nhỏ | Phụ thuộc vào hạ tầng và dịch vụ thuê ngoài |

Có thể thấy rằng, mỗi phương án đều có thế mạnh riêng. **Backend truyền thống** mang lại mức độ tùy biến cao và khả năng kiểm soát toàn diện đối với hạ tầng, do đó phù hợp với các hệ thống có yêu cầu nghiệp vụ phức tạp, đặc thù hoặc cần tuân thủ các quy chuẩn riêng. Trong khi đó, **Firebase** lại phù hợp hơn với các dự án có quy mô vừa và nhỏ, ưu tiên tốc độ triển khai và giảm thiểu khối lượng công việc liên quan tới hạ tầng. Trong trường hợp của đồ án Meep, các yếu tố như thời lượng phát triển giới hạn, nhóm thực hiện không có chuyên môn sâu về vận hành máy chủ và đặc tính thời gian thực cần thiết cho bảng tin và cuộc trò chuyện cùng dẫn tới việc Firebase được chọn làm nền tảng máy chủ cho hệ thống.

---

## 2.4. Kiến trúc ứng dụng theo mô hình ba lớp với Riverpod

Việc lựa chọn được công cụ phát triển phù hợp (Flutter ở phía ứng dụng di động và Firebase ở phía dịch vụ máy chủ) mới chỉ giải quyết được câu hỏi "dùng công nghệ nào". Để hệ thống có thể vận hành ổn định, dễ bảo trì và dễ mở rộng trong điều kiện có nhiều thành viên cùng tham gia phát triển, cần phải xác định thêm một kiến trúc tổ chức mã nguồn rõ ràng. Mục này trình bày mô hình kiến trúc ba lớp được áp dụng cho phần ứng dụng di động của Meep, cùng với cơ chế quản lý trạng thái và tiêm phụ thuộc dựa trên thư viện **Riverpod**.

### Mô hình kiến trúc ba lớp

Toàn bộ phần ứng dụng di động được tổ chức theo mô hình kiến trúc phân tầng gồm ba lớp tách biệt rõ ràng về vai trò: **lớp dữ liệu (data layer)**, **lớp ứng dụng (application layer)** và **lớp giao diện (presentation layer)**. Việc phân tách này tuân theo nguyên tắc **chia trách nhiệm đơn nhất (Single Responsibility Principle)** — mỗi lớp chỉ đảm nhiệm một nhóm trách nhiệm nhất định và không được phép vượt qua ranh giới đó để can thiệp vào trách nhiệm của lớp khác.

**Lớp dữ liệu (data)** là lớp duy nhất được phép giao tiếp trực tiếp với các dịch vụ phía máy chủ và các nguồn dữ liệu bên ngoài, bao gồm **Cloud Firestore**, **Cloud Storage**, **Firebase Authentication** và bộ nhớ đệm cục bộ trên thiết bị. Toàn bộ các thao tác đọc, ghi, truy vấn hay nhận dữ liệu thời gian thực đều được đóng gói trong các lớp được gọi là **Repository**. Mỗi Repository chịu trách nhiệm cho một thực thể nghiệp vụ cụ thể, ví dụ `AuthRepository` xử lý đăng nhập – đăng ký, `PostRepository` xử lý bài đăng và `FriendshipRepository` xử lý quan hệ bạn bè. Mọi đối tượng tài liệu thô từ Firestore đều được chuyển đổi thành các lớp dữ liệu bất biến (immutable) ngay tại Repository thông qua thư viện **freezed** và **json_serializable**, từ đó đảm bảo dữ liệu lưu hành trong ứng dụng luôn có kiểu dữ liệu xác định và an toàn.

**Lớp ứng dụng (application)** đóng vai trò trung gian giữa lớp dữ liệu và lớp giao diện. Đây là nơi tập trung **logic nghiệp vụ** của hệ thống — bao gồm điều phối các luồng xử lý phức tạp, quản lý trạng thái của từng chức năng, kiểm tra điều kiện hợp lệ và chuyển đổi dữ liệu thô thành dữ liệu phục vụ hiển thị. Các thành phần chính trong lớp này được gọi là **Controller** (hoặc **Notifier**), trong đó mỗi Controller chịu trách nhiệm cho một luồng nghiệp vụ cụ thể, ví dụ `SignUpController` cho luồng đăng ký bốn bước, `FeedController` cho luồng tải bảng tin và `PostController` cho luồng tạo bài đăng mới. Lớp ứng dụng không được phép gọi trực tiếp tới các dịch vụ Firebase mà phải đi qua các Repository tương ứng ở lớp dữ liệu.

**Lớp giao diện (presentation)** là lớp ngoài cùng, chịu trách nhiệm về toàn bộ phần hiển thị và tương tác với người dùng. Các thành phần ở lớp này là các **widget** trong Flutter — từ các trang màn hình (Page) cho tới các thành phần nhỏ hơn như nút bấm, danh sách hay biểu mẫu. Nguyên tắc thiết kế của lớp giao diện là **"chỉ hiển thị trạng thái và phát đi ý định người dùng"** (render state and dispatch intents) — widget không trực tiếp gọi tới Firebase, không xử lý logic nghiệp vụ và cũng không tự ý biến đổi dữ liệu. Khi người dùng thao tác, widget gửi tín hiệu tới Controller tương ứng ở lớp ứng dụng; khi Controller cập nhật trạng thái, widget tự động vẽ lại theo trạng thái mới.

Cơ chế phân tách trên có thể được biểu diễn một cách trực quan thông qua sơ đồ kiến trúc ba lớp dưới đây:

> **Hình 2.** Mô hình kiến trúc ba lớp `data` – `application` – `presentation` của ứng dụng di động Meep.
> *[CẦN BỔ SUNG: chèn sơ đồ ba lớp xếp chồng — lớp Presentation (Widget/Page) ở trên, lớp Application (Controller/Notifier) ở giữa, lớp Data (Repository) ở dưới; mũi tên một chiều thể hiện rằng các lớp phía trên gọi tới các lớp phía dưới qua giao diện trừu tượng (abstract interface), và Repository giao tiếp với Firebase ở ngoài cùng.]*

### Quản lý trạng thái và tiêm phụ thuộc bằng Riverpod

Để hệ thống ba lớp nêu trên có thể hoạt động một cách thống nhất, ứng dụng Meep sử dụng **Riverpod** — một thư viện quản lý trạng thái và tiêm phụ thuộc (Dependency Injection) phổ biến trong cộng đồng Flutter. Riverpod đóng đồng thời hai vai trò chính trong kiến trúc của hệ thống.

Thứ nhất, Riverpod cung cấp một cơ chế **tiêm phụ thuộc thống nhất** giữa các lớp. Mọi đối tượng phụ thuộc — từ các Repository ở lớp dữ liệu cho tới các Controller ở lớp ứng dụng — đều được khai báo dưới dạng **Provider**. Khi một widget hay một Controller cần sử dụng một thành phần khác, nó đăng ký phụ thuộc đó thông qua Provider tương ứng thay vì khởi tạo trực tiếp. Cách tiếp cận này giúp các thành phần trở nên độc lập với phần cài đặt cụ thể, qua đó tạo điều kiện thuận lợi cho việc thay thế phần cài đặt khi cần (ví dụ thay `FirebaseAuthRepository` bằng một phiên bản giả lập trong quá trình kiểm thử).

Thứ hai, Riverpod cung cấp một mô hình **quản lý trạng thái phản ứng (reactive state management)**. Trạng thái của từng Controller được biểu diễn dưới dạng một đối tượng bất biến và được tự động phát đi cho mọi widget đang lắng nghe mỗi khi có thay đổi. Nhờ vậy, lớp giao diện luôn phản ánh đúng trạng thái nghiệp vụ tại thời điểm hiện tại mà không cần lập trình viên viết các đoạn mã đồng bộ thủ công. Đối với các dữ liệu thay đổi liên tục theo thời gian — như bảng tin, danh sách bạn bè hay cuộc trò chuyện — Riverpod hỗ trợ sẵn các kiểu Provider chuyên dụng cho luồng dữ liệu bất đồng bộ như `StreamProvider` và `FutureProvider`.

### Lý do lựa chọn kiến trúc ba lớp cho hệ thống Meep

Việc áp dụng mô hình kiến trúc ba lớp kết hợp Riverpod cho hệ thống Meep được lựa chọn dựa trên một số yếu tố thực tế.

Thứ nhất, **kiến trúc phân lớp giúp giảm sự phụ thuộc trực tiếp vào Firebase trong toàn bộ mã nguồn**. Mọi thao tác liên quan tới Firestore, Cloud Storage hay Firebase Authentication chỉ tồn tại trong lớp dữ liệu. Phần còn lại của ứng dụng làm việc thông qua các giao diện trừu tượng. Nếu trong tương lai hệ thống cần thay thế một dịch vụ phía máy chủ — chẳng hạn chuyển đổi từ Firestore sang một cơ sở dữ liệu khác — chỉ phần cài đặt của Repository cần thay đổi, các lớp phía trên không bị ảnh hưởng.

Thứ hai, **kiến trúc phân lớp tạo điều kiện thuận lợi cho việc kiểm thử**. Mỗi lớp có thể được kiểm thử độc lập: Repository được kiểm thử với Firestore giả lập (`fake_cloud_firestore`) và Firebase Authentication giả lập (`firebase_auth_mocks`); Controller được kiểm thử với Repository giả; widget được kiểm thử với Controller giả. Nhờ vậy, các trường hợp lỗi và biên có thể được kiểm tra một cách có hệ thống.

Thứ ba, **kiến trúc phân lớp phù hợp với mô hình tổ chức nhóm phát triển**. Trong dự án Meep, mỗi thành viên phụ trách trọn vẹn một mô-đun nghiệp vụ từ tầng dữ liệu đến tầng giao diện. Việc phân tầng rõ ràng giúp các thành viên dễ dàng tuân theo cùng một khuôn mẫu, đồng thời giảm nguy cơ phát sinh xung đột khi nhiều người cùng làm việc trên các mô-đun khác nhau của ứng dụng.

Cuối cùng, **kiến trúc phân lớp tạo nền tảng cho việc mở rộng hệ thống về sau**. Khi cần bổ sung một chức năng mới — ví dụ thêm hỗ trợ chụp ảnh đồng thời hai camera hoặc thêm một nguồn dữ liệu cục bộ cho chế độ ngoại tuyến — chỉ cần bổ sung thêm các thành phần ở từng lớp tương ứng theo cùng khuôn mẫu đã có, mà không phải tái cấu trúc toàn bộ ứng dụng.

---

## 2.5. Home-screen Widget Android

Một trong những điểm khác biệt quan trọng của hệ thống Meep so với các ứng dụng cùng phân khúc là khả năng hiển thị ảnh mới nhất từ bạn bè ngay trên màn hình chính của thiết bị mà không cần mở ứng dụng. Tính năng này được hiện thực hóa thông qua cơ chế **Home-screen Widget** trên nền tảng Android. Do đây là một thành phần mã nguồn gốc (native) nằm bên ngoài phạm vi của Flutter, mục này trình bày cơ sở lý thuyết về cơ chế hoạt động của Home-screen Widget và cách thức tích hợp với phần ứng dụng Flutter của Meep.

### Khái niệm về Home-screen Widget

**Home-screen Widget** (còn được gọi là **AppWidget** trong hệ điều hành Android) là một dạng tiện ích cho phép ứng dụng trình bày một phần nội dung trực tiếp trên màn hình chính của thiết bị, song song với các biểu tượng (icon) của các ứng dụng khác. Khác với một biểu tượng thông thường vốn chỉ giữ vai trò mở ứng dụng, widget thực sự **hiển thị nội dung sống** — ví dụ thời tiết hiện tại, lịch ngày, các bài hát đang phát hoặc, trong trường hợp của Meep, là bức ảnh mới nhất từ bạn bè.

Về mặt kỹ thuật, một AppWidget trên Android được hiện thực hóa thông qua một thành phần gọi là **AppWidgetProvider** — đây là một dạng đặc biệt của **BroadcastReceiver**, hoạt động dưới sự điều phối của hệ điều hành. AppWidgetProvider không tự vẽ giao diện một cách trực tiếp như một `Activity` hay `Fragment` thông thường, mà phải sử dụng một cơ chế trung gian gọi là **RemoteViews**.

### Cơ chế hoạt động

Trong kiến trúc của Android, widget được vẽ bên trong tiến trình của **ứng dụng Launcher** (ví dụ Pixel Launcher, Samsung One UI Launcher) chứ không phải tiến trình của ứng dụng sở hữu widget. Điều này dẫn đến hai hệ quả quan trọng về mặt kỹ thuật.

Thứ nhất, do widget chạy ở tiến trình khác, **ứng dụng sở hữu widget không thể trực tiếp can thiệp vào giao diện của widget**. Mọi thay đổi về nội dung phải được mô tả dưới dạng một đối tượng **RemoteViews** — một dạng "mô tả giao diện có thể truyền qua tiến trình" do Android cung cấp — sau đó gửi tới hệ thống thông qua phương thức `AppWidgetManager.updateAppWidget()`. Hệ thống Launcher sẽ nhận đối tượng này và thay mặt ứng dụng vẽ lại giao diện của widget trên màn hình chính.

Thứ hai, **widget không thể chứa các thành phần giao diện tùy ý** mà chỉ được sử dụng một tập hợp giới hạn các thành phần được Android cho phép trong RemoteViews, ví dụ `ImageView`, `TextView`, `LinearLayout` và `Button`. Đặc điểm này khiến cho việc thiết kế giao diện cho widget có những giới hạn nhất định so với việc thiết kế giao diện thông thường của một ứng dụng.

Để widget có thể tự cập nhật nội dung theo thời gian — chẳng hạn khi bạn bè đăng một bức ảnh mới — Android cung cấp một số cơ chế cập nhật khác nhau. Trong số đó, cơ chế được sử dụng cho hệ thống Meep là **WorkManager** — một thành phần thuộc bộ thư viện **Android Jetpack** chuyên dùng để lên lịch và thực thi các tác vụ nền một cách đáng tin cậy. WorkManager cho phép ứng dụng đăng ký một tác vụ định kỳ (**PeriodicWorkRequest**) với chu kỳ tối thiểu khoảng mười lăm phút. Tác vụ này được hệ điều hành đảm bảo thực thi ngay cả khi ứng dụng không đang chạy, đồng thời tự động điều chỉnh thời điểm thực thi để phù hợp với chế độ tiết kiệm pin (**Doze mode**) của thiết bị.

Bên cạnh việc cập nhật nội dung, widget còn có thể phản hồi tương tác của người dùng thông qua cơ chế **PendingIntent**. Khi người dùng chạm vào widget, hệ thống sẽ kích hoạt một `Intent` đã được đăng ký từ trước, từ đó dẫn người dùng tới một màn hình cụ thể trong ứng dụng — đây chính là cơ sở để Meep hiện thực hóa luồng "chạm vào widget để mở bài đăng" (deep link).

> **Hình 3.** Cơ chế hoạt động của Home-screen Widget trên Android trong hệ thống Meep.
> *[CẦN BỔ SUNG: chèn sơ đồ luồng — gồm các khối **WorkManager** (PeriodicWorkRequest) → **WidgetSyncWorker** (đọc dữ liệu từ Firebase Authentication và Cloud Firestore) → **RemoteViews** (xây dựng lại giao diện widget) → **AppWidgetManager.updateAppWidget()** → **Launcher** vẽ lại widget trên màn hình chính; thêm một mũi tên thể hiện luồng **PendingIntent** từ widget khi người dùng chạm vào để mở ứng dụng tại bài đăng tương ứng.]*

### Tích hợp giữa Flutter và Widget Android trong hệ thống Meep

Mặc dù phần ứng dụng chính của Meep được phát triển bằng Flutter, toàn bộ phần Home-screen Widget vẫn phải được hiện thực hóa bằng mã nguồn gốc Kotlin do bản thân framework Flutter không hỗ trợ trực tiếp việc vẽ giao diện trên một thành phần widget của hệ điều hành. Để giải quyết vấn đề này, hệ thống sử dụng gói thư viện **`home_widget`** trên kho **pub.dev** — đây là một cầu nối được xây dựng dựa trên cơ chế **Platform Channel** đã được giới thiệu ở mục 2.2.

Cơ chế tích hợp được tổ chức như sau. Phần Flutter chịu trách nhiệm xử lý các luồng nghiệp vụ liên quan tới người dùng — đăng nhập, kết bạn, đăng bài — và lưu trữ một số thông tin tham chiếu vào bộ nhớ dùng chung giữa hai phía (ví dụ thời điểm gần nhất người dùng mở ứng dụng, dùng để tính số bài chưa xem). Phần Kotlin gồm hai thành phần chính: **MeepWidget** (`MeepWidget.kt`) đóng vai trò là AppWidgetProvider chịu trách nhiệm dựng giao diện thông qua RemoteViews, và **WidgetSyncWorker** (`WidgetSyncWorker.kt`) đóng vai trò là Worker chạy nền do WorkManager điều phối, định kỳ truy vấn dữ liệu trực tiếp từ Cloud Firestore bằng phiên xác thực hiện có của Firebase Authentication.

Cách tiếp cận trên cho phép widget vận hành **độc lập với trạng thái mở/đóng của ứng dụng Flutter**. Ngay cả khi người dùng không mở Meep trong một khoảng thời gian dài, miễn là phiên đăng nhập Firebase còn hiệu lực, widget vẫn có thể truy vấn dữ liệu mới và tự cập nhật nội dung trên màn hình chính của thiết bị.

### Vai trò trong hệ thống Meep và phạm vi triển khai

Trong tổng thể hệ thống Meep, Home-screen Widget được xác định là **một kênh hiển thị nội dung độc lập song song với ứng dụng chính**, thay vì chỉ là một tiện ích phụ. Vai trò cụ thể của widget bao gồm: hiển thị ảnh mới nhất từ bạn bè dưới dạng ảnh kích thước **2×2** trên màn hình chính, hiển thị huy hiệu (badge) đếm số bài chưa xem, và đóng vai trò làm lối tắt mở ứng dụng tại đúng bài đăng mà người dùng quan tâm.

Về phạm vi triển khai, theo quyết định đã trình bày tại mục 1.2.3, hệ thống Meep chỉ hiện thực hóa Home-screen Widget trên nền tảng **Android** trong phiên bản MVP. Phiên bản dành cho nền tảng **iOS** thông qua khung tương ứng (**WidgetKit**) được lùi lại sau giai đoạn MVP do yêu cầu phải xây dựng một mã nguồn gốc hoàn toàn riêng biệt bằng Swift, cũng như do các điều kiện về thiết bị phát triển và quy trình phát hành trên kho ứng dụng của Apple chưa phù hợp với khuôn khổ đồ án.

Từ những phân tích trên, có thể thấy rằng việc hiện thực hóa Home-screen Widget không đơn thuần là một quyết định về giao diện mà còn liên quan trực tiếp tới các cơ chế nền tảng của hệ điều hành Android, từ AppWidgetProvider, RemoteViews cho tới WorkManager và Platform Channel. Việc nắm vững các cơ sở lý thuyết được trình bày trong chương này là tiền đề cần thiết cho phần thiết kế và hiện thực hóa hệ thống được trình bày trong các chương tiếp theo.