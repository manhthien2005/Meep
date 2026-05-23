# CHƯƠNG 3. MÔ TẢ CÁC YÊU CẦU CHỨC NĂNG CỦA HỆ THỐNG

Chương này trình bày chi tiết các yêu cầu chức năng của hệ thống Meep. Trong hệ thống, tác nhân (actor) duy nhất là **người dùng (User)** — cá nhân đã đăng ký tài khoản và thực hiện toàn bộ các thao tác trên ứng dụng. Do bản chất của hệ thống là một mạng lưới chia sẻ ảnh khép kín giữa bạn bè thân thiết, hệ thống không tồn tại các tác nhân khác như "Người quản trị" hay "Bên cung cấp dịch vụ" thường gặp ở những loại ứng dụng có nhiều vai trò khác nhau.

Toàn bộ các thao tác được trình bày theo mười ba nhóm chức năng, từ chức năng nền tảng như xác thực người dùng, quản lý bạn bè, đến các chức năng đặc trưng tạo nên điểm khác biệt của hệ thống như Home-screen Widget trên Android và không gian chung dành cho từng nhóm bạn. Đối với mỗi nhóm chức năng, nội dung được trình bày theo cấu trúc thống nhất sau đây:

- Mô tả tổng quan mục đích và phạm vi của chức năng.
- Liệt kê các biến thể hoặc luồng phụ (nếu có).
- Bảng các bước thực hiện (Steps) thể hiện luồng tương tác giữa người dùng và hệ thống.
- Wireframe minh họa thiết kế giao diện tương ứng.

Trước khi đi vào từng nhóm chức năng cụ thể, mô hình Use Case tổng quát dưới đây cung cấp một góc nhìn bao quát về toàn bộ các hành vi mà người dùng có thể thực hiện trên hệ thống.

> **Hình 4.** Mô hình Use Case tổng quát của người dùng trong hệ thống Meep.
> *[CẦN BỔ SUNG: chèn sơ đồ Use Case — gồm một tác nhân "Người dùng" ở giữa, kết nối tới các Use Case xung quanh: Xác thực tài khoản, Quản lý bạn bè, Chụp ảnh và đăng bài, Xem bảng tin, Thả cảm xúc, Nhận thông báo, Quản lý hồ sơ cá nhân, Sử dụng không gian chung, Ghi nhật ký, Trò chuyện, Sử dụng Home-screen Widget, Cài đặt tài khoản, Xem lịch sử kỷ niệm.]*

---

## 3.1. Chức năng Xác thực người dùng

Chức năng Xác thực người dùng đóng vai trò là cửa ngõ của toàn bộ hệ thống. Mọi chức năng khác chỉ có thể được sử dụng sau khi người dùng đã xác thực thành công và có một phiên làm việc hợp lệ. Chức năng này cho phép người dùng tạo tài khoản mới, đăng nhập vào hệ thống và khôi phục mật khẩu khi cần thiết. Sau lần đăng nhập thành công đầu tiên, hệ thống ghi nhớ phiên làm việc của người dùng và tự động đăng nhập lại trong những lần mở ứng dụng tiếp theo cho đến khi người dùng chủ động đăng xuất.

Chức năng Xác thực bao gồm các luồng thao tác chính sau đây:

- **Đăng ký tài khoản bằng email và mật khẩu** thông qua bốn bước nhập liệu tuần tự.
- **Đăng ký hoặc đăng nhập bằng tài khoản Google** thông qua dịch vụ Google Sign-In.
- **Đăng nhập bằng email và mật khẩu** đã đăng ký trước đó.
- **Khôi phục mật khẩu** trong trường hợp người dùng quên mật khẩu.
- **Đăng nhập tự động** ở những lần mở ứng dụng tiếp theo khi phiên làm việc còn hiệu lực.

### 3.1.1. Đăng ký tài khoản bằng email và mật khẩu

Luồng đăng ký bằng email và mật khẩu được thiết kế thành **bốn bước nhập liệu tuần tự**, trong đó mỗi bước chỉ tập trung vào một loại thông tin duy nhất. Cách tổ chức này giúp giảm tải nhận thức cho người dùng và tăng khả năng hoàn thành đăng ký, đặc biệt là trên thiết bị di động có không gian màn hình hạn chế.

**Bảng 3.1.** Các bước thực hiện chức năng Đăng ký tài khoản bằng email và mật khẩu.

| Steps | Description |
|---|---|
| S1 | Người dùng mở ứng dụng lần đầu. Hệ thống hiển thị **màn hình Khởi động (Intro)** gồm tên ứng dụng, biểu tượng và hai nút lựa chọn: "Tạo tài khoản mới" và "Đăng nhập". |
| S2 | Người dùng chọn nút "Tạo tài khoản mới". Hệ thống chuyển sang **màn hình Nhập email** với tiêu đề "Email của bạn là gì?". |
| S3 | Người dùng nhập địa chỉ email và chọn "Tiếp tục". Hệ thống kiểm tra định dạng email. Nếu email không đúng định dạng, hệ thống hiển thị thông báo lỗi và giữ nguyên ở màn hình hiện tại. Nếu hợp lệ, hệ thống chuyển sang bước tiếp theo. |
| S4 | Hệ thống hiển thị **màn hình Chọn mật khẩu** với tiêu đề "Chọn một mật khẩu". Người dùng nhập mật khẩu tối thiểu tám ký tự và chọn "Tiếp tục". Nếu mật khẩu chưa đủ độ dài, hệ thống hiển thị thông báo lỗi tương ứng. |
| S5 | Hệ thống hiển thị **màn hình Nhập họ và tên** với tiêu đề "Tên bạn là gì?". Người dùng nhập đầy đủ Họ và Tên rồi chọn "Tiếp tục". Trường hợp một trong hai ô để trống, nút "Tiếp tục" bị vô hiệu hóa. |
| S6 | Hệ thống hiển thị **màn hình Chọn tên người dùng (username)** với tiêu đề "Chọn tên người dùng của bạn". Tên người dùng phải thỏa mãn các điều kiện: độ dài từ ba đến hai mươi ký tự, chỉ chứa chữ cái thường, chữ số và dấu gạch dưới. |
| S7 | Sau mỗi ký tự được nhập, hệ thống tự động kiểm tra tính khả dụng của tên người dùng bằng cách truy vấn dịch vụ phía máy chủ. Có ba trạng thái phản hồi: đang kiểm tra (biểu tượng quay), khả dụng (biểu tượng tích xanh kèm thông báo "Tuyệt vời!"), đã được sử dụng (đường viền đỏ kèm thông báo lỗi). Nút "Hoàn tất" chỉ bật khi tên ở trạng thái khả dụng. |
| S8 | Người dùng chọn "Hoàn tất". Hệ thống thực hiện đồng thời hai thao tác: tạo tài khoản trên dịch vụ **Firebase Authentication** với email và mật khẩu đã nhập, sau đó ghi hồ sơ người dùng vào cơ sở dữ liệu **Cloud Firestore**. |
| S9 | Nếu cả hai thao tác trên thành công, hệ thống hiển thị **màn hình chào mừng** ("Bạn đã sẵn sàng") trong khoảng một giây rưỡi, sau đó tự động chuyển người dùng tới **màn hình chính (Home)**. Nếu có lỗi xảy ra (ví dụ email đã được đăng ký), hệ thống quay lại bước có liên quan và hiển thị thông báo lỗi tương ứng. |

> **Hình 5a.** Wireframe luồng Đăng ký tài khoản bằng email và mật khẩu.
> *[CẦN BỔ SUNG: chèn dãy wireframe sáu màn hình theo thứ tự: Intro → Nhập email → Chọn mật khẩu → Nhập họ và tên → Chọn tên người dùng (ba trạng thái: trống, đang kiểm tra, khả dụng) → Màn hình chào mừng.]*

### 3.1.2. Đăng ký hoặc đăng nhập bằng tài khoản Google

Bên cạnh luồng đăng ký bằng email và mật khẩu, hệ thống cung cấp phương án **đăng ký hoặc đăng nhập bằng tài khoản Google** nhằm rút ngắn quá trình tạo tài khoản cho người dùng đã có sẵn tài khoản Google trên thiết bị. Luồng này thay thế hai bước nhập email và mật khẩu bằng một thao tác xác thực duy nhất qua dịch vụ Google Sign-In.

**Bảng 3.2.** Các bước thực hiện chức năng Đăng ký hoặc đăng nhập bằng tài khoản Google.

| Steps | Description |
|---|---|
| S1 | Tại màn hình Nhập email (xuất hiện cả trong luồng đăng ký lẫn luồng đăng nhập), người dùng chọn nút **"Tiếp tục với Google"** đặt bên dưới ô nhập email. |
| S2 | Hệ thống mở hộp thoại lựa chọn tài khoản Google của hệ điều hành. Người dùng chọn tài khoản Google mong muốn. |
| S3 | Sau khi xác thực Google thành công, hệ thống truy vấn **Cloud Firestore** với khóa là mã định danh người dùng (UID) trả về từ Firebase Authentication. |
| S4 | Trường hợp **đã tồn tại** hồ sơ người dùng trong Firestore (người dùng cũ), hệ thống bỏ qua các bước thu thập thông tin và chuyển thẳng đến **màn hình chính (Home)**. |
| S5 | Trường hợp **chưa tồn tại** hồ sơ (người dùng mới), hệ thống chuyển tới **màn hình Nhập họ và tên** với hai trường được điền sẵn từ tài khoản Google (có thể chỉnh sửa lại). |
| S6 | Người dùng tiếp tục hoàn thành các bước nhập tên và chọn tên người dùng tương tự như ở luồng đăng ký thông thường, sau đó hệ thống ghi hồ sơ vào Firestore và đưa người dùng tới màn hình chính. |

### 3.1.3. Đăng nhập bằng email và mật khẩu

Chức năng Đăng nhập bằng email và mật khẩu được sử dụng đối với những tài khoản đã được đăng ký trước đó bằng phương thức email/mật khẩu hoặc Google (đối với Google, luồng đăng nhập tự nhận diện và chuyển sang luồng đăng nhập bằng Google).

**Bảng 3.3.** Các bước thực hiện chức năng Đăng nhập bằng email và mật khẩu.

| Steps | Description |
|---|---|
| S1 | Tại màn hình Khởi động (Intro), người dùng chọn nút "Đăng nhập". Hệ thống hiển thị **màn hình Nhập email** dành cho đăng nhập. |
| S2 | Người dùng nhập địa chỉ email đã đăng ký và chọn "Tiếp tục". |
| S3 | Hệ thống hiển thị **màn hình Nhập mật khẩu** với tiêu đề "Điền mật khẩu của bạn". Bên dưới ô nhập mật khẩu có liên kết "Bạn đã quên mật khẩu?" dẫn tới luồng khôi phục mật khẩu (xem 3.1.4). |
| S4 | Người dùng nhập mật khẩu và chọn "Tiếp tục". Hệ thống gọi tới Firebase Authentication để xác thực. Nếu thông tin đăng nhập không chính xác, hệ thống hiển thị thông báo lỗi ngay tại màn hình hiện tại. |
| S5 | Khi xác thực thành công, hệ thống hiển thị **màn hình chào mừng** trong khoảng một giây rưỡi và tự động chuyển người dùng tới **màn hình chính**. |

### 3.1.4. Khôi phục mật khẩu

Chức năng Khôi phục mật khẩu được kích hoạt từ liên kết "Bạn đã quên mật khẩu?" trên màn hình nhập mật khẩu của luồng đăng nhập. Hệ thống không thực hiện đặt lại mật khẩu trực tiếp trong ứng dụng mà gửi một thư điện tử kèm theo liên kết đặt lại do **Firebase Authentication** quản lý.

**Bảng 3.4.** Các bước thực hiện chức năng Khôi phục mật khẩu.

| Steps | Description |
|---|---|
| S1 | Người dùng chọn liên kết "Bạn đã quên mật khẩu?" trên màn hình Nhập mật khẩu. Hệ thống hiển thị **màn hình Khôi phục mật khẩu** với địa chỉ email đã được điền sẵn từ bước trước. |
| S2 | Người dùng xác nhận lại địa chỉ email và chọn "Gửi liên kết khôi phục". |
| S3 | Hệ thống gọi tới dịch vụ Firebase Authentication để gửi thư điện tử khôi phục mật khẩu tới địa chỉ tương ứng. Hệ thống hiển thị thông báo thành công và quay lại màn hình đăng nhập. |
| S4 | Người dùng mở thư trong hộp thư đến, chọn liên kết khôi phục để đặt lại mật khẩu mới theo hướng dẫn của Firebase. |
| S5 | Sau khi đặt lại mật khẩu thành công, người dùng quay lại ứng dụng và thực hiện đăng nhập bằng mật khẩu mới theo luồng được mô tả ở mục 3.1.3. |

### 3.1.5. Đăng nhập tự động

Sau lần đăng nhập thành công đầu tiên, **Firebase Authentication** lưu trữ một thẻ phiên (session token) trên thiết bị. Mỗi khi người dùng mở lại ứng dụng, hệ thống kiểm tra thẻ phiên này một cách tự động và đưa người dùng đi tới một trong ba trạng thái tương ứng:

- Nếu chưa có phiên hợp lệ, ứng dụng hiển thị **màn hình Khởi động (Intro)** để người dùng chọn đăng ký hoặc đăng nhập.
- Nếu có phiên hợp lệ nhưng hồ sơ người dùng trong Cloud Firestore chưa hoàn thiện (trường hợp đăng ký bằng Google chưa hoàn tất bước nhập tên hoặc tên người dùng), ứng dụng đưa người dùng quay lại đúng bước còn dang dở.
- Nếu có phiên hợp lệ và hồ sơ đã hoàn thiện, ứng dụng đưa thẳng người dùng tới **màn hình chính**.

Cơ chế này được hiện thực hóa thông qua việc lắng nghe luồng `authStateChanges` của Firebase Authentication, kết hợp với một bộ điều hướng (router guard) kiểm tra đồng thời trạng thái xác thực và trạng thái hồ sơ người dùng.

> **Hình 5b.** Wireframe luồng Đăng nhập, Khôi phục mật khẩu và Đăng nhập tự động.
> *[CẦN BỔ SUNG: chèn dãy wireframe các màn hình: Intro → Nhập email (đăng nhập) → Nhập mật khẩu (có liên kết "Bạn đã quên mật khẩu?") → Khôi phục mật khẩu → Màn hình chào mừng. Bổ sung thêm sơ đồ trạng thái thể hiện ba nhánh điều hướng tự động.]*

---

## 3.2. Chức năng Quản lý bạn bè

Chức năng Quản lý bạn bè cho phép người dùng xây dựng và duy trì mạng lưới bạn bè của mình trên hệ thống Meep. Khác với mô hình "theo dõi" công khai trên các mạng xã hội đại chúng, quan hệ bạn bè trong Meep được tổ chức theo **cơ chế hai chiều** — một quan hệ bạn bè chỉ được thiết lập sau khi cả hai phía cùng đồng thuận (một bên gửi lời mời và bên còn lại chấp nhận). Quan hệ này là cơ sở để hệ thống xác định ai có quyền xem bài đăng của ai, từ đó duy trì tính riêng tư của toàn bộ hệ thống. Trong phạm vi của phiên bản MVP, mỗi người dùng được phép có **tối đa hai mươi người bạn**, nhằm phù hợp với tinh thần khép kín và thân mật của ứng dụng.

Chức năng này bao gồm các luồng thao tác chính sau đây:

- Mở và xem danh sách bạn bè hiện có.
- Tìm kiếm người dùng theo tên người dùng (username) và gửi lời mời kết bạn.
- Xử lý các lời mời kết bạn nhận được, gồm chấp nhận hoặc từ chối.
- Hủy kết bạn với một người bạn hiện có.
- Chia sẻ liên kết mời sử dụng ứng dụng tới những người chưa có tài khoản Meep.

### 3.2.1. Mở và xem danh sách bạn bè

Toàn bộ các thao tác liên quan tới quản lý bạn bè được tập trung tại một thành phần giao diện duy nhất gọi là **"Bạn bè" bottom sheet** — một bảng kéo lên từ phía dưới màn hình, được kích hoạt từ nút hiển thị số lượng bạn bè trên màn hình chụp ảnh. Bottom sheet này gồm bốn khu vực chính: khu vực tìm kiếm, khu vực hiển thị các lời mời kết bạn đang chờ xử lý (nếu có), khu vực chia sẻ liên kết mời và khu vực danh sách bạn bè hiện có.

**Bảng 3.5.** Các bước thực hiện chức năng Mở và xem danh sách bạn bè.

| Steps | Description |
|---|---|
| S1 | Người dùng đang ở **màn hình chính (Home)** với phần Camera được hiển thị. Tại thanh trên cùng có nút thể hiện số lượng bạn bè hiện tại, ví dụ "15 người bạn". |
| S2 | Người dùng chọn nút "N người bạn". Hệ thống mở **bottom sheet "Bạn bè"** trượt lên từ phía dưới màn hình. |
| S3 | Bottom sheet hiển thị bốn khu vực theo thứ tự từ trên xuống: ô tìm kiếm với gợi ý "Thêm một người bạn mới", khu vực "Yêu cầu kết bạn" (chỉ hiện khi có ít nhất một lời mời đang chờ), khu vực "Chia sẻ liên kết Meep của bạn", và khu vực "Bạn bè của bạn" liệt kê toàn bộ bạn bè hiện có. |
| S4 | Khu vực "Bạn bè của bạn" hiển thị các bạn bè theo dạng danh sách cuộn, mỗi mục bao gồm ảnh đại diện, tên hiển thị, tên người dùng và một biểu tượng dấu chéo dùng để hủy kết bạn. |
| S5 | Trong trường hợp số lượng bạn bè vượt quá phần hiển thị mặc định, hệ thống cung cấp nút "Xem thêm" để mở rộng toàn bộ danh sách. |
| S6 | Người dùng có thể đóng bottom sheet bằng cách kéo xuống hoặc chạm ra ngoài khu vực bottom sheet để quay về màn hình chính. |

### 3.2.2. Tìm kiếm và gửi lời mời kết bạn

Việc kết bạn trong Meep được thực hiện thông qua thao tác tìm kiếm chính xác theo **tên người dùng (username)**. Hệ thống không hỗ trợ tìm kiếm theo họ tên do tính chất duy nhất của username giúp đảm bảo người dùng tìm đúng đối tượng mà mình mong muốn.

**Bảng 3.6.** Các bước thực hiện chức năng Tìm kiếm và gửi lời mời kết bạn.

| Steps | Description |
|---|---|
| S1 | Trong bottom sheet "Bạn bè", người dùng chọn ô tìm kiếm "Thêm một người bạn mới". Hệ thống mở rộng ô tìm kiếm, hiển thị thêm nút "Hủy" bên cạnh và ẩn các khu vực khác để tập trung vào kết quả tìm kiếm. |
| S2 | Người dùng nhập tên người dùng cần tìm. Hệ thống chờ khoảng năm trăm mili-giây sau lần gõ phím cuối cùng (debounce) trước khi thực hiện truy vấn nhằm tránh truy vấn dư thừa. |
| S3 | Hệ thống truy vấn cơ sở dữ liệu để tìm tên người dùng khớp **chính xác toàn bộ chuỗi** (không phân biệt chữ hoa, chữ thường). Trong khi truy vấn, biểu tượng quay nhỏ được hiển thị. |
| S4 | Có ba khả năng phản hồi: (a) **Tìm thấy người dùng chưa phải bạn**: hệ thống hiển thị thẻ thông tin gồm ảnh đại diện, tên hiển thị, tên người dùng và nút "Gửi kết bạn"; (b) **Tìm thấy người dùng đã là bạn**: hệ thống hiển thị thẻ thông tin kèm nút "Trang cá nhân" cho phép xem hồ sơ; (c) **Không tìm thấy**: hệ thống hiển thị thông báo "Không có người dùng với tên người dùng này". |
| S5 | Trường hợp tên người dùng đã tìm trùng với chính người dùng đang đăng nhập, hệ thống hiển thị thẻ thông tin với nhãn "Đây là tôi" thay vì cho phép gửi lời mời cho bản thân. |
| S6 | Khi người dùng chọn nút "Gửi kết bạn", hệ thống tạo một lời mời kết bạn ở trạng thái "đang chờ" (pending) và lưu vào cơ sở dữ liệu. Nút trên thẻ đổi sang trạng thái "Đã gửi lời mời" để xác nhận cho người dùng. |
| S7 | Người dùng chọn nút "Hủy" để thoát khỏi chế độ tìm kiếm và quay về trạng thái mặc định của bottom sheet. |

### 3.2.3. Xử lý lời mời kết bạn nhận được

Khi nhận được một lời mời kết bạn từ người khác, người dùng có thể chấp nhận để hai bên trở thành bạn hai chiều, hoặc từ chối để đóng lời mời mà không thiết lập quan hệ.

**Bảng 3.7.** Các bước thực hiện chức năng Xử lý lời mời kết bạn nhận được.

| Steps | Description |
|---|---|
| S1 | Khi mở bottom sheet "Bạn bè" trong trường hợp có ít nhất một lời mời đang chờ, khu vực "Yêu cầu kết bạn" hiển thị danh sách các lời mời, mỗi mục gồm ảnh đại diện, tên hiển thị của người gửi, nút "Chấp nhận" và biểu tượng dấu chéo (từ chối). |
| S2 | Để **chấp nhận lời mời**, người dùng chọn nút "Chấp nhận". Hệ thống gọi tới dịch vụ phía máy chủ để tạo quan hệ bạn bè hai chiều giữa hai người dùng, đồng thời cập nhật số lượng bạn của cả hai. |
| S3 | Nếu việc chấp nhận thành công, thẻ lời mời biến mất khỏi khu vực "Yêu cầu kết bạn" và tên người dùng vừa được kết bạn xuất hiện trong khu vực "Bạn bè của bạn". |
| S4 | Trường hợp việc chấp nhận không thể thực hiện do người dùng đã đạt giới hạn hai mươi bạn, hệ thống hiển thị thông báo: "Bạn đã có 20 bạn bè, không thể chấp nhận". Lời mời vẫn giữ ở trạng thái đang chờ. |
| S5 | Để **từ chối lời mời**, người dùng chọn biểu tượng dấu chéo trên thẻ lời mời. Hệ thống cập nhật trạng thái lời mời sang "đã từ chối" và thẻ biến mất khỏi danh sách. |

### 3.2.4. Hủy kết bạn

Người dùng có thể chủ động hủy kết bạn với một người bạn hiện có. Sau khi hủy, hai phía không còn nhìn thấy bài đăng của nhau và sẽ phải gửi lời mời mới nếu muốn kết bạn trở lại.

**Bảng 3.8.** Các bước thực hiện chức năng Hủy kết bạn.

| Steps | Description |
|---|---|
| S1 | Trong khu vực "Bạn bè của bạn" của bottom sheet, mỗi mục bạn bè được hiển thị kèm theo một biểu tượng dấu chéo ở phía bên phải. |
| S2 | Người dùng chọn biểu tượng dấu chéo. Hệ thống hiển thị một hộp thoại xác nhận yêu cầu người dùng xác nhận hành động hủy kết bạn. |
| S3 | Người dùng chọn xác nhận. Hệ thống xóa quan hệ bạn bè giữa hai người dùng khỏi cơ sở dữ liệu và cập nhật lại số lượng bạn của cả hai phía. |
| S4 | Thẻ thông tin của người bạn vừa hủy biến mất khỏi danh sách "Bạn bè của bạn". Bài đăng của người bạn này không còn xuất hiện trong bảng tin của người dùng và ngược lại. |

### 3.2.5. Chia sẻ liên kết mời sử dụng ứng dụng

Đối với những người bạn chưa có tài khoản Meep, người dùng có thể chia sẻ một liên kết mời cá nhân hóa (deep link) để bạn của mình cài đặt ứng dụng và kết nối nhanh chóng sau khi đăng ký.

**Bảng 3.9.** Các bước thực hiện chức năng Chia sẻ liên kết mời sử dụng ứng dụng.

| Steps | Description |
|---|---|
| S1 | Trong bottom sheet "Bạn bè", khu vực "Chia sẻ liên kết Meep của bạn" cung cấp một số phương thức chia sẻ: sao chép liên kết, chia sẻ qua Messenger, chia sẻ qua tin nhắn Instagram, chia sẻ vào tin Instagram, và chia sẻ qua tin nhắn. |
| S2 | Khi người dùng chọn "Liên kết của bạn", hệ thống sao chép liên kết mời cá nhân hóa vào bộ nhớ tạm của thiết bị. Biểu tượng liên kết chuyển sang biểu tượng dấu tích trong khoảng hai giây để xác nhận. |
| S3 | Khi người dùng chọn các phương thức còn lại, hệ thống mở **bảng chia sẻ hệ thống (system share sheet)** của Android, để người dùng tự chọn ứng dụng cụ thể nhận liên kết. |
| S4 | Khi người bạn được mời chạm vào liên kết, hệ thống mở ứng dụng Meep. Nếu người bạn đã có tài khoản và đã đăng nhập, hệ thống dẫn họ tới trang hồ sơ của người dùng đã gửi liên kết kèm nút "Kết bạn". Nếu chưa đăng nhập, hệ thống đưa người bạn vào luồng đăng ký, sau đó tự động quay lại trang hồ sơ tương ứng. |

> **Hình 6.** Wireframe các luồng thuộc chức năng Quản lý bạn bè.
> *[CẦN BỔ SUNG: chèn các wireframe theo thứ tự: Camera screen với nút "N người bạn" → Bottom sheet "Bạn bè" (trạng thái mặc định gồm ô tìm kiếm, khu vực yêu cầu kết bạn, khu vực chia sẻ liên kết, danh sách bạn bè) → Trạng thái tìm kiếm (kết quả tìm thấy / không tìm thấy / là chính người dùng) → Hộp thoại xác nhận hủy kết bạn → Bảng chia sẻ liên kết.]*

---

## 3.3. Chức năng Chụp ảnh và đăng bài

Chức năng Chụp ảnh và đăng bài là chức năng nghiệp vụ cốt lõi của hệ thống. Đây là nguồn duy nhất sinh ra dữ liệu hình ảnh cho toàn bộ hệ thống — mọi nội dung hiển thị trên bảng tin, trên Home-screen Widget cũng như đối tượng của các tương tác (thả cảm xúc, trò chuyện) đều có nguồn gốc từ những bài đăng được tạo ra qua chức năng này. Chức năng cho phép người dùng ghi lại một khoảnh khắc bằng camera trên thiết bị (hoặc chọn một ảnh có sẵn trong thư viện), thêm một chú thích ngắn gọn, lựa chọn đối tượng nhận bài đăng và gửi đi tới nhóm bạn bè được chỉ định.

Chức năng này bao gồm các luồng thao tác chính sau đây:

- Chụp ảnh trực tiếp từ camera của thiết bị hoặc lựa chọn một ảnh có sẵn từ thư viện hình ảnh.
- Xem trước ảnh, đính kèm chú thích theo một trong bảy định dạng được hệ thống hỗ trợ.
- Lựa chọn đối tượng nhận bài đăng: gửi tới toàn bộ bạn bè hoặc chỉ tới một nhóm chọn lọc cụ thể.
- Hoàn tất đăng bài bằng cách tải ảnh lên dịch vụ lưu trữ và tạo bản ghi tương ứng trên hệ thống.
- Lưu một bản sao của ảnh vào thư viện trên thiết bị mà không thực hiện đăng bài (luồng phụ).

### 3.3.1. Mở giao diện chụp ảnh và chụp ảnh

Khác với nhiều mạng xã hội đặt nút chụp ảnh ở một vị trí phụ trong giao diện, hệ thống Meep đặt **camera ngay tại phần trên của màn hình chính**. Người dùng có thể chụp một bức ảnh ngay khi mở ứng dụng mà không phải thực hiện thêm bất kỳ thao tác điều hướng nào.

**Bảng 3.10.** Các bước thực hiện chức năng Chụp ảnh từ camera của thiết bị.

| Steps | Description |
|---|---|
| S1 | Người dùng mở ứng dụng. Hệ thống hiển thị **màn hình chính (Home)** với phần camera được đặt ngay phía trên bảng tin. |
| S2 | Phần camera bao gồm: khung ngắm (viewfinder) hình vuông, các điều khiển phụ ở phía trên (nút điều chỉnh đèn pin, nhãn mức thu phóng "1x"), thanh thao tác ở phía dưới gồm ba nút "Thư viện", "Chụp" (nút lớn ở giữa) và "Đảo camera". Ngoài ra còn có nút "N người bạn" thể hiện số bạn bè hiện tại của người dùng dùng làm bộ chọn đối tượng nhận cho bài đăng sắp tới. |
| S3 | Trước khi sử dụng camera lần đầu, hệ thống yêu cầu người dùng cấp quyền truy cập camera của thiết bị. Nếu người dùng từ chối, hệ thống hiển thị thông báo hướng dẫn cách cấp lại quyền từ phần cài đặt hệ điều hành. |
| S4 | Người dùng có thể điều chỉnh các thông số trước khi chụp: chọn bật/tắt đèn pin bằng nút "Đèn pin", đổi camera trước/sau bằng nút "Đảo camera". |
| S5 | Người dùng chọn nút "Chụp". Hệ thống ghi lại bức ảnh và chuyển sang **màn hình Xem trước ảnh** (xem mục 3.3.2). |

Bên cạnh việc chụp ảnh trực tiếp, người dùng có thể chọn một ảnh có sẵn từ thư viện trên thiết bị. Luồng phụ này được thực hiện thông qua nút "Thư viện" trên thanh thao tác của phần camera. Khi được chọn, hệ thống mở trình chọn ảnh của hệ điều hành; sau khi người dùng chọn một bức ảnh, hệ thống tải ảnh đó vào màn hình Xem trước với luồng xử lý tiếp theo giống hệt luồng chụp ảnh trực tiếp.

### 3.3.2. Xem trước ảnh, thêm chú thích, chọn đối tượng nhận và đăng bài

Sau khi có được bức ảnh (từ camera hoặc thư viện), người dùng được chuyển tới **màn hình Xem trước**. Đây là màn hình tập trung mọi tinh chỉnh trước khi bài đăng được phát đi: chú thích, đối tượng nhận và các thao tác kết thúc (gửi đi, hủy bỏ hoặc lưu cục bộ).

**Bảng 3.11.** Các bước thực hiện chức năng Đăng bài kể từ màn hình Xem trước ảnh.

| Steps | Description |
|---|---|
| S1 | Tại màn hình Xem trước, ảnh vừa chụp (hoặc ảnh được chọn từ thư viện) được hiển thị ở vùng trung tâm với kích thước vuông. Phía trên ảnh có nút đóng (X) để hủy, nút lưu (mũi tên xuống) để sao lưu ảnh vào thư viện thiết bị. Phía dưới ảnh có bộ chọn đối tượng nhận và nút "Gửi". Một thẻ chú thích (caption pill) được đặt chồng lên phần dưới của ảnh. |
| S2 | **Thêm chú thích.** Người dùng chạm vào thẻ chú thích để mở **modal chọn loại chú thích**. Hệ thống hỗ trợ bảy loại chú thích: văn bản thuần, vị trí, thời tiết, âm nhạc, ngôi sao (kỷ niệm), thời gian và chuỗi ngày liên tiếp (streak). Người dùng chọn một loại, sau đó nhập nội dung chú thích với độ dài tối đa ba mươi ký tự nhằm đảm bảo chú thích hiển thị gọn gàng trên ảnh và trên Home-screen Widget. Trường hợp người dùng không muốn đính kèm chú thích, thẻ chú thích có thể được để trống. |
| S3 | Người dùng cũng có thể vuốt trái hoặc phải trên thẻ chú thích để chuyển qua lại giữa bảy loại chú thích một cách nhanh chóng mà không cần mở modal. |
| S4 | **Chọn đối tượng nhận bài đăng.** Phía dưới ảnh hiển thị bộ chọn đối tượng gồm nút "Tất cả" (được chọn mặc định) và một dãy ảnh đại diện của các bạn bè hiện có. Nếu người dùng giữ nguyên lựa chọn "Tất cả", bài đăng sẽ được gửi tới toàn bộ bạn bè. Nếu người dùng chạm vào ảnh đại diện của từng người bạn cụ thể, bài đăng chỉ được gửi tới những người bạn được chọn. |
| S5 | **Gửi bài đăng.** Người dùng chọn nút "Gửi". Hệ thống bắt đầu quá trình đăng bài gồm hai bước: tải tệp ảnh lên **Cloud Storage** và tạo bản ghi bài đăng trong **Cloud Firestore** với các thông tin gồm mã định danh tác giả, tên hiển thị, đường dẫn ảnh, nội dung và loại chú thích, kiểu đối tượng nhận và danh sách mã định danh người nhận (nếu có). |
| S6 | Trong khi quá trình đăng diễn ra, hệ thống hiển thị biểu tượng quay (loading). Sau khi đăng thành công, hệ thống đưa người dùng quay trở lại **màn hình chính** với phần Camera ở trạng thái sẵn sàng cho lần chụp tiếp theo. |
| S7 | Tại phía máy chủ, một **Cloud Function** được kích hoạt khi bản ghi bài đăng được tạo. Hàm này thực hiện hai nhiệm vụ song song: phân phối bản ghi bài đăng vào bảng tin (feed) của từng người bạn nằm trong danh sách nhận, và phát thông báo đẩy tới các thiết bị của họ thông qua **Firebase Cloud Messaging** (xem mục 3.6). |
| S8 | Trường hợp người dùng quyết định không đăng bài, có thể chọn nút đóng (X) ở góc trên bên trái để hủy. Hệ thống quay về màn hình chính mà không lưu lại bất kỳ dữ liệu nào. |

### 3.3.3. Lưu ảnh vào thư viện thiết bị

Bên cạnh luồng đăng bài chính, người dùng có thể lưu một bản sao của bức ảnh vào thư viện hình ảnh của thiết bị mà không thực hiện đăng bài. Đây là luồng phụ độc lập, không tạo ra bất kỳ bản ghi nào trên hệ thống.

**Bảng 3.12.** Các bước thực hiện chức năng Lưu ảnh vào thư viện thiết bị.

| Steps | Description |
|---|---|
| S1 | Tại màn hình Xem trước ảnh, người dùng chọn nút lưu (biểu tượng mũi tên hướng xuống) ở góc trên bên phải. |
| S2 | Lần đầu sử dụng tính năng này, hệ thống yêu cầu người dùng cấp quyền truy cập thư viện hình ảnh của thiết bị. Sau khi được cấp quyền, hệ thống ghi bản sao ảnh vào thư viện. |
| S3 | Biểu tượng nút lưu được thay đổi tạm thời sang biểu tượng dấu tích trong khoảng hai giây để xác nhận thao tác thành công. Người dùng vẫn ở lại màn hình Xem trước để có thể tiếp tục thực hiện đăng bài nếu mong muốn. |

> **Hình 7.** Wireframe các luồng thuộc chức năng Chụp ảnh và đăng bài.
> *[CẦN BỔ SUNG: chèn các wireframe theo thứ tự: Màn hình chính với phần Camera ở vị trí trên cùng → Hộp thoại cấp quyền camera → Màn hình Xem trước ảnh (trạng thái mặc định) → Modal chọn loại chú thích → Trạng thái sau khi chọn đối tượng nhận cụ thể (highlight các avatar được chọn) → Trạng thái đang gửi (loading) → Trạng thái sau khi lưu vào thư viện (biểu tượng dấu tích).]*

---

## 3.4. Chức năng Bảng tin (Feed)

Chức năng Bảng tin là nơi người dùng tiếp nhận các bài đăng mới nhất từ những người bạn trong mạng lưới của mình. Bảng tin được đặt ngay phía dưới phần Camera trên màn hình chính, cho phép người dùng vừa chụp ảnh vừa xem bảng tin trong cùng một luồng cuộn liên tục. Thay vì hiển thị một danh sách rời rạc gồm nhiều bài đăng cùng lúc, mỗi bài đăng được trình bày dưới dạng một thẻ ảnh chiếm trọn chiều rộng màn hình, sắp xếp theo thứ tự **mới nhất trước**. Cách trình bày này nhấn mạnh tính tức thì và sự thân mật vốn là tinh thần chính của hệ thống Meep.

Chức năng Bảng tin bao gồm các luồng thao tác chính sau đây:

- Hiển thị các bài đăng từ bạn bè theo thứ tự thời gian.
- Lọc bảng tin để chỉ hiển thị bài đăng từ một người bạn cụ thể.
- Chuyển sang chế độ xem dạng lưới (grid view) gồm ba cột.
- Chia sẻ một bài đăng ra ngoài ứng dụng hoặc xóa bài đăng (đối với bài của chính người dùng).

### 3.4.1. Hiển thị bảng tin

Bảng tin được hiển thị ngay khi người dùng cuộn xuống từ phần Camera trên màn hình chính. Việc tải dữ liệu được thực hiện theo cơ chế phân trang (pagination), trong đó hệ thống chỉ tải một số lượng bài đăng giới hạn ở mỗi lần truy vấn và tự động tải thêm khi người dùng tiếp tục cuộn xuống.

**Bảng 3.13.** Các bước thực hiện chức năng Hiển thị bảng tin.

| Steps | Description |
|---|---|
| S1 | Người dùng cuộn xuống từ phần Camera trên màn hình chính. Phần Bảng tin xuất hiện ngay phía dưới với thanh điều khiển nhỏ ở trên cùng gồm nút lọc theo bạn bè (mặc định "Mọi người"), nút chuyển sang chế độ xem dạng lưới và nút chia sẻ. |
| S2 | Hệ thống truy vấn **Cloud Firestore** để lấy danh sách các bài đăng nằm trong bảng tin của người dùng. Mỗi lần truy vấn tải tối đa mười bài đăng được sắp xếp theo thời gian giảm dần. |
| S3 | Trong quá trình tải lần đầu, hệ thống hiển thị biểu tượng quay (loading). Sau khi nhận được dữ liệu, mỗi bài đăng được trình bày dưới dạng một thẻ ảnh kích thước vuông chiếm trọn chiều rộng màn hình, kèm theo các thông tin: chú thích (dạng pill chồng lên ảnh), tên người đăng và thời điểm đăng (dạng nhãn bên dưới ảnh). |
| S4 | Tùy vào người đăng bài là chính người dùng hay bạn bè, hệ thống hiển thị thẻ bài đăng theo hai kiểu khác nhau: bài của bạn bè có thêm thanh tương tác ở phía dưới để thả cảm xúc và gửi tin nhắn (chi tiết tại mục 3.5 và 3.10), bài của chính người dùng hiển thị nhãn "Bạn" cùng với thông tin về số lượng phản hồi đã nhận được. |
| S5 | Khi người dùng cuộn tới gần cuối danh sách hiện tại, hệ thống tự động truy vấn tiếp mười bài đăng tiếp theo và bổ sung vào cuối danh sách. Quá trình này tiếp tục cho tới khi không còn bài đăng cũ hơn. |
| S6 | Trong trường hợp bảng tin chưa có bài đăng nào (người dùng mới hoặc bạn bè chưa đăng bài), hệ thống hiển thị thông báo trạng thái rỗng với gợi ý người dùng thực hiện đăng bài đầu tiên hoặc kết bạn để xem bài đăng. |

### 3.4.2. Lọc bảng tin theo bạn bè

Khi mạng lưới bạn bè có nhiều người, người dùng có thể chỉ muốn xem các bài đăng từ một người bạn cụ thể thay vì toàn bộ bảng tin. Chức năng lọc bảng tin được kích hoạt thông qua nút lựa chọn ở phía trên Bảng tin (gọi là **bộ lọc Bạn bè**) — đây là một thành phần khác biệt với nút chọn đối tượng nhận trên phần Camera, mặc dù hai nút có hình thức tương tự.

**Bảng 3.14.** Các bước thực hiện chức năng Lọc bảng tin theo bạn bè.

| Steps | Description |
|---|---|
| S1 | Tại thanh điều khiển phía trên Bảng tin, nút bộ lọc Bạn bè hiển thị nhãn mặc định là "Mọi người" — tương ứng với trạng thái không lọc. |
| S2 | Người dùng chạm vào nút bộ lọc. Hệ thống mở danh sách thả xuống (dropdown) liệt kê các tùy chọn lọc gồm: "Mọi người", "Bạn" (chỉ xem bài đăng của chính người dùng), và lần lượt từng người bạn trong mạng lưới (kèm ảnh đại diện và tên hiển thị). |
| S3 | Người dùng chọn một mục trong danh sách. Hệ thống đóng danh sách, cập nhật nhãn của nút bộ lọc thành tên người được chọn kèm ảnh đại diện, đồng thời thực hiện lại truy vấn bảng tin với điều kiện bổ sung tương ứng. |
| S4 | Bảng tin được vẽ lại với chỉ những bài đăng phù hợp với bộ lọc. Cơ chế phân trang tiếp tục hoạt động bình thường trên tập dữ liệu đã lọc. |
| S5 | Để quay về trạng thái không lọc, người dùng chọn lại bộ lọc và chọn mục "Mọi người". Nhãn của nút bộ lọc được khôi phục về giá trị mặc định. |

### 3.4.3. Xem bảng tin ở chế độ dạng lưới

Bên cạnh chế độ xem mặc định (từng thẻ ảnh chiếm trọn chiều rộng màn hình), người dùng có thể chuyển sang **chế độ xem dạng lưới** gồm ba cột. Chế độ này hữu ích khi người dùng muốn nhìn bao quát nhiều bài đăng cùng một lúc, đặc biệt khi mạng lưới bạn bè đăng bài thường xuyên.

**Bảng 3.15.** Các bước thực hiện chức năng Xem bảng tin ở chế độ dạng lưới.

| Steps | Description |
|---|---|
| S1 | Trên thanh điều khiển phía trên Bảng tin, người dùng chọn biểu tượng dạng lưới (ba cột). Hệ thống chuyển sang **màn hình Xem dạng lưới**. |
| S2 | Màn hình mới hiển thị tất cả bài đăng dưới dạng lưới gồm ba cột, mỗi ô vuông là một bài đăng được thu nhỏ. Bộ lọc Bạn bè ở chế độ trước được giữ nguyên. |
| S3 | Người dùng có thể cuộn dọc trong màn hình dạng lưới để xem các bài đăng cũ hơn. Cơ chế phân trang tự động tải thêm dữ liệu khi người dùng tới gần cuối danh sách. |
| S4 | Khi người dùng chạm vào một bài đăng trong lưới, hệ thống mở **màn hình Xem ảnh toàn màn hình** với đầy đủ các thông tin và thao tác như trên thẻ bài đăng ở chế độ xem mặc định. |
| S5 | Người dùng có thể quay lại chế độ xem mặc định bằng cách chọn biểu tượng tương ứng trên thanh điều khiển. |

### 3.4.4. Chia sẻ và xóa bài đăng

Đối với mỗi bài đăng trên Bảng tin, người dùng có thể mở một bảng thao tác bổ sung để chia sẻ bài đăng ra ngoài ứng dụng (đối với bài của bạn bè) hoặc xóa bài đăng (đối với bài của chính người dùng).

**Bảng 3.16.** Các bước thực hiện chức năng Chia sẻ và xóa bài đăng.

| Steps | Description |
|---|---|
| S1 | Trên thanh điều khiển phía trên Bảng tin, người dùng chọn biểu tượng chia sẻ (mũi tên hướng lên). Hệ thống hiển thị **bottom sheet "Chia sẻ đến..."** dành cho bài đăng đang được xem hoặc bài đăng gần nhất hiển thị trên màn hình. |
| S2 | Bottom sheet cung cấp các phương thức chia sẻ: chia sẻ qua bảng chia sẻ hệ thống, chia sẻ qua Messenger, chia sẻ qua Instagram, và gửi qua tin nhắn nội bộ (tin nhắn nội bộ được hiện thực hóa thông qua chức năng Trò chuyện — xem mục 3.10). |
| S3 | Bên cạnh các phương thức chia sẻ, bottom sheet còn cung cấp hai nút thao tác: **"Lưu"** — sao lưu bản sao của ảnh vào thư viện của thiết bị, và **"Xóa"** — chỉ hiển thị khi bài đăng thuộc về chính người dùng đang đăng nhập. |
| S4 | Khi người dùng chọn "Xóa", hệ thống hiển thị hộp thoại xác nhận. Nếu người dùng xác nhận, hệ thống xóa bản ghi bài đăng khỏi **Cloud Firestore** và xóa tệp ảnh khỏi **Cloud Storage**. Bài đăng đồng thời biến mất khỏi bảng tin của tất cả người nhận. |
| S5 | Người dùng có thể đóng bottom sheet bằng cách kéo xuống hoặc chạm ra ngoài khu vực bottom sheet. |

> **Hình 8.** Wireframe các luồng thuộc chức năng Bảng tin.
> *[CẦN BỔ SUNG: chèn các wireframe theo thứ tự: Màn hình chính với phần Bảng tin sau khi cuộn xuống → Thẻ bài đăng của bạn bè (đầy đủ thanh tương tác) → Thẻ bài đăng của chính người dùng (có nhãn "Bạn") → Trạng thái dropdown của bộ lọc Bạn bè → Chế độ xem dạng lưới ba cột → Màn hình Xem ảnh toàn màn hình từ lưới → Bottom sheet "Chia sẻ đến..." với hai biến thể: hiển thị nút "Xóa" (bài của người dùng) và không hiển thị nút "Xóa" (bài của bạn bè).]*

---

## 3.5. Chức năng Thả cảm xúc (Reaction)

Chức năng Thả cảm xúc cho phép người dùng phản hồi nhanh đối với một bài đăng của bạn bè thông qua một biểu tượng cảm xúc (emoji). So với việc phải soạn một câu trả lời bằng văn bản, hình thức phản hồi này nhẹ nhàng hơn về mặt thao tác và phù hợp với tinh thần chia sẻ ngắn gọn, tức thì của hệ thống Meep. Trong phạm vi thiết kế của ứng dụng, mỗi người dùng chỉ được phép thả **một biểu tượng cảm xúc duy nhất** trên một bài đăng cụ thể tại một thời điểm. Việc chạm vào biểu tượng cảm xúc khác sẽ thay thế biểu tượng đã chọn trước đó, còn việc chạm lại đúng biểu tượng đang được thả sẽ thu hồi phản hồi đó. Quy ước này giúp tránh tình trạng một bài đăng nhận được nhiều phản hồi từ cùng một người, vốn không phù hợp với một mạng lưới bạn bè thân thiết và quy mô nhỏ.

Chức năng này bao gồm các luồng thao tác chính sau đây:

- Thả một biểu tượng cảm xúc lên bài đăng của bạn bè.
- Thay đổi biểu tượng cảm xúc đã thả sang một biểu tượng khác.
- Thu hồi (bỏ thả) biểu tượng cảm xúc đã thả.
- Xem danh sách những người đã thả cảm xúc cùng biểu tượng tương ứng (đối với bài đăng của chính người dùng hoặc bài đăng trong nhóm bạn của mình).

### 3.5.1. Thả, thay đổi và thu hồi cảm xúc

Trên mỗi thẻ bài đăng của bạn bè trong bảng tin, hệ thống hiển thị một **thanh thao tác cảm xúc** ở phía dưới ảnh. Thanh này gồm ba biểu tượng cảm xúc thường dùng được thiết kế sẵn (preset) và một nút bổ sung dùng để mở **bộ chọn cảm xúc đầy đủ**. Ba thao tác thả, thay đổi và thu hồi đều được điều phối bởi cùng một hành vi của hệ thống và có thể được mô tả thông qua một luồng chung.

**Bảng 3.17.** Các bước thực hiện chức năng Thả, thay đổi và thu hồi cảm xúc.

| Steps | Description |
|---|---|
| S1 | Trên thẻ bài đăng của một người bạn, người dùng nhìn thấy thanh thao tác cảm xúc bao gồm ba biểu tượng cảm xúc thường dùng và một biểu tượng dấu cộng (mở bộ chọn đầy đủ). |
| S2 | **Thả cảm xúc lần đầu.** Người dùng chạm vào một trong ba biểu tượng cảm xúc preset. Hệ thống ghi nhận một bản ghi cảm xúc tương ứng vào **Cloud Firestore**, kèm theo các thông tin: mã định danh người thả, tên hiển thị, biểu tượng được chọn và thời điểm. Biểu tượng vừa chọn được hiển thị ở trạng thái nổi bật (active), đồng thời số lượng cảm xúc hiển thị trên thẻ được tăng lên một đơn vị. |
| S3 | **Mở bộ chọn cảm xúc đầy đủ.** Nếu ba biểu tượng preset không phù hợp với mong muốn, người dùng có thể chạm vào biểu tượng dấu cộng. Hệ thống mở **bottom sheet bộ chọn cảm xúc** cho phép lựa chọn từ một danh sách biểu tượng phong phú hơn được phân loại theo chủ đề. Sau khi chọn, bottom sheet đóng lại và biểu tượng được chọn hiện ở trạng thái active trên thanh thao tác. |
| S4 | **Thay đổi cảm xúc.** Trong trường hợp người dùng đã thả một biểu tượng cảm xúc trước đó nhưng muốn đổi sang biểu tượng khác, người dùng chỉ cần chạm vào biểu tượng mới (trong số ba preset hoặc từ bộ chọn đầy đủ). Hệ thống cập nhật trường biểu tượng trong bản ghi cảm xúc đã có sang giá trị mới mà không tạo thêm bản ghi mới. Tổng số lượng cảm xúc trên bài đăng không thay đổi. |
| S5 | **Thu hồi cảm xúc.** Nếu người dùng muốn thu hồi cảm xúc đã thả, chỉ cần chạm lại vào biểu tượng đang ở trạng thái active. Hệ thống xóa bản ghi cảm xúc tương ứng khỏi Cloud Firestore; biểu tượng trở về trạng thái bình thường và số lượng cảm xúc giảm đi một đơn vị. |
| S6 | Trong tất cả các trường hợp ở trên, hệ thống thực hiện cập nhật giao diện theo cơ chế **cập nhật lạc quan (optimistic update)** — trạng thái mới được phản ánh tức thời trên giao diện trước khi nhận được phản hồi từ máy chủ. Trường hợp xảy ra lỗi (ví dụ mất kết nối mạng), hệ thống khôi phục trạng thái cũ và hiển thị thông báo lỗi tương ứng. |
| S7 | Khi một cảm xúc mới được tạo ra trên bài đăng của một người, tác giả của bài đăng nhận được một thông báo đẩy thông qua hệ thống thông báo. Cơ chế này được trình bày chi tiết trong mục 3.6. |

### 3.5.2. Xem danh sách những người đã thả cảm xúc

Khi một bài đăng nhận được nhiều cảm xúc khác nhau từ bạn bè, người dùng có nhu cầu xem cụ thể ai đã thả cảm xúc gì. Hệ thống cung cấp một bottom sheet liệt kê toàn bộ những người đã phản hồi để đáp ứng nhu cầu này.

**Bảng 3.18.** Các bước thực hiện chức năng Xem danh sách những người đã thả cảm xúc.

| Steps | Description |
|---|---|
| S1 | Trên thanh thao tác cảm xúc của một bài đăng, ngoài các biểu tượng cảm xúc, hệ thống hiển thị **tổng số lượng cảm xúc** mà bài đăng đã nhận được (chỉ hiển thị khi số lượng lớn hơn không). |
| S2 | Người dùng chạm vào vùng hiển thị số lượng cảm xúc. Hệ thống mở **bottom sheet "Danh sách phản hồi"** trượt lên từ phía dưới. |
| S3 | Bottom sheet liệt kê tất cả những người đã thả cảm xúc trên bài đăng, mỗi mục gồm: ảnh đại diện, tên hiển thị và biểu tượng cảm xúc đã thả. Danh sách được sắp xếp theo thời gian giảm dần — phản hồi mới nhất hiển thị ở trên cùng. |
| S4 | Người dùng có thể chạm vào ảnh đại diện của một người trong danh sách để mở hồ sơ cá nhân của người đó (xem mục 3.7), với điều kiện người đó nằm trong mạng lưới bạn bè của người dùng. |
| S5 | Để đóng bottom sheet, người dùng kéo xuống hoặc chạm ra ngoài khu vực của bottom sheet. |

> **Hình 9.** Wireframe các luồng thuộc chức năng Thả cảm xúc.
> *[CẦN BỔ SUNG: chèn các wireframe theo thứ tự: Thẻ bài đăng với thanh thao tác cảm xúc ở trạng thái mặc định → Trạng thái sau khi thả một biểu tượng cảm xúc preset (highlight) → Bottom sheet bộ chọn cảm xúc đầy đủ → Trạng thái sau khi thay đổi sang biểu tượng khác → Bottom sheet "Danh sách phản hồi" liệt kê những người đã thả cảm xúc.]*

---

## 3.6. Chức năng Thông báo đẩy (Push Notification)

Chức năng Thông báo đẩy có nhiệm vụ chủ động thông báo cho người dùng về các sự kiện liên quan đến mình trong hệ thống, ngay cả khi ứng dụng không đang được mở. Khác với những chức năng khác trong báo cáo này, phần lớn các bước của Thông báo đẩy được xử lý ở **phía máy chủ** thông qua các hàm **Cloud Functions** được kích hoạt tự động khi có sự kiện tương ứng xảy ra trong cơ sở dữ liệu. Việc gửi thông báo tới thiết bị được thực hiện qua dịch vụ **Firebase Cloud Messaging (FCM)** — một thành phần đã được giới thiệu trong chương 2.

Chức năng này bao gồm các luồng thao tác chính sau đây:

- Quản lý vòng đời của thẻ định danh thiết bị (FCM token) — tạo, lưu trữ và xóa khi người dùng đăng nhập hoặc đăng xuất.
- Tự động gửi thông báo cho người dùng khi xảy ra một trong bốn sự kiện được hệ thống quan tâm.
- Hiển thị thông báo theo cách phù hợp với trạng thái hiện tại của ứng dụng (đang mở, chạy ngầm hoặc đã đóng).
- Xem lại lịch sử thông báo gần đây ngay trong ứng dụng.
- Dẫn người dùng tới đúng màn hình liên quan khi chạm vào thông báo.

### 3.6.1. Quản lý thẻ định danh thiết bị và các loại sự kiện thông báo

Để có thể gửi thông báo tới đúng thiết bị của một người dùng, hệ thống cần lưu trữ **thẻ định danh thiết bị (FCM token)** — một chuỗi ký tự duy nhất do Firebase Cloud Messaging cấp phát cho mỗi thiết bị đã cài đặt ứng dụng. Việc quản lý vòng đời của thẻ này được thực hiện tự động.

**Bảng 3.19.** Các bước thực hiện chức năng Quản lý thẻ định danh thiết bị.

| Steps | Description |
|---|---|
| S1 | Khi người dùng đăng nhập thành công vào ứng dụng (lần đầu hoặc trong các phiên kế tiếp), hệ thống yêu cầu cấp quyền nhận thông báo từ người dùng (đối với các phiên bản Android có yêu cầu quyền này). |
| S2 | Sau khi được cấp quyền, hệ thống yêu cầu một thẻ định danh thiết bị từ **Firebase Cloud Messaging** và lưu trữ thẻ này vào **Cloud Firestore** dưới đường dẫn `users/{uid}/fcmTokens` thuộc về tài khoản đang đăng nhập. |
| S3 | Trong quá trình sử dụng, FCM có thể cấp lại một thẻ mới (token refresh) khi thẻ cũ hết hạn. Khi đó, hệ thống tự động cập nhật thẻ mới vào cơ sở dữ liệu và đánh dấu lại thời gian cập nhật. |
| S4 | Khi người dùng đăng xuất khỏi ứng dụng (xem mục 3.12), hệ thống xóa toàn bộ thẻ định danh thiết bị của tài khoản khỏi cơ sở dữ liệu, đảm bảo thiết bị này không tiếp tục nhận được thông báo dành cho tài khoản đã đăng xuất. |

Trên cơ sở thẻ định danh thiết bị đã được lưu trữ, hệ thống hỗ trợ **bốn loại sự kiện thông báo** được liệt kê trong bảng dưới đây:

**Bảng 3.20.** Các loại sự kiện thông báo được hệ thống hỗ trợ.

| Loại sự kiện | Điều kiện kích hoạt | Đối tượng nhận thông báo | Nội dung thông báo |
|---|---|---|---|
| `friend_request_received` | Khi có người gửi lời mời kết bạn mới | Người được mời | "{Tên người gửi} muốn kết bạn với bạn" |
| `friend_request_accepted` | Khi một lời mời kết bạn đã gửi được chấp nhận | Người đã gửi lời mời | "{Tên người chấp nhận} đã chấp nhận lời mời kết bạn" |
| `new_post` | Khi một người bạn đăng bài đăng mới | Toàn bộ bạn bè trong danh sách nhận | "{Tên người đăng} vừa chia sẻ một khoảnh khắc" |
| `reaction_received` | Khi có người thả cảm xúc trên bài đăng của mình | Tác giả bài đăng | "{Tên người thả cảm xúc} đã thả cảm xúc vào ảnh của bạn" |

Mỗi sự kiện được kích hoạt bằng một **Cloud Function** tương ứng. Hàm này nhận sự kiện thay đổi từ cơ sở dữ liệu (ví dụ một bản ghi bài đăng mới được tạo), đọc thẻ định danh thiết bị của người nhận, sau đó gửi nội dung thông báo qua Firebase Cloud Messaging. Riêng với sự kiện `new_post`, hệ thống thực hiện thêm thao tác **phân phối (fan-out)** — gửi thông báo lần lượt tới từng người bạn nằm trong danh sách nhận của bài đăng.

### 3.6.2. Hiển thị thông báo theo trạng thái của ứng dụng

Hành vi hiển thị thông báo phụ thuộc vào việc ứng dụng đang ở trạng thái nào tại thời điểm thông báo đến thiết bị. Hệ thống xử lý ba trạng thái chính: ứng dụng đang mở (foreground), ứng dụng đang chạy ngầm (background) và ứng dụng đã bị đóng hoàn toàn (terminated).

**Bảng 3.21.** Các bước thực hiện chức năng Hiển thị thông báo.

| Steps | Description |
|---|---|
| S1 | **Trạng thái mở (foreground).** Khi thông báo đến trong lúc người dùng đang sử dụng ứng dụng, hệ thống hiển thị một **dải thông báo (banner)** trượt xuống từ phía trên màn hình, kèm theo logo ứng dụng, tên người gửi, dấu thời gian và đoạn xem trước nội dung. Dải thông báo có thể được mở rộng để hiển thị thêm hai thao tác phụ: "Trả lời" (đối với những sự kiện cho phép) và "Tắt thông báo". |
| S2 | **Trạng thái chạy ngầm (background).** Khi thông báo đến trong lúc ứng dụng không hiển thị trên màn hình, hệ thống hiển thị thông báo theo dạng thông thường của hệ điều hành — ở vùng thông báo phía trên màn hình và trong khay thông báo. |
| S3 | **Trạng thái đã đóng (terminated).** Khi ứng dụng đã bị đóng hoàn toàn, FCM vẫn đảm bảo việc gửi thông báo tới thiết bị thông qua dịch vụ của hệ điều hành. Thông báo được hiển thị trong khay thông báo của Android. |
| S4 | **Tương tác với thông báo.** Khi người dùng chạm vào thông báo, hệ thống mở ứng dụng và điều hướng tới màn hình tương ứng với loại sự kiện: lời mời kết bạn dẫn tới bottom sheet "Bạn bè", lời mời được chấp nhận dẫn tới hồ sơ của người vừa kết bạn, thông báo cảm xúc dẫn tới bài đăng cụ thể trong bảng tin, thông báo bài đăng mới dẫn tới phần đầu của bảng tin. |

### 3.6.3. Xem lịch sử thông báo trong ứng dụng

Bên cạnh thông báo đẩy được hiển thị ngay khi sự kiện xảy ra, hệ thống còn lưu lại lịch sử các thông báo quan trọng để người dùng có thể xem lại sau này. Lịch sử này được lưu trong cơ sở dữ liệu và truy cập thông qua một màn hình riêng trong ứng dụng.

**Bảng 3.22.** Các bước thực hiện chức năng Xem lịch sử thông báo trong ứng dụng.

| Steps | Description |
|---|---|
| S1 | Từ màn hình chính, người dùng mở **màn hình Thông báo** thông qua biểu tượng tương ứng trên thanh điều hướng phụ. |
| S2 | Hệ thống truy vấn các thông báo đã lưu của người dùng từ cơ sở dữ liệu và hiển thị theo dạng danh sách, sắp xếp theo thời gian giảm dần. Mỗi mục thông báo gồm: biểu tượng tương ứng với loại sự kiện, tiêu đề, nội dung tóm tắt và dấu thời gian tương đối (ví dụ "5 phút trước", "Hôm qua"). |
| S3 | Các thông báo chưa được đọc được đánh dấu trực quan (ví dụ bằng một chấm nhỏ ở góc) để phân biệt với những thông báo đã đọc. |
| S4 | Khi người dùng chạm vào một mục thông báo, hệ thống đánh dấu thông báo là đã đọc và điều hướng tới màn hình tương ứng, tương tự như khi chạm vào thông báo đẩy. |
| S5 | Trường hợp người dùng chưa có thông báo nào, hệ thống hiển thị trạng thái rỗng với một thông điệp ngắn gọn. |

> **Hình 10.** Wireframe các luồng thuộc chức năng Thông báo đẩy.
> *[CẦN BỔ SUNG: chèn các wireframe theo thứ tự: Hộp thoại cấp quyền nhận thông báo → Dải thông báo (banner) khi ứng dụng đang mở (hai trạng thái: thu gọn và mở rộng) → Thông báo trong khay thông báo của Android khi ứng dụng chạy ngầm hoặc đã đóng → Màn hình Lịch sử thông báo trong ứng dụng với các mục đã đọc và chưa đọc → Trạng thái rỗng khi chưa có thông báo nào.]*

---

## 3.7. Chức năng Hồ sơ cá nhân (Profile)

Chức năng Hồ sơ cá nhân cho phép mỗi người dùng quản lý các thông tin định danh và hiển thị của mình trên hệ thống Meep, đồng thời cung cấp một nơi tập hợp lại toàn bộ các bài đăng đã chia sẻ từ trước tới nay. Trang hồ sơ đóng vai trò là "danh thiếp" của người dùng trong mạng lưới bạn bè — đây là nơi bạn bè nhìn thấy ảnh đại diện, tên hiển thị, tên người dùng và một số chỉ số tóm lược về hoạt động của người dùng trên hệ thống. Người dùng có quyền chỉnh sửa các thông tin trên hồ sơ của mình, đồng thời cũng có thể xem hồ sơ của những người bạn đã kết nối.

Chức năng này bao gồm các luồng thao tác chính sau đây:

- Xem trang cá nhân của chính mình với các thông tin tóm lược và lịch sử bài đăng.
- Chỉnh sửa các thông tin cá nhân, bao gồm cả ảnh đại diện.
- Chia sẻ liên kết tới trang cá nhân ra ngoài ứng dụng.
- Xem hồ sơ của một người bạn trong mạng lưới của mình.

### 3.7.1. Xem trang cá nhân

Trang cá nhân là điểm tập trung mọi thông tin định danh và hoạt động của người dùng trên hệ thống. Trang này được truy cập thông qua thanh điều hướng phụ ở phía dưới màn hình.

**Bảng 3.23.** Các bước thực hiện chức năng Xem trang cá nhân.

| Steps | Description |
|---|---|
| S1 | Người dùng chọn biểu tượng "Hồ sơ" trên thanh điều hướng phụ. Hệ thống mở **màn hình Hồ sơ cá nhân**. |
| S2 | Phần đầu màn hình hiển thị các thông tin tóm lược về tài khoản, gồm: ảnh đại diện hình tròn (hoặc ảnh đại diện mặc định nếu người dùng chưa tải lên), tên hiển thị, tên người dùng (kèm ký hiệu `@`), và phần tiểu sử ngắn (nếu có). |
| S3 | Bên dưới phần tóm lược là dãy ba chỉ số thống kê thể hiện hoạt động của người dùng: **số khoảnh khắc** (tổng số bài đăng đã chia sẻ), **số bạn bè** trong mạng lưới và **số không gian chung** mà người dùng đang tham gia. Khi chạm vào chỉ số "Bạn bè", hệ thống mở bottom sheet quản lý bạn bè (xem mục 3.2). |
| S4 | Phía dưới khu vực thống kê là hai nút thao tác chính: **"Chỉnh sửa"** dẫn tới luồng chỉnh sửa thông tin (xem mục 3.7.2) và **"Chia sẻ trang cá nhân"** dẫn tới luồng chia sẻ (xem mục 3.7.3). |
| S5 | Phần dưới cùng của trang là **thanh chuyển tab** với hai mục: "Khoảnh khắc" (hiển thị danh sách ảnh dạng lưới ba cột) và "Nhật ký" (hiển thị các bản nhật ký có chế độ chia sẻ với bạn bè — xem mục 3.9). Tab "Khoảnh khắc" được chọn mặc định. |
| S6 | Khi tab "Khoảnh khắc" được chọn, hệ thống truy vấn toàn bộ bài đăng của người dùng từ cơ sở dữ liệu và hiển thị theo dạng lưới ba cột, sắp xếp theo thời gian giảm dần. Việc tải dữ liệu được thực hiện theo cơ chế phân trang chín bài mỗi lần. |
| S7 | Khi người dùng chạm vào một bài đăng trong lưới, hệ thống mở **màn hình Xem ảnh chi tiết** hiển thị ảnh ở kích thước đầy đủ kèm chú thích, thời điểm đăng và một dải hình ảnh thu nhỏ ở phía dưới cho phép vuốt qua các bài đăng khác. |

### 3.7.2. Chỉnh sửa thông tin cá nhân

Người dùng có thể chỉnh sửa hầu hết các thông tin cá nhân của mình thông qua màn hình chỉnh sửa hồ sơ. Một số thông tin nhạy cảm (như địa chỉ thư điện tử) yêu cầu **xác thực lại mật khẩu** trước khi cập nhật, nhằm đảm bảo chỉ chủ tài khoản mới có quyền thực hiện thay đổi.

**Bảng 3.24.** Các bước thực hiện chức năng Chỉnh sửa thông tin cá nhân.

| Steps | Description |
|---|---|
| S1 | Tại trang cá nhân, người dùng chọn nút "Chỉnh sửa". Hệ thống mở **màn hình Chỉnh sửa hồ sơ** dưới dạng danh sách các mục có thể chỉnh sửa. |
| S2 | **Chỉnh sửa ảnh đại diện.** Người dùng chọn mục "Chỉnh sửa ảnh đại diện". Hệ thống mở bottom sheet với ba tùy chọn: "Chọn từ thư viện" (mở trình chọn ảnh của hệ điều hành), "Chụp ảnh" (mở camera để chụp ảnh mới), hoặc "Gỡ ảnh hiện tại" (xóa ảnh đại diện về trạng thái mặc định). Sau khi người dùng chọn hoặc chụp một ảnh mới, hệ thống tải ảnh lên **Cloud Storage** và cập nhật đường dẫn vào hồ sơ. |
| S3 | **Chỉnh sửa các trường văn bản đơn giản.** Đối với các trường như họ tên, tiểu sử, hệ thống mở một bottom sheet nhập liệu. Người dùng nhập giá trị mới và xác nhận, hệ thống cập nhật hồ sơ trong cơ sở dữ liệu. |
| S4 | **Chỉnh sửa tên người dùng (username).** Khi người dùng chọn mục này, hệ thống mở ô nhập liệu kèm cơ chế kiểm tra tính khả dụng tương tự như ở luồng đăng ký (mục 3.1.1). Tên mới chỉ được lưu khi vừa thỏa điều kiện về định dạng vừa chưa được người dùng khác sử dụng. |
| S5 | **Chỉnh sửa ngày sinh, số điện thoại, giới tính.** Hệ thống mở bottom sheet phù hợp với từng loại dữ liệu (bộ chọn ngày tháng cho ngày sinh, ô nhập số cho số điện thoại, danh sách lựa chọn cho giới tính). Người dùng xác nhận và hệ thống cập nhật vào hồ sơ. |
| S6 | **Cập nhật địa chỉ thư điện tử.** Đây là thao tác đặc biệt yêu cầu xác thực lại. Sau khi người dùng nhập địa chỉ email mới, hệ thống hiển thị hộp thoại yêu cầu nhập mật khẩu hiện tại để xác minh danh tính. Khi xác minh thành công, hệ thống gọi tới Firebase Authentication để cập nhật email và đồng bộ thay đổi vào hồ sơ. |
| S7 | **Bật hoặc tắt thông báo.** Người dùng có thể bật hoặc tắt việc nhận thông báo đẩy thông qua một công tắc trong màn hình chỉnh sửa. Trạng thái này được lưu cục bộ trên thiết bị và áp dụng tại tầng hiển thị thông báo. |
| S8 | Sau mỗi thao tác cập nhật thành công, hệ thống hiển thị một thông báo ngắn xác nhận và quay lại trạng thái danh sách của màn hình Chỉnh sửa hồ sơ. Người dùng có thể quay về trang cá nhân thông qua nút quay lại ở góc trên bên trái. |

### 3.7.3. Chia sẻ trang cá nhân

Tương tự như chức năng chia sẻ liên kết mời sử dụng ứng dụng (mục 3.2.5), chức năng Chia sẻ trang cá nhân cung cấp một liên kết riêng dẫn tới hồ sơ của người dùng. Khác với liên kết mời chung, liên kết này trỏ trực tiếp tới hồ sơ của một người dùng cụ thể.

**Bảng 3.25.** Các bước thực hiện chức năng Chia sẻ trang cá nhân.

| Steps | Description |
|---|---|
| S1 | Tại trang cá nhân, người dùng chọn nút "Chia sẻ trang cá nhân". Hệ thống mở **bottom sheet Chia sẻ hồ sơ** với tiêu đề "Kết bạn với tôi trên Meep nhé!". |
| S2 | Bottom sheet hiển thị liên kết hồ sơ cá nhân dạng `meep://profile/{username}` cùng hai phương thức chia sẻ: "Gửi qua Messenger" và "Sao chép liên kết". |
| S3 | Khi người dùng chọn "Sao chép liên kết", hệ thống sao chép liên kết vào bộ nhớ tạm và hiển thị thông báo xác nhận. |
| S4 | Khi người dùng chọn "Gửi qua Messenger", hệ thống mở bảng chia sẻ hệ thống của Android, từ đó người dùng có thể tiếp tục gửi liên kết tới ứng dụng mong muốn. |
| S5 | Người bạn nhận được liên kết, khi chạm vào, sẽ được dẫn tới hồ sơ của người gửi (nếu đã có tài khoản và đã là bạn) hoặc luồng đăng ký (nếu chưa có tài khoản). |

### 3.7.4. Xem hồ sơ của bạn bè

Bên cạnh việc xem hồ sơ của chính mình, người dùng còn có thể xem hồ sơ của những người bạn đã kết nối trong mạng lưới của mình. Hồ sơ bạn bè có cấu trúc tương tự hồ sơ cá nhân, tuy nhiên không hiển thị các thao tác chỉnh sửa và chỉ hiển thị những nội dung mà người sở hữu hồ sơ đã cho phép chia sẻ.

**Bảng 3.26.** Các bước thực hiện chức năng Xem hồ sơ của bạn bè.

| Steps | Description |
|---|---|
| S1 | Người dùng có thể mở hồ sơ của một người bạn theo nhiều cách: chạm vào ảnh đại diện hoặc tên hiển thị trên một bài đăng của người đó trên bảng tin, chọn nút "Trang cá nhân" trong kết quả tìm kiếm bạn bè (mục 3.2.2), hoặc chạm vào ảnh đại diện trong danh sách những người đã thả cảm xúc (mục 3.5.2). |
| S2 | Hệ thống kiểm tra xem người dùng có nằm trong mạng lưới bạn bè của tài khoản chủ hồ sơ hay không. Nếu không, hệ thống chỉ hiển thị thông tin tối thiểu kèm nút "Gửi kết bạn" thay vì hồ sơ đầy đủ. |
| S3 | Nếu là bạn bè, hệ thống hiển thị hồ sơ với các thành phần tương tự hồ sơ cá nhân: ảnh đại diện, tên hiển thị, tên người dùng, tiểu sử và ba chỉ số thống kê. Hai nút "Chỉnh sửa" và "Chia sẻ trang cá nhân" được thay thế bằng các thao tác phù hợp với bạn bè (ví dụ chuyển sang chức năng Trò chuyện — xem mục 3.10). |
| S4 | Thanh chuyển tab hiển thị "Khoảnh khắc" (lưới ba cột các bài đăng) và "Nhật ký" (các bản nhật ký được người bạn đặt ở chế độ chia sẻ với bạn bè). |
| S5 | Người dùng có thể quay về màn hình trước thông qua nút quay lại ở góc trên bên trái. |

> **Hình 11.** Wireframe các luồng thuộc chức năng Hồ sơ cá nhân.
> *[CẦN BỔ SUNG: chèn các wireframe theo thứ tự: Màn hình Hồ sơ cá nhân (trạng thái mặc định, tab Khoảnh khắc) → Tab Nhật ký → Màn hình Chỉnh sửa hồ sơ (danh sách các mục) → Bottom sheet Chỉnh sửa ảnh đại diện → Hộp thoại xác thực lại mật khẩu khi đổi email → Bottom sheet Chia sẻ trang cá nhân → Hồ sơ bạn bè.]*

---

## 3.8. Chức năng Không gian chung (Space)

Bên cạnh mạng lưới bạn bè tổng quát, hệ thống Meep cung cấp một dạng nhóm nhỏ riêng tư gọi là **Không gian chung (Space)** — nơi tập hợp một nhóm bạn bè cụ thể để chia sẻ ảnh và trò chuyện trong phạm vi hẹp hơn. Một Space được tạo bởi một người dùng (gọi là **người sáng lập**) và bao gồm các thành viên do người sáng lập mời tham gia từ danh sách bạn bè của mình. Mỗi Space có tên riêng, một biểu tượng đại diện (gồm emoji và màu nền) và một bảng tin nội bộ chỉ hiển thị với các thành viên trong Space. Trong phạm vi MVP, mỗi Space được giới hạn ở **tối đa mười thành viên**, bao gồm cả người sáng lập, nhằm phù hợp với tinh thần chia sẻ thân mật của ứng dụng.

Chức năng này bao gồm các luồng thao tác chính sau đây:

- Tạo một Space mới thông qua quy trình ba bước: chọn thành viên, đặt tên và chọn biểu tượng.
- Đăng ảnh vào Space và xem bảng tin riêng của Space.
- Trò chuyện nhóm bên trong Space thông qua thao tác phản hồi (reply) một bài đăng.
- Quản lý Space, bao gồm thay đổi thành viên, rời Space và xóa Space.

### 3.8.1. Tạo Space mới

Việc tạo một Space được tổ chức thành ba bước nhập liệu liên tiếp, nhằm hướng dẫn người dùng từng bước hoàn thiện thông tin cần thiết. Tất cả các bước đều được trình bày dưới dạng bottom sheet kéo lên từ phía dưới màn hình.

**Bảng 3.27.** Các bước thực hiện chức năng Tạo Space mới.

| Steps | Description |
|---|---|
| S1 | Tại màn hình chính, người dùng **giữ lâu (long-press)** vào nút "N người bạn" trên thanh trên cùng của phần Camera. Hệ thống mở **bottom sheet "Thêm Space mới"** ở bước thứ nhất. |
| S2 | **Bước 1 — Chọn bạn bè.** Bottom sheet hiển thị một ô tìm kiếm và danh sách bạn bè hiện có dưới dạng các thẻ kèm hộp kiểm. Người dùng chọn những người bạn muốn đưa vào Space (ít nhất một người). Nút "Tiếp tục" được kích hoạt khi đã có ít nhất một thành viên được chọn. |
| S3 | **Bước 2 — Đặt tên và chọn biểu tượng.** Hệ thống chuyển sang bottom sheet "Cấu hình Space" gồm hai phần: ô nhập tên Space (tối đa ba mươi ký tự, không được để trống) và danh sách biểu tượng được thiết kế sẵn (preset). Mỗi biểu tượng preset là một cặp gồm một emoji và một màu nền tương ứng. Người dùng chọn một biểu tượng từ danh sách hoặc chọn ô "+" để chuyển sang bước tạo biểu tượng tùy chỉnh. |
| S4 | **Bước 3 — Tạo biểu tượng tùy chỉnh (nếu cần).** Hệ thống mở bottom sheet "Tạo theme cho Space" cho phép người dùng chọn một emoji bất kỳ thông qua bộ chọn emoji và một màu nền từ bảng màu thiết kế sẵn. Sau khi hoàn tất, người dùng chọn "Xong" để quay lại bước 2 với biểu tượng vừa tạo. |
| S5 | **Hoàn tất tạo Space.** Tại bước 2, sau khi đã đặt tên và chọn biểu tượng, người dùng chọn nút "Hoàn tất". Hệ thống thực hiện tạo Space bằng cách: tạo bản ghi Space mới trong **Cloud Firestore**, ghi nhận danh sách thành viên (bao gồm cả người sáng lập), gắn biểu tượng đã chọn. Cloud Function tương ứng đồng thời gửi thông báo cho từng thành viên về việc được mời vào Space. |
| S6 | Khi tạo Space thành công, hệ thống đóng bottom sheet và đưa người dùng tới **bảng tin riêng của Space** vừa được tạo. Nếu xảy ra lỗi (ví dụ mất kết nối mạng), hệ thống hiển thị thông báo "Không thể tạo Space, vui lòng thử lại". |

### 3.8.2. Đăng ảnh vào Space và xem bảng tin của Space

Sau khi đã có Space, người dùng có thể chuyển ngữ cảnh chụp ảnh sang Space cụ thể để mọi bài đăng được tự động phân phối tới toàn bộ thành viên của Space đó, đồng thời xem lại các bài đăng trước đó trong bảng tin riêng của Space.

**Bảng 3.28.** Các bước thực hiện chức năng Đăng ảnh vào Space và xem bảng tin của Space.

| Steps | Description |
|---|---|
| S1 | Tại màn hình chính, người dùng chạm vào nút "N người bạn" trên thanh trên cùng của phần Camera. Hệ thống mở bottom sheet hiển thị danh sách các Space mà người dùng đang tham gia. |
| S2 | Người dùng chọn một Space cụ thể trong danh sách. Hệ thống đóng bottom sheet và chuyển phần Camera sang **chế độ ngữ cảnh Space** — màu chủ đạo của giao diện Camera được cập nhật theo màu của Space, và nút phía trên cùng hiển thị tên của Space thay vì "N người bạn". |
| S3 | Người dùng tiếp tục thao tác chụp ảnh, thêm chú thích và đăng bài tương tự như luồng thông thường được mô tả ở mục 3.3. Khác biệt duy nhất là khi bài đăng được phát đi, hệ thống tự động phân phối tới **toàn bộ thành viên của Space** (không có bước chọn đối tượng nhận thủ công). |
| S4 | **Xem bảng tin của Space.** Người dùng truy cập bảng tin nội bộ của một Space thông qua danh sách Space trên hồ sơ cá nhân hoặc thông qua danh sách Space trong bottom sheet chọn ngữ cảnh. Bảng tin của Space được hiển thị với cấu trúc tương tự bảng tin chính (mục 3.4), tuy nhiên chỉ chứa các bài đăng được đăng trong Space đó. |
| S5 | Để quay về ngữ cảnh chia sẻ cho tất cả bạn bè, người dùng mở lại bottom sheet danh sách Space và chọn mục "Tất cả bạn bè" (hoặc tương đương). Màu chủ đạo và tiêu đề của phần Camera được khôi phục về trạng thái mặc định. |

### 3.8.3. Trò chuyện nhóm trong Space

Mỗi Space được tích hợp sẵn một kênh trò chuyện nhóm dành riêng cho các thành viên. Khác với chức năng Trò chuyện một-một được trình bày trong mục 3.10, trò chuyện trong Space luôn gắn với một bài đăng cụ thể trong bảng tin của Space — thay vì là một cuộc hội thoại độc lập.

**Bảng 3.29.** Các bước thực hiện chức năng Trò chuyện nhóm trong Space.

| Steps | Description |
|---|---|
| S1 | Tại bảng tin của một Space, trên mỗi thẻ bài đăng có một thanh nhập tin nhắn ở phía dưới với gợi ý "Gửi tin nhắn...". |
| S2 | Người dùng chạm vào thanh nhập tin nhắn và nhập nội dung muốn gửi, sau đó chọn nút gửi. Hệ thống tạo một bản ghi tin nhắn trong kênh trò chuyện nhóm của Space, đồng thời tham chiếu tới bài đăng mà tin nhắn đang phản hồi. |
| S3 | Tin nhắn vừa gửi được hiển thị tới toàn bộ thành viên của Space đang xem bài đăng tương ứng. Đồng thời, hệ thống gửi thông báo đẩy tới các thành viên khác đang không mở ứng dụng. |
| S4 | Người dùng có thể truy cập màn hình **trò chuyện nhóm đầy đủ** của Space để xem toàn bộ tin nhắn theo dòng thời gian, không phụ thuộc vào bài đăng cụ thể nào. Tin nhắn trong màn hình đầy đủ vẫn giữ liên kết tới bài đăng mà mỗi tin được gửi để phản hồi. |

### 3.8.4. Quản lý thành viên và Space

Người sáng lập của một Space có quyền quản lý cao nhất, bao gồm thêm thành viên mới, loại bỏ thành viên và xóa Space. Các thành viên khác chỉ có quyền rời Space.

**Bảng 3.30.** Các bước thực hiện chức năng Quản lý thành viên và Space.

| Steps | Description |
|---|---|
| S1 | Người dùng mở **màn hình thông tin Space** thông qua nút thông tin trên đầu bảng tin của Space. Màn hình hiển thị tên Space, biểu tượng, danh sách thành viên và các nút thao tác phù hợp với vai trò của người dùng. |
| S2 | **Thêm thành viên mới (chỉ người sáng lập).** Người sáng lập chọn nút "Thêm thành viên". Hệ thống mở danh sách bạn bè chưa thuộc Space để chọn. Sau khi xác nhận, hệ thống bổ sung các thành viên đã chọn vào Space và gửi thông báo tương ứng. |
| S3 | **Loại bỏ thành viên (chỉ người sáng lập).** Người sáng lập chọn biểu tượng tương ứng trên thẻ thành viên và xác nhận thao tác. Thành viên bị loại bỏ không còn nhận được bài đăng cũng như tin nhắn mới trong Space. |
| S4 | **Rời Space (tất cả thành viên).** Người dùng chọn nút "Rời Space". Hệ thống hiển thị hộp thoại xác nhận trước khi thực hiện. Sau khi xác nhận, người dùng được đưa về màn hình chính và không còn truy cập được Space đó. |
| S5 | **Xóa Space (chỉ người sáng lập).** Người sáng lập chọn nút "Xóa Space". Hệ thống hiển thị hộp thoại cảnh báo về việc toàn bộ nội dung của Space sẽ bị xóa vĩnh viễn. Sau khi xác nhận, hệ thống xóa các bản ghi liên quan và đưa toàn bộ thành viên về màn hình chính. |
| S6 | **Trường hợp người sáng lập muốn rời Space.** Hệ thống yêu cầu người sáng lập **chuyển quyền sáng lập** cho một thành viên khác trước khi rời, nhằm đảm bảo Space luôn có người chịu trách nhiệm quản lý. |

> **Hình 12.** Wireframe các luồng thuộc chức năng Không gian chung.
> *[CẦN BỔ SUNG: chèn các wireframe theo thứ tự: Bottom sheet "Thêm Space mới" — Bước 1 chọn bạn bè → Bước 2 đặt tên và chọn biểu tượng (danh sách preset) → Bước 3 tạo biểu tượng tùy chỉnh (tab emoji và tab màu) → Bảng tin riêng của Space sau khi tạo thành công → Trạng thái phần Camera khi đang ở ngữ cảnh Space (màu chủ đạo theo Space) → Bottom sheet danh sách Space để chuyển ngữ cảnh → Thanh nhập tin nhắn trên thẻ bài đăng trong Space → Màn hình trò chuyện nhóm đầy đủ → Màn hình thông tin Space với danh sách thành viên và các nút quản lý.]*

---

## 3.9. Chức năng Nhật ký (Diary)

Trong khi các chức năng chia sẻ ảnh và trò chuyện nói trên đều mang tính tương tác hai chiều giữa người dùng và mạng lưới bạn bè, chức năng **Nhật ký (Diary)** lại được thiết kế hướng nội nhiều hơn — đây là nơi người dùng ghi lại cảm xúc và suy nghĩ cá nhân theo từng ngày dưới dạng một bài viết kết hợp giữa hình ảnh và văn bản. Mỗi bản nhật ký bao gồm một **ảnh tâm trạng (mood image)** đặt làm bìa, kèm theo phần nội dung văn bản và có thể chèn thêm các hình ảnh khác bên trong nội dung. Người dùng có quyền lựa chọn chế độ hiển thị cho từng bản nhật ký: **riêng tư** (chỉ chính người dùng nhìn thấy) hoặc **công khai** (cho phép bạn bè trong mạng lưới xem thông qua trang cá nhân).

Chức năng này bao gồm các luồng thao tác chính sau đây:

- Mở mục Nhật ký và xem danh sách các bản nhật ký đã tạo.
- Tạo một bản nhật ký mới, gồm chọn ảnh tâm trạng làm bìa, soạn nội dung và chèn thêm hình ảnh.
- Thiết lập chế độ hiển thị (riêng tư hoặc công khai) trước khi lưu.
- Xem lại nội dung một bản nhật ký đã tạo.
- Tìm kiếm trong các bản nhật ký theo từ khóa.

### 3.9.1. Mở Nhật ký và xem danh sách

Chức năng Nhật ký được truy cập thông qua biểu tượng tương ứng trên thanh điều hướng phụ. Tùy thuộc vào việc người dùng đã có bản nhật ký nào hay chưa, hệ thống sẽ hiển thị màn hình tương ứng.

**Bảng 3.31.** Các bước thực hiện chức năng Mở Nhật ký và xem danh sách.

| Steps | Description |
|---|---|
| S1 | Trên thanh điều hướng phụ ở phía dưới màn hình, người dùng chọn biểu tượng "Nhật ký" (hình quyển sách kèm trái tim). |
| S2 | Hệ thống truy vấn các bản nhật ký của người dùng từ cơ sở dữ liệu. Trong khi truy vấn, hệ thống hiển thị biểu tượng quay (loading). |
| S3 | **Trường hợp chưa có bản nhật ký nào.** Hệ thống hiển thị **trạng thái rỗng** với thông điệp "Bạn chưa có nhật ký nào" và một nút tròn lớn (Floating Action Button) ở phía dưới màn hình để tạo nhật ký đầu tiên. |
| S4 | **Trường hợp đã có bản nhật ký.** Hệ thống hiển thị **màn hình Danh sách Nhật ký** với các bản nhật ký được trình bày dưới dạng lưới các thẻ tròn. Mỗi thẻ gồm ảnh tâm trạng làm bìa kèm nhãn ngày tháng phía dưới. Thanh trên cùng của màn hình gồm biểu tượng tìm kiếm, tiêu đề "Nhật ký" và ảnh đại diện của người dùng. |
| S5 | Khi người dùng chạm vào một thẻ trong danh sách, hệ thống mở **màn hình Xem nhật ký** ở chế độ chỉ đọc (xem mục 3.9.3). |
| S6 | Khi người dùng chạm vào nút tròn lớn ở phía dưới, hệ thống mở luồng Tạo nhật ký mới (xem mục 3.9.2). Khi người dùng chạm vào biểu tượng tìm kiếm, hệ thống mở màn hình Tìm kiếm Nhật ký (xem mục 3.9.4). |

### 3.9.2. Tạo bản nhật ký mới

Luồng tạo nhật ký được tổ chức theo trình tự: chọn ảnh tâm trạng → soạn nội dung trong trình chỉnh sửa dạng vẽ (canvas) → thiết lập chế độ hiển thị → lưu lại. Mục đích của trình tự này là giúp người dùng bắt đầu một bản nhật ký từ một cảm xúc cụ thể trong ngày, trước khi triển khai nội dung chi tiết.

**Bảng 3.32.** Các bước thực hiện chức năng Tạo bản nhật ký mới.

| Steps | Description |
|---|---|
| S1 | Từ màn hình Danh sách Nhật ký (hoặc trạng thái rỗng), người dùng chạm vào nút tạo mới. Hệ thống mở một overlay với tiêu đề "Hôm nay bạn thế nào?", hiển thị ảnh gần đây nhất từ thư viện của thiết bị, đặt trong năm khung tâm trạng tương ứng với năm cảm xúc: vui vẻ, chán nản, mệt mỏi, buồn bã, ngại ngùng. |
| S2 | Người dùng chọn một khung tâm trạng phù hợp với cảm xúc hiện tại. Hệ thống đóng overlay và mở **màn hình Canvas — trình chỉnh sửa nhật ký** với ảnh tâm trạng đã chọn được đặt làm bìa của bản nhật ký. |
| S3 | **Soạn nội dung.** Bên dưới ảnh bìa là vùng soạn thảo văn bản. Người dùng nhập nội dung nhật ký, có thể bao gồm nhiều đoạn văn nối tiếp nhau. Khi cần thay đổi kiểu chữ cho một đoạn (văn bản thường, tiêu đề, trích dẫn, v.v.), người dùng chọn bộ chọn kiểu chữ trên thanh công cụ của trình chỉnh sửa. |
| S4 | **Chèn thêm ảnh.** Trong quá trình soạn thảo, người dùng có thể chèn thêm hình ảnh từ thư viện thiết bị vào giữa các đoạn văn. Mỗi ảnh được chèn cũng đi kèm với khung trang trí lựa chọn từ thư viện khung có sẵn của hệ thống. |
| S5 | **Thiết lập chế độ hiển thị.** Trước khi lưu, người dùng chạm vào nút thiết lập quyền riêng tư. Hệ thống hiển thị **màn hình Cập nhật quyền** với hai lựa chọn: "Riêng tư" (chỉ người dùng nhìn thấy) và "Công khai" (bạn bè có thể xem thông qua trang cá nhân). Mặc định, mỗi bản nhật ký mới được đặt ở chế độ "Riêng tư". |
| S6 | **Lưu nhật ký.** Người dùng chọn biểu tượng dấu tích trên thanh trên cùng của Canvas. Hệ thống ghi bản nhật ký vào cơ sở dữ liệu kèm theo nội dung văn bản, danh sách ảnh đã chèn, chế độ hiển thị và thời điểm tạo. Sau khi lưu thành công, người dùng được đưa quay lại Danh sách Nhật ký. |
| S7 | Trường hợp người dùng muốn hủy bỏ bản nhật ký đang soạn, chọn nút quay lại ở góc trên bên trái. Hệ thống hiển thị hộp thoại xác nhận trước khi loại bỏ nội dung đã soạn. |

### 3.9.3. Xem bản nhật ký đã tạo

Khi mở một bản nhật ký đã tồn tại, hệ thống chuyển sang chế độ chỉ đọc — toàn bộ nội dung được hiển thị nhưng các ô nhập liệu không cho phép chỉnh sửa.

**Bảng 3.33.** Các bước thực hiện chức năng Xem bản nhật ký đã tạo.

| Steps | Description |
|---|---|
| S1 | Từ Danh sách Nhật ký (mục 3.9.1) hoặc từ tab "Nhật ký" trên trang cá nhân của bạn bè (mục 3.7.4), người dùng chạm vào một bản nhật ký cụ thể. |
| S2 | Hệ thống mở **màn hình Xem nhật ký** với ảnh bìa, nội dung văn bản, các ảnh chèn thêm và bố cục giống y hệt khi soạn thảo, nhưng các vùng nhập liệu được khóa lại để ngăn chỉnh sửa ngoài ý muốn. |
| S3 | Đối với nhật ký của chính người dùng, hệ thống hiển thị các thao tác bổ sung trên thanh trên cùng, gồm nút thay đổi chế độ hiển thị và các thao tác quản lý khác. |
| S4 | Đối với nhật ký công khai của bạn bè, hệ thống hiển thị nội dung ở chế độ chỉ đọc mà không cung cấp các thao tác chỉnh sửa hay quản lý. |
| S5 | Người dùng quay về Danh sách Nhật ký (hoặc trang trước đó) thông qua nút quay lại ở góc trên bên trái. |

### 3.9.4. Tìm kiếm nhật ký

Khi số lượng bản nhật ký tăng dần theo thời gian, người dùng có nhu cầu tìm lại một bản nhật ký cụ thể dựa trên từ khóa. Chức năng tìm kiếm cho phép tìm trong nội dung văn bản của các bản nhật ký do chính người dùng tạo ra.

**Bảng 3.34.** Các bước thực hiện chức năng Tìm kiếm nhật ký.

| Steps | Description |
|---|---|
| S1 | Tại màn hình Danh sách Nhật ký, người dùng chạm vào biểu tượng tìm kiếm trên thanh trên cùng. Hệ thống mở **màn hình Tìm kiếm Nhật ký** với một ô nhập liệu ở phía trên. |
| S2 | Người dùng nhập từ khóa muốn tìm. Sau mỗi ký tự được nhập, hệ thống thực hiện tìm kiếm trên toàn bộ các bản nhật ký của người dùng và cập nhật danh sách kết quả tương ứng. |
| S3 | Kết quả được hiển thị dưới dạng các thẻ tương tự ở Danh sách Nhật ký, mỗi thẻ gồm ảnh bìa và đoạn xem trước nội dung có chứa từ khóa. |
| S4 | Khi người dùng chạm vào một kết quả, hệ thống mở bản nhật ký tương ứng ở chế độ chỉ đọc. |
| S5 | Trường hợp không có bản nhật ký nào khớp với từ khóa, hệ thống hiển thị thông báo "Không tìm thấy kết quả phù hợp". |

> **Hình 13.** Wireframe các luồng thuộc chức năng Nhật ký.
> *[CẦN BỔ SUNG: chèn các wireframe theo thứ tự: Trạng thái rỗng của Nhật ký với nút tạo mới → Màn hình Danh sách Nhật ký dạng lưới các thẻ tròn → Overlay "Hôm nay bạn thế nào?" với năm khung tâm trạng → Màn hình Canvas chỉnh sửa nhật ký (ảnh bìa + nội dung + thanh công cụ) → Trạng thái mở bàn phím trong Canvas → Bộ chọn kiểu chữ → Màn hình Cập nhật quyền (riêng tư / công khai) → Màn hình Xem nhật ký ở chế độ chỉ đọc → Màn hình Tìm kiếm Nhật ký với kết quả.]*

---

## 3.10. Chức năng Trò chuyện (Chat)

Chức năng Trò chuyện cho phép người dùng trao đổi tin nhắn văn bản trong phạm vi mạng lưới bạn bè của mình. Khác với các ứng dụng nhắn tin thông thường vốn cho phép tạo một cuộc trò chuyện độc lập bất cứ lúc nào, hệ thống Meep áp dụng một mô hình đặc thù: **mọi cuộc trò chuyện đều bắt nguồn từ một bài đăng cụ thể**. Người dùng chỉ có thể khởi tạo một cuộc trò chuyện một-một bằng cách phản hồi (reply) một bài đăng trên bảng tin của bạn bè; sau đó, cuộc trò chuyện có thể tiếp tục như một dòng hội thoại thông thường. Cách tiếp cận này phù hợp với tinh thần "lấy ảnh làm trung tâm" của ứng dụng, đồng thời giảm thiểu các tin nhắn không có ngữ cảnh giữa những người chưa thực sự thân thiết.

Chức năng Trò chuyện trong báo cáo này tập trung vào trò chuyện **một-một** giữa hai người bạn. Trò chuyện nhóm trong Space — vốn là một trường hợp đặc biệt — đã được trình bày tại mục 3.8.3.

Chức năng này bao gồm các luồng thao tác chính sau đây:

- Mở danh sách các cuộc trò chuyện (Inbox) đã có.
- Bắt đầu một cuộc trò chuyện một-một bằng cách phản hồi một bài đăng.
- Tiếp tục trao đổi tin nhắn trong cuộc trò chuyện đã có.
- Thực hiện các thao tác quản lý ngay từ trong cuộc trò chuyện, gồm chặn người dùng hoặc hủy kết bạn.

### 3.10.1. Mở danh sách các cuộc trò chuyện

Danh sách các cuộc trò chuyện (Inbox) là nơi tập hợp toàn bộ các dòng hội thoại mà người dùng đang tham gia, bao gồm cả các cuộc trò chuyện một-một và các cuộc trò chuyện nhóm trong Space.

**Bảng 3.35.** Các bước thực hiện chức năng Mở danh sách các cuộc trò chuyện.

| Steps | Description |
|---|---|
| S1 | Trên thanh điều hướng phụ ở phía dưới màn hình, người dùng chọn biểu tượng "Tin nhắn". |
| S2 | Hệ thống truy vấn cơ sở dữ liệu để lấy danh sách các cuộc trò chuyện mà người dùng tham gia. Trong khi truy vấn, hệ thống hiển thị bộ khung tạm (loading skeleton). |
| S3 | Sau khi nhận được dữ liệu, các cuộc trò chuyện được hiển thị theo thứ tự **thời gian tin nhắn cuối cùng giảm dần**. Mỗi mục trong danh sách gồm: ảnh đại diện (đối với chat một-một) hoặc biểu tượng Space (đối với chat nhóm), tên cuộc trò chuyện, nội dung xem trước của tin nhắn cuối cùng, và dấu thời gian. |
| S4 | Khi người dùng chạm vào một mục, hệ thống mở **màn hình Chi tiết cuộc trò chuyện** tương ứng (chat một-một hoặc chat nhóm Space). |
| S5 | Trường hợp người dùng chưa có cuộc trò chuyện nào, hệ thống hiển thị thông báo trạng thái rỗng với hướng dẫn ngắn gọn: "Chưa có tin nhắn nào — phản hồi một ảnh để bắt đầu". |

### 3.10.2. Bắt đầu và tiếp tục trò chuyện một-một

Một cuộc trò chuyện một-một được bắt đầu thông qua thao tác phản hồi một bài đăng trên bảng tin. Sau khi đã có cuộc trò chuyện, người dùng có thể tiếp tục trao đổi tin nhắn thông qua màn hình Chi tiết cuộc trò chuyện.

**Bảng 3.36.** Các bước thực hiện chức năng Bắt đầu và tiếp tục trò chuyện một-một.

| Steps | Description |
|---|---|
| S1 | **Khởi tạo từ bảng tin.** Trên bảng tin, mỗi thẻ bài đăng của bạn bè có một thanh thao tác phía dưới gồm gợi ý "Gửi tin nhắn...". Người dùng chạm vào vùng này. |
| S2 | Thanh thao tác mở rộng tại chỗ thành một ô nhập tin nhắn (không chuyển sang màn hình khác), bên trên ô nhập có hiển thị ảnh thu nhỏ của bài đăng đang được phản hồi. |
| S3 | Người dùng nhập nội dung tin nhắn (tối đa năm trăm ký tự) và chọn nút gửi. Hệ thống ghi tin nhắn vào cơ sở dữ liệu với liên kết tới bài đăng tương ứng. Trong trường hợp cuộc trò chuyện chưa tồn tại trước đó, hệ thống tạo mới một cuộc trò chuyện một-một giữa người dùng và tác giả bài đăng. |
| S4 | Sau khi gửi, ô nhập tin nhắn thu lại về trạng thái ban đầu để người dùng có thể tiếp tục xem bảng tin. Tác giả bài đăng nhận được thông báo về tin nhắn mới (xem mục 3.6). |
| S5 | **Tiếp tục trò chuyện từ Inbox.** Để xem toàn bộ lịch sử hoặc tiếp tục cuộc trò chuyện, người dùng truy cập danh sách tin nhắn và chọn cuộc trò chuyện tương ứng. Hệ thống mở **màn hình Chi tiết cuộc trò chuyện một-một**. |
| S6 | Màn hình này gồm: thanh trên cùng (ảnh đại diện và tên người đối thoại, nút thoát, biểu tượng mở menu thao tác), khối ảnh được phản hồi ở phía trên (đặt làm ngữ cảnh cho dòng hội thoại), danh sách các tin nhắn đã trao đổi sắp xếp theo thứ tự thời gian tăng dần (tin nhắn của người dùng ở bên phải, tin nhắn của người đối thoại ở bên trái), và ô nhập tin nhắn ở phía dưới. |
| S7 | Người dùng nhập tin nhắn mới và gửi tương tự như khi phản hồi từ bảng tin. Hệ thống cập nhật danh sách tin nhắn theo thời gian thực để cả hai phía cùng nhìn thấy nội dung mới. |

### 3.10.3. Quản lý cuộc trò chuyện một-một

Từ trong màn hình Chi tiết cuộc trò chuyện một-một, người dùng có thể thực hiện một số thao tác quản lý liên quan tới người đối thoại — bao gồm hủy kết bạn và chặn (block). Đây là các thao tác mang tính cá nhân nhằm bảo vệ trải nghiệm của người dùng trong những tình huống không mong muốn.

**Bảng 3.37.** Các bước thực hiện chức năng Quản lý cuộc trò chuyện một-một.

| Steps | Description |
|---|---|
| S1 | Tại màn hình Chi tiết cuộc trò chuyện, người dùng chọn biểu tượng menu (ba dấu chấm) trên thanh trên cùng. Hệ thống hiển thị danh sách thả xuống gồm hai mục: "Hủy kết bạn" và "Chặn". |
| S2 | **Hủy kết bạn.** Khi người dùng chọn mục này, hệ thống hiển thị hộp thoại xác nhận. Nếu xác nhận, hệ thống xóa quan hệ bạn bè giữa hai người (tương tự luồng đã mô tả ở mục 3.2.4). Cuộc trò chuyện hiện tại được giữ lại ở chế độ chỉ đọc: người dùng vẫn xem được lịch sử nhưng không thể gửi tin nhắn mới. |
| S3 | **Chặn người dùng.** Khi người dùng chọn mục "Chặn", hệ thống hiển thị bottom sheet xác nhận với lời cảnh báo rằng người bị chặn sẽ không còn liên lạc được với người dùng và ngược lại. |
| S4 | Sau khi xác nhận chặn, hệ thống ghi nhận bản ghi chặn vào cơ sở dữ liệu, đồng thời xóa quan hệ bạn bè (nếu đang tồn tại). Người bị chặn không còn thấy bài đăng, hồ sơ của người dùng và ngược lại. Cuộc trò chuyện chuyển sang chế độ chỉ đọc tương tự trường hợp hủy kết bạn. |
| S5 | Để hủy bỏ một lệnh chặn đã thực hiện trước đó, người dùng truy cập **Cài đặt** (xem mục 3.12) và thao tác từ danh sách người dùng đã chặn. |

> **Hình 14.** Wireframe các luồng thuộc chức năng Trò chuyện.
> *[CẦN BỔ SUNG: chèn các wireframe theo thứ tự: Màn hình Danh sách tin nhắn (Inbox) với các cuộc trò chuyện một-một và nhóm → Trạng thái rỗng của Inbox → Bảng tin với ô phản hồi mở rộng tại chỗ (kèm ảnh thu nhỏ) → Màn hình Chi tiết cuộc trò chuyện một-một (khối ảnh ngữ cảnh ở trên + danh sách tin nhắn) → Trạng thái mở menu thao tác trên thanh trên cùng → Hộp thoại xác nhận hủy kết bạn → Bottom sheet xác nhận chặn → Trạng thái chỉ đọc của cuộc trò chuyện sau khi hủy kết bạn hoặc chặn.]*

---

## 3.11. Chức năng Home-screen Widget Android

Chức năng Home-screen Widget Android là một trong những điểm khác biệt nổi bật của hệ thống Meep so với các ứng dụng cùng phân khúc. Thông qua một tiện ích kích thước **2×2** đặt trên màn hình chính của thiết bị, người dùng có thể nhìn thấy ngay khoảnh khắc mới nhất do bạn bè chia sẻ, kèm theo huy hiệu (badge) thể hiện số lượng bài đăng chưa xem, mà không cần mở ứng dụng. Cơ sở lý thuyết về cách thức hoạt động của Home-screen Widget trên Android đã được trình bày ở mục 2.5 của báo cáo; mục này tập trung vào các luồng thao tác cụ thể mà người dùng thực hiện khi sử dụng widget.

Chức năng này bao gồm các luồng thao tác chính sau đây:

- Thêm Widget Meep vào màn hình chính của thiết bị.
- Theo dõi nội dung được Widget hiển thị và cập nhật theo thời gian.
- Mở ứng dụng đến đúng bài đăng tương ứng khi chạm vào Widget.

### 3.11.1. Thêm Widget vào màn hình chính

Việc thêm Widget được khởi tạo từ trong ứng dụng Meep nhằm hướng dẫn người dùng đi qua hộp thoại của hệ điều hành, thay vì để người dùng phải tự tìm Widget Meep trong số nhiều widget khác của thiết bị.

**Bảng 3.38.** Các bước thực hiện chức năng Thêm Widget vào màn hình chính.

| Steps | Description |
|---|---|
| S1 | Người dùng mở bottom sheet **Cài đặt** từ ảnh đại diện ở góc trên bên phải của màn hình chính (xem mục 3.12). |
| S2 | Trong bottom sheet, người dùng chọn mục "Thêm tiện ích". Hệ thống mở **bottom sheet xác nhận thêm Widget** với hình ảnh xem trước của Widget kích thước 2×2 và hai nút "Thêm" và "Hủy". |
| S3 | Người dùng chọn nút "Thêm". Hệ thống gọi tới giao diện lập trình ứng dụng của hệ điều hành Android nhằm yêu cầu thêm Widget vào màn hình chính. |
| S4 | Hệ điều hành mở **trình chọn vị trí Widget** của chính nó, cho phép người dùng kéo thả Widget Meep vào vị trí mong muốn trên màn hình chính. |
| S5 | Sau khi Widget đã được đặt thành công, hệ điều hành đóng trình chọn và quay về màn hình chính. Hệ thống Meep hiển thị một **màn hình hướng dẫn xác nhận thành công** kèm hình ảnh minh họa Widget đã xuất hiện trên màn hình chính của thiết bị. |
| S6 | Trường hợp người dùng chọn "Hủy" ở bước 2, hệ thống đóng bottom sheet và quay về trạng thái trước đó mà không thực hiện thêm Widget. |

### 3.11.2. Hiển thị ảnh trên Widget

Sau khi đã được thêm vào màn hình chính, Widget hoạt động hoàn toàn tự động — không yêu cầu thêm thao tác nào của người dùng để cập nhật. Nội dung hiển thị trên Widget bao gồm ảnh nền chiếm trọn diện tích, ảnh đại diện của tác giả ở góc dưới bên trái, chú thích đặt cạnh ảnh đại diện (nếu có) và huy hiệu đếm bài chưa xem ở góc trên bên phải.

**Bảng 3.39.** Các bước thực hiện chức năng Hiển thị ảnh trên Widget.

| Steps | Description |
|---|---|
| S1 | Sau khi Widget được thêm vào màn hình chính, một **tác vụ nền định kỳ (Periodic Work Request)** được đăng ký với hệ điều hành Android. Tác vụ này có chu kỳ khoảng mười lăm phút, có thể giãn ra một chút tùy thuộc vào trạng thái tiết kiệm pin của thiết bị. |
| S2 | Khi tác vụ nền được hệ điều hành kích hoạt, hệ thống xác thực phiên đăng nhập hiện tại của người dùng với Firebase Authentication. Trong trường hợp người dùng chưa đăng nhập hoặc đã đăng xuất, Widget hiển thị **trạng thái chỗ giữ chỗ (placeholder)** với biểu trưng Meep cùng dòng chữ "Mở Meep để bắt đầu". |
| S3 | Khi phiên đăng nhập hợp lệ, tác vụ nền truy vấn cơ sở dữ liệu để lấy bài đăng mới nhất trong bảng tin của người dùng. Nếu không có bài đăng nào (ví dụ người dùng chưa có bạn bè đã đăng bài), Widget cũng hiển thị trạng thái chỗ giữ chỗ. |
| S4 | Khi đã có bài đăng phù hợp, tác vụ nền tải tệp ảnh và ảnh đại diện về bộ nhớ đệm cục bộ, đồng thời tính toán **số lượng bài đăng chưa xem** kể từ lần gần nhất người dùng mở ứng dụng. |
| S5 | Tác vụ nền cập nhật giao diện của Widget thông qua giao diện lập trình ứng dụng của Android: đặt ảnh nền, ảnh đại diện dạng tròn, văn bản chú thích (ẩn nếu bài đăng không có chú thích) và huy hiệu đếm. Huy hiệu hiển thị số thực từ 1 tới 9; trong trường hợp số lượng từ 10 trở lên, hiển thị nhãn "9+". |
| S6 | Mỗi lần người dùng mở ứng dụng Meep, hệ thống cập nhật mốc thời gian "lần cuối xem" để cơ chế đếm bài chưa xem ở Widget được tính lại từ thời điểm đó. Kết quả là huy hiệu đếm sẽ trở về không sau khi người dùng đã mở ứng dụng. |

### 3.11.3. Mở ứng dụng từ Widget

Bên cạnh việc hiển thị nội dung, Widget còn đóng vai trò là **lối tắt** dẫn người dùng vào đúng bài đăng đang được trình bày, thay vì chỉ mở ứng dụng ở trạng thái mặc định.

**Bảng 3.40.** Các bước thực hiện chức năng Mở ứng dụng từ Widget.

| Steps | Description |
|---|---|
| S1 | Người dùng chạm vào bất kỳ vị trí nào trên Widget Meep ở màn hình chính của thiết bị. |
| S2 | Hệ điều hành kích hoạt một **ý định mở ứng dụng (Pending Intent)** đã được đăng ký từ trước. Ý định này mang theo mã định danh của bài đăng đang được Widget hiển thị. |
| S3 | Ứng dụng Meep được khởi động — hoặc được khôi phục từ chế độ chạy ngầm nếu trước đó đã được mở — và nhận lấy mã định danh bài đăng. |
| S4 | Hệ thống điều hướng người dùng tới **bảng tin** và tự động cuộn tới vị trí của bài đăng tương ứng, kèm hiệu ứng làm nổi bật trong vài giây đầu để giúp người dùng nhận ra. |
| S5 | Sau khi ứng dụng đã được mở, mốc thời gian "lần cuối xem" của người dùng được cập nhật, và huy hiệu đếm trên Widget sẽ được thiết lập lại trong lần cập nhật định kỳ tiếp theo. |

> **Hình 15.** Wireframe các luồng thuộc chức năng Home-screen Widget Android.
> *[CẦN BỔ SUNG: chèn các wireframe theo thứ tự: Bottom sheet Cài đặt với mục "Thêm tiện ích" → Bottom sheet xác nhận thêm Widget (xem trước Widget 2×2) → Trình chọn vị trí Widget của hệ điều hành Android → Màn hình hướng dẫn xác nhận thành công kèm hình ảnh minh họa Widget trên màn hình chính → Trạng thái thông thường của Widget (ảnh nền + ảnh đại diện + chú thích + huy hiệu đếm) → Trạng thái chỗ giữ chỗ của Widget khi chưa đăng nhập hoặc chưa có bài đăng → Trạng thái màn hình chính của Meep sau khi chạm vào Widget (bảng tin với bài đăng được làm nổi bật).]*

---

## 3.12. Chức năng Cài đặt (Settings)

Chức năng Cài đặt là điểm tập trung các thao tác liên quan tới quản lý tài khoản, quyền riêng tư, các thiết lập của ứng dụng và truy cập tới các tài liệu pháp lý của hệ thống. Khác với cách thiết kế truyền thống đặt Cài đặt như một màn hình riêng biệt, hệ thống Meep đặt toàn bộ phần Cài đặt trong một **bottom sheet trượt lên từ phía dưới**, được kích hoạt nhanh chóng từ ảnh đại diện ở góc trên bên phải của màn hình chính. Cách thiết kế này giúp người dùng truy cập các thiết lập mà không phải rời khỏi ngữ cảnh đang sử dụng.

Chức năng này bao gồm các luồng thao tác chính sau đây:

- Mở bottom sheet Cài đặt và sử dụng các lối tắt nhanh (sao chép liên kết hồ sơ, mở danh sách bạn bè, chia sẻ trang cá nhân, truy cập các Space, thêm Widget).
- Quản lý danh sách những người dùng đã chặn.
- Điều chỉnh quyền riêng tư và dữ liệu.
- Đăng xuất khỏi tài khoản.
- Xóa tài khoản.

### 3.12.1. Mở bottom sheet Cài đặt và sử dụng các lối tắt nhanh

Khi mở Cài đặt, người dùng nhìn thấy một bottom sheet được tổ chức thành nhiều khu vực, mỗi khu vực phục vụ một nhóm thao tác cụ thể. Phần dưới đây mô tả các thao tác nhanh được đặt ở phần trên của bottom sheet, trước khi đi sâu vào các mục cài đặt chi tiết ở các tiểu mục kế tiếp.

**Bảng 3.41.** Các bước thực hiện chức năng Mở bottom sheet Cài đặt và sử dụng các lối tắt nhanh.

| Steps | Description |
|---|---|
| S1 | Tại màn hình chính, người dùng chạm vào **ảnh đại diện** đặt ở góc trên bên phải của thanh trên cùng. Hệ thống mở **bottom sheet Cài đặt** trượt lên từ phía dưới với nền phía sau được làm mờ. |
| S2 | **Phần đầu của bottom sheet** hiển thị tóm lược tài khoản gồm: ảnh đại diện, tên người dùng, và liên kết hồ sơ cá nhân dạng `meep://profile/{username}` kèm biểu tượng sao chép. Khi người dùng chạm vào biểu tượng sao chép, hệ thống sao chép liên kết vào bộ nhớ tạm và hiển thị thông báo xác nhận "Đã sao chép liên kết". |
| S3 | Ngay dưới phần đầu là hàng hai nút thao tác nhanh: **"N người bạn"** mở bottom sheet quản lý bạn bè (xem mục 3.2.1) và **"Chia sẻ"** mở bottom sheet chia sẻ trang cá nhân (xem mục 3.7.3). |
| S4 | **Khu vực Space** hiển thị danh sách các Space mà người dùng đang tham gia dưới dạng các thẻ cuộn ngang, kèm nút "Tạo" cho phép tạo Space mới (xem mục 3.8.1). Khi chạm vào một thẻ Space, người dùng được dẫn tới bảng tin riêng của Space đó. |
| S5 | **Khu vực Thiết lập** chứa mục **"Thêm tiện ích"** dẫn tới luồng thêm Home-screen Widget (xem mục 3.11.1). |
| S6 | **Khu vực Riêng tư và Bảo mật** chứa hai mục: "Tài khoản đã chặn" (xem mục 3.12.2) và "Quyền riêng tư và dữ liệu" (xem mục 3.12.3). |
| S7 | **Khu vực Giới thiệu** chứa hai mục liên kết tới các tài liệu pháp lý của hệ thống: "Điều khoản dịch vụ" và "Chính sách quyền riêng tư". Khi chạm vào mỗi mục, hệ thống mở một trang nội dung dạng văn bản có thể cuộn. |
| S8 | **Khu vực Tài khoản** ở phía dưới cùng của bottom sheet chứa hai mục: "Đăng xuất" (xem mục 3.12.4) và "Xóa tài khoản" (hiển thị với màu đỏ để nhấn mạnh tính chất nguy hiểm — xem mục 3.12.5). |
| S9 | Người dùng có thể đóng bottom sheet bằng cách kéo xuống hoặc chạm ra ngoài khu vực bottom sheet để quay về màn hình chính. |

### 3.12.2. Quản lý tài khoản đã chặn

Khi người dùng đã chặn một số tài khoản (thông qua luồng chặn từ trong cuộc trò chuyện — xem mục 3.10.3), danh sách những tài khoản này có thể được xem và quản lý từ phần Cài đặt.

**Bảng 3.42.** Các bước thực hiện chức năng Quản lý tài khoản đã chặn.

| Steps | Description |
|---|---|
| S1 | Trong bottom sheet Cài đặt, người dùng chọn mục "Tài khoản đã chặn". Hệ thống mở **màn hình Tài khoản đã chặn**. |
| S2 | Màn hình hiển thị danh sách tất cả các tài khoản mà người dùng đã chặn, mỗi mục gồm: ảnh đại diện, tên hiển thị, tên người dùng và nút "Bỏ chặn". |
| S3 | Trường hợp danh sách rỗng, hệ thống hiển thị thông báo trạng thái rỗng tương ứng. |
| S4 | Khi người dùng chọn nút "Bỏ chặn", hệ thống thực hiện ngay thao tác bỏ chặn mà không yêu cầu xác nhận lại — do đây là thao tác đảo ngược một thiết lập đã có trước đó, không gây ra hậu quả không mong muốn. Bản ghi chặn được xóa khỏi cơ sở dữ liệu và mục tương ứng biến mất khỏi danh sách. |
| S5 | Lưu ý rằng việc bỏ chặn **không tự động khôi phục quan hệ bạn bè** đã bị xóa trước đó. Nếu hai bên muốn kết nối lại, một trong hai phải chủ động gửi lời mời kết bạn mới. |

### 3.12.3. Quyền riêng tư và dữ liệu

Mục Quyền riêng tư và dữ liệu cung cấp các cài đặt liên quan đến mức độ hiển thị của người dùng trên hệ thống. Đây là nơi người dùng có thể kiểm soát việc tài khoản của mình có được phép tìm thấy thông qua các cơ chế tìm kiếm hay không.

**Bảng 3.43.** Các bước thực hiện chức năng Điều chỉnh Quyền riêng tư và dữ liệu.

| Steps | Description |
|---|---|
| S1 | Trong bottom sheet Cài đặt, người dùng chọn mục "Quyền riêng tư và dữ liệu". Hệ thống mở **màn hình Quyền riêng tư và dữ liệu**. |
| S2 | Màn hình hiển thị các thiết lập quyền riêng tư, trong đó thiết lập chính là công tắc **"Cho phép tìm kiếm bằng tên người dùng"**. Khi công tắc ở trạng thái bật (mặc định), những người dùng khác có thể tìm thấy tài khoản của người dùng thông qua chức năng tìm kiếm trong luồng kết bạn (xem mục 3.2.2). |
| S3 | Khi người dùng tắt công tắc này, tài khoản sẽ không xuất hiện trong kết quả tìm kiếm, dù người tìm kiếm có gõ đúng tên người dùng. Thay vào đó, kết quả trả về sẽ là "Không tìm thấy". |
| S4 | Sau mỗi thao tác bật hoặc tắt, hệ thống cập nhật ngay lập tức trạng thái mới vào cơ sở dữ liệu mà không yêu cầu nút "Lưu" riêng. Hệ thống hiển thị thông báo ngắn xác nhận thay đổi đã được áp dụng. |
| S5 | Người dùng quay về bottom sheet Cài đặt thông qua nút quay lại ở góc trên bên trái. |

### 3.12.4. Đăng xuất khỏi tài khoản

Chức năng Đăng xuất kết thúc phiên làm việc hiện tại của người dùng, xóa thông tin xác thực được lưu trên thiết bị và đưa người dùng trở về màn hình Khởi động.

**Bảng 3.44.** Các bước thực hiện chức năng Đăng xuất khỏi tài khoản.

| Steps | Description |
|---|---|
| S1 | Trong bottom sheet Cài đặt, người dùng chọn mục "Đăng xuất". Hệ thống hiển thị hộp thoại xác nhận với nội dung "Bạn có chắc muốn đăng xuất khỏi tài khoản?". |
| S2 | Khi người dùng xác nhận, hệ thống thực hiện đồng thời các thao tác: gọi tới **Firebase Authentication** để hủy phiên làm việc hiện tại, xóa thẻ định danh thiết bị (FCM token) khỏi cơ sở dữ liệu nhằm dừng việc nhận thông báo đẩy cho tài khoản đó, và xóa các thông tin tạm thời được lưu trên thiết bị (xem mục 3.6.1). |
| S3 | Sau khi hoàn tất, hệ thống tự động điều hướng người dùng trở về **màn hình Khởi động (Intro)** — cùng với màn hình mà người dùng nhìn thấy khi mở ứng dụng lần đầu. |
| S4 | Người dùng có thể đăng nhập lại vào ngay tài khoản đó hoặc đăng nhập vào một tài khoản khác bằng các phương thức được mô tả ở mục 3.1. |
| S5 | Trường hợp người dùng đã thêm Home-screen Widget, Widget sẽ chuyển sang trạng thái chỗ giữ chỗ với thông điệp "Mở Meep để bắt đầu" trong lần cập nhật định kỳ tiếp theo (xem mục 3.11.2). |

### 3.12.5. Xóa tài khoản

Chức năng Xóa tài khoản cho phép người dùng yêu cầu xóa vĩnh viễn toàn bộ dữ liệu cá nhân khỏi hệ thống. Đây là thao tác **không thể đảo ngược**, do đó hệ thống áp dụng nhiều lớp xác nhận trước khi thực hiện.

**Bảng 3.45.** Các bước thực hiện chức năng Xóa tài khoản.

| Steps | Description |
|---|---|
| S1 | Trong bottom sheet Cài đặt, người dùng chọn mục "Xóa tài khoản" (hiển thị với màu đỏ để nhấn mạnh tính chất). Hệ thống hiển thị **hộp thoại cảnh báo** liệt kê các hệ quả của thao tác: toàn bộ bài đăng, tin nhắn, nhật ký, hồ sơ và mối quan hệ bạn bè sẽ bị xóa vĩnh viễn và không thể khôi phục. |
| S2 | Người dùng đọc cảnh báo và chọn nút xác nhận tiếp tục. Hệ thống yêu cầu **xác thực lại danh tính** bằng cách yêu cầu nhập mật khẩu hiện tại (đối với tài khoản đăng nhập bằng email/mật khẩu) hoặc xác thực lại với Google (đối với tài khoản đăng nhập bằng Google Sign-In). |
| S3 | Khi việc xác thực lại thành công, hệ thống bắt đầu **quy trình xóa dữ liệu dạng phân tầng (cascade delete)**: xóa hồ sơ người dùng, các bài đăng, các bản ghi cảm xúc đã thả, các tin nhắn đã gửi, các bản nhật ký, các mối quan hệ bạn bè, và toàn bộ tệp ảnh thuộc tài khoản trên dịch vụ lưu trữ. |
| S4 | Đối với những Space mà người dùng là người sáng lập duy nhất, hệ thống xóa luôn cả Space tương ứng. Đối với những Space mà người dùng chỉ là thành viên, hệ thống chỉ loại người dùng ra khỏi Space và giữ nguyên Space. |
| S5 | Sau khi hoàn tất quy trình xóa, hệ thống xóa tài khoản trên Firebase Authentication và đưa người dùng quay về màn hình Khởi động. Trong các phiên làm việc kế tiếp, người dùng sẽ thấy ứng dụng ở trạng thái sơ khai, tương tự như khi mới cài đặt. |

> **Hình 16.** Wireframe các luồng thuộc chức năng Cài đặt.
> *[CẦN BỔ SUNG: chèn các wireframe theo thứ tự: Trạng thái mặc định của bottom sheet Cài đặt (đầy đủ các khu vực) → Trạng thái sau khi sao chép liên kết hồ sơ (toast xác nhận) → Màn hình Tài khoản đã chặn (danh sách + nút Bỏ chặn) → Trạng thái rỗng của Tài khoản đã chặn → Màn hình Quyền riêng tư và dữ liệu với công tắc "Cho phép tìm kiếm bằng tên người dùng" → Hộp thoại xác nhận Đăng xuất → Hộp thoại cảnh báo Xóa tài khoản → Hộp thoại xác thực lại mật khẩu trước khi Xóa tài khoản.]*

---

## 3.13. Chức năng Streak / Kỷ niệm

Chức năng Streak / Kỷ niệm cho phép người dùng nhìn lại toàn bộ các khoảnh khắc đã chia sẻ trên hệ thống theo trục thời gian, dưới dạng một cuốn lịch trực quan. Đây là chức năng mang tính hồi tưởng (read-only) — không tạo ra dữ liệu mới mà chỉ trình bày lại các bài đăng đã có theo một cách tổ chức khác. Bên cạnh việc xem lại ảnh theo từng ngày, chức năng còn cung cấp hai chỉ số tóm lược: **tổng số khoảnh khắc** đã đăng và **số ngày chuỗi liên tiếp (streak)** hiện tại.

Khác với các chức năng trước đó, **dữ liệu của Streak / Kỷ niệm không được lưu trong một collection riêng** trong cơ sở dữ liệu mà được tính toán trực tiếp từ tập hợp các bài đăng đã có của người dùng. Cách tiếp cận này giúp duy trì tính nhất quán giữa các chức năng — mọi thay đổi đối với bài đăng (đăng mới, xóa) đều được phản ánh ngay vào lịch.

Chức năng này bao gồm các luồng thao tác chính sau đây:

- Xem lịch các ngày đã đăng bài theo từng tháng, kèm các chỉ số tóm lược.
- Xem chi tiết các bức ảnh đã đăng trong một ngày cụ thể.
- Chia sẻ, lưu cục bộ hoặc xóa một bức ảnh từ trong giao diện Kỷ niệm.

### 3.13.1. Xem lịch các ngày đã đăng bài theo tháng

Màn hình chính của chức năng được tổ chức xoay quanh một bộ lịch tháng. Mỗi ô trong lịch tương ứng với một ngày; các ngày đã có bài đăng được hiển thị nổi bật, trong khi các ngày chưa có bài đăng được làm mờ.

**Bảng 3.46.** Các bước thực hiện chức năng Xem lịch các ngày đã đăng bài theo tháng.

| Steps | Description |
|---|---|
| S1 | Trên thanh điều hướng phụ ở phía dưới màn hình, người dùng chọn biểu tượng "Kỷ niệm" (hình quyển lịch). |
| S2 | Hệ thống truy vấn các bài đăng của người dùng trong tháng hiện tại từ cơ sở dữ liệu. Trong khi truy vấn, hệ thống hiển thị bộ khung tạm (skeleton calendar) với các ô được làm mờ. |
| S3 | Sau khi nhận được dữ liệu, hệ thống hiển thị **màn hình Kỷ niệm** với cấu trúc gồm: tiêu đề "Kỷ niệm" và ảnh đại diện ở phía trên, lịch tháng ở phần thân, và thẻ thống kê ở phía dưới lịch. |
| S4 | Lịch tháng được trình bày theo lưới bảy cột tương ứng với bảy ngày trong tuần, có nhãn ngày trong tuần ở hàng tiêu đề. Các ngày đã đăng bài hiển thị ô **sáng** với ảnh thu nhỏ của bài đăng làm nền; các ngày chưa đăng hiển thị ô **tối** không có nội dung. Ngày hiện tại được làm nổi bật bằng đường viền riêng. |
| S5 | **Chuyển tháng.** Người dùng có thể chuyển sang tháng cũ hơn bằng cách vuốt theo chiều ngang (từ phải sang trái). Tương tự, vuốt theo chiều ngược lại cho phép chuyển sang tháng gần hơn — tuy nhiên không thể vượt qua tháng hiện tại. Khi chuyển tháng, hệ thống thực hiện truy vấn tương tự với khoảng thời gian mới. |
| S6 | **Thẻ thống kê** ở phía dưới lịch hiển thị hai chỉ số tổng quát của tài khoản, không phụ thuộc vào tháng đang xem: "**N** Khoảnh khắc" (tổng số bài đăng) và "**X** ngày chuỗi" (số ngày liên tiếp gần nhất mà người dùng đã đăng ít nhất một bài). |
| S7 | **Trạng thái rỗng.** Nếu người dùng chưa từng đăng bài nào, hệ thống hiển thị lịch với toàn bộ ô tối, cùng thông điệp "Gửi khoảnh khắc đầu tiên của bạn tại Meep!" và thẻ thống kê hiển thị "0 Khoảnh khắc | 0 ngày chuỗi". |
| S8 | Khi người dùng chạm vào một ô ngày đã có bài đăng trên lịch, hệ thống mở **màn hình Chi tiết ảnh** tương ứng với ngày đó (xem mục 3.13.2). |

### 3.13.2. Xem chi tiết ảnh theo ngày

Khi chạm vào một ngày cụ thể trên lịch, người dùng được dẫn tới màn hình xem ảnh chi tiết — nơi cho phép xem từng bức ảnh ở kích thước đầy đủ và duyệt nhanh giữa các ngày khác nhau trong cùng tháng.

**Bảng 3.47.** Các bước thực hiện chức năng Xem chi tiết ảnh theo ngày.

| Steps | Description |
|---|---|
| S1 | Người dùng chạm vào một ô ngày đã có bài đăng trên lịch tháng. Hệ thống mở **màn hình Chi tiết ảnh** ở chế độ toàn màn hình. |
| S2 | Thanh trên cùng của màn hình hiển thị nút đóng (X) ở góc trái, nhãn ngày tháng ở trung tâm, và biểu tượng chia sẻ ở góc phải. |
| S3 | Phần thân của màn hình hiển thị một bức ảnh ở kích thước lớn, kèm chú thích nếu có, và nhãn ghi giờ đăng. Trong trường hợp ngày đó người dùng đã đăng nhiều bức ảnh, các ảnh được hiển thị trong một carousel. |
| S4 | Người dùng có thể vuốt theo chiều ngang để chuyển sang ngày cũ hơn hoặc gần hơn **trong cùng tháng đang xem**. Khi đến ảnh đầu tiên hoặc cuối cùng trong tháng, hiệu ứng nảy nhẹ cho biết đã đến giới hạn — hệ thống không tự động chuyển sang tháng khác. |
| S5 | Phía dưới carousel có một dải các hình ảnh thu nhỏ (thumbnail strip) cuộn ngang, đại diện cho từng ngày có bài đăng trong tháng đang xem. Hình thu nhỏ tương ứng với ảnh đang xem được làm nổi bật bằng đường viền. Người dùng có thể chạm vào một hình thu nhỏ để chuyển nhanh sang ảnh tương ứng. |
| S6 | Khi người dùng chọn nút đóng ở góc trái, hệ thống quay về màn hình Kỷ niệm với lịch tháng giữ nguyên trạng thái trước đó. |

### 3.13.3. Chia sẻ và quản lý ảnh từ giao diện Kỷ niệm

Ngoài việc xem lại, người dùng còn có thể thực hiện một số thao tác trên các bài đăng đã có ngay từ trong giao diện Kỷ niệm thông qua bottom sheet chia sẻ.

**Bảng 3.48.** Các bước thực hiện chức năng Chia sẻ và quản lý ảnh từ giao diện Kỷ niệm.

| Steps | Description |
|---|---|
| S1 | Tại màn hình Chi tiết ảnh, người dùng chọn biểu tượng chia sẻ ở góc phải của thanh trên cùng. Hệ thống mở **bottom sheet "Chia sẻ đến..."** trượt lên từ phía dưới. |
| S2 | Bottom sheet này có cấu trúc tương tự bottom sheet chia sẻ bài đăng đã được trình bày ở mục 3.4.4, gồm các phương thức chia sẻ ra ngoài ứng dụng và các thao tác bổ sung "Lưu" và "Xóa". |
| S3 | Khi người dùng chọn "Lưu", hệ thống ghi bản sao bức ảnh đang xem vào thư viện của thiết bị và hiển thị thông báo xác nhận. Trường hợp lưu thất bại (ví dụ do thiếu quyền), hệ thống hiển thị thông báo lỗi tương ứng. |
| S4 | Khi người dùng chọn "Xóa", hệ thống hiển thị hộp thoại xác nhận. Nếu xác nhận, hệ thống xóa bản ghi bài đăng khỏi cơ sở dữ liệu và xóa tệp ảnh khỏi dịch vụ lưu trữ. Sau khi xóa thành công, hệ thống đóng các màn hình con và đưa người dùng quay về màn hình Kỷ niệm, với ô tương ứng trên lịch tháng được cập nhật về trạng thái không có bài đăng. |
| S5 | Việc xóa một bài đăng tại đây ảnh hưởng đồng thời tới các giao diện khác có hiển thị bài đăng đó: bài đăng biến mất khỏi bảng tin của người nhận, biến mất khỏi trang cá nhân của người dùng, và Widget Home-screen sẽ cập nhật nội dung trong lần đồng bộ định kỳ tiếp theo. |

> **Hình 17.** Wireframe các luồng thuộc chức năng Streak / Kỷ niệm.
> *[CẦN BỔ SUNG: chèn các wireframe theo thứ tự: Màn hình Kỷ niệm với lịch tháng có nhiều ngày sáng và một số ngày tối → Trạng thái khi swipe sang tháng cũ hơn → Trạng thái rỗng khi chưa từng đăng bài → Màn hình Chi tiết ảnh (carousel + thumbnail strip) → Trạng thái khi vuốt qua ảnh khác trong tháng → Bottom sheet "Chia sẻ đến..." từ Kỷ niệm → Hộp thoại xác nhận xóa ảnh.]*