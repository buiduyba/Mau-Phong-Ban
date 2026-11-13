# Khởi tạo vault cho phòng ban từ repo mẫu. Chạy MỘT LẦN, sau khi đã sửa CAU-HINH-PHONG-BAN.psd1.
# Cách chạy: bấm chuột phải file này > Run with PowerShell.
# Việc script làm: tạo thư mục từng team, tạo Cai-Dat-Vault.ps1 cho thành viên, tạo CODEOWNERS và README,
# rồi commit, đẩy nhánh main và tạo các nhánh Team-* lên GitHub.
# Tham số -ChiTaoFile: chỉ tạo file trên máy, không commit và không đẩy lên GitHub (dùng để xem thử).
param([switch]$ChiTaoFile)

$ErrorActionPreference = 'Continue'
$Goc = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$CoBOM = New-Object System.Text.UTF8Encoding($true)
$KhongBOM = New-Object System.Text.UTF8Encoding($false)

function Dung-Lai {
    param([int]$Ma = 0)
    if (-not $ChiTaoFile) { try { Read-Host 'Nhấn Enter để thoát' | Out-Null } catch { } }
    exit $Ma
}

function Chay-Git {
    & git -C $Goc @args
    if ($LASTEXITCODE -ne 0) { throw ('Lệnh git ' + ($args -join ' ') + ' báo lỗi (mã ' + $LASTEXITCODE + ').') }
}

function Viet-File {
    param([string]$DuongDan, [string]$NoiDung, [bool]$BOM = $false)
    $enc = $KhongBOM
    if ($BOM) { $enc = $CoBOM }
    $thuMuc = Split-Path $DuongDan -Parent
    if (-not (Test-Path -LiteralPath $thuMuc)) { New-Item -ItemType Directory -Path $thuMuc -Force | Out-Null }
    [IO.File]::WriteAllText($DuongDan, $NoiDung, $enc)
}

function Dat-Nhay-Don { param([string]$Chuoi) return $Chuoi.Replace("'", "''") }

try {
    Write-Host ''
    Write-Host '=== Khởi tạo vault phòng ban ===' -ForegroundColor Cyan

    # 1. Đọc và kiểm tra cấu hình
    $FileCauHinh = Join-Path $Goc 'CAU-HINH-PHONG-BAN.psd1'
    if (-not (Test-Path -LiteralPath $FileCauHinh)) { throw "Không thấy file cấu hình: $FileCauHinh" }
    $CH = Import-PowerShellDataFile -Path $FileCauHinh
    $TenPhongBan = ([string]$CH.TenPhongBan).Trim()
    $DiaChiRepo = ([string]$CH.DiaChiRepo).Trim()
    $TenThuMuc = ([string]$CH.TenThuMucVault).Trim()
    $NguoiPhuTrach = ([string]$CH.NguoiPhuTrach).Trim()
    $Teams = @($CH.DanhSachTeam | ForEach-Object { ([string]$_).Trim() })

    $loi = @()
    if (-not $TenPhongBan) { $loi += 'TenPhongBan đang trống.' }
    if (-not $DiaChiRepo -or $DiaChiRepo -like '*ten-cong-ty*') { $loi += 'DiaChiRepo chưa được thay bằng địa chỉ repo thật của phòng ban.' }
    if (-not $TenThuMuc -or $TenThuMuc -match '[\\/:*?"<>|]' -or $TenThuMuc.EndsWith('.')) { $loi += 'TenThuMucVault đang trống hoặc có ký tự không hợp lệ (\ / : * ? " < > | hoặc dấu chấm ở cuối).' }
    if ($Teams.Count -eq 0) { $loi += 'DanhSachTeam đang trống.' }
    foreach ($t in $Teams) {
        if ($t -notmatch '^[A-Za-z0-9][A-Za-z0-9-]*$') { $loi += "Tên team '$t' không hợp lệ: chỉ dùng chữ không dấu, số, dấu gạch ngang, không có khoảng trắng." }
    }
    if (@($Teams | ForEach-Object { $_.ToUpper() } | Select-Object -Unique).Count -ne $Teams.Count) { $loi += 'DanhSachTeam có tên team bị trùng (không phân biệt hoa thường).' }
    if ($loi.Count -gt 0) {
        Write-Host 'Cấu hình chưa đúng, hãy sửa CAU-HINH-PHONG-BAN.psd1 rồi chạy lại:' -ForegroundColor Red
        $loi | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        Dung-Lai 1
    }
    Write-Host "Phòng ban : $TenPhongBan"
    Write-Host "Repo      : $DiaChiRepo"
    Write-Host "Thư mục   : $TenThuMuc"
    Write-Host ('Các team  : ' + (($Teams | ForEach-Object { "Team-$_" }) -join ', '))

    # 2. Tạo Cai-Dat-Vault.ps1 cho thành viên từ file mẫu
    $FileMau = Join-Path $PSScriptRoot 'Cai-Dat-Vault.mau.ps1'
    if (-not (Test-Path -LiteralPath $FileMau)) { throw "Không thấy file mẫu: $FileMau" }
    $noiDung = [IO.File]::ReadAllText($FileMau, [Text.Encoding]::UTF8)
    $mangTeam = '@(' + (($Teams | ForEach-Object { "'" + (Dat-Nhay-Don $_) + "'" }) -join ', ') + ')'
    $noiDung = $noiDung.Replace('{{TEN_PHONG_BAN}}', (Dat-Nhay-Don $TenPhongBan)).Replace('{{DIA_CHI_REPO}}', (Dat-Nhay-Don $DiaChiRepo)).Replace('{{TEN_THU_MUC}}', (Dat-Nhay-Don $TenThuMuc)).Replace('{{DANH_SACH_TEAM}}', $mangTeam)
    Viet-File (Join-Path $PSScriptRoot 'Cai-Dat-Vault.ps1') $noiDung $true
    Write-Host 'Đã tạo .github/setup/Cai-Dat-Vault.ps1 (file gửi cho thành viên).' -ForegroundColor Green

    # 3. Note lõi và thư mục từng team
    # Cặp dấu cosmic-map là chỗ plugin Cosmic Engine tự cập nhật danh sách hành tinh. Thiếu cặp dấu này plugin sẽ bỏ qua note lõi.
    $links = (@($Teams | ForEach-Object { 'TEAM ' + $_.ToUpper() } | Sort-Object) | ForEach-Object { '- [[' + $_ + ']]' }) -join "`n"
    $noteLoi = "---`ntags: [core]`n---`n# $TenThuMuc`n`nLõi của vault $TenPhongBan. Các thư mục bên dưới là các hành tinh quay quanh lõi.`n`n<!-- cosmic-map:start -->`n## Hành tinh`n$links`n<!-- cosmic-map:end -->`n"
    $fileLoi = Join-Path $Goc ($TenThuMuc + '.md')
    $taoLoi = -not (Test-Path -LiteralPath $fileLoi)
    if (-not $taoLoi) {
        $cu = [IO.File]::ReadAllText($fileLoi, [Text.Encoding]::UTF8)
        if ($cu.Contains('Lõi của vault Phòng Ban Mẫu')) { $taoLoi = $true }
    }
    if ($taoLoi) {
        Viet-File $fileLoi $noteLoi
    } else {
        # Note lõi đã có người sửa: không ghi đè. Nếu có cặp dấu cosmic-map thì plugin Cosmic Engine tự cập nhật,
        # nếu không có thì chỉ bổ sung link team còn thiếu.
        if (-not $cu.Contains('<!-- cosmic-map:start -->')) {
            foreach ($t in $Teams) {
                $lk = '[[TEAM ' + $t.ToUpper() + ']]'
                if (-not $cu.Contains($lk)) { $cu = $cu.TrimEnd() + "`n- $lk`n" }
            }
            Viet-File $fileLoi $cu
        }
    }
    $loiCu = Join-Path $Goc 'PHONG BAN.md'
    if (($TenThuMuc -ne 'PHONG BAN') -and (Test-Path -LiteralPath $loiCu)) { Remove-Item -LiteralPath $loiCu -Force }

    # Xoá thư mục team mẫu (A, B, C) nếu không dùng và còn nguyên chưa ai sửa
    foreach ($m in @('A', 'B', 'C')) {
        if ($Teams | Where-Object { $_ -ieq $m }) { continue }
        $thuMucMau = Join-Path $Goc ('TEAM ' + $m)
        if (Test-Path -LiteralPath $thuMucMau) {
            $files = @(Get-ChildItem -LiteralPath $thuMucMau -Recurse -File -Force)
            if ($files.Count -eq 0 -or ($files.Count -eq 1 -and $files[0].Name -eq ('TEAM ' + $m + '.md'))) {
                Remove-Item -LiteralPath $thuMucMau -Recurse -Force
            }
        }
    }

    foreach ($t in $Teams) {
        $ten = 'TEAM ' + $t.ToUpper()
        $fileNote = Join-Path (Join-Path $Goc $ten) ($ten + '.md')
        if (-not (Test-Path -LiteralPath $fileNote)) {
            $note = "---`ntags: [team]`n---`n# $ten`n`nKhu làm việc của Team $t. Chỉ sửa trong thư mục này.`n`nThuộc: [[$TenThuMuc]]`n`n## Danh sách`n- [ ] Việc cần làm | Người phụ trách | Hạn | Trạng thái`n"
            Viet-File $fileNote $note
        }
    }
    Write-Host 'Đã tạo note lõi và thư mục từng team.' -ForegroundColor Green

    # 4. CODEOWNERS
    $co = "# Người phụ trách duyệt pull request. Dòng sau thắng dòng trước.`n# Dấu cách trong đường dẫn phải viết thành `"\ `".`n`n"
    if ($NguoiPhuTrach) {
        $co += "# Mặc định: người phụ trách chung`n*                                   $NguoiPhuTrach`n`n"
    } else {
        $co += "# Mặc định: người phụ trách chung (thay bằng tài khoản GitHub thật, ví dụ @ten-tai-khoan)`n# *                                   @ten-tai-khoan`n`n"
    }
    $co += "# Từng team: thêm người phụ trách riêng nếu cần`n"
    foreach ($t in $Teams) { $co += '# /TEAM\ ' + $t.ToUpper() + '/' + "                           @ten-tai-khoan-github`n" }
    # Chỉ tạo khi còn là bản mẫu, để lần chạy lại không ghi đè phần người quản lý đã sửa
    $fileCO = Join-Path $Goc '.github\CODEOWNERS'
    $taoCO = -not (Test-Path -LiteralPath $fileCO)
    if (-not $taoCO) { $taoCO = [IO.File]::ReadAllText($fileCO, [Text.Encoding]::UTF8).Contains('File này sẽ được tạo lại') }
    if ($taoCO) { Viet-File $fileCO $co }

    # 5. README của phòng ban (thay README hướng dẫn dùng mẫu)
    $dsNhanh = ($Teams | ForEach-Object { '`Team-' + $_ + '`' }) -join ', '
    $readme = @"
# $TenPhongBan

Vault Obsidian của $TenPhongBan. Mỗi team làm trên nhánh riêng, thay đổi được tự gửi lên GitHub và tự mở pull request để người phụ trách duyệt.

## Cài đặt (Windows, một lần)

1. Nhờ người quản lý mời tài khoản GitHub của bạn vào repo này.
2. Lấy file ``Cai-Dat-Vault.ps1`` (trong thư mục ``.github/setup`` của repo, hoặc do người quản lý gửi), bấm chuột phải, chọn **Run with PowerShell**, rồi chọn team của bạn.
3. Mở Obsidian, chọn **Open folder as vault**, chọn thư mục ``Documents\$TenThuMuc``, bấm **Trust author and enable plugins**.

Tên thư mục vault phải là ``$TenThuMuc`` trên máy mọi người.

## Cách làm việc hằng ngày

- Chỉ sửa trong thư mục của team mình. Viết note như bình thường, không cần thao tác Git.
- Plugin Obsidian Git tự lưu và gửi lên nhánh team mỗi 10 phút, và tự kéo bản mới khi mở vault.
- Khi có thay đổi, GitHub tự mở pull request vào ``main``. Người phụ trách duyệt rồi merge bằng **Create a merge commit** (không dùng squash).
- Sau khi ``main`` cập nhật, bản mới tự được đưa ngược về các nhánh team.

## Quy ước

- Nhánh: ``main`` (được bảo vệ) và các nhánh team: $dsNhanh.
- Không đưa API key, mật khẩu hay file lớn (ảnh, PSD, AI) vào repo. Lưu file lớn trên Drive và để link trong note.
- Cấu hình phòng ban nằm trong ``CAU-HINH-PHONG-BAN.psd1``.
"@
    $fileReadme = Join-Path $Goc 'README.md'
    $taoReadme = -not (Test-Path -LiteralPath $fileReadme)
    if (-not $taoReadme) { $taoReadme = [IO.File]::ReadAllText($fileReadme, [Text.Encoding]::UTF8).Contains('Repo mẫu: vault Obsidian cho phòng ban') }
    if ($taoReadme) { Viet-File $fileReadme $readme }
    if ($taoCO -or $taoReadme) {
        Write-Host 'Đã tạo CODEOWNERS và README của phòng ban.' -ForegroundColor Green
    } else {
        Write-Host 'CODEOWNERS và README đã có, giữ nguyên.' -ForegroundColor Yellow
    }

    # 6. Commit, đẩy main, tạo và đẩy các nhánh team
    if ($ChiTaoFile) {
        Write-Host ''
        Write-Host 'Chế độ -ChiTaoFile: đã tạo file, không commit và không đẩy lên GitHub.' -ForegroundColor Yellow
        Dung-Lai 0
    }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Chưa cài Git. Tải tại https://git-scm.com/download/win rồi chạy lại.' }
    if (-not (Test-Path -LiteralPath (Join-Path $Goc '.git'))) { throw 'Thư mục này chưa phải repo Git. Hãy clone repo của phòng ban về rồi chạy lại.' }
    $nhanhHienTai = (& git -C $Goc rev-parse --abbrev-ref HEAD).Trim()
    if ($nhanhHienTai -ne 'main') { throw "Đang ở nhánh '$nhanhHienTai'. Hãy chuyển sang nhánh main (git checkout main) rồi chạy lại." }

    $remotes = @(& git -C $Goc remote)
    if ($remotes -notcontains 'origin') {
        Chay-Git remote add origin $DiaChiRepo
    } else {
        $origin = (& git -C $Goc remote get-url origin).Trim()
        if ($origin -ne $DiaChiRepo) { Write-Host "Lưu ý: origin hiện tại là $origin, khác DiaChiRepo trong cấu hình. Script sẽ đẩy lên origin." -ForegroundColor Yellow }
    }

    $tenGit = (& git -C $Goc config user.name)
    $mailGit = (& git -C $Goc config user.email)
    if (-not $tenGit) { $tenGit = Read-Host 'Nhập họ tên của bạn (hiển thị trên lịch sử thay đổi)'; & git config --global user.name $tenGit }
    if (-not $mailGit) { $mailGit = Read-Host 'Nhập email GitHub của bạn'; & git config --global user.email $mailGit }

    Chay-Git add -A
    & git -C $Goc diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        Chay-Git commit -m "Khởi tạo vault $TenPhongBan"
    } else {
        Write-Host 'Không có thay đổi mới để commit.' -ForegroundColor Yellow
    }
    Write-Host 'Đang đẩy nhánh main lên GitHub. Nếu có cửa sổ đăng nhập GitHub hiện ra, hãy đăng nhập.' -ForegroundColor Cyan
    Chay-Git push -u origin main

    foreach ($t in $Teams) {
        $nhanh = "Team-$t"
        & git -C $Goc show-ref --verify --quiet "refs/heads/$nhanh"
        if ($LASTEXITCODE -ne 0) { Chay-Git branch $nhanh main }
        Chay-Git push -u origin $nhanh
        Write-Host "Đã tạo nhánh $nhanh." -ForegroundColor Green
    }

    Write-Host ''
    Write-Host 'Xong! Các việc còn lại trên GitHub:' -ForegroundColor Green
    Write-Host '  1) Settings > Branches: bảo vệ nhánh main (bắt buộc pull request, cần Code Owner duyệt).'
    Write-Host '  2) Settings > Actions > General: bật "Allow GitHub Actions to create and approve pull requests".'
    Write-Host '  3) Settings > General: chỉ dùng "Create a merge commit" khi merge.'
    Write-Host '  4) Settings > Collaborators: mời thành viên vào repo.'
    Write-Host '  5) Gửi file .github/setup/Cai-Dat-Vault.ps1 cho thành viên để họ cài đặt.'
    Dung-Lai 0
}
catch {
    Write-Host ('Lỗi: ' + $_.Exception.Message) -ForegroundColor Red
    Dung-Lai 1
}
