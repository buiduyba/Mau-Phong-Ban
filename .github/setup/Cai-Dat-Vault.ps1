# FILE MẪU: không chạy trực tiếp file này.
# Khoi-Tao-Phong-Ban.ps1 điền cấu hình vào các chỗ {{...}} rồi tạo ra Cai-Dat-Vault.ps1 để gửi cho thành viên.
#
# Cai-Dat-Vault.ps1: cài Git, tải vault về đúng nhánh team, cấu hình sẵn (Windows).
# Cách chạy: bấm chuột phải file này > Run with PowerShell. Cần có tài khoản GitHub đã được mời vào repo.
# Hai tham số tuỳ chọn dùng khi kiểm thử: -ThuMucDich (thư mục tải về) và -ChonTeam (số thứ tự team).
param([string]$ThuMucDich, [int]$ChonTeam = 0)

$TenPhongBan = 'Phòng Kế Toán'
$Repo = 'C:\Users\bdduy\AppData\Local\Temp\kiemtra-mau-8df61ccd\remote.git'
$TenThuMuc = 'KE TOAN'
$DanhSachTeam = @('Thue', 'Quy')

function Dung-Lai {
    param([int]$Ma = 0)
    if (-not $ThuMucDich) { try { Read-Host 'Nhấn Enter để đóng' | Out-Null } catch { } }
    exit $Ma
}

if ($Repo -like '*{{*') {
    Write-Host 'Đây là file mẫu. Hãy chạy Khoi-Tao-Phong-Ban.ps1 để tạo ra Cai-Dat-Vault.ps1.' -ForegroundColor Red
    Dung-Lai 1
}

# Tên thư mục vault PHẢI giống nhau trên máy mọi người, vì một số plugin dùng tên vault.
if ($ThuMucDich) { $Folder = $ThuMucDich } else { $Folder = Join-Path ([Environment]::GetFolderPath('MyDocuments')) $TenThuMuc }

Write-Host ''
Write-Host "=== Cài đặt vault $TenPhongBan ===" -ForegroundColor Cyan
Write-Host 'Chọn team của bạn:'
for ($i = 0; $i -lt $DanhSachTeam.Count; $i++) {
    Write-Host ('  {0}) {1}' -f ($i + 1), $DanhSachTeam[$i])
}
if ($ChonTeam -ge 1) { $choice = [string]$ChonTeam } else { $choice = Read-Host ('Nhập số từ 1 đến {0}' -f $DanhSachTeam.Count) }
$so = 0
if (-not [int]::TryParse($choice, [ref]$so) -or $so -lt 1 -or $so -gt $DanhSachTeam.Count) {
    Write-Host ('Lựa chọn không hợp lệ. Chạy lại và nhập số từ 1 đến {0}.' -f $DanhSachTeam.Count) -ForegroundColor Red
    Dung-Lai 1
}
$team = $DanhSachTeam[$so - 1]
$branch = "Team-$team"

function Test-Git { [bool](Get-Command git -ErrorAction SilentlyContinue) }

if (-not (Test-Git)) {
    Write-Host 'Chưa có Git. Đang cài Git bằng winget...' -ForegroundColor Yellow
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
        $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
    }
    if (-not (Test-Git)) {
        Write-Host 'Không cài được Git tự động. Hãy tải và cài tại https://git-scm.com/download/win rồi chạy lại file này.' -ForegroundColor Red
        Dung-Lai 1
    }
}

if (Test-Path (Join-Path $Folder '.git')) {
    Write-Host "Vault đã có tại $Folder. Chỉ cập nhật cấu hình." -ForegroundColor Yellow
} else {
    if ((Test-Path $Folder) -and (Get-ChildItem $Folder -Force | Select-Object -First 1)) {
        Write-Host "Thư mục $Folder đã tồn tại và không trống. Đổi tên hoặc xoá nó rồi chạy lại." -ForegroundColor Red
        Dung-Lai 1
    }
    Write-Host "Đang tải vault (nhánh $branch). Nếu có cửa sổ đăng nhập GitHub hiện ra, hãy đăng nhập." -ForegroundColor Cyan
    git clone --branch $branch $Repo $Folder
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Tải vault không thành công. Kiểm tra bạn đã được mời vào repo và đăng nhập đúng tài khoản GitHub.' -ForegroundColor Red
        Dung-Lai 1
    }
}

$name = git config --global user.name
$email = git config --global user.email
if (-not $name) { $name = Read-Host 'Nhập họ tên của bạn (hiển thị trên lịch sử thay đổi)'; git config --global user.name $name }
if (-not $email) { $email = Read-Host 'Nhập email GitHub của bạn'; git config --global user.email $email }

git -C $Folder config pull.rebase false
git -C $Folder config core.quotepath false
git -C $Folder config credential.helper manager

Write-Host ''
Write-Host 'Xong! Các bước còn lại trong Obsidian:' -ForegroundColor Green
Write-Host "  1) Mở Obsidian > Open folder as vault > chọn: $Folder"
Write-Host '  2) Khi hỏi, bấm "Trust author and enable plugins".'
Write-Host '  3) Viết note như bình thường. Thay đổi được tự gửi lên GitHub mỗi 10 phút.'
Dung-Lai 0
