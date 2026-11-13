# Phòng Kế Toán

Vault Obsidian của Phòng Kế Toán. Mỗi team làm trên nhánh riêng, thay đổi được tự gửi lên GitHub và tự mở pull request để người phụ trách duyệt.

## Cài đặt (Windows, một lần)

1. Nhờ người quản lý mời tài khoản GitHub của bạn vào repo này.
2. Lấy file `Cai-Dat-Vault.ps1` (trong thư mục `.github/setup` của repo, hoặc do người quản lý gửi), bấm chuột phải, chọn **Run with PowerShell**, rồi chọn team của bạn.
3. Mở Obsidian, chọn **Open folder as vault**, chọn thư mục `Documents\KE TOAN`, bấm **Trust author and enable plugins**.

Tên thư mục vault phải là `KE TOAN` trên máy mọi người.

## Cách làm việc hằng ngày

- Chỉ sửa trong thư mục của team mình. Viết note như bình thường, không cần thao tác Git.
- Plugin Obsidian Git tự lưu và gửi lên nhánh team mỗi 10 phút, và tự kéo bản mới khi mở vault.
- Khi có thay đổi, GitHub tự mở pull request vào `main`. Người phụ trách duyệt rồi merge bằng **Create a merge commit** (không dùng squash).
- Sau khi `main` cập nhật, bản mới tự được đưa ngược về các nhánh team.

## Quy ước

- Nhánh: `main` (được bảo vệ) và các nhánh team: `Team-Thue`, `Team-Quy`.
- Không đưa API key, mật khẩu hay file lớn (ảnh, PSD, AI) vào repo. Lưu file lớn trên Drive và để link trong note.
- Cấu hình phòng ban nằm trong `CAU-HINH-PHONG-BAN.psd1`.