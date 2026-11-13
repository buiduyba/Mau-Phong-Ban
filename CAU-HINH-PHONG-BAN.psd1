# CẤU HÌNH PHÒNG BAN
# Sửa các giá trị bên dưới, lưu file, rồi chạy .github/setup/Khoi-Tao-Phong-Ban.ps1
# (bấm chuột phải file đó, chọn Run with PowerShell).
@{
    # Tên phòng ban, dùng trong ghi chú và hướng dẫn.
    TenPhongBan    = 'Phòng Ban Mẫu'

    # Địa chỉ repo GitHub của phòng ban (repo tạo từ mẫu, nên để Private).
    DiaChiRepo     = 'https://github.com/ten-cong-ty/Vault_PhongBan.git'

    # Tên thư mục vault trên máy mọi người, nằm trong Documents.
    # Không dùng các ký tự \ / : * ? " < > |
    TenThuMucVault = 'PHONG BAN'

    # Danh sách team. Mỗi team có nhánh Team-<tên> và thư mục TEAM <TÊN IN HOA>.
    # Chỉ dùng chữ không dấu, số và dấu gạch ngang, không có khoảng trắng.
    DanhSachTeam   = @('A', 'B', 'C')

    # (Tuỳ chọn) Tài khoản GitHub của người duyệt chung, ví dụ '@ten-tai-khoan'.
    # Để trống nếu chưa có.
    NguoiPhuTrach  = ''
}
