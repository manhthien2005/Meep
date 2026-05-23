# CHƯƠNG 5. HIỆN THỰC ỨNG DỤNG

Chương này trình bày kết quả hiện thực hóa hệ thống Meep dưới dạng các giao diện thực tế đã được xây dựng trên thiết bị di động và Home-screen Widget Android. Trên cơ sở các yêu cầu chức năng đã được mô tả ở chương 3 và mô hình dữ liệu đã được trình bày ở chương 4, nhóm thực hiện đã tiến hành lập trình toàn bộ hệ thống bằng **Flutter** ở phía ứng dụng di động, **Kotlin** ở phía Home-screen Widget, và **TypeScript** trên môi trường **Cloud Functions** của Firebase ở phía máy chủ. Các giao diện được mô tả trong chương này đều là các giao diện đã được hiện thực hóa, tích hợp với các dịch vụ phía máy chủ và đã được vận hành thử nghiệm trên thiết bị Android thực tế.

Mỗi mục trong chương được tổ chức theo cấu trúc thống nhất: một đoạn giới thiệu ngắn về vai trò của nhóm màn hình, các ảnh chụp giao diện thực tế (screenshot), và phần mô tả các thao tác đặc trưng mà người dùng có thể thực hiện trên nhóm màn hình đó. Toàn bộ nội dung của chương tập trung vào **kết quả nhìn thấy được** của hệ thống, không lặp lại phần phân tích yêu cầu đã trình bày trong các chương trước.

Trong phạm vi MVP, các nhóm màn hình được hiện thực hóa bao gồm: màn hình khởi động và xác thực người dùng, màn hình chụp ảnh và đăng bài, bảng tin và xem dạng lưới, quản lý bạn bè, thả cảm xúc, thông báo, hồ sơ cá nhân, không gian chung, nhật ký, trò chuyện, Home-screen Widget trên Android, và cài đặt.

---

## 5.1. Màn hình Khởi động và Xác thực người dùng

Nhóm màn hình Khởi động và Xác thực là nhóm màn hình đầu tiên mà mọi người dùng tiếp xúc khi mở ứng dụng. Toàn bộ nhóm này được thiết kế nhằm dẫn dắt người dùng đi từ trạng thái chưa có tài khoản hoặc chưa đăng nhập đến trạng thái sẵn sàng sử dụng các chức năng chính của hệ thống. Giao diện được thiết kế tối giản, mỗi màn hình chỉ tập trung vào một loại thông tin nhập liệu duy nhất nhằm giảm tải nhận thức cho người dùng trong quá trình đăng ký hoặc đăng nhập.

> **Hình 19.** Giao diện các màn hình thuộc nhóm Khởi động và Xác thực người dùng.
> *[CẦN BỔ SUNG: chèn dãy ảnh chụp màn hình thực tế theo thứ tự sau, mỗi ảnh chiếm khoảng nửa chiều rộng trang: (1) Màn hình Khởi động (Intro) với biểu trưng Meep, tagline và hai nút "Tạo tài khoản mới" / "Đăng nhập"; (2) Màn hình Nhập email khi đăng ký; (3) Màn hình Chọn mật khẩu; (4) Màn hình Nhập họ và tên; (5) Màn hình Chọn tên người dùng (ba trạng thái: ô trống, đang kiểm tra tính khả dụng, khả dụng); (6) Hộp thoại lựa chọn tài khoản Google khi đăng nhập bằng Google; (7) Màn hình Nhập mật khẩu khi đăng nhập (có liên kết "Bạn đã quên mật khẩu?"); (8) Màn hình Khôi phục mật khẩu; (9) Màn hình chào mừng "Bạn đã sẵn sàng" hiện ra trước khi chuyển vào màn hình chính.]*

Khi mở ứng dụng lần đầu, người dùng được đưa tới **màn hình Khởi động (Intro)** với hai lựa chọn rõ ràng: tạo tài khoản mới hoặc đăng nhập vào tài khoản đã có. Đây là điểm phân nhánh đầu tiên trong luồng xác thực — mỗi lựa chọn dẫn người dùng đi vào một dãy màn hình riêng biệt nhưng có chung phong cách trình bày.

Luồng đăng ký bằng email và mật khẩu được chia thành **bốn màn hình tuần tự**, mỗi màn hình thu thập một loại thông tin nhất định: địa chỉ thư điện tử, mật khẩu, họ và tên, và tên người dùng. Đặc biệt, trên màn hình Chọn tên người dùng, hệ thống thực hiện kiểm tra tính khả dụng theo thời gian thực sau mỗi ký tự được nhập, với phản hồi trực quan bằng đường viền và biểu tượng tích xanh khi tên người dùng hợp lệ và khả dụng. Bên cạnh luồng đăng ký bằng email, người dùng cũng có thể chọn nút "Tiếp tục với Google" trên màn hình nhập email để rút ngắn luồng đăng ký thông qua dịch vụ Google Sign-In.

Luồng đăng nhập có cấu trúc tương tự nhưng ngắn hơn — chỉ gồm hai bước nhập liệu (email và mật khẩu) và một màn hình chào mừng trước khi chuyển vào màn hình chính. Trên màn hình nhập mật khẩu, người dùng có thể truy cập liên kết "Bạn đã quên mật khẩu?" để mở luồng khôi phục mật khẩu — gửi thư điện tử kèm liên kết đặt lại do Firebase Authentication quản lý.

Sau lần đăng nhập thành công đầu tiên, hệ thống ghi nhớ phiên làm việc của người dùng. Trong các lần mở ứng dụng tiếp theo, người dùng sẽ không phải nhìn thấy lại màn hình Khởi động hay nhập lại thông tin xác thực, mà được đưa thẳng đến màn hình chính — trừ khi người dùng chủ động đăng xuất từ phần Cài đặt.

---

## 5.2. Màn hình Chụp ảnh và đăng bài

Nhóm màn hình Chụp ảnh và đăng bài là nhóm màn hình trung tâm của hệ thống, nơi diễn ra hành vi cốt lõi của một ứng dụng chia sẻ ảnh. Khác với nhiều ứng dụng đặt camera trong một tab phụ, hệ thống Meep đặt **phần Camera ngay tại nửa trên của màn hình chính**. Cách bố trí này cho phép người dùng có thể chụp một bức ảnh ngay khi mở ứng dụng mà không phải thực hiện thêm thao tác điều hướng nào.

> **Hình 20.** Giao diện các màn hình thuộc nhóm Chụp ảnh và đăng bài.
> *[CẦN BỔ SUNG: chèn dãy ảnh chụp màn hình thực tế theo thứ tự: (1) Màn hình chính với phần Camera ở vị trí trên cùng (khung ngắm, các nút điều khiển: Thư viện, Chụp, Đảo camera, nút "N người bạn"); (2) Trạng thái khi camera đang mở viewfinder thực sự (hiển thị hình ảnh từ camera của thiết bị); (3) Màn hình Xem trước ảnh với chú thích mặc định để trống và bộ chọn đối tượng nhận "Tất cả"; (4) Modal chọn loại chú thích với bảy biểu tượng tương ứng bảy loại; (5) Trạng thái sau khi chọn đối tượng nhận cụ thể (các ảnh đại diện bạn bè được làm nổi bật); (6) Trạng thái đang gửi bài đăng (biểu tượng quay); (7) Trạng thái sau khi lưu cục bộ thành công (biểu tượng dấu tích thay biểu tượng tải xuống).]*

Khi người dùng mở ứng dụng và đã đăng nhập, **phần Camera** trên màn hình chính hiển thị khung ngắm hình vuông cùng các điều khiển phụ: nút bật/tắt đèn pin, nhãn mức thu phóng, và ba nút thao tác chính ở phía dưới (mở thư viện, chụp ảnh, đảo camera trước/sau). Bên trên khung ngắm có nút "N người bạn" hiển thị số bạn bè hiện tại — đây cũng chính là bộ chọn đối tượng nhận mặc định cho bài đăng sắp tới. Ảnh đại diện ở góc trên bên phải là lối tắt mở bottom sheet Cài đặt.

Sau khi chạm vào nút Chụp, hệ thống chuyển sang **màn hình Xem trước ảnh** — đây là nơi tập trung toàn bộ các tinh chỉnh trước khi bài đăng được phát đi. Ảnh vừa chụp được hiển thị ở vùng trung tâm. Một thẻ chú thích (caption pill) đặt chồng lên phía dưới ảnh; người dùng có thể vuốt qua lại để chuyển nhanh giữa bảy loại chú thích, hoặc chạm vào thẻ để mở modal chọn loại chú thích đầy đủ và nhập nội dung. Phía dưới ảnh là bộ chọn đối tượng nhận với nút "Tất cả" được chọn mặc định và một dãy ảnh đại diện của các bạn bè để người dùng có thể tùy chọn gửi cho từng người cụ thể.

Trên màn hình Xem trước, các nút phụ ở phía trên cho phép người dùng hủy bỏ (nút X) hoặc lưu bản sao ảnh vào thư viện của thiết bị (nút mũi tên xuống) mà không thực hiện đăng bài. Khi người dùng chọn nút "Gửi", hệ thống thực hiện đồng thời tải tệp ảnh lên dịch vụ lưu trữ và tạo bản ghi bài đăng trong cơ sở dữ liệu; sau khi hoàn tất, người dùng được đưa quay lại màn hình chính với phần Camera ở trạng thái sẵn sàng cho lần chụp tiếp theo.

---

## 5.3. Màn hình Bảng tin và xem dạng lưới

Nhóm màn hình Bảng tin được đặt ngay phía dưới phần Camera trên màn hình chính. Hệ thống sử dụng cơ chế cuộn liên tục cho cả hai phần — người dùng cuộn xuống để xem bảng tin và cuộn lên trở lại phần Camera. Cách bố trí này giúp hai chức năng cốt lõi của hệ thống (chụp ảnh và xem ảnh của bạn bè) tồn tại trong cùng một luồng cuộn dọc thay vì được chuyển bằng các tab riêng biệt.

> **Hình 21.** Giao diện các màn hình thuộc nhóm Bảng tin và xem dạng lưới.
> *[CẦN BỔ SUNG: chèn dãy ảnh chụp màn hình thực tế theo thứ tự: (1) Màn hình chính sau khi cuộn xuống, hiển thị Bảng tin với một thẻ bài đăng của bạn bè (đầy đủ thanh tương tác cảm xúc và ô gửi tin nhắn); (2) Thẻ bài đăng của chính người dùng (có nhãn "Bạn" thay cho tên hiển thị); (3) Trạng thái dropdown của bộ lọc Bạn bè khi được mở (liệt kê "Mọi người", "Bạn", và các bạn bè theo từng người); (4) Bảng tin sau khi đã lọc theo một người bạn cụ thể (nhãn ở thanh trên cùng đổi sang tên người bạn); (5) Chế độ xem dạng lưới ba cột; (6) Màn hình Xem ảnh toàn màn hình từ chế độ lưới; (7) Trạng thái rỗng của Bảng tin khi người dùng chưa có bạn bè hoặc bạn bè chưa đăng bài nào.]*

Mỗi bài đăng trên Bảng tin được trình bày dưới dạng một thẻ chiếm trọn chiều rộng màn hình, với ảnh ở kích thước vuông và các thông tin phụ được sắp xếp xung quanh. Đối với bài đăng của bạn bè, hệ thống hiển thị: tên hiển thị và thời điểm đăng dưới dạng nhãn ở phía dưới ảnh, chú thích (nếu có) được đặt chồng lên ảnh dưới dạng pill, và một thanh tương tác ở phía dưới gồm ba biểu tượng cảm xúc thường dùng và ô gửi tin nhắn. Đối với bài đăng của chính người dùng, thẻ hiển thị nhãn "Bạn" thay cho tên hiển thị, kèm theo thông tin về số lượng phản hồi đã nhận được.

Phía trên Bảng tin là một thanh điều khiển nhỏ gồm ba thành phần: **bộ lọc Bạn bè** (mặc định "Mọi người"), nút chuyển sang chế độ xem dạng lưới, và biểu tượng chia sẻ. Khi người dùng chạm vào bộ lọc, hệ thống mở danh sách thả xuống cho phép lọc bài đăng theo "Mọi người", "Bạn" (chỉ bài của chính người dùng) hoặc theo từng người bạn cụ thể. Sau khi chọn, nhãn của nút lọc được cập nhật và bảng tin được vẽ lại theo dữ liệu đã lọc.

Khi người dùng chuyển sang **chế độ xem dạng lưới**, hệ thống hiển thị toàn bộ các bài đăng dưới dạng lưới ba cột, mỗi ô là một bài đăng được thu nhỏ. Bộ lọc Bạn bè được giữ nguyên giữa hai chế độ. Khi chạm vào một bài đăng trong lưới, hệ thống mở màn hình Xem ảnh toàn màn hình với các thông tin chi tiết tương tự như trên thẻ ở chế độ xem mặc định.

---

## 5.4. Màn hình Quản lý bạn bè

Toàn bộ các thao tác liên quan tới quản lý bạn bè được tập trung trong **bottom sheet "Bạn bè"** — một thành phần giao diện trượt lên từ phía dưới màn hình chính. Bottom sheet này được kích hoạt từ nút "N người bạn" trên phần Camera của màn hình chính, và đóng vai trò là điểm tập trung cho năm luồng nhỏ: xem danh sách bạn bè, tìm kiếm và gửi lời mời, chấp nhận hoặc từ chối lời mời nhận được, hủy kết bạn, và chia sẻ liên kết mời sử dụng ứng dụng.

> **Hình 22.** Giao diện các màn hình thuộc nhóm Quản lý bạn bè.
> *[CẦN BỔ SUNG: chèn dãy ảnh chụp màn hình thực tế theo thứ tự: (1) Bottom sheet "Bạn bè" ở trạng thái mặc định, hiển thị đủ bốn khu vực: ô tìm kiếm, khu vực "Yêu cầu kết bạn", khu vực "Chia sẻ liên kết Meep của bạn", và khu vực "Bạn bè của bạn"; (2) Trạng thái khi ô tìm kiếm được mở rộng và các khu vực khác bị ẩn đi; (3) Kết quả tìm kiếm có người dùng chưa kết bạn với nút "Gửi kết bạn"; (4) Kết quả tìm kiếm trùng với chính người dùng (nhãn "Đây là tôi"); (5) Trạng thái khi không tìm thấy người dùng; (6) Bottom sheet "Bạn bè" hiển thị một lời mời kết bạn đang chờ xử lý (với nút "Chấp nhận" và biểu tượng từ chối); (7) Hộp thoại xác nhận hủy kết bạn.]*

Khi mở bottom sheet, người dùng nhìn thấy bốn khu vực được sắp xếp từ trên xuống. Ô tìm kiếm "Thêm một người bạn mới" được đặt ở vị trí dễ thao tác nhất; khu vực "Yêu cầu kết bạn" chỉ hiển thị khi có ít nhất một lời mời đang chờ xử lý, mỗi mục gồm ảnh đại diện và tên người gửi kèm hai nút thao tác "Chấp nhận" (màu chủ đạo của ứng dụng) và biểu tượng dấu chéo (từ chối); khu vực "Chia sẻ liên kết Meep của bạn" cung cấp các phương thức chia sẻ liên kết mời cho những người chưa có tài khoản; khu vực "Bạn bè của bạn" liệt kê tất cả bạn bè hiện tại theo dạng cuộn dọc.

Khi người dùng chạm vào ô tìm kiếm, ô được mở rộng và các khu vực còn lại được ẩn đi để tập trung vào trải nghiệm tìm kiếm. Việc nhập từ khóa được debounce khoảng năm trăm mili-giây trước khi truy vấn cơ sở dữ liệu; trong khi truy vấn, hệ thống hiển thị biểu tượng quay nhỏ. Hệ thống xử lý ba khả năng phản hồi: tìm thấy một người dùng chưa kết bạn (hiển thị thẻ kèm nút "Gửi kết bạn"), tìm thấy một người dùng đã là bạn (hiển thị thẻ kèm nút "Trang cá nhân"), hoặc không tìm thấy (hiển thị thông báo tương ứng). Trường hợp đặc biệt, nếu tên người dùng tìm trùng với chính người dùng đang đăng nhập, hệ thống hiển thị thẻ kèm nhãn "Đây là tôi" thay vì cho phép gửi lời mời cho bản thân.

Đối với mỗi mục trong danh sách bạn bè hiện có, một biểu tượng dấu chéo ở phía bên phải cho phép người dùng hủy kết bạn — sau khi xác nhận qua hộp thoại, hệ thống xóa quan hệ bạn bè khỏi cơ sở dữ liệu và cập nhật lại số lượng bạn của cả hai phía. Người dùng cũng có thể chia sẻ liên kết mời sử dụng ứng dụng — liên kết được sao chép vào bộ nhớ tạm hoặc được chuyển qua bảng chia sẻ hệ thống của Android tùy theo phương thức được chọn.

---

## 5.5. Màn hình Thả cảm xúc

Khác với các nhóm màn hình khác trong chương này, chức năng Thả cảm xúc không có màn hình riêng mà được tích hợp trực tiếp vào thẻ bài đăng trên Bảng tin. Thanh thao tác cảm xúc được đặt ngay phía dưới mỗi ảnh, cho phép người dùng phản hồi nhanh mà không phải rời khỏi luồng cuộn bảng tin. Các thành phần giao diện bổ sung — bộ chọn cảm xúc đầy đủ và danh sách phản hồi — được trình bày dưới dạng bottom sheet trượt lên từ phía dưới.

> **Hình 23.** Giao diện các thành phần thuộc nhóm Thả cảm xúc.
> *[CẦN BỔ SUNG: chèn dãy ảnh chụp màn hình thực tế theo thứ tự: (1) Thẻ bài đăng của bạn bè với thanh thao tác cảm xúc ở trạng thái mặc định (ba biểu tượng cảm xúc preset và một biểu tượng dấu cộng); (2) Trạng thái sau khi thả một biểu tượng cảm xúc preset (biểu tượng được chọn được làm nổi bật và số đếm tăng lên); (3) Bottom sheet bộ chọn cảm xúc đầy đủ với danh sách biểu tượng phong phú được phân loại theo chủ đề; (4) Trạng thái sau khi thay đổi sang một biểu tượng khác từ bộ chọn đầy đủ; (5) Bottom sheet "Danh sách phản hồi" liệt kê những người đã thả cảm xúc cùng biểu tượng tương ứng, sắp xếp theo thời gian gần nhất ở phía trên.]*

Thanh thao tác cảm xúc trên mỗi thẻ bài đăng gồm **ba biểu tượng cảm xúc preset** được lựa chọn nhằm bao quát các phản hồi thường gặp nhất, kèm theo một biểu tượng dấu cộng cho phép mở bộ chọn đầy đủ. Khi người dùng chạm vào một biểu tượng, hệ thống ngay lập tức ghi nhận phản hồi vào cơ sở dữ liệu và cập nhật giao diện theo cơ chế **cập nhật lạc quan (optimistic update)** — biểu tượng được chọn chuyển sang trạng thái nổi bật và số đếm cảm xúc tăng lên một đơn vị trước khi nhận được xác nhận từ máy chủ. Nếu thao tác thất bại do mất kết nối, hệ thống khôi phục trạng thái cũ và hiển thị thông báo lỗi.

Cơ chế **một người dùng chỉ có một cảm xúc trên một bài đăng** được hiện thực hóa trực tiếp tại tầng giao diện. Khi người dùng đã thả một biểu tượng và chạm vào một biểu tượng khác, hệ thống chỉ cập nhật trường biểu tượng trong bản ghi cảm xúc đã có thay vì tạo bản ghi mới — số đếm tổng không thay đổi. Khi người dùng chạm lại đúng biểu tượng đang ở trạng thái nổi bật, hệ thống xóa bản ghi cảm xúc; biểu tượng trở về trạng thái bình thường và số đếm giảm đi một đơn vị.

Khi người dùng chạm vào vùng hiển thị số đếm cảm xúc trên thanh thao tác, hệ thống mở **bottom sheet "Danh sách phản hồi"** liệt kê tất cả những người đã thả cảm xúc trên bài đăng. Mỗi mục trong danh sách gồm ảnh đại diện, tên hiển thị và biểu tượng cảm xúc đã thả; danh sách được sắp xếp theo thời gian giảm dần để phản hồi mới nhất xuất hiện ở phía trên cùng.

---

## 5.6. Màn hình Thông báo

Nhóm thành phần giao diện liên quan tới thông báo của hệ thống bao gồm: dải thông báo (banner) hiển thị khi ứng dụng đang mở, thông báo hệ thống của Android xuất hiện trong khay thông báo, và màn hình lịch sử thông báo bên trong ứng dụng. Cách trình bày của thông báo được điều chỉnh tùy theo trạng thái hiện tại của ứng dụng nhằm giảm thiểu sự gián đoạn đối với người dùng.

> **Hình 24.** Giao diện các thành phần thuộc nhóm Thông báo.
> *[CẦN BỔ SUNG: chèn dãy ảnh chụp màn hình thực tế theo thứ tự: (1) Hộp thoại cấp quyền nhận thông báo của hệ điều hành Android xuất hiện khi người dùng đăng nhập lần đầu; (2) Dải thông báo dạng thu gọn xuất hiện ở phía trên màn hình khi ứng dụng đang mở (logo, tên người gửi, thời gian, một dòng xem trước); (3) Dải thông báo dạng mở rộng với các thao tác phụ "Trả lời" và "Tắt thông báo"; (4) Thông báo trong khay thông báo của hệ điều hành Android khi ứng dụng đang chạy ngầm hoặc đã đóng; (5) Màn hình Lịch sử thông báo trong ứng dụng với danh sách các thông báo đã nhận, có phân biệt giữa thông báo đã đọc và chưa đọc; (6) Trạng thái rỗng của Lịch sử thông báo khi người dùng chưa có thông báo nào.]*

Khi ứng dụng đang được mở và một thông báo mới đến thiết bị, hệ thống hiển thị một **dải thông báo (banner)** trượt xuống từ phía trên màn hình thay vì để thông báo xuất hiện trong khay thông báo của hệ điều hành. Dải thông báo có thể ở hai trạng thái: dạng thu gọn chỉ hiển thị một dòng xem trước, hoặc dạng mở rộng có thêm hai thao tác phụ "Trả lời" (đối với các thông báo cho phép phản hồi nhanh) và "Tắt thông báo" (tắt việc hiển thị banner cho phiên hiện tại). Đối với các thông báo đến khi ứng dụng đang chạy ngầm hoặc đã đóng, hệ thống dựa vào cơ chế thông báo gốc của Android — thông báo xuất hiện trong khay thông báo và có thể được mở rộng theo cách thông thường.

Khi người dùng chạm vào một thông báo bất kỳ, hệ thống mở ứng dụng và điều hướng tới màn hình tương ứng với loại sự kiện. Cụ thể, thông báo về lời mời kết bạn dẫn người dùng tới bottom sheet "Bạn bè"; thông báo về việc kết bạn đã được chấp nhận dẫn tới hồ sơ của người vừa kết bạn; thông báo về cảm xúc trên ảnh của mình dẫn tới bài đăng tương ứng trên bảng tin; thông báo về bài đăng mới của bạn bè dẫn tới phần đầu của bảng tin.

Bên cạnh các thông báo đẩy hiển thị tức thời, hệ thống còn lưu lại lịch sử các thông báo quan trọng trong cơ sở dữ liệu. Người dùng có thể mở **màn hình Lịch sử thông báo** từ biểu tượng tương ứng trên thanh điều hướng phụ để xem lại các thông báo đã nhận trước đây. Trên màn hình này, các thông báo chưa được đọc được đánh dấu bằng một chấm nhỏ ở góc; khi người dùng chạm vào một mục, hệ thống đánh dấu thông báo đã được đọc và điều hướng tới màn hình tương ứng.

---

## 5.7. Màn hình Hồ sơ cá nhân

Nhóm màn hình Hồ sơ cá nhân là nơi tập trung các thông tin định danh, các chỉ số thống kê, lịch sử bài đăng và các bản nhật ký công khai của người dùng. Đây cũng là nơi người dùng truy cập các luồng chỉnh sửa thông tin và chia sẻ trang cá nhân ra ngoài ứng dụng. Bên cạnh hồ sơ của chính mình, người dùng cũng có thể xem hồ sơ của bạn bè trong mạng lưới với cấu trúc tương tự nhưng không có các thao tác chỉnh sửa.

> **Hình 25.** Giao diện các màn hình thuộc nhóm Hồ sơ cá nhân.
> *[CẦN BỔ SUNG: chèn dãy ảnh chụp màn hình thực tế theo thứ tự: (1) Màn hình Hồ sơ cá nhân ở trạng thái mặc định với tab "Khoảnh khắc" được chọn (avatar, tên hiển thị, tên người dùng, tiểu sử, ba chỉ số thống kê, hai nút "Chỉnh sửa" và "Chia sẻ trang cá nhân", lưới ảnh ba cột phía dưới); (2) Tab "Nhật ký" được chọn, hiển thị các bản nhật ký công khai dạng lưới; (3) Màn hình Chỉnh sửa hồ sơ dạng danh sách các mục có thể chỉnh sửa; (4) Bottom sheet Chỉnh sửa ảnh đại diện với ba tùy chọn (Chọn từ thư viện / Chụp ảnh / Gỡ ảnh hiện tại); (5) Hộp thoại yêu cầu nhập mật khẩu hiện tại để xác thực lại khi cập nhật địa chỉ thư điện tử; (6) Bottom sheet Chia sẻ trang cá nhân với liên kết và các phương thức chia sẻ; (7) Hồ sơ của một người bạn với cấu trúc tương tự nhưng không có các nút chỉnh sửa; (8) Màn hình Xem ảnh chi tiết khi chạm vào một bài đăng trong lưới.]*

Phần đầu của màn hình Hồ sơ cá nhân hiển thị **các thông tin định danh** của người dùng: ảnh đại diện hình tròn ở vị trí trung tâm, tên hiển thị được in đậm phía dưới, kèm theo tên người dùng (có ký hiệu `@` ở phía trước) và tiểu sử ngắn nếu có. Bên dưới phần định danh là dãy **ba chỉ số thống kê**: số khoảnh khắc đã chia sẻ, số bạn bè và số không gian chung mà người dùng đang tham gia. Khi người dùng chạm vào chỉ số "Bạn bè", hệ thống mở bottom sheet quản lý bạn bè đã được mô tả ở mục 5.4.

Phía dưới các chỉ số là hai nút thao tác nằm ngang: **"Chỉnh sửa"** mở màn hình Chỉnh sửa hồ sơ dạng danh sách, và **"Chia sẻ trang cá nhân"** mở bottom sheet với liên kết cá nhân hóa dạng `meep://profile/{username}` cùng các phương thức chia sẻ. Phía dưới cùng là **thanh chuyển tab** gồm hai mục "Khoảnh khắc" (mặc định, hiển thị lưới ảnh ba cột tất cả bài đăng đã chia sẻ) và "Nhật ký" (hiển thị các bản nhật ký công khai).

Trên **màn hình Chỉnh sửa hồ sơ**, các mục có thể chỉnh sửa được tổ chức theo dạng danh sách, mỗi mục dẫn tới một bottom sheet hoặc hộp thoại phù hợp với loại dữ liệu cần nhập. Việc chỉnh sửa ảnh đại diện được thực hiện thông qua bottom sheet với ba tùy chọn: chọn ảnh từ thư viện, chụp ảnh mới hoặc gỡ bỏ ảnh hiện tại. Đối với việc cập nhật địa chỉ thư điện tử, hệ thống yêu cầu **xác thực lại bằng mật khẩu hiện tại** thông qua một hộp thoại riêng nhằm bảo đảm chỉ chủ tài khoản mới có quyền thực hiện thay đổi.

Khi người dùng chạm vào hồ sơ của một người bạn (từ thẻ bài đăng, từ kết quả tìm kiếm bạn bè, hoặc từ danh sách phản hồi cảm xúc), hệ thống mở **màn hình Hồ sơ bạn bè** với cấu trúc tương tự hồ sơ của chính mình, nhưng các nút chỉnh sửa được thay bằng các thao tác phù hợp với bạn bè (ví dụ chuyển sang chức năng trò chuyện). Tab "Khoảnh khắc" hiển thị toàn bộ bài đăng của người bạn, còn tab "Nhật ký" chỉ hiển thị các bản nhật ký mà người bạn đã đặt ở chế độ chia sẻ với bạn bè.

---

## 5.8. Màn hình Không gian chung

Nhóm màn hình Không gian chung bao gồm quy trình tạo Space gồm ba bước nhập liệu liên tiếp, cơ chế chuyển ngữ cảnh trên phần Camera để đăng bài vào một Space cụ thể, và bảng tin riêng của từng Space. Các bottom sheet trong quy trình tạo Space được thiết kế kế tiếp nhau theo dạng nhiều bước, giúp người dùng tập trung vào từng loại thông tin cần cung cấp ở mỗi bước.

> **Hình 26.** Giao diện các màn hình thuộc nhóm Không gian chung.
> *[CẦN BỔ SUNG: chèn dãy ảnh chụp màn hình thực tế theo thứ tự: (1) Bottom sheet "Thêm Space mới" — Bước 1 chọn bạn bè (ô tìm kiếm + danh sách bạn bè với hộp kiểm); (2) Bước 2 đặt tên và chọn biểu tượng (ô nhập tên + danh sách biểu tượng preset gồm tám cặp emoji – màu sắc + ô "+" để tạo biểu tượng tùy chỉnh); (3) Bước 3 tạo biểu tượng tùy chỉnh — tab chọn emoji với bộ chọn đầy đủ; (4) Bước 3 tab chọn màu nền với bảng màu thiết kế sẵn; (5) Bảng tin riêng của Space sau khi tạo thành công; (6) Trạng thái phần Camera khi đang ở ngữ cảnh Space (màu chủ đạo của giao diện được cập nhật theo màu của Space, nhãn nút phía trên hiển thị tên Space); (7) Bottom sheet danh sách Space dùng để chuyển ngữ cảnh giữa các Space và chế độ "Tất cả bạn bè"; (8) Màn hình thông tin Space với danh sách thành viên và các nút quản lý (Thêm thành viên, Loại bỏ, Rời Space, Xóa Space).]*

Quy trình tạo một Space được kích hoạt từ thao tác **giữ lâu (long-press)** trên nút "N người bạn" của phần Camera — đây là thao tác khác biệt với việc chạm thông thường (vốn được dùng để chuyển ngữ cảnh Camera sang một Space đã có). Bước thứ nhất của quy trình là chọn các thành viên cho Space từ danh sách bạn bè hiện có. Bottom sheet hiển thị ô tìm kiếm và danh sách bạn bè dưới dạng các thẻ kèm hộp kiểm; nút "Tiếp tục" chỉ được kích hoạt khi đã có ít nhất một thành viên được chọn.

Tại bước thứ hai, hệ thống chuyển sang bottom sheet "Cấu hình Space" cho phép người dùng đặt tên (tối đa ba mươi ký tự) và chọn một biểu tượng đại diện từ danh sách **tám biểu tượng preset**. Mỗi biểu tượng preset là một cặp gồm một emoji và một màu nền tương ứng đã được thiết kế hài hòa. Nếu các biểu tượng preset không phù hợp, người dùng có thể chọn ô dấu cộng để chuyển sang bước thứ ba — tạo biểu tượng tùy chỉnh với một emoji bất kỳ và một màu nền chọn từ bảng màu thiết kế sẵn. Sau khi đặt tên và chọn biểu tượng, người dùng chọn nút "Hoàn tất" và được đưa thẳng tới bảng tin riêng của Space vừa được tạo.

Sau khi đã có Space, người dùng có thể **chuyển ngữ cảnh phần Camera** sang một Space cụ thể bằng cách chạm vào nút "N người bạn" và chọn Space từ danh sách. Khi đã ở trong ngữ cảnh Space, màu chủ đạo của giao diện Camera được cập nhật theo màu của Space và nhãn nút phía trên hiển thị tên Space. Mọi bài đăng được tạo trong ngữ cảnh này được tự động phân phối tới toàn bộ thành viên của Space mà không cần qua bước chọn đối tượng nhận thủ công. Bảng tin riêng của Space được hiển thị với cấu trúc tương tự bảng tin chính, nhưng chỉ chứa các bài đăng được đăng trong Space đó. Mỗi thẻ bài đăng trong Space có thêm thanh nhập tin nhắn ở phía dưới, gắn liền với kênh trò chuyện nhóm của Space (trình bày ở mục 5.10).

Màn hình thông tin Space được mở từ nút thông tin trên đầu bảng tin của Space, hiển thị tên, biểu tượng, danh sách thành viên và các nút quản lý phù hợp với vai trò của người dùng. Người sáng lập có quyền thêm thành viên mới, loại bỏ thành viên hiện có và xóa Space; các thành viên thường chỉ có quyền rời Space.

---

## 5.9. Màn hình Nhật ký

Nhóm màn hình Nhật ký bao gồm: trạng thái rỗng khi người dùng chưa có bản nhật ký nào, danh sách các bản nhật ký đã tạo, trình chỉnh sửa dạng vẽ (canvas) để soạn nội dung, và các màn hình phụ trợ cho việc thiết lập quyền riêng tư và tìm kiếm. Khác với các nhóm màn hình trước, giao diện của Nhật ký mang phong cách sáng tạo hơn — sử dụng các khung tâm trạng để khuyến khích người dùng bắt đầu bản nhật ký từ một cảm xúc cụ thể.

> **Hình 27.** Giao diện các màn hình thuộc nhóm Nhật ký.
> *[CẦN BỔ SUNG: chèn dãy ảnh chụp màn hình thực tế theo thứ tự: (1) Trạng thái rỗng của Nhật ký với thông điệp "Bạn chưa có nhật ký nào" và nút tạo mới; (2) Màn hình Danh sách Nhật ký với các thẻ tròn (Diary Mood card) sắp xếp dạng lưới, mỗi thẻ là một ảnh tâm trạng kèm nhãn ngày tháng; (3) Overlay "Hôm nay bạn thế nào?" với ảnh gần đây nhất từ thư viện được đặt trong năm khung tâm trạng (vui vẻ, chán nản, mệt mỏi, buồn bã, ngại ngùng); (4) Màn hình Canvas chỉnh sửa nhật ký với ảnh bìa, vùng soạn nội dung, và thanh công cụ; (5) Trạng thái Canvas khi bàn phím được mở trong quá trình nhập liệu; (6) Bộ chọn kiểu chữ trong Canvas; (7) Màn hình Cập nhật quyền với hai lựa chọn "Riêng tư" và "Công khai"; (8) Màn hình Xem nhật ký ở chế độ chỉ đọc; (9) Màn hình Tìm kiếm Nhật ký với ô nhập từ khóa và kết quả tìm được.]*

Khi người dùng mở mục Nhật ký lần đầu, hệ thống hiển thị **trạng thái rỗng** với thông điệp gợi ý và nút tròn lớn (Floating Action Button) ở phía dưới để tạo bản nhật ký đầu tiên. Sau khi đã có ít nhất một bản nhật ký, mục này chuyển sang hiển thị **màn hình Danh sách Nhật ký** với các thẻ tròn, mỗi thẻ là một ảnh bìa kèm nhãn ngày tháng. Thanh trên cùng của màn hình gồm biểu tượng tìm kiếm, tiêu đề "Nhật ký" và ảnh đại diện của người dùng.

Quy trình tạo bản nhật ký mới được khởi đầu bằng overlay "Hôm nay bạn thế nào?" — đây là điểm đặc trưng tạo nên không khí riêng của chức năng. Overlay hiển thị ảnh gần đây nhất từ thư viện của thiết bị trong **năm khung tâm trạng** tương ứng với năm cảm xúc: vui vẻ, chán nản, mệt mỏi, buồn bã và ngại ngùng. Mỗi khung tâm trạng có hình dạng riêng và được kết hợp với một biểu tượng cảm xúc tương ứng. Sau khi người dùng chọn một khung, ảnh đó cùng khung được chuyển thành ảnh bìa của bản nhật ký và hệ thống mở Canvas chỉnh sửa.

Trên **màn hình Canvas**, ảnh bìa được đặt ở phía trên và vùng soạn thảo văn bản nằm phía dưới. Người dùng có thể nhập nội dung văn bản, chèn thêm hình ảnh, và lựa chọn các kiểu chữ khác nhau (văn bản thường, tiêu đề, tiêu đề phụ, trích dẫn) cho từng đoạn thông qua bộ chọn kiểu chữ trên thanh công cụ. Trước khi lưu, người dùng chạm vào nút thiết lập quyền riêng tư để mở màn hình Cập nhật quyền và chọn giữa "Riêng tư" (mặc định) hoặc "Công khai" — quyền công khai cho phép bạn bè trong mạng lưới xem bản nhật ký thông qua tab "Nhật ký" trên trang cá nhân của người dùng.

Khi mở một bản nhật ký đã có, hệ thống hiển thị toàn bộ nội dung ở **chế độ chỉ đọc** — bố cục và các thành phần giống y hệt khi soạn thảo, nhưng các vùng nhập liệu được khóa lại. Chức năng tìm kiếm được mở từ biểu tượng tương ứng trên Danh sách Nhật ký; sau khi nhập từ khóa, hệ thống thực hiện tìm kiếm trên toàn bộ các bản nhật ký của người dùng và hiển thị kết quả dạng các thẻ tương tự danh sách chính.

---

## 5.10. Màn hình Trò chuyện

Nhóm màn hình Trò chuyện bao gồm: danh sách các cuộc trò chuyện (Inbox), giao diện chi tiết của một cuộc trò chuyện một-một, và một số trạng thái đặc biệt liên quan tới việc khởi tạo cuộc trò chuyện từ bảng tin cùng các thao tác quản lý. Đặc thù của hệ thống Meep là **mọi cuộc trò chuyện đều bắt nguồn từ một bài đăng cụ thể**, do đó giao diện luôn giữ lại tham chiếu tới ảnh ngữ cảnh ở phía trên dòng hội thoại.

> **Hình 28.** Giao diện các màn hình thuộc nhóm Trò chuyện.
> *[CẦN BỔ SUNG: chèn dãy ảnh chụp màn hình thực tế theo thứ tự: (1) Màn hình Danh sách tin nhắn (Inbox) với các cuộc trò chuyện một-một và nhóm Space sắp xếp theo thời gian tin nhắn cuối; (2) Trạng thái rỗng của Inbox khi người dùng chưa có cuộc trò chuyện nào; (3) Bảng tin với ô phản hồi mở rộng tại chỗ trên thẻ bài đăng (ảnh thu nhỏ của bài đăng phía trên ô nhập tin nhắn); (4) Màn hình Chi tiết cuộc trò chuyện một-một với khối ảnh ngữ cảnh ở phía trên dòng hội thoại; (5) Trạng thái khi menu thao tác trên thanh trên cùng được mở (gồm hai mục "Hủy kết bạn" và "Chặn"); (6) Hộp thoại xác nhận hủy kết bạn; (7) Bottom sheet xác nhận chặn người dùng; (8) Trạng thái chỉ đọc của cuộc trò chuyện sau khi đã hủy kết bạn hoặc chặn (vẫn xem được lịch sử nhưng ô nhập tin nhắn bị vô hiệu hóa); (9) Màn hình Chi tiết cuộc trò chuyện nhóm trong Space.]*

**Màn hình Danh sách tin nhắn (Inbox)** được truy cập từ biểu tượng tương ứng trên thanh điều hướng phụ. Tại đây, các cuộc trò chuyện một-một và các cuộc trò chuyện nhóm trong Space được hiển thị chung trong một danh sách, sắp xếp theo thời gian tin nhắn cuối cùng giảm dần. Mỗi mục gồm: ảnh đại diện (đối với chat một-một) hoặc biểu tượng Space (đối với chat nhóm), tên cuộc trò chuyện, đoạn xem trước của tin nhắn cuối cùng và dấu thời gian. Khi danh sách rỗng, hệ thống hiển thị thông báo "Chưa có tin nhắn nào — phản hồi một ảnh để bắt đầu" nhằm gợi ý người dùng về cơ chế khởi tạo cuộc trò chuyện.

Một cuộc trò chuyện một-một được khởi tạo thông qua thao tác phản hồi một bài đăng trên bảng tin. Khi người dùng chạm vào vùng "Gửi tin nhắn..." trên thanh thao tác của thẻ bài đăng, ô nhập tin nhắn được mở rộng **tại chỗ** trên màn hình bảng tin — không chuyển sang màn hình khác. Phía trên ô nhập, hệ thống hiển thị ảnh thu nhỏ của bài đăng đang được phản hồi để giữ ngữ cảnh trực quan. Sau khi gửi, ô nhập thu lại và người dùng có thể tiếp tục cuộn bảng tin.

Để xem toàn bộ lịch sử hoặc tiếp tục một cuộc trò chuyện đã có, người dùng mở **màn hình Chi tiết cuộc trò chuyện** từ Inbox. Màn hình này có cấu trúc đặc trưng gồm: thanh trên cùng với ảnh đại diện và tên người đối thoại; **khối ảnh được phản hồi** đặt ở vị trí đầu tiên của dòng hội thoại (đóng vai trò là ngữ cảnh); danh sách các tin nhắn đã trao đổi sắp xếp theo thời gian tăng dần (tin nhắn của người dùng đặt bên phải, tin nhắn của người đối thoại đặt bên trái); và ô nhập tin nhắn ở phía dưới cùng.

Trên thanh trên cùng của màn hình Chi tiết cuộc trò chuyện, biểu tượng menu (ba dấu chấm) cho phép người dùng truy cập hai thao tác quản lý: **"Hủy kết bạn"** mở hộp thoại xác nhận trước khi xóa quan hệ bạn bè, và **"Chặn"** mở bottom sheet xác nhận chặn. Đặc biệt, sau khi hủy kết bạn hoặc chặn, cuộc trò chuyện không biến mất khỏi Inbox mà chuyển sang **chế độ chỉ đọc** — người dùng vẫn xem được lịch sử các tin nhắn đã trao đổi nhưng ô nhập tin nhắn bị vô hiệu hóa.

---

## 5.11. Home-screen Widget trên Android

Khác với toàn bộ các nhóm màn hình đã trình bày ở trên, Home-screen Widget không phải là một màn hình bên trong ứng dụng Meep mà là một **tiện ích nằm bên ngoài ứng dụng**, hoạt động trực tiếp trên màn hình chính của thiết bị Android. Đây là thành phần đặc thù được hiện thực hóa bằng mã nguồn gốc Kotlin, hoạt động độc lập với phần Flutter và đồng bộ dữ liệu định kỳ thông qua một tác vụ nền do hệ điều hành điều phối.

> **Hình 29.** Giao diện Home-screen Widget trên Android và luồng thêm Widget.
> *[CẦN BỔ SUNG: chèn dãy ảnh chụp màn hình thực tế theo thứ tự: (1) Bottom sheet Cài đặt với mục "Thêm tiện ích" được làm nổi bật; (2) Bottom sheet xác nhận thêm Widget với hình ảnh xem trước của Widget kích thước 2×2 và hai nút "Thêm" / "Hủy"; (3) Trình chọn vị trí Widget của hệ điều hành Android (giao diện gốc của hệ thống); (4) Màn hình hướng dẫn xác nhận thành công kèm minh họa Widget đã xuất hiện trên màn hình chính; (5) Widget Meep trên màn hình chính của thiết bị Android ở trạng thái thông thường — hiển thị ảnh mới nhất từ bạn bè làm nền, ảnh đại diện hình tròn của tác giả ở góc dưới bên trái, chú thích kèm theo, và huy hiệu đếm bài chưa xem ở góc trên bên phải; (6) Widget ở trạng thái chỗ giữ chỗ (placeholder) khi người dùng chưa đăng nhập hoặc chưa có bài đăng nào trong bảng tin; (7) Trạng thái màn hình chính của Meep sau khi chạm vào Widget — Bảng tin được mở với bài đăng tương ứng được làm nổi bật trong vài giây.]*

Việc thêm Widget vào màn hình chính được khởi tạo từ trong ứng dụng Meep nhằm hướng dẫn người dùng đi qua các bước cấu hình của hệ điều hành. Quy trình bắt đầu từ mục "Thêm tiện ích" trong bottom sheet Cài đặt; khi người dùng chạm vào, hệ thống mở bottom sheet xác nhận với hình ảnh xem trước của Widget. Khi người dùng chọn "Thêm", ứng dụng gọi tới giao diện lập trình ứng dụng của hệ điều hành Android để yêu cầu thêm Widget; hệ điều hành mở trình chọn vị trí riêng của mình cho phép người dùng kéo thả Widget vào vị trí mong muốn trên màn hình chính. Sau khi đặt xong, hệ thống Meep hiển thị một màn hình hướng dẫn xác nhận thành công kèm hình ảnh minh họa.

Sau khi đã được thêm vào màn hình chính, Widget hoạt động **hoàn toàn tự động** mà không cần thêm thao tác nào của người dùng. Một **tác vụ nền định kỳ (Periodic Work Request)** với chu kỳ khoảng mười lăm phút được hệ điều hành kích hoạt; tác vụ này xác thực phiên đăng nhập, truy vấn bài đăng mới nhất trong bảng tin của người dùng, tải tệp ảnh về bộ nhớ đệm cục bộ, tính số lượng bài chưa xem kể từ lần cuối mở ứng dụng, và cập nhật giao diện của Widget tương ứng. Giao diện Widget được dựng từ bốn thành phần: ảnh nền (ảnh của bài đăng), ảnh đại diện hình tròn của tác giả ở góc dưới bên trái, chú thích đặt cạnh ảnh đại diện (ẩn nếu bài đăng không có chú thích), và huy hiệu đếm bài chưa xem ở góc trên bên phải (hiển thị số thực từ 1 tới 9, hoặc nhãn "9+" cho số lượng từ 10 trở lên).

Trong các trường hợp người dùng chưa đăng nhập hoặc bảng tin chưa có bài đăng nào, Widget chuyển sang **trạng thái chỗ giữ chỗ (placeholder)** với biểu trưng Meep và dòng chữ "Mở Meep để bắt đầu". Khi người dùng chạm vào bất kỳ vị trí nào trên Widget, hệ điều hành kích hoạt một ý định mở ứng dụng đã được đăng ký từ trước, mang theo mã định danh của bài đăng đang được hiển thị. Ứng dụng Meep được khởi động hoặc khôi phục từ chế độ chạy ngầm, và hệ thống điều hướng người dùng tới bảng tin với hiệu ứng làm nổi bật bài đăng tương ứng trong vài giây đầu.

---

## 5.12. Màn hình Cài đặt

Nhóm màn hình Cài đặt được tổ chức dưới dạng một **bottom sheet trung tâm** thay vì một màn hình riêng biệt — cách bố trí này phù hợp với phong cách tổng thể của hệ thống Meep và cho phép người dùng truy cập nhanh các thiết lập mà không phải rời khỏi ngữ cảnh đang sử dụng. Bottom sheet được kích hoạt từ ảnh đại diện ở góc trên bên phải của màn hình chính, và là điểm vào của các luồng quản lý tài khoản, quyền riêng tư, đăng xuất và xóa tài khoản.

> **Hình 30.** Giao diện các màn hình thuộc nhóm Cài đặt.
> *[CẦN BỔ SUNG: chèn dãy ảnh chụp màn hình thực tế theo thứ tự: (1) Bottom sheet Cài đặt ở trạng thái mặc định với đầy đủ các khu vực (đầu mục với avatar và liên kết hồ sơ, hai nút thao tác nhanh, khu vực Space, khu vực Thiết lập, khu vực Riêng tư và Bảo mật, khu vực Giới thiệu, khu vực Tài khoản); (2) Trạng thái sau khi sao chép liên kết hồ sơ (thông báo xác nhận "Đã sao chép liên kết"); (3) Màn hình Tài khoản đã chặn với danh sách các tài khoản và nút "Bỏ chặn" trên từng mục; (4) Trạng thái rỗng của Tài khoản đã chặn; (5) Màn hình Quyền riêng tư và dữ liệu với công tắc "Cho phép tìm kiếm bằng tên người dùng"; (6) Trang Điều khoản dịch vụ dạng văn bản dài có thể cuộn; (7) Hộp thoại xác nhận Đăng xuất; (8) Hộp thoại cảnh báo trước khi Xóa tài khoản; (9) Hộp thoại yêu cầu xác thực lại mật khẩu trước khi tiến hành Xóa tài khoản.]*

Bottom sheet Cài đặt được tổ chức thành nhiều khu vực theo nhóm chức năng, sắp xếp từ trên xuống theo mức độ ảnh hưởng tăng dần. **Phần đầu** hiển thị tóm lược tài khoản gồm ảnh đại diện, tên người dùng và liên kết hồ sơ cá nhân dạng `meep://profile/{username}` kèm biểu tượng sao chép. Tiếp theo là hàng hai nút thao tác nhanh ("N người bạn" và "Chia sẻ") dẫn tới các bottom sheet đã được mô tả ở các mục trước. **Khu vực Space** liệt kê các Space mà người dùng đang tham gia dưới dạng các thẻ cuộn ngang kèm nút "Tạo" để tạo Space mới. **Khu vực Thiết lập** chứa mục "Thêm tiện ích" dẫn tới luồng thêm Home-screen Widget đã được mô tả ở mục 5.11.

**Khu vực Riêng tư và Bảo mật** chứa hai mục dẫn tới các màn hình quản lý quyền riêng tư. **Màn hình Tài khoản đã chặn** hiển thị danh sách các tài khoản người dùng đã chặn cùng nút "Bỏ chặn" trên từng mục — đáng chú ý là việc bỏ chặn không yêu cầu xác nhận, do đây là thao tác đảo ngược một thiết lập đã có trước đó và không gây hậu quả không mong muốn. **Màn hình Quyền riêng tư và dữ liệu** cung cấp công tắc "Cho phép tìm kiếm bằng tên người dùng" (mặc định bật) — khi tắt, tài khoản của người dùng sẽ không xuất hiện trong kết quả tìm kiếm của các người dùng khác. **Khu vực Giới thiệu** liên kết tới hai tài liệu pháp lý dạng văn bản dài: Điều khoản dịch vụ và Chính sách quyền riêng tư.

**Khu vực Tài khoản** ở phía dưới cùng chứa hai mục có tính chất khác nhau. **"Đăng xuất"** thực hiện hủy phiên làm việc hiện tại sau hộp thoại xác nhận đơn giản — hệ thống đồng thời xóa thẻ định danh thiết bị khỏi cơ sở dữ liệu để dừng việc nhận thông báo đẩy, và đưa người dùng quay về màn hình Khởi động. **"Xóa tài khoản"** được hiển thị bằng màu đỏ nhằm nhấn mạnh tính chất không thể đảo ngược; thao tác này yêu cầu **hai lớp xác nhận** — một hộp thoại cảnh báo về các hệ quả, sau đó là một bước xác thực lại danh tính bằng mật khẩu hiện tại — trước khi hệ thống thực hiện quy trình xóa dữ liệu phân tầng đối với toàn bộ hồ sơ, bài đăng, cảm xúc, tin nhắn, nhật ký, mối quan hệ bạn bè và tệp ảnh thuộc về tài khoản.

---

Đến đây, mười hai nhóm màn hình đã được trình bày qua các ảnh chụp giao diện thực tế và phần mô tả thao tác đặc trưng. Có thể thấy rằng, các nhóm màn hình đã được hiện thực hóa bao phủ trọn vẹn phạm vi chức năng MVP đã được xác định trong chương 1 và mô tả chi tiết trong chương 3, đồng thời tận dụng được mô hình dữ liệu đã được thiết kế trong chương 4. Bên cạnh phần ứng dụng di động được phát triển bằng Flutter, hệ thống còn bao gồm thành phần Home-screen Widget Android viết bằng Kotlin và phần xử lý phía máy chủ viết bằng TypeScript trên Cloud Functions — toàn bộ cùng tạo nên một hệ thống vận hành hoàn chỉnh, đáp ứng các yêu cầu ban đầu của đề tài.
