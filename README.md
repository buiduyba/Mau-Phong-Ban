# Repo mẫu: vault Obsidian cho phòng ban

Repo mẫu để mỗi phòng ban có một vault Obsidian chạy trên GitHub: mỗi team một nhánh riêng, thay đổi tự gửi lên, tự mở pull request, người phụ trách duyệt rồi merge. Thành viên chỉ cần chạy một script để tải vault về đúng nhánh team của mình.

File README này chỉ là hướng dẫn dùng mẫu. Sau khi khởi tạo, nó được thay bằng README của phòng ban.

## Dành cho người quản lý phòng ban (làm một lần)

1. **Tạo repo từ mẫu.** Trên trang repo mẫu bấm **Use this template** > **Create a new repository**, chọn **Private**, đặt tên repo cho phòng ban của bạn.
2. **Clone repo mới về máy** (cần cài Git, hoặc dùng GitHub Desktop).
3. **Sửa file `CAU-HINH-PHONG-BAN.psd1`**: tên phòng ban, địa chỉ repo, tên thư mục vault, danh sách team.
4. **Chạy `.github/setup/Khoi-Tao-Phong-Ban.ps1`** (bấm chuột phải, chọn **Run with PowerShell**). Script sẽ:
   - tạo thư mục và note cho từng team, tạo note lõi theo tên thư mục vault;
   - tạo `Cai-Dat-Vault.ps1` đã điền sẵn cấu hình, để gửi cho thành viên;
   - tạo `CODEOWNERS` và README của phòng ban;
   - commit, đẩy nhánh `main`, tạo và đẩy các nhánh `Team-...`.
5. **Cài đặt trên GitHub:** bảo vệ nhánh `main`, bật quyền cho GitHub Actions mở pull request, chỉ dùng "Create a merge commit", rồi mời thành viên vào repo.
6. **Gửi file `Cai-Dat-Vault.ps1`** cho thành viên.

## Dành cho thành viên

Bấm chuột phải `Cai-Dat-Vault.ps1`, chọn **Run with PowerShell**, chọn team của bạn, rồi mở thư mục vault trong Obsidian. Chi tiết nằm trong README của phòng ban.

## Trong repo có gì

| Đường dẫn | Việc của nó |
|---|---|
| `CAU-HINH-PHONG-BAN.psd1` | Nơi duy nhất để sửa tên phòng ban, địa chỉ repo, tên thư mục, danh sách team |
| `.github/setup/Khoi-Tao-Phong-Ban.ps1` | Script cho người quản lý, chạy một lần |
| `.github/setup/Cai-Dat-Vault.mau.ps1` | Mẫu của script cài đặt cho thành viên. Không chạy trực tiếp |
| `.github/workflows/auto-pr-team.yml` | Tự mở pull request khi có người đẩy lên nhánh `Team-*` |
| `.github/workflows/sync-main-to-teams.yml` | Khi `main` đổi, tự merge `main` vào mọi nhánh `Team-*` |
| `.github/CODEOWNERS` | Người duyệt pull request |
| `.gitignore` | Chặn file chứa khoá bí mật và cấu hình riêng từng người |
| `.obsidian/` | Cấu hình Obsidian và hai plugin: Obsidian Git (tự lưu và đẩy mỗi 10 phút) và Cosmic Engine (bản đồ 3D của vault) |
| `PHONG BAN.md`, `TEAM A/`, `TEAM B/`, `TEAM C/` | Vault mẫu. Được đổi theo cấu hình khi khởi tạo |

Hai workflow tự tìm các nhánh `Team-*`, nên thêm hoặc bớt team không cần sửa workflow.

## Thêm team sau khi đã dùng

1. Thêm tên team vào `DanhSachTeam` trong `CAU-HINH-PHONG-BAN.psd1`.
2. Chạy lại `Khoi-Tao-Phong-Ban.ps1`. Script bổ sung thư mục và nhánh còn thiếu, tạo lại `Cai-Dat-Vault.ps1`. Script không ghi đè `CODEOWNERS`, `README.md` và note lõi đã có (note lõi chỉ được thêm link team mới).
3. Gửi lại file `Cai-Dat-Vault.ps1` mới cho thành viên.

## Lưu ý

- Plugin Obsidian Git (tác giả Vinzent03) và Cosmic Engine (tác giả Duy) đi kèm trong `.obsidian/plugins` để vault chạy ngay.
- Cosmic Engine lấy tên thư mục vault làm note lõi và tự cập nhật danh sách team trong note lõi, ở đoạn nằm giữa hai dấu `cosmic-map:start` và `cosmic-map:end`. Đừng xoá hai dấu này.
- Cosmic Engine chỉ gọi Anthropic API khi người dùng tự nhập API key trong cài đặt plugin. Key lưu trên máy từng người (`data.json` bị `.gitignore` chặn), nội dung note được gửi tới Anthropic khi dùng tính năng hỏi đáp, và mặc định Claude có thể ghi vào vault. Phòng ban nên thống nhất có dùng tính năng này hay không.
- Khi cài thêm plugin khác, kiểm tra `data.json` của nó có chứa API key hay không trước khi cho phép đưa lên Git (xem `.gitignore`).
- Không đưa API key, mật khẩu hay file lớn vào repo.
