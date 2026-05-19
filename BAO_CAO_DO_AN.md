# BÁO CÁO ĐỒ ÁN: TỔNG QUAN VỀ HỆ THỐNG SUPER APP 

Dưới đây là một số nội dung quan trọng và mẫu văn bản bạn có thể chép / tham khảo trực tiếp để đưa vào cuốn báo cáo đồ án của mình. Các nội dung được tổ chức và trau chuốt bằng văn phong học thuật, chuyên nghiệp.

---

## 1. Giới thiệu đề tài
**Tên đề tài dự kiến:** Xây dựng và Phát triển hệ thống Super App đa dịch vụ trên nền tảng di động (Ride Hailing, Food Delivery, E-Wallet)

**Mục tiêu:**
Đề tài tập trung vào việc nghiên cứu và xây dựng một hệ thống ứng dụng đa chức năng (Super App) cung cấp hệ sinh thái khép kín cho người dùng bao gồm các dịch vụ thiết yếu: di chuyển (Ride), đặt đồ ăn (Food Delivery), đi chợ hộ (Mart), giao hàng tốc hành (Courier) và thanh toán bằng ví điện tử (E-wallet). Hệ thống được thiết kế hướng tới khả năng mở rộng cao, tối ưu hóa trải nghiệm người dùng và phục vụ đồng thời nhiều nhóm đối tượng (Khách hàng, Tài xế, Đối tác/Nhà hàng, Quản trị viên).

---

## 2. Kiến trúc Hệ thống (System Architecture)
Hệ thống được phát triển theo **Kiến trúc Client - Server**, ứng dụng mô hình **Microservices/Service-Oriented** ở mức cơ bản thông qua các đám mây lưu trữ (BaaS – Backend as a Service).

*   **Lớp Client (Mobile & Web App):**
    *   Xây dựng bằng framework **Flutter**, cho phép biên dịch đa nền tảng (iOS, Android, Web) từ cùng một mã nguồn duy nhất.
    *   Áp dụng kiến trúc quản lý trạng thái (State Management) với **Riverpod**, giúp luồng dữ liệu (data flow) hoạt động một cách mượt mà, tối ưu hiệu năng việc render UI và tách biệt hoàn toàn giữa logic xử lý (services) với giao diện (screens).
*   **Lớp Backend & Database (BaaS):**
    *   Hệ thống sử dụng **Supabase / Firebase** làm backend nội sinh, thay vì tự xây dựng máy chủ cục bộ. Điều này giúp tối giản tài nguyên phần cứng, hỗ trợ cập nhật dữ liệu theo thời gian thực (Real-time Database).
    *   Service Xác thực người dùng (Authentication) được quản lý qua token JWT bảo mật cao. 
*   **Lớp Tiện ích & Third-party APIs:**
    *   Tích hợp dịch vụ định vị và bản đồ từ **Goong Maps / OpenStreetMap** hoặc **Google Maps** để tối ưu hóa quãng đường và chi phí.
    *   Tích hợp API Cổng thanh toán (VNPAY / Momo logic stub) phục vụ hệ thống Ví điện tử in-app.

---

## 3. Các Phân hệ và Chức năng Chính
Hệ thống được chia làm 4 module (vai trò) cơ bản, hoạt động logic và tương tác trực tiếp với nhau thông qua CSDL thời gian thực:

### 3.1. Phân hệ Khách hàng (Customer)
*   **Dịch vụ Đặt xe (Ride Hailing):** Cung cấp các loại hình xe đa dạng. Hệ thống tự động tính toán khoảng cách qua API bản đồ và ước tính giá cước.
*   **Dịch vụ Giao nhận đồ ăn / Đi chợ (Food / Mart):** Cho phép tìm kiếm quán ăn, siêu thị; xem thực đơn, xếp đồ vào giỏ hàng và thanh toán. 
*   **Dịch vụ Giao hàng tốc hành (Courier):** Người dùng nhập địa chỉ Đi/Đến với các tùy chọn kiện hàng đa dạng (Tài liệu, Gói nhỏ, Lớn).
*   **Ví điện tử nội bộ (My Wallet):** Hệ thống nạp, rút tiền và thanh toán trực tiếp không cần qua thẻ vật lý. Hỗ trợ tích điểm trung thành (Loyalty Points) và mã khuyến mãi giảm giá. 

### 3.2. Phân hệ Tài xế (Driver)
*   **Trạng thái hoạt động:** Công tắc On/Off chế độ nhận cuốc xe, tự động phát hiện vị trí hiện tại của tài xế để đối chiếu với các đơn hàng gần nhất.
*   **Tiếp nhận Đơn hàng:** Dashboard thời gian thực, cho phép Xác nhận hoăc Từ chối cuốc xe/giao hàng.
*   **Bản đồ định vị:** Cung cấp lộ trình tối ưu từ điểm đón Khách/Quán ăn tới điểm đích.

### 3.3. Phân hệ Thương nhân (Merchant - Quán ăn / Siêu thị)
*   Quản lý Thực đơn / Cửa hàng: Cho phép thêm, sửa, xóa món ăn, chỉnh sửa hình ảnh trực quan đối với từng danh mục sản phẩm.
*   Quản lý Đơn hàng: Cập nhật trạng thái từng đơn (Đang chuẩn bị, Chờ tài xế lấy, Đã giao xong) giúp luồng thông tin minh bạch đối với khách.

### 3.4. Phân hệ Quản trị (Admin Dashboard)
*   **Dashboard Website:** Khác với 3 vai trò trên, Admin được thiết kế dưới dạng Web responsive giúp linh động cho người điều hành.
*   **Thống kê & Giám sát:** Cung cấp các biểu đồ động (Sử dụng `fl_chart`) để vẽ Doanh thu theo tháng, và Tỉ lệ người dùng, đơn hàng.
*   **Quản lý Khuyến mãi:** Tạo mới và giám sát các voucher giảm giá đang phát hành trong ecosystem.

---

## 4. Công nghệ & Ngôn ngữ lập trình (Tech Stack)
*   **Ngôn ngữ lập trình:** Dart (phiên bản `3.10+`).
*   **Framework Frontend:** Flutter.
*   **Backend & DB:** 
    *   **Supabase** (thay thế Firebase để tránh giới hạn về sau đối với RDBMS SQL). Cấu trúc NoSQL/SQL Realtime Database.
*   **Bản đồ & Geocoding:** `flutter_map`, Latlng2, Goong Maps REST APIs.
*   **Thư viện nổi bật khác:** `flutter_riverpod` (quản lý state), `shared_preferences` (cache local dữ liệu người dùng, cấu hình ngôn ngữ/Dark Mode). `image_picker` (quản lý ảnh), `fl_chart` (vẽ đồ thị).

---

## 5. Tổ chức Cơ sở dữ liệu (Database Schema Concepts)
Dữ liệu lưu trữ tập trung vào một số Collections / Tables cốt lõi, liên kết với nhau bằng Document_ID hoặc User_ID:
1.  **Users:** Lưu trữ toàn bộ thông tin đăng nhập, phân quyền Role (Phân loại Admin, Customer, Driver, Merchant). Bao gồm thông tin Ví (Wallet Balance), và Point (Điểm thưởng).
2.  **Orders:** Lưu trữ toàn bộ cuốc xe, đơn đồ ăn, đơn gửi hàng (Pickup, Dropoff, Price, Status).
3.  **Promotions:** Quản lý Voucher (Mã, Tỉ lệ giảm, Giá trị tối đa, Ngày hết hạn).
4.  **Transactions:** Lưu vết mọi thay đổi của Ví và Tiền trong tài khoản giúp tạo báo cáo và chống gian lận.

---

## 6. Khó khăn mắc phải & Giải pháp
Trong cuốn đồ án có phần này để ghi điểm với hội đồng, bạn có thể tham khảo viết như sau:

*   **Khó khăn 1:** Quản lý vòng đời (Lifecycle) và luồng bất đồng bộ (Asynchronous) ở Flutter làm ứng dụng thường xuyên bị treo hoặc rò rỉ bộ nhớ khi load dữ liệu lớn trên Dashboard Admin.
    *   **Giải pháp:** Áp dụng `Ref.watch` bằng Riverpod thay vì setState truyền thống, kết hợp tối ưu Stream, ngắt Stream triệt để bằng cách xử lý `mounted` lifecycle khi thay đổi màn hình.
*   **Khó khăn 2:** Liên kết giữa Auth và Database cũ (Firebase Auth) gây cản trở việc cấp quyền tạo bảng (Row Level Security).
    *   **Giải pháp:** Di chuyển (Migrate) hoàn toàn bộ điều khiển Authenticate sang chung hệ sinh thái Supabase, giúp các thao tác xác thực an toàn và gắn kết CSDL đồng bộ, loại bỏ lỗi "User Not Logged in" khi gọi lệnh Insert.

---

*Lưu ý: Bạn có thể copy nội dung các mục trên đưa vào phần **Chương 1: Giới thiệu**, **Chương 2: Cơ sở Lý thuyết** và **Chương 3: Phân tích Thiết kế Hệ thống** cho cuốn báo cáo Word của mình!*
