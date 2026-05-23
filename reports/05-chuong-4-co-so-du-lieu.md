# CHƯƠNG 4. CƠ SỞ DỮ LIỆU

Chương này trình bày mô hình dữ liệu được sử dụng trong hệ thống Meep. Trên cơ sở quyết định lựa chọn nền tảng máy chủ Firebase đã được phân tích trong chương 2, toàn bộ dữ liệu nghiệp vụ của hệ thống được lưu trên dịch vụ **Cloud Firestore** — một cơ sở dữ liệu **hướng tài liệu (document-oriented NoSQL)** hoạt động theo mô hình thời gian thực. Khác với các hệ cơ sở dữ liệu quan hệ truyền thống sử dụng các bảng, hàng và cột với mối quan hệ chặt chẽ giữa các bảng, Cloud Firestore tổ chức dữ liệu dưới dạng các **tài liệu (document)** được nhóm lại thành các **bộ sưu tập (collection)**. Mỗi tài liệu là một đối tượng dạng cặp khóa – giá trị có cấu trúc linh hoạt và mỗi collection có thể chứa nhiều tài liệu cùng chủ đề.

Do tính chất phi quan hệ, mô hình dữ liệu của hệ thống được mô tả theo cấu trúc các collection thay vì các bảng. Trong các bảng mô tả schema dưới đây, cột "Kiểu dữ liệu" thể hiện các kiểu dữ liệu đặc trưng mà Cloud Firestore hỗ trợ, bao gồm: `string` (chuỗi), `number` (số), `boolean` (logic), `timestamp` (mốc thời gian), `array` (mảng), `map` (đối tượng lồng nhau) và `reference` (tham chiếu tới tài liệu khác).

---

## 4.1. Tổng quan mô hình dữ liệu Firestore

Trong phạm vi MVP, hệ thống sử dụng **mười collection** chính ở cấp gốc của cơ sở dữ liệu, đồng thời tận dụng cơ chế **subcollection (bộ sưu tập con)** của Firestore để tổ chức các dữ liệu có quan hệ phụ thuộc một-nhiều (ví dụ các tin nhắn trong một cuộc trò chuyện, các phản hồi cảm xúc trên một bài đăng, hay các thông báo của một người dùng). Việc lựa chọn các collection được thực hiện dựa trên nguyên tắc: **một collection tương ứng với một thực thể nghiệp vụ độc lập**, đồng thời cân nhắc tới các yêu cầu về luật bảo mật và mô hình truy vấn của từng chức năng.

Sơ đồ dưới đây trình bày tổng quan các collection và mối quan hệ chính giữa chúng:

> **Hình 18.** Sơ đồ quan hệ giữa các collection trong Cloud Firestore.
> *[CẦN BỔ SUNG: chèn sơ đồ kiểu ERD — các khối hình chữ nhật đại diện cho mười collection chính (`users`, `usernames`, `posts`, `friendships`, `friend_requests`, `blocks`, `spaces`, `space_members`, `conversations`, `diary`); các đường nối thể hiện quan hệ: `users` ↔ `posts` (1-N theo `authorId`), `users` ↔ `friendships` (N-N qua `pairId`), `users` ↔ `friend_requests` (1-N theo `senderId` và `receiverId`), `users` ↔ `blocks` (N-N), `spaces` ↔ `space_members` (1-N), `users` ↔ `conversations` (N-N qua `participantIds`), `users` ↔ `diary` (1-N theo `authorUid`); các subcollection được thể hiện bằng mũi tên lồng nhau từ tài liệu cha tới tài liệu con (`users/{uid}/notifications`, `users/{uid}/feed`, `users/{uid}/fcmTokens`, `posts/{postId}/reactions`, `conversations/{cid}/messages`, `space_members/{sid}/members`).]*

Bảng dưới đây tóm lược chức năng của từng collection để làm cơ sở cho các mục mô tả chi tiết kế tiếp:

**Bảng 4.1.** Tổng quan các collection chính trong hệ thống Meep.

| Collection | Vai trò | Chức năng liên quan |
|---|---|---|
| `users` | Lưu hồ sơ đầy đủ của người dùng | Xác thực, Hồ sơ cá nhân, Cài đặt |
| `usernames` | Bảo đảm tính duy nhất của tên người dùng | Đăng ký, Tìm kiếm bạn bè |
| `posts` | Lưu các bài đăng (ảnh + chú thích) | Đăng bài, Bảng tin, Kỷ niệm, Widget |
| `friendships` | Lưu mối quan hệ bạn bè hai chiều đã được chấp nhận | Quản lý bạn bè, Bảng tin |
| `friend_requests` | Lưu các lời mời kết bạn chưa được xử lý | Quản lý bạn bè |
| `blocks` | Lưu các bản ghi chặn giữa các người dùng | Cài đặt, Trò chuyện |
| `spaces` | Lưu thông tin của các Không gian chung | Không gian chung |
| `space_members` | Lưu danh sách thành viên của từng Space | Không gian chung |
| `conversations` | Lưu metadata của các cuộc trò chuyện | Trò chuyện |
| `diary` | Lưu các bản nhật ký của người dùng | Nhật ký |

Trong các mục từ 4.2 đến 4.11, mỗi collection được trình bày bằng một bảng schema ba cột gồm: **tên trường**, **kiểu dữ liệu** và **mô tả**. Đối với những collection có subcollection đáng chú ý, các subcollection cũng được mô tả ngay bên dưới collection cha tương ứng.

---

## 4.2. Collection `users`

Collection `users` lưu trữ hồ sơ đầy đủ của mỗi người dùng đã đăng ký trên hệ thống. Mỗi tài liệu trong collection này có mã định danh là **mã định danh người dùng (UID)** do Firebase Authentication cấp phát, đảm bảo mối liên kết một-một giữa tài khoản xác thực và hồ sơ nghiệp vụ. Collection này được tạo và cập nhật trong các luồng Xác thực (mục 3.1), Hồ sơ cá nhân (mục 3.7) và Cài đặt (mục 3.12).

**Bảng 4.2.** Cấu trúc dữ liệu của một tài liệu trong collection `users`.

| Tên trường | Kiểu dữ liệu | Mô tả |
|---|---|---|
| `uid` | string | Mã định danh người dùng do Firebase Authentication cấp phát. Trùng với mã định danh của tài liệu. |
| `email` | string | Địa chỉ thư điện tử dùng để đăng nhập. |
| `displayName` | string | Họ và tên đầy đủ do người dùng cung cấp khi đăng ký, hiển thị trên các giao diện công khai. |
| `username` | string | Tên người dùng duy nhất trên toàn hệ thống. Chỉ chứa chữ thường, chữ số và dấu gạch dưới; độ dài từ ba đến hai mươi ký tự. |
| `avatarUrl` | string \| null | Đường dẫn tới ảnh đại diện trên Cloud Storage. Giá trị `null` khi người dùng chưa tải ảnh lên. |
| `bio` | string \| null | Tiểu sử ngắn do người dùng tự nhập (tối đa một trăm năm mươi ký tự). |
| `dateOfBirth` | string \| null | Ngày sinh ở định dạng `DD/MM/YYYY`. Không bắt buộc. |
| `phoneNumber` | string \| null | Số điện thoại liên lạc. Không bắt buộc. |
| `gender` | string \| null | Giới tính. Một trong các giá trị: `male`, `female`, `other`. |
| `postCount` | number | Tổng số bài đăng đã chia sẻ. Được Cloud Functions tự động cập nhật khi có bài đăng mới hoặc bị xóa. |
| `friendCount` | number | Tổng số người bạn hiện có. Được Cloud Functions tự động cập nhật khi lời mời kết bạn được chấp nhận hoặc khi hủy kết bạn. |
| `spaceCount` | number | Tổng số Không gian chung mà người dùng đang tham gia. Được Cloud Functions tự động cập nhật. |
| `isSearchable` | boolean | Cho phép người dùng khác tìm thấy tài khoản này bằng tên người dùng hay không. Giá trị mặc định là `true`, được điều chỉnh tại mục Cài đặt (xem mục 3.12.3). |
| `createdAt` | timestamp | Thời điểm tài khoản được tạo. |
| `updatedAt` | timestamp | Thời điểm gần nhất hồ sơ được cập nhật. |

Bên cạnh các trường dữ liệu trực tiếp ở trên, mỗi tài liệu `users/{uid}` còn chứa bốn subcollection phục vụ những dữ liệu có quan hệ phụ thuộc một-nhiều và cần được tổ chức riêng biệt để đảm bảo hiệu năng và luật bảo mật.

**Bảng 4.3.** Các subcollection thuộc tài liệu `users/{uid}`.

| Đường dẫn subcollection | Vai trò | Mô tả tóm lược |
|---|---|---|
| `users/{uid}/private` | Lưu các thông tin nhạy cảm chỉ chủ tài khoản truy cập được | Dùng cho các dữ liệu nội bộ không hiển thị công khai. |
| `users/{uid}/notifications` | Lưu lịch sử thông báo của người dùng | Mỗi tài liệu là một thông báo đã nhận, gồm `type`, `title`, `body`, `read`, `createdAt`. Chỉ chủ tài khoản đọc được, Cloud Functions có quyền ghi. |
| `users/{uid}/feed` | Lưu kết quả phân phối bài đăng tới người dùng | Mỗi tài liệu là một tham chiếu (`postId`, `authorId`, `spaceId`, `createdAt`) tới một bài đăng từ bạn bè được Cloud Function phân phối tới. Chỉ chủ tài khoản đọc được; ghi chỉ qua Cloud Functions. |
| `users/{uid}/fcmTokens` | Lưu các thẻ định danh thiết bị nhận thông báo đẩy | Mỗi tài liệu chứa `token`, `platform`, `updatedAt`. Tham khảo thêm tại mục 3.6.1. |

Có thể thấy rằng, các trường `postCount`, `friendCount`, `spaceCount` được lưu **trùng lặp (denormalized)** trong tài liệu `users/{uid}` thay vì được tính toán lại mỗi khi cần. Lựa chọn thiết kế này giúp các giao diện hiển thị chỉ số thống kê (ví dụ trang cá nhân) có thể đọc dữ liệu trong một lượt truy vấn duy nhất, thay vì phải thực hiện nhiều truy vấn đếm số lượng riêng biệt. Việc đồng bộ giá trị giữa các bản ghi liên quan được đảm bảo thông qua các Cloud Functions kích hoạt theo sự kiện.

---

## 4.3. Collection `usernames`

Collection `usernames` đóng vai trò là một **bảng tra cứu ngược (reverse lookup table)** nhằm bảo đảm tính duy nhất của tên người dùng trên toàn bộ hệ thống. Mặc dù mỗi tài liệu trong collection `users` đã có trường `username`, nếu chỉ dựa vào trường này thì việc kiểm tra một tên người dùng có sẵn hay chưa sẽ yêu cầu truy vấn toàn bộ collection — không hiệu quả về mặt hiệu năng và không thể đảm bảo nguyên tử (atomic) khi có hai tài khoản đăng ký cùng một tên ở cùng thời điểm.

Để giải quyết vấn đề trên, hệ thống sử dụng tên người dùng làm **mã định danh của tài liệu** trong collection `usernames`. Khi một tài khoản mới được tạo, hệ thống ghi đồng thời hai tài liệu trong cùng một thao tác ghi nguyên tử (batch write): tài liệu `users/{uid}` và tài liệu `usernames/{username}`. Nếu một người dùng khác cùng cố gắng đăng ký với tên đó, thao tác ghi tài liệu `usernames/{username}` sẽ thất bại do trùng mã định danh, đảm bảo tính duy nhất trên toàn hệ thống.

**Bảng 4.4.** Cấu trúc dữ liệu của một tài liệu trong collection `usernames`.

| Tên trường | Kiểu dữ liệu | Mô tả |
|---|---|---|
| `uid` | string | Mã định danh của người dùng đang sở hữu tên người dùng này. Tham chiếu tới `users/{uid}`. |

Collection này được sử dụng trong các chức năng sau:

- **Đăng ký tài khoản** (mục 3.1.1): kiểm tra tính khả dụng của tên người dùng theo thời gian thực trước khi tạo tài khoản.
- **Tìm kiếm bạn bè** (mục 3.2.2): tra cứu nhanh người dùng theo tên người dùng nhập vào.

Có thể thấy rằng, mặc dù collection này chỉ chứa một trường dữ liệu duy nhất, vai trò của nó trong việc bảo đảm tính toàn vẹn của dữ liệu là không thể thay thế. Mọi thay đổi tên người dùng (nếu được hỗ trợ trong tương lai) đều phải đi kèm với việc xóa tài liệu cũ và tạo tài liệu mới trong cùng một thao tác nguyên tử.

---

## 4.4. Collection `posts`

Collection `posts` lưu trữ toàn bộ các bài đăng được tạo ra trên hệ thống, không phân biệt bài đăng cho tất cả bạn bè, bài đăng có chọn lọc người nhận, hay bài đăng trong một Không gian chung. Việc tập trung tất cả bài đăng trong cùng một collection giúp các chức năng hiển thị (Bảng tin, Hồ sơ cá nhân, Kỷ niệm, Widget) có thể truy vấn dữ liệu theo nhiều tiêu chí khác nhau (theo tác giả, theo Space, theo thời gian) một cách thống nhất.

**Bảng 4.5.** Cấu trúc dữ liệu của một tài liệu trong collection `posts`.

| Tên trường | Kiểu dữ liệu | Mô tả |
|---|---|---|
| `postId` | string | Mã định danh duy nhất của bài đăng. Trùng với mã định danh của tài liệu. |
| `authorId` | string | Mã định danh của người dùng đã đăng bài. Tham chiếu tới `users/{uid}`. |
| `authorName` | string | Tên hiển thị của tác giả tại thời điểm đăng. Được lưu trùng lặp để hiển thị nhanh khi đọc bảng tin. |
| `authorAvatarUrl` | string \| null | Đường dẫn ảnh đại diện của tác giả tại thời điểm đăng. Được lưu trùng lặp. |
| `imageUrl` | string \| null | Đường dẫn ảnh chính của bài đăng trên Cloud Storage. Có giá trị khi bài đăng dùng chế độ camera đơn. |
| `backImageUrl` | string \| null | Đường dẫn ảnh chụp từ camera sau. Dành cho chế độ camera kép (ngoài phạm vi MVP). |
| `frontImageUrl` | string \| null | Đường dẫn ảnh chụp từ camera trước. Dành cho chế độ camera kép. |
| `isDualCamera` | boolean | Cờ đánh dấu bài đăng có dùng chế độ camera kép hay không. Giá trị mặc định là `false`. |
| `caption` | string \| null | Nội dung chú thích của bài đăng. Độ dài tối đa ba mươi ký tự (xem mục 3.3.2). Có thể để trống. |
| `captionType` | string \| null | Loại chú thích, một trong các giá trị: `text`, `location`, `weather`, `music`, `star`, `time`, `streak`. |
| `audienceType` | string | Kiểu đối tượng nhận bài đăng. Một trong hai giá trị: `all` (gửi cho toàn bộ bạn bè) hoặc `select` (gửi cho danh sách bạn bè được chọn). |
| `audienceUids` | array<string> | Danh sách mã định danh của những người bạn nhận bài đăng. Có giá trị khi `audienceType` là `select`. |
| `spaceId` | string \| null | Mã định danh của Không gian chung mà bài đăng thuộc về. Khi có giá trị, các trường `audienceType` và `audienceUids` sẽ không có tác dụng vì bài đăng được phân phối tới toàn bộ thành viên của Space. |
| `createdAt` | timestamp | Thời điểm bài đăng được tạo. Sử dụng `serverTimestamp()` để tránh phụ thuộc đồng hồ của thiết bị người dùng. |

Bên cạnh các trường dữ liệu trên, mỗi tài liệu `posts/{postId}` còn có một subcollection chứa các phản hồi cảm xúc mà người dùng khác đã thả lên bài đăng.

**Bảng 4.6.** Cấu trúc dữ liệu của một tài liệu trong subcollection `posts/{postId}/reactions`.

| Tên trường | Kiểu dữ liệu | Mô tả |
|---|---|---|
| `reactorUid` | string | Mã định danh của người đã thả cảm xúc. Trùng với mã định danh của tài liệu, đảm bảo mỗi người chỉ có một phản hồi trên một bài đăng (xem mục 3.5). |
| `reactorName` | string | Tên hiển thị của người đã thả cảm xúc. Lưu trùng lặp để hiển thị nhanh trong danh sách phản hồi. |
| `emoji` | string | Biểu tượng cảm xúc dạng một ký tự emoji. |
| `createdAt` | timestamp | Thời điểm phản hồi được tạo hoặc cập nhật. |

Cấu trúc denormalize của các trường `authorName`, `authorAvatarUrl` trên tài liệu bài đăng và `reactorName` trên tài liệu phản hồi là một quyết định thiết kế phục vụ hiệu năng. Nhờ cách lưu này, mỗi khi hiển thị một thẻ bài đăng trên bảng tin hoặc một mục trong danh sách phản hồi, ứng dụng không phải thực hiện thêm một truy vấn riêng tới `users/{uid}` để lấy thông tin tác giả hoặc người phản hồi. Bù lại, trong trường hợp người dùng thay đổi tên hiển thị hoặc ảnh đại diện, các bài đăng cũ vẫn giữ giá trị tại thời điểm đăng — đây là chấp nhận đánh đổi phù hợp với bản chất của một mạng xã hội ảnh, nơi mỗi bài đăng phản ánh một khoảnh khắc cụ thể trong quá khứ.

---

## 4.5. Collection `friendships`

Collection `friendships` lưu trữ các mối quan hệ bạn bè đã được thiết lập giữa hai người dùng trên hệ thống. Do mỗi quan hệ bạn bè trên Meep mang **tính chất hai chiều** (cả hai phía cùng là bạn của nhau), hệ thống không tách thành hai bản ghi riêng cho mỗi phía mà chỉ lưu **một bản ghi duy nhất** cho mỗi cặp người dùng.

Để bảo đảm tính duy nhất và tránh tạo trùng quan hệ bạn bè giữa cùng một cặp, **mã định danh của tài liệu** trong collection `friendships` được tạo theo quy tắc đặc biệt gọi là **mã định danh cặp (pair identifier)**: nối hai mã định danh người dùng theo thứ tự từ điển (mã định danh nhỏ hơn đứng trước), ngăn cách bằng dấu gạch dưới. Ví dụ: nếu hai người dùng có mã định danh là `abc123` và `xyz789`, mã định danh của tài liệu sẽ là `abc123_xyz789`. Quy tắc này đảm bảo dù lời mời được gửi từ phía nào trước, mã định danh được sinh ra cũng giống nhau.

**Bảng 4.7.** Cấu trúc dữ liệu của một tài liệu trong collection `friendships`.

| Tên trường | Kiểu dữ liệu | Mô tả |
|---|---|---|
| `uid1` | string | Mã định danh của một trong hai người trong quan hệ bạn bè. |
| `uid2` | string | Mã định danh của người còn lại. |
| `members` | array<string> | Mảng chứa hai mã định danh `uid1` và `uid2`. Trường này được lưu trùng lặp nhằm hỗ trợ truy vấn theo cơ chế `array-contains` của Firestore — cho phép lấy nhanh tất cả các quan hệ bạn bè liên quan đến một người dùng cụ thể. |
| `createdAt` | timestamp | Thời điểm quan hệ bạn bè được thiết lập (khi lời mời kết bạn được chấp nhận). |

Việc thiết lập một bản ghi trong collection `friendships` chỉ được thực hiện thông qua một **Cloud Function**, không phải bởi ứng dụng phía client. Cụ thể, khi người nhận chấp nhận một lời mời kết bạn (xem mục 3.2.3), Cloud Function tương ứng sẽ thực hiện đồng thời: tạo bản ghi `friendships` mới, cập nhật trạng thái của lời mời kết bạn liên quan thành "đã chấp nhận", và tăng số lượng bạn bè của cả hai phía. Cách tiếp cận này đảm bảo tính toàn vẹn của dữ liệu xuyên suốt các bước.

---

## 4.6. Collection `friend_requests`

Collection `friend_requests` lưu trữ các lời mời kết bạn — bao gồm cả lời mời đang chờ xử lý và lời mời đã được xử lý. Khác với collection `friendships` chỉ lưu các quan hệ đã thiết lập, collection này phản ánh **trạng thái tương tác đang diễn ra** giữa các người dùng và giữ lại lịch sử của các lời mời để hỗ trợ tham chiếu khi cần.

**Bảng 4.8.** Cấu trúc dữ liệu của một tài liệu trong collection `friend_requests`.

| Tên trường | Kiểu dữ liệu | Mô tả |
|---|---|---|
| `requestId` | string | Mã định danh duy nhất của lời mời. Trùng với mã định danh của tài liệu. |
| `senderId` | string | Mã định danh của người gửi lời mời. Tham chiếu tới `users/{uid}`. |
| `receiverId` | string | Mã định danh của người được mời. Tham chiếu tới `users/{uid}`. |
| `status` | string | Trạng thái hiện tại của lời mời, một trong bốn giá trị: `pending` (đang chờ xử lý), `accepted` (đã được chấp nhận), `declined` (đã bị từ chối) hoặc `cancelled` (đã được người gửi thu hồi). |
| `createdAt` | timestamp | Thời điểm lời mời được tạo. |
| `updatedAt` | timestamp | Thời điểm gần nhất trạng thái của lời mời được cập nhật. |

Vòng đời của một tài liệu trong collection `friend_requests` được mô tả như sau:

- Khi người dùng A gửi lời mời tới người dùng B (xem mục 3.2.2), hệ thống tạo một tài liệu mới với `status = "pending"`.
- Nếu B chấp nhận, một Cloud Function cập nhật `status = "accepted"` và đồng thời tạo bản ghi tương ứng trong collection `friendships`.
- Nếu B từ chối, `status` được cập nhật thành `"declined"`.
- Nếu A muốn thu hồi lời mời trước khi B kịp xử lý, `status` được cập nhật thành `"cancelled"`.

Việc giữ lại các lời mời đã xử lý (thay vì xóa chúng khỏi cơ sở dữ liệu) cho phép hệ thống tra cứu lịch sử khi cần, đồng thời tránh các trường hợp một người dùng gửi nhiều lời mời lặp đi lặp lại trong thời gian ngắn. Tuy nhiên, các lời mời này không hiển thị trên giao diện danh sách lời mời đang chờ — giao diện chỉ lấy các tài liệu có `status = "pending"`.

---

## 4.7. Collection `blocks`

Collection `blocks` lưu trữ các bản ghi chặn (block) giữa các người dùng. Khác với quan hệ bạn bè vốn mang tính hai chiều, **quan hệ chặn là một chiều**: người chặn (blocker) chủ động ngắt mọi tương tác với người bị chặn (blocked), nhưng người bị chặn không tự động chặn lại phía bên kia.

Do tính một chiều này, mã định danh của tài liệu trong collection `blocks` được tạo bằng cách nối **mã định danh người chặn trước, sau đó là mã định danh người bị chặn**, ngăn cách bằng dấu gạch dưới (theo đúng thứ tự, không sắp xếp). Nhờ đó, hai bản ghi tương ứng với hai chiều chặn (nếu có) tồn tại như hai tài liệu độc lập.

**Bảng 4.9.** Cấu trúc dữ liệu của một tài liệu trong collection `blocks`.

| Tên trường | Kiểu dữ liệu | Mô tả |
|---|---|---|
| `blockId` | string | Mã định danh duy nhất của bản ghi chặn. Trùng với mã định danh của tài liệu, có dạng `{blockerUid}_{blockedUid}`. |
| `blockerUid` | string | Mã định danh của người dùng đã thực hiện thao tác chặn. Tham chiếu tới `users/{uid}`. |
| `blockedUid` | string | Mã định danh của người dùng bị chặn. Tham chiếu tới `users/{uid}`. |
| `createdAt` | timestamp | Thời điểm bản ghi chặn được tạo. |

Việc tạo và xóa bản ghi trong collection `blocks` chỉ được thực hiện thông qua Cloud Functions. Cụ thể, khi một người dùng chặn một người khác (xem mục 3.10.3), Cloud Function thực hiện đồng thời: ghi bản ghi vào `blocks`, xóa bản ghi tương ứng trong `friendships` nếu hai bên đang là bạn, và cập nhật trạng thái của cuộc trò chuyện liên quan thành chỉ đọc. Ngược lại, khi người dùng thực hiện thao tác "Bỏ chặn" từ phần Cài đặt (mục 3.12.2), bản ghi tương ứng được xóa khỏi collection.

Dữ liệu trong collection này được sử dụng làm điều kiện kiểm tra trong các luật bảo mật của Firestore — ví dụ một bài đăng chỉ được hiển thị cho một người dùng nếu giữa hai phía không có bản ghi chặn theo bất kỳ chiều nào.

---

## 4.8. Collection `spaces`

Collection `spaces` lưu trữ thông tin của các Không gian chung (Space) — các nhóm bạn bè nhỏ được người dùng tạo ra để chia sẻ ảnh và trò chuyện riêng tư. Mỗi tài liệu trong collection này chứa các thông tin chung của một Space: tên, biểu tượng đại diện, người sáng lập và danh sách thành viên ở dạng tóm lược.

**Bảng 4.10.** Cấu trúc dữ liệu của một tài liệu trong collection `spaces`.

| Tên trường | Kiểu dữ liệu | Mô tả |
|---|---|---|
| `spaceId` | string | Mã định danh duy nhất của Space. Trùng với mã định danh của tài liệu. |
| `name` | string | Tên Space do người sáng lập đặt. Độ dài tối đa ba mươi ký tự (xem mục 3.8.1). |
| `iconEmoji` | string | Biểu tượng cảm xúc đại diện cho Space, ở dạng một ký tự emoji. Giá trị mặc định là `👥`. |
| `colorHex` | string | Màu nền của biểu tượng dưới dạng chuỗi mã màu hệ thập lục phân, gồm bảy ký tự bắt đầu bằng `#`. |
| `creatorId` | string | Mã định danh của người sáng lập Space. Tham chiếu tới `users/{uid}`. |
| `memberCount` | number | Tổng số thành viên hiện có của Space, bao gồm cả người sáng lập. Tối đa mười thành viên (xem mục 3.8). Lưu trùng lặp để truy vấn nhanh. |
| `memberIds` | array<string> | Danh sách mã định danh của các thành viên. Lưu trùng lặp để hỗ trợ truy vấn theo cơ chế `array-contains`. |
| `createdAt` | timestamp | Thời điểm Space được tạo. |
| `deletedAt` | timestamp \| null | Thời điểm Space bị xóa. Giá trị `null` cho biết Space đang hoạt động bình thường; có giá trị cho biết Space đã được **xóa mềm (soft delete)**. |

Hệ thống áp dụng cơ chế **xóa mềm** đối với Space thay vì xóa cứng. Khi người sáng lập xóa một Space, hệ thống không loại bỏ tài liệu khỏi cơ sở dữ liệu mà chỉ gán giá trị cho trường `deletedAt`. Cách tiếp cận này giúp các bài đăng và tin nhắn liên quan vẫn giữ được tham chiếu hợp lệ cho mục đích kiểm toán và sao lưu, đồng thời cho phép hệ thống cung cấp tùy chọn khôi phục trong một khoảng thời gian xác định nếu cần (tính năng này nằm ngoài phạm vi MVP).

---

## 4.9. Collection `space_members`

Trong khi collection `spaces` chỉ lưu các thông tin tóm lược về Space, collection `space_members` lưu **chi tiết về từng thành viên** của mỗi Space, bao gồm vai trò và thời điểm tham gia. Đây là một collection được tổ chức theo dạng **subcollection ở cấp gốc** — tức là sử dụng đường dẫn lồng nhau `space_members/{spaceId}/members/{uid}` nhằm tách biệt rõ dữ liệu thành viên của từng Space.

**Bảng 4.11.** Cấu trúc dữ liệu của một tài liệu trong subcollection `space_members/{spaceId}/members/{uid}`.

| Tên trường | Kiểu dữ liệu | Mô tả |
|---|---|---|
| `uid` | string | Mã định danh của thành viên. Trùng với mã định danh của tài liệu, đảm bảo mỗi người chỉ là thành viên duy nhất một lần trong cùng một Space. |
| `role` | string | Vai trò của thành viên trong Space. Một trong hai giá trị: `creator` (người sáng lập, có quyền cao nhất) hoặc `member` (thành viên thường). |
| `joinedAt` | timestamp | Thời điểm thành viên được thêm vào Space. |

Cấu trúc tách biệt giữa hai collection `spaces` và `space_members` mang tới một số lợi ích thiết kế:

- **Tách biệt mức độ truy cập:** thông tin tóm lược của Space (tên, biểu tượng, danh sách mã định danh thành viên) được lưu trong `spaces`, nơi có luật bảo mật cho phép tất cả thành viên đọc. Thông tin chi tiết về từng thành viên (bao gồm thời điểm tham gia và vai trò) được tách ra `space_members` để có thể áp dụng các luật bảo mật chi tiết hơn.
- **Hiệu năng truy vấn:** việc liệt kê danh sách thành viên của một Space cụ thể được thực hiện bằng truy vấn trực tiếp lên subcollection, không cần đọc toàn bộ tài liệu `spaces`.
- **Tính mở rộng:** trong tương lai, nếu bổ sung thêm các thuộc tính cá nhân hóa cho từng thành viên (ví dụ biệt danh trong Space, trạng thái thông báo riêng), các trường này có thể được thêm vào `space_members` mà không ảnh hưởng đến cấu trúc của `spaces`.

Việc thêm, xóa thành viên đều được thực hiện qua Cloud Functions để bảo đảm tính nhất quán giữa `space_members`, trường `memberIds`/`memberCount` trong tài liệu cha `spaces` và trường `spaceCount` trong tài liệu của từng thành viên ở collection `users`.

---

## 4.10. Collection `conversations`

Collection `conversations` lưu trữ thông tin tóm lược của các cuộc trò chuyện đang diễn ra trên hệ thống, bao gồm cả các cuộc trò chuyện **một-một** giữa hai người bạn và các cuộc trò chuyện **nhóm** trong Không gian chung. Mỗi tài liệu trong collection này không chứa nội dung tin nhắn cụ thể (do tin nhắn được tách ra subcollection để quản lý phân trang hiệu quả), mà chỉ chứa các thông tin cần thiết cho việc liệt kê và điều hướng tới một cuộc trò chuyện cụ thể.

**Bảng 4.12.** Cấu trúc dữ liệu của một tài liệu trong collection `conversations`.

| Tên trường | Kiểu dữ liệu | Mô tả |
|---|---|---|
| `conversationId` | string | Mã định danh duy nhất của cuộc trò chuyện. Trùng với mã định danh của tài liệu. |
| `type` | string | Kiểu cuộc trò chuyện. Một trong hai giá trị: `direct` (trò chuyện một-một giữa hai người bạn) hoặc `space` (trò chuyện nhóm trong Không gian chung). |
| `participantIds` | array<string> | Danh sách mã định danh của những người tham gia cuộc trò chuyện. Đối với chat một-một, mảng có đúng hai phần tử; đối với chat nhóm Space, mảng chứa toàn bộ thành viên của Space. |
| `spaceId` | string \| null | Mã định danh của Không gian chung mà cuộc trò chuyện thuộc về, nếu là chat nhóm. Có giá trị `null` đối với chat một-một. |
| `quotedPostId` | string \| null | Mã định danh của bài đăng mà cuộc trò chuyện được khởi tạo từ đó. Khái niệm "trò chuyện gắn với ảnh" của hệ thống (xem mục 3.10) được phản ánh thông qua trường này. |
| `lastMessage` | string | Nội dung xem trước của tin nhắn cuối cùng (tối đa năm mươi ký tự). Lưu trùng lặp để hiển thị nhanh trên danh sách Inbox mà không phải truy vấn thêm vào subcollection tin nhắn. |
| `lastMessageAt` | timestamp | Thời điểm của tin nhắn cuối cùng. Dùng làm tiêu chí sắp xếp danh sách Inbox. |
| `lastSenderId` | string | Mã định danh của người gửi tin nhắn cuối cùng. |
| `status` | string | Trạng thái của cuộc trò chuyện. Một trong ba giá trị: `active` (đang hoạt động bình thường), `blocked` (một trong hai phía đã chặn phía kia — cuộc trò chuyện chuyển sang chỉ đọc) hoặc `unfriended` (quan hệ bạn bè đã bị hủy — cuộc trò chuyện cũng chuyển sang chỉ đọc). |
| `createdAt` | timestamp | Thời điểm cuộc trò chuyện được tạo. |

Bên cạnh các trường dữ liệu trên, mỗi tài liệu `conversations/{conversationId}` còn có một subcollection chứa nội dung các tin nhắn đã trao đổi:

**Bảng 4.13.** Cấu trúc dữ liệu của một tài liệu trong subcollection `conversations/{conversationId}/messages`.

| Tên trường | Kiểu dữ liệu | Mô tả |
|---|---|---|
| `messageId` | string | Mã định danh duy nhất của tin nhắn. Trùng với mã định danh của tài liệu. |
| `senderId` | string | Mã định danh của người gửi tin nhắn. Tham chiếu tới `users/{uid}`. |
| `text` | string | Nội dung tin nhắn dạng văn bản. Độ dài tối đa năm trăm ký tự. |
| `createdAt` | timestamp | Thời điểm tin nhắn được gửi. Cũng dùng làm tiêu chí sắp xếp tin nhắn trong cuộc trò chuyện. |

Việc tách nội dung tin nhắn ra subcollection (thay vì lưu thẳng vào tài liệu cha dưới dạng mảng) mang lại hai lợi ích quan trọng. Thứ nhất, kích thước của tài liệu cha được giữ ở mức nhỏ — Cloud Firestore áp dụng giới hạn một megabyte cho mỗi tài liệu, do đó việc lưu tin nhắn dưới dạng mảng sẽ nhanh chóng đạt giới hạn này trong các cuộc trò chuyện kéo dài. Thứ hai, cơ chế phân trang tin nhắn (tải dần các tin nhắn cũ khi người dùng cuộn lên) được hiện thực hóa dễ dàng nhờ truy vấn dạng cursor trên subcollection, thay vì phải tải toàn bộ tin nhắn cùng lúc.

---

## 4.11. Collection `diary`

Collection `diary` lưu trữ các bản nhật ký cá nhân do người dùng tạo ra. Khác với các bài đăng trong collection `posts` vốn được thiết kế để chia sẻ tới bạn bè, các bản nhật ký mang tính cá nhân nhiều hơn — mặc định ở chế độ riêng tư và chỉ được chia sẻ ở mức giới hạn (cho bạn bè xem thông qua trang cá nhân) khi người dùng chủ động chuyển sang chế độ công khai.

Cấu trúc của một bản nhật ký phức tạp hơn các thực thể khác trong hệ thống do mỗi bản nhật ký chứa **nhiều khối nội dung** xen kẽ giữa văn bản và hình ảnh. Để hỗ trợ cấu trúc này, hệ thống sử dụng một mảng các đối tượng kiểu `map` để lưu trữ nội dung theo thứ tự.

**Bảng 4.14.** Cấu trúc dữ liệu của một tài liệu trong collection `diary`.

| Tên trường | Kiểu dữ liệu | Mô tả |
|---|---|---|
| `entryId` | string | Mã định danh duy nhất của bản nhật ký. Trùng với mã định danh của tài liệu. |
| `authorUid` | string | Mã định danh của tác giả bản nhật ký. Tham chiếu tới `users/{uid}`. |
| `moodTemplate` | string | Khung tâm trạng được chọn cho ảnh bìa của bản nhật ký. Một trong năm giá trị: `happy` (vui vẻ), `bored` (chán nản), `tired` (mệt mỏi), `shy` (ngại ngùng), `sad` (buồn bã). |
| `coverImageUrl` | string | Đường dẫn ảnh bìa của bản nhật ký trên Cloud Storage. |
| `moodCaption` | string | Tiêu đề ngắn của bản nhật ký, hiển thị trên ảnh bìa. Độ dài tối đa năm mươi ký tự. |
| `content` | array<map> | Mảng các khối nội dung được sắp xếp theo thứ tự. Mỗi phần tử là một đối tượng kiểu `map` mô tả một khối văn bản hoặc một khối hình ảnh. Tối đa hai mươi khối trên một bản nhật ký. |
| `privacy` | string | Chế độ hiển thị của bản nhật ký. Một trong hai giá trị: `private` (chỉ tác giả nhìn thấy — mặc định) hoặc `public` (bạn bè của tác giả cũng có thể xem qua trang cá nhân). |
| `createdAt` | timestamp | Thời điểm bản nhật ký được tạo. |
| `updatedAt` | timestamp | Thời điểm gần nhất bản nhật ký được chỉnh sửa. |

Mỗi phần tử trong mảng `content` là một đối tượng `map` có cấu trúc tùy thuộc vào loại khối, được phân biệt qua trường `runtimeType` đặt sẵn:

**Bảng 4.15.** Cấu trúc của một khối nội dung trong trường `content` của bản nhật ký.

| Loại khối | Trường | Kiểu dữ liệu | Mô tả |
|---|---|---|---|
| Khối văn bản | `runtimeType` | string | Giá trị cố định: `text`. |
| | `value` | string | Nội dung văn bản của khối. |
| | `style` | string | Kiểu định dạng văn bản. Một trong các giá trị: `normal` (văn bản thường), `heading` (tiêu đề), `subheading` (tiêu đề phụ) hoặc `quote` (trích dẫn). |
| Khối hình ảnh | `runtimeType` | string | Giá trị cố định: `image`. |
| | `imageUrl` | string | Đường dẫn tới hình ảnh được chèn trong khối, lưu trên Cloud Storage. |

Cấu trúc lưu trữ này cho phép hệ thống hỗ trợ một bố cục nhật ký linh hoạt — văn bản và hình ảnh có thể xen kẽ tự do — đồng thời vẫn giữ được khả năng truy vấn ở cấp tài liệu mà không cần đến một subcollection riêng cho từng khối. Giới hạn hai mươi khối trên một bản nhật ký được đặt ra nhằm bảo đảm kích thước tài liệu nằm trong giới hạn của Cloud Firestore và tránh các bản nhật ký quá dài làm giảm hiệu năng tải dữ liệu.

---

Đến đây, mười collection chính của hệ thống Meep đã được trình bày đầy đủ. Có thể thấy rằng, mô hình dữ liệu được xây dựng dựa trên ba nguyên tắc chính: **tách biệt các thực thể nghiệp vụ độc lập** thành các collection riêng, **denormalize có chủ đích** đối với những trường được đọc nhiều hơn ghi (`postCount`, `authorName`, `memberIds`, `lastMessage`...), và **sử dụng subcollection** cho những dữ liệu có quan hệ phụ thuộc một-nhiều có khả năng tăng trưởng không giới hạn (notifications, feed, fcmTokens, reactions, messages). Các nguyên tắc này, kết hợp với cơ chế **luật bảo mật (Security Rules)** và các **Cloud Functions** thực thi logic phía máy chủ, tạo nên một mô hình dữ liệu vừa đáp ứng các yêu cầu chức năng đã trình bày trong chương 3, vừa đảm bảo các yêu cầu phi chức năng về bảo mật và hiệu năng đã được nêu ở chương 1.
