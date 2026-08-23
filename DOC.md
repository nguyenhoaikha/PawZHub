# PawZHub v2.1 - Tài Liệu Đầy Đủ

Script hub Roblox với hệ thống xác thực key, gắn HWID, hỗ trợ executor toàn phần, và quản lý qua Discord Bot.

**Phiên bản**: 2.1.0 | **Giấy phép**: MIT

---

## Mục Lục

1. [Bắt Đầu Nhanh](#bắt-đầu-nhanh)
2. [Cách Hoạt Động](#cách-hoạt-động)
3. [Kiến Trúc](#kiến-trúc)
4. [Hệ Thống Key](#hệ-thống-key)
5. [Hệ Thống HWID](#hệ-thống-hwid)
6. [Discord Bot](#discord-bot)
7. [Backend API](#backend-api)
8. [Hỗ Trợ Executor](#hỗ-trợ-executor)
9. [Hệ Thống Giao Diện](#hệ-thống-giao-diện)
10. [Hướng Dẫn Setup](#hướng-dẫn-setup)
11. [Kiếm Tiền](#kiếm-tiền)
12. [Schema Database](#schema-database)
13. [Bảo Mật](#bảo-mật)
14. [Setup Key Miễn Phí](#setup-key-miễn-phí)
15. [Xử Lý Lỗi](#xử-lý-lỗi)

---

## Bắt Đầu Nhanh

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main/loader.lua"))()
```

**Key Thử:**
- Miễn phí: `PAWZ-FREE-2024-DEMO1` (24h)
- Vĩnh viễn: `PAWZ-LIFE-2024-VIP1` (vô thời hạn)

---

## Cách Hoạt Động

### Key Miễn Phí (24h, 1 thiết bị)

```
Người dùng bấm "Get Key"
  -> Hoàn thành Link 1 (Rekonise) - làm nhiệm vụ quảng cáo
  -> Hoàn thành Link 2 (WorkInk) - làm nhiệm vụ quảng cáo
  -> Nhận key PAWZ-XXXX-XXXX-XXXX (24h)
  -> Dán key vào và gửi
```

### Key Vĩnh Viễn (Vô thời hạn, có thể reset HWID)

```
1. Mua mã license từ người bán
2. Tham gia server Discord
3. Dùng /redeem <code> (ví dụ: /redeem a12e137e)
4. Nhận key vĩnh viễn qua DM (ví dụ: f03d3260914a9475faf29b12)
5. Dùng key trong executor
6. HWID bị lỗi? Dùng /resetkey <key> (cooldown 7 ngày)
```

### Định Dạng Key

| Loại | Định Dạng | Ví Dụ | Thời Hạn |
|------|-----------|-------|----------|
| Miễn phí | `PAWZ-XXXX-XXXX-XXXX` | `PAWZ-A1B2-C3D4-E5F6` | 24 giờ |
| Vĩnh viễn | 24 ký tự hex | `f03d3260914a9475faf29b12` | Vô thời hạn |

---

## Kiến Trúc

### Cấu Trúc Thư Mục

```
PawZHub/
  loader.lua              Điểm vào, phát hiện game
  checkkey.lua            Hệ thống xác thực, giao diện macOS

  script/                 Script theo game
    PawZHubBF.lua         Blox Fruits
    PawZHubGG.lua         Gunfight Arena

  backend/                Server REST API
    server.js             Express + MongoDB
    .env.example          Mẫu cấu hình

  discord-bot/            Discord Bot (slash commands)
    bot.js                Logic bot
    deploy-commands.js    Đăng ký lệnh với Discord API
    .env.example          Mẫu cấu hình
```

### Lưu Lượng Thực Thi

```
loader.lua
  Phát hiện executor (PC/iOS/Android)
  Phát hiện game (PlaceId)
  Tải checkkey.lua
  Hiển thị giao diện key

checkkey.lua
  Người dùng nhập key
  Phát hiện loại key (miễn phí hoặc vĩnh viễn)
  POST /api/verify với key + HWID
  Tạo session khi thành công
  Tải script game
```

### Phát Hiện Loại Key

| Đầu Vào | Loại | Độ Dài |
|---------|------|--------|
| `PAWZ-XXXX-XXXX-XXXX` | Miễn phí | 19 ký tự |
| 24 ký tự hex | Vĩnh viễn | 24 ký tự |

---

## Hệ Thống Key

### Key Miễn Phí

**Lưu:**
```
Người dùng bấm "Get Key"
  Sao chép Link 1 URL (Rekonise)
  Người dùng hoàn thành nhiệm vụ quảng cáo
  Sao chép Link 2 URL (WorkInk)
  Người dùng hoàn thành nhiệm vụ quảng cáo
  Dán key PAWZ vào giao diện
  Gửi -> POST /api/verify
```

**Tính Năng:**
- Định dạng: `PAWZ-XXXX-XXXX-XXXX`
- Thời hạn: 24 giờ
- Thiết bị: 1 (gắn HWID)
- Lượt sử dụng: Không giới hạn trong 24h
- Reset HWID: Không hỗ trợ

### Key Vĩnh Viễn

**Lưu:**
```
Người dùng mua mã license (8 ký tự hex, ví dụ: a12e137e)
Người dùng tham gia server Discord
Người dùng chạy /redeem a12e137e
Bot tạo key vĩnh viễn (24 ký tự hex)
Bot gửi key qua DM
Người dùng nhập key trong executor
```

**Tính Năng:**
- Định dạng: 24 ký tự hex
- Thời hạn: Vô thời hạn
- Thiết bị: Không giới hạn (có thể reset HWID)
- Reset HWID: Mỗi 7 ngày qua Discord hoặc API

---

## Hệ Thống HWID

### Cách Hoạt Động

```
1. Người dùng nhập key
2. Client tạo HWID từ thông tin thiết bị
3. Server nhận key + HWID
4. Lần đầu dùng: Server gắn HWID với key
5. Các lần sau: Server kiểm tra HWID khớp
6. Không khớp: Từ chối truy cập
```

### Tạo HWID (Lua)

Các thành phần được kết hợp và băm (FNV-1a):
1. Roblox Client ID (ổn định nhất)
2. User ID + Tuổi tài khoản
3. Nền tảng (PC/Mobile/Console)

Đầu ra: Chuỗi hex 16 ký tự

```lua
local function getHWID()
    local components = {}
    pcall(function()
        local clientId = game:GetService("RbxAnalyticsService"):GetClientId()
        if clientId ~= "" then table.insert(components, clientId) end
    end)
    local player = game:GetService("Players").LocalPlayer
    table.insert(components, string.format("%d:%d", player.UserId, player.AccountAge))
    local UIS = game:GetService("UserInputService")
    table.insert(components, UIS.TouchEnabled and "mobile" or "pc")
    local combined = table.concat(components, "|")
    local h = 2166136261
    for i = 1, #combined do
        h = bit32.bxor(h, string.byte(combined, i))
        h = (h * 16777619) % 4294967296
    end
    return string.format("%08X%08X", h1, h2)
end
```

### Gắn HWID

**Quan trọng: Mỗi key chỉ dùng được trên 1 thiết bị tại 1 thời điểm.**

**Key miễn phí:** Gắn 1 HWID duy nhất, không reset được. Muốn dùng thiết bị khác phải lấy key mới.

**Key vĩnh viễn:** Gắn 1 HWID duy nhất. Muốn chuyển thiết bị phải reset HWID (cooldown 7 ngày).

### Reset HWID

**Qua Discord:** `/resetkey f03d3260914a9475faf29b12`

**Qua API:**
```
POST /api/hwid-reset
{
    "key": "f03d3260914a9475faf29b12",
    "hwid": "CHUOI_HWID_MOI"
}
```

**Qua Giao Diện Executor:** Nút "Reset HWID" xuất hiện khi nhập key vĩnh viễn

**Lưu ý:** Reset sẽ xóa HWID cũ, cho phép gắn key với thiết bị mới. Sau khi reset, lần dùng tiếp theo sẽ tự động gắn key với thiết bị mới.

**Cooldown:** 7 ngày giữa các lần reset

---

## Discord Bot

### Cài Đặt

```bash
cd discord-bot
npm install
cp .env.example .env
# Sửa .env: DISCORD_BOT_TOKEN, CLIENT_ID, MONGODB_URI
node deploy-commands.js  # Đăng ký slash commands (chỉ chạy 1 lần)
node bot.js
```

### Biến Môi Trường

```env
DISCORD_BOT_TOKEN=token_bot_cua_ban
CLIENT_ID=application_id_cua_ban
MONGODB_URI=mongodb://localhost:27017/pawzhub
ADMIN_ROLE_IDS=                    # phẩy cách nhau, để trống để tự động theo tên
DISCORD_WEBHOOK_URL=               # tùy chọn, để ghi log
```

### Lệnh Người Dùng

| Lệnh | Mô Tả |
|------|-------|
| `/redeem <code>` | Đổi mã license lấy key vĩnh viễn |
| `/mykeys` | Xem các key vĩnh viễn của bạn |
| `/resetkey <key>` | Reset HWID (cooldown 7 ngày) |
| `/freekey [hwid]` | Tạo key miễn phí 24h |
| `/help` | Hiển thị hướng dẫn |

### Lệnh Admin

| Lệnh | Mô Tả |
|------|-------|
| `/admin gen <count>` | Tạo 1-100 mã license |
| `/admin list [filter]` | Liệt kê licenses (tất cả/chưa dùng/đã dùng) |
| `/admin check <input>` | Kiểm tra license (8 ký tự) hoặc key (24 ký tự) |
| `/admin ban <key>` | Cấm key vĩnh viễn |
| `/admin unban <key>` | Bỏ cấm key |
| `/admin blacklist <userid>` | Cấm người dùng lấy key miễn phí |
| `/admin unblacklist <userid>` | Bỏ cấm người dùng |
| `/admin stats` | Thống kê hệ thống |

### Lưu Đổi License

```
1. Người dùng mua mã license (8 ký tự hex, ví dụ: a12e137e)
2. Người dùng chạy /redeem a12e137e trong Discord
3. Bot kiểm tra code chưa được dùng
4. Bot tạo key vĩnh viễn (24 ký tự hex)
5. Bot tạo LifetimeKey trong MongoDB
6. Bot đánh dấu License là "đã đổi"
7. Bot gửi key vĩnh viễn qua DM
8. Người dùng nhập key trong executor
```

### Tạo License (Admin)

```
/admin gen 10
  -> Tạo 10 mã 8 ký tự hex duy nhất
  -> Mã được lưu vào MongoDB với trạng thái "chưa dùng"
  -> Mã được hiển thị trong Discord để copy/paste
  -> Bán các mã này cho người dùng
```

---

## Backend API

### Cài Đặt

```bash
cd backend
npm install
cp .env.example .env
# Sửa .env: MONGODB_URI, ADMIN_TOKEN
node server.js
```

### Biến Môi Trường

```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/pawzhub
ADMIN_TOKEN=doi_thanh_token_bimat
DISCORD_WEBHOOK_URL=               # tùy chọn
```

### Endpoint Công Khai

| Phương Thức | Endpoint | Mô Tả |
|-------------|----------|-------|
| GET | `/` | Kiểm tra trạng thái |
| POST | `/api/verify` | Xác thực key (miễn phí + vĩnh viễn) |
| GET | `/api/getkey?user=&hwid=` | Tạo key miễn phí |
| POST | `/api/hwid-reset` | Reset HWID (key vĩnh viễn) |
| GET | `/api/blacklist` | Lấy danh sách bị cấm |
| GET | `/api/version` | Kiểm tra phiên bản |

### Endpoint Admin

Tất cả endpoint admin yêu cầu: `Authorization: Bearer <ADMIN_TOKEN>`

| Phương Thức | Endpoint | Mô Tả |
|-------------|----------|-------|
| GET | `/admin/keys` | Liệt kê key miễn phí |
| GET | `/admin/lifetime-keys` | Liệt kê key vĩnh viễn |
| GET | `/admin/licenses` | Liệt kê licenses |
| POST | `/admin/ban` | Cấm một key |
| POST | `/admin/blacklist` | Thêm vào danh sách cấm |
| GET | `/admin/stats` | Thống kê hệ thống |

### Xác Thực Key

```
POST /api/verify
Content-Type: application/json

{
    "key": "PAWZ-A1B2-C3D4-E5F6",
    "hwid": "ABC123DEF456",
    "userId": "123456789",
    "username": "TênNgườiChơi",
    "gameId": "2753915549"
}
```

**Phản Hồi Key Miễn Phí:**
```json
{
    "valid": true,
    "message": "Key đã được xác thực",
    "tier": "free",
    "features": ["basic"],
    "expiry": "2024-12-25T12:00:00Z"
}
```

**Phản Hồi Key Vĩnh Viễn:**
```json
{
    "valid": true,
    "message": "Key vĩnh viễn đã được xác thực",
    "tier": "lifetime",
    "features": ["basic", "advanced", "premium", "exclusive"],
    "expiry": null,
    "hwidResetAvailable": true
}
```

**Tin Nhắn Lỗi:**
- `Key không hợp lệ` - Không tìm thấy key
- `Key đã hết hạn` - Key miễn phí quá 24h
- `Key đã bị cấm` - Admin đã cấm key
- `Key đã gắn vào thiết bị khác` - HWID không khớp (key miễn phí)
- `HWID không khớp. Dùng /resetkey trong Discord để reset.` - HWID không khớp (key vĩnh viễn)

### Tạo Key Miễn Phí

```
GET /api/getkey?user={userId}&hwid={hwid}
```

Phản hồi:
```json
{
    "success": true,
    "key": "PAWZ-A1B2-C3D4-E5F6",
    "message": "Key đã được tạo thành công",
    "expiresAt": "2024-12-25T12:00:00Z"
}
```

### Reset HWID

```
POST /api/hwid-reset
Content-Type: application/json

{
    "key": "f03d3260914a9475faf29b12",
    "hwid": "CHUOI_HWID_MOI"
}
```

Phản hồi:
```json
{
    "success": true,
    "message": "Reset HWID thành công",
    "nextResetAvailable": "2024-12-30T00:00:00Z",
    "newHWID": "CHUOI_HWID_MOI"
}
```

### Tích Hợp Lua

```lua
local HttpService = game:GetService("HttpService")
local player = game:GetService("Players").LocalPlayer

local response = HttpService:PostAsync(
    "https://api-cua-ban.com/api/verify",
    HttpService:JSONEncode({
        key = "PAWZ-A1B2-C3D4-E5F6",
        hwid = getHWID(),
        userId = player.UserId,
        gameId = game.PlaceId
    }),
    Enum.HttpContentType.ApplicationJson
)

local data = HttpService:JSONDecode(response)
if data.valid then
    print("Key hợp lệ:", data.tier)
else
    print("Lỗi:", data.message)
end
```

### Giới Hạn Tốc Độ

- 20 yêu cầu mỗi 15 phút mỗi IP
- 3 lần thất bại -> khóa
- Reset HWID: cooldown 7 ngày mỗi key

---

## Hỗ Trợ Executor

### Executor PC

| Executor | Trạng Thái |
|----------|------------|
| Synapse X | Hỗ trợ đầy đủ |
| Script-Ware | Hỗ trợ đầy đủ |
| KRNL | Hỗ trợ đầy đủ |
| Fluxus | Hỗ trợ đầy đủ |
| Oxygen U | Hỗ trợ đầy đủ |
| Solara | Hỗ trợ đầy đủ |
| Electron | Hỗ trợ đầy đủ |
| Evon | Hỗ trợ đầy đủ |
| Trigon | Hỗ trợ đầy đủ |
| Wave | Hỗ trợ đầy đủ |
| Nezur | Hỗ trợ đầy đủ |
| Arceus X Neo | Hỗ trợ đầy đủ |
| JJSploit | Hạn chế |

**Phát hiện:** Kiểm tra `syn`, `KRNL_LOADED`, `identifyexecutor`, và các biến khác.

### Executor iOS

| Executor | Trạng Thái |
|----------|------------|
| Delta | Hỗ trợ đầy đủ |
| Flux | Hỗ trợ đầy đủ |
| Arceus X | Hỗ trợ đầy đủ |
| Zeus | Hỗ trợ đầy đủ |
| EonHub | Hỗ trợ đầy đủ |
| Appletouchhook | Hỗ trợ đầy đủ |
| SideStore | Hỗ trợ đầy đủ |

**Phát hiện:** Kiểm tra `APPLETOUCHHOOK_LOADED`, `FLUX_LOADED`

### Executor Android

| Executor | Trạng Thái |
|----------|------------|
| Arceus X | Hỗ trợ đầy đủ |
| Hydrogen | Hỗ trợ đầy đủ |
| Fluxus Android | Hỗ trợ đầy đủ |
| CodeX | Hỗ trợ đầy đủ |
| Valyse | Hỗ trợ đầy đủ |

**Phát hiện:** Kiểm tra `Arceus`, `hydrogen`

### Tự Động Phát Hiện

```lua
-- Phát hiện tự động trong loader.lua
_G.PawZHub_Executor = {
    name = "Tên đã phát hiện",
    platform = "PC" | "iOS" | "Android" | "Mobile"
}
```

Nếu không phát hiện được, hiển thị "Unknown Executor" - vẫn hoạt động bình thường.

---

## Hệ Thống Giao Diện

### Thiết Kế Kiểu macOS

- Nền kính mờ
- Điều khiển cửa sổ hình đèn giao (đỏ, vàng, xanh lá)
- Kéo thả cửa sổ (chỉ thanh tiêu đề)
- Hoạt động mượt (TweenService)
- Hiệu ứng khi focus (vòng xanh ở input)
- Hoạt động rung khi có lỗi

### Bố Cục Responsive

- **PC**: Cửa sổ 420x240px
- **Mobile**: Cửa sổ 340x320px (cao hơn để chạm)

### Tính Năng Giao Diện Key

- Nút "Get Key" với hệ thống 2 bước link
- Nút "Submit" với loading spinner
- Nút "Reset HWID" (xuất hiện cho key vĩnh viễn)
- Tin nhắn trạng thái với màu sắc
- Phát hiện loại key (miễn phí vs vĩnh viễn)

---

## Hướng Dẫn Setup

### Yêu Cầu

- Node.js 16+
- MongoDB (Atlas miễn phí hoặc cài đặt cục bộ)
- Token bot Discord (từ discord.com/developers)
- Tài khoản Linkvertise (cho key miễn phí)

### Backend

```bash
cd backend
npm install
cp .env.example .env
# Sửa .env: MONGODB_URI, ADMIN_TOKEN, DISCORD_WEBHOOK_URL
node server.js
```

### Discord Bot

```bash
cd discord-bot
npm install
cp .env.example .env
# Sửa .env: DISCORD_BOT_TOKEN, CLIENT_ID, MONGODB_URI
node deploy-commands.js  # Đăng ký lệnh (chỉ chạy 1 lần)
node bot.js
```

### Tạo Bot Discord

1. Vào https://discord.com/developers/applications
2. Bấm "New Application" -> Tên: "PawZHub Bot"
3. Vào tab "Bot" -> Bấm "Add Bot"
4. Copy Bot Token
5. Bật "Message Content Intent" và "Server Members Intent"
6. Vào "OAuth2" -> "URL Generator"
7. Chọn Scopes: `bot`, `applications.commands`
8. Chọn Permissions: Send Messages, Read Messages, Embed Links
9. Copy URL -> Mở trong trình duyệt -> Mời vào server

### Thêm Game

Sửa `loader.lua`, thêm vào `SUPPORTED_GAMES`:

```lua
[PLACE_ID_CUA_BAN] = {
    name = "Tên Game",
    script = "ScriptCuaBan.lua",
    displayName = "Tên Game"
}
```

Tạo `script/ScriptCuaBan.lua` với logic game của bạn.

---

## Kiếm Tiền

### Key Miễn Phí

**Phương Pháp: Hệ Thống 2 Link**

**Dịch Vụ:**
1. Rekonise - Nền tảng quảng cáo kiểu Linkvertise
2. WorkInk - Rút gọn liên kết với nhiệm vụ

**Lưu:**
```
Người dùng bấm "Get Key"
  -> Sao chép Link 1 (Rekonise) -> Làm nhiệm vụ (20-30s)
  -> Sao chép Link 2 (WorkInk) -> Làm nhiệm vụ (20-30s)
  -> Nhận key PAWZ (24h)
```

**Doanh Thu:**
- CPM: $3-7 mỗi 1000 lượt xem
- 100 key/ngày: ~$75/tháng
- 500 key/ngày: ~$375/tháng

### Key Vĩnh Viễn

**Phương Pháp: Mã License + Discord Bot**

**Lưu:**
```
1. Người dùng mua mã license từ người bán
2. Người dùng tham gia server Discord
3. Người dùng chạy: /redeem a12e137e
4. Bot tạo key vĩnh viễn (24 ký tự hex)
5. Bot gửi key qua DM
6. Người dùng nhập key trong executor
```

**Mã License:**
- 8 ký tự hex (ví dụ: `a12e137e`)
- Chỉ dùng 1 lần
- Độc quyền cho 1 tài khoản Discord

**Key Vĩnh Viễn:**
- 24 ký tự hex (ví dụ: `f03d3260914a9475faf29b12`)
- Vô thời hạn
- Có thể reset HWID mỗi 7 ngày

**Doanh Thu:**
- Giá: $5-20 mỗi license
- 20 bán/tháng: ~$200/tháng
- 50 bán/tháng: ~$500/tháng

**Sàn Bán:**
- Shoppy.gg
- Sellix.io
- PayPal (thủ công)
- Discord (thủ công)

### Dự Đoán Doanh Thu Tổng

| Thời Gian | Key Miễn Phí | Bán Key Vĩnh Viễn | Tổng |
|-----------|--------------|-------------------|------|
| Tháng 1-3 | $75/tháng | $200/tháng | **$275/tháng** |
| Tháng 4-6 | $375/tháng | $400/tháng | **$775/tháng** |
| Tháng 6+ | $750/tháng | $500/tháng | **$1250/tháng** |

---

## Schema Database

### License (8 ký tự hex)

```javascript
{
    code: "a12e137e",                    // duy nhất, chữ thường
    status: "chưa_dùng",                 // "chưa_dùng" | "đã_dùng"
    redeemedBy: null,                    // Discord ID (sau khi đổi)
    redeemedAt: null,                    // Ngày (sau khi đổi)
    redeemedTag: null,                   // User#0000
    generatedKey: null,                  // Key vĩnh viễn (sau khi đổi)
    createdAt: Date
}
```

### LifetimeKey (24 ký tự hex)

```javascript
{
    key: "f03d3260914a9475faf29b12",     // duy nhất, chữ thường
    licenseCode: "a12e137e",             // tham chiếu đến license
    discordId: "123456789",              // Discord ID chủ sở hữu
    discordTag: "User#0000",
    boundHWIDs: ["ABC123DEF456"],        // mảng các HWID đã gắn
    lastHWIDReset: Date,
    nextResetAvailable: Date,            // ngày cho phép reset tiếp
    totalUses: 42,
    lastUsed: Date,
    status: "hoạt_động",                 // "hoạt_động" | "bị_cấm"
    createdAt: Date
}
```

### FreeKey (PAWZ-XXXX-XXXX-XXXX)

```javascript
{
    key: "PAWZ-A1B2-C3D4-E5F6",         // duy nhất
    userId: "123456789",
    hwid: "ABC123DEF456",               // 1 HWID duy nhất
    tier: "miễn_phí",
    features: ["basic"],
    expiresAt: Date,                     // + 24 giờ
    uses: 0,
    maxUses: -1,
    status: "hoạt_động",                 // "hoạt_động" | "hết_hạn" | "bị_cấm"
    source: "linkvertise" | "discord",
    createdAt: Date
}
```

### Blacklist (Danh Sách Cấm)

```javascript
{
    userId: "123456789",
    reason: "Chia sẻ key",
    addedAt: Date
}
```

---

## Bảo Mật

- **Giới hạn tốc độ**: 20 yêu cầu mỗi 15 phút mỗi IP
- **Khóa tài khoản**: 3 lần thất bại
- **Danh sách cấm**: Cấm người dùng lấy key miễn phí
- **Gắn HWID**: Ngăn chặn chia sẻ key
- **Ghi log Webhook**: Thông báo sự kiện key qua Discord
- **Xác thực Admin**: Bearer token cho API admin
- **Tính độc quyền**: Mã 8 ký tự hex là duy nhất

---

## Setup Key Miễn Phí

### Bước 1: Tạo Tài Khoản

**Link 1: Rekonise**
- Website: https://rekonise.com
- Đăng ký tài khoản publisher
- Tạo campaign

**Link 2: WorkInk**
- Website: https://work.ink
- Đăng ký tài khoản publisher
- Tạo link rút gọn

### Bước 2: Cấu Hình URL Chuyển Hướng

Đặt URL chuyển hướng thành:
```
https://ten-mien-cua-ban.com/api/getkey?user=USER_ID
```

### Bước 3: Sửa checkkey.lua

Sửa bảng `links` trong `checkkey.lua`:

```lua
local links = {
    {
        name = "Link 1",
        url = string.format("https://rekonise.com/CAMPAIGN_CUA_BAN/%s", userId),
    },
    {
        name = "Link 2",
        url = string.format("https://work.ink/LINK_CUA_BAN/%s", userId),
    },
}
```

### Bước 4: Thử Lưu Lượng

1. Bấm "Get Key" trong executor
2. Hoàn thành nhiệm vụ Link 1
3. Hoàn thành nhiệm vụ Link 2
4. Nhận key PAWZ-XXXX-XXXX-XXXX
5. Dán key vào và gửi
6. Key được xác thực, script tải lên

---

## Game Hỗ Trợ

| Game | Place ID | Trạng Thái |
|------|----------|------------|
| Blox Fruits | 2753915549 | Đang hoạt động |
| Gunfight Arena | 4866604015 | Đang hoạt động |

Thêm game của bạn trong `loader.lua` tại `SUPPORTED_GAMES`.

---

## Công Nghệ

- **Lua** - Scripting Roblox
- **Node.js + Express** - Backend API
- **MongoDB** - Cơ sở dữ liệu
- **Discord.js v14** - Bot với slash commands

---

## Xử Lý Lỗi

### Bot Không Phản Hồi
- Kiểm tra bot đang online trong Discord
- Bật "Message Content Intent" trong Discord Developer Portal
- Kiểm tra kết nối MongoDB
- Kiểm tra console để xem lỗi

### Không Đổi Được License
- Kiểm tra định dạng (8 ký tự hex, chữ thường)
- Đảm bảo license chưa được đổi
- Kiểm tra bạn có sở hữu key không (discordId phải khớp)

### Không Reset Được HWID
- Chờ 7 ngày từ lần reset cuối
- Đảm bảo bạn sở hữu key
- Kiểm tra định dạng key (24 ký tự hex)

### HWID Key Không Khớp
- Key miễn phí: Không reset được, cần key mới
- Key vĩnh viễn: Dùng `/resetkey <key>` trong Discord

### API Không Hoạt Động
- Kiểm tra kết nối MongoDB
- Kiểm tra biến môi trường
- Kiểm tra giới hạn tốc độ (20 yêu cầu/15 phút)

---

**PawZHub v2.1**
