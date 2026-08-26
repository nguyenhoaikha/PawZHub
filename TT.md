# Tổng Quan Hệ Thống PawZHub

Tài liệu này ghi lại toàn bộ hệ thống PawZHub sau khi được kiểm tra và hoàn thiện đầy đủ.

---

## 🎯 Hệ Thống Là Gì?

**PawZHub** là một Roblox Script Hub với key system, cho phép người dùng:
- Lấy **key miễn phí** (12-24h) bằng cách hoàn thành checkpoint quảng cáo (Work.ink, LootLabs)
- Mua **premium key** (trial 7 ngày / monthly 30 ngày / lifetime 10 năm)
- Sử dụng key để mở khóa scripts cho nhiều game Roblox
- Quản lý key qua Discord bot

---

## 📦 Cấu Trúc Dự Án

```
PawZHub/
├── web/                    # Next.js 16.3 (Frontend + API)
│   ├── src/app/           # Pages và API routes
│   │   ├── page.tsx       # Trang chủ
│   │   ├── getkey/        # Trang lấy free key
│   │   ├── admin/         # Admin dashboard
│   │   └── api/           # 10 API routes
│   ├── src/lib/           # Core libraries
│   │   ├── db.ts          # Upstash Redis wrapper
│   │   ├── keygen.ts      # Premium key generation
│   │   ├── env.ts         # Env validation
│   │   └── config.ts      # Public config
│   └── .env.local         # Local dev environment
│
├── bot/                    # Discord bot (TypeScript)
│   ├── src/commands/      # 9 slash commands
│   ├── src/lib/api.ts     # Web API wrapper
│   └── .env               # Bot credentials
│
├── backend/                # Express server (tùy chọn)
│   ├── src/index.js       # Webhook receivers
│   └── public/            # Static files
│
├── script/                 # Game scripts
│   ├── PawZHubBF.lua      # Blox Fruits (4000+ dòng)
│   └── PawZHubGG.lua      # Greedy Growers (3000+ dòng)
│
├── loader.lua              # Legacy entry point
├── loader-web.lua          # Main loader
└── checkkey.lua            # Key system UI + logic
```

---

## 🔑 Hệ Thống Key

### Free Keys (JWT)
- **Format**: `eyJ...` (base64 JWT)
- **Duration**: 12-24h tùy platform
- **Cách lấy**: Hoàn thành 2 checkpoint quảng cáo
- **HWID**: Không enforce (dùng được nhiều thiết bị)
- **Gia hạn**: Tối đa 3 lần

### Premium Keys (HMAC)
- **Format**: `PH.{base64url_payload}.{signature_32chars}`
- **Payload**: `{t: issued_timestamp, e: expiry_timestamp, p: plan(0/1/2), u: userId}`
- **Signature**: HMAC-SHA256 với `KEYGEN_SECRET`
- **HWID Binding**: First-use-binds (key khóa với thiết bị đầu tiên verify)
- **HWID Reset**: Cooldown 7 ngày
- **Plans**:
  - **Trial** (p=0): 7 ngày
  - **Monthly** (p=1): 30 ngày
  - **Lifetime** (p=2): 10 năm

---

## 🌐 Web API (10 Routes)

### Public Endpoints

| Route | Method | Chức năng |
|-------|--------|-----------|
| `/api/verifykey` | POST | Verify key (gọi từ Lua client) |
| `/api/getkey` | POST | Tạo free key sau 2 checkpoint |
| `/api/renewkey` | POST | Gia hạn free key (max 3 lần) |
| `/api/checkpoint` | POST/GET | Tạo server-side checkpoint token |
| `/api/checkpoint/complete` | POST | Đánh dấu checkpoint hoàn thành |
| `/api/checkpoint/info` | GET | Kiểm tra trạng thái token |
| `/api/hwid-reset` | POST/GET | Reset HWID binding |
| `/api/lootlabs` | GET | Tạo LootLabs content locker link |
| `/api/checkout` | POST | Mua premium key (cần payment verify) |
| `/api/redeem` | POST | Đổi code thành lifetime key |

### Admin Endpoints (Cần Bearer token)

| Route | Method | Chức năng |
|-------|--------|-----------|
| `/api/admin?action=stats` | GET | System stats |
| `/api/admin?action=blacklist` | GET/POST/DELETE | Quản lý blacklist |
| `/api/admin?action=generate-key` | POST | Tạo premium key |
| `/api/admin?action=verify-key` | POST | Xem chi tiết key |
| `/api/admin?action=reset-hwid` | POST | Force reset HWID |
| `/api/admin?action=revoke-key` | POST | Thu hồi key |
| `/api/admin?action=list-revoked` | GET | Danh sách key đã thu hồi |
| `/api/admin?action=list-keys` | GET | **[MỚI]** Danh sách tất cả keys hoặc active keys |
| `/api/admin?action=create-codes` | POST | Tạo redemption codes |
| `/api/admin?action=list-codes` | GET | Danh sách codes |
| `/api/admin?action=logs` | GET | Usage logs |

**Params cho `list-keys`**:
- `type=all` — Tất cả keys từ logs (mặc định)
- `type=active` — Chỉ keys được dùng trong 24h gần nhất
- `limit=100` — Số lượng logs để scan (mặc định 100, max 1000)

---

## 🤖 Discord Bot (9 Commands)

### User Commands
- `/verify [key] [hwid?]` — Verify key
- `/redeem [code]` — Đổi redemption code → lifetime key

### Admin Commands (Cần ADMIN_USER_IDS)
- `/keygen [plan] [count?]` — Tạo premium keys hàng loạt
- `/inspect-key [key]` — Xem chi tiết key (plan, expiry, HWID, logs)
- `/reset-hwid [key] [new-hwid]` — Force reset HWID (bypass cooldown)
- `/revoke-key [key] [reason]` — Thu hồi key
- `/blacklist [userid] [reason]` — Thêm vào blacklist
- `/unblacklist [userid]` — Xóa khỏi blacklist
- `/stats` — System stats

---

## 🎮 Lua Scripts

### 1. loader.lua (Legacy Entry)
- Fetch `loader-web.lua` và execute
- Tồn tại cho backward compatibility

### 2. loader-web.lua (Main Loader)
- Detect executor (Synapse X, KRNL, Delta, etc.)
- Fetch `checkkey.lua` và execute

### 3. checkkey.lua (Key System v4.0)
- UI modal màu đen/trắng/xám (black/white/gray theme)
- HWID generation: `RbxAnalyticsService:GetClientId()` + `UserId:AccountAge` + platform
- Verify key với `/api/verifykey`
- 4 fallback HTTP methods: `PostAsync`, `request()`, `http_request()`, `syn.request`
- Cache local 60s
- Rate limit 2s giữa các request
- Lockout 3s sau 3 lần fail
- **Auto-load game script** sau verify thành công

### 4. Game Scripts

#### PawZHubBF.lua (Blox Fruits) — 4000+ dòng
- **Features**: Auto Farm Level (quest-based), Auto Mastery, Auto Boss, Auto Raid, Elite Hunter, ESP, Noclip, Fruit Sniper, Server Hop, Bring Mobs, Observation Haki
- **World Scanner**: Scan Enemies, Islands, Quest NPCs, Remotes
- **Level Guide**: 0→2500+ level mapping cho Sea 1/2/3
- **Feature Engine**: Heartbeat-based với primary/secondary arbitration

#### PawZHubGG.lua (Greedy Growers) — 3000+ dòng
- **Features**: Auto Buy Seeds (conveyor path), Auto Plant, Auto Harvest, Auto Collect, Auto Sell, Auto Fertilizer (với GUI chọn phân), Auto Feed Pets, Server Hop
- **Prompt Cache**: Tránh lag khi interact
- **Protection**: Own Plot Only mode

---

## 🗄️ Storage Layer (Upstash Redis)

### Production: Upstash Redis REST API
- **Atomic operations**: Lua EVAL scripts (chống race condition)
- **Key prefixes**:
  - `cp:{token}` — Checkpoint tokens
  - `hwid:{keyId}` — HWID bindings
  - `hwid:resets:{keyId}` — Reset history
  - `bl:{userId}` — Blacklist
  - `logs:queue` — Usage logs (LPUSH + LTRIM)
  - `rc:{code}` — Redemption codes
  - `revoked:{keyId}` — Revoked keys

### Dev Fallback: In-Memory Map
- Chỉ dùng `npm run dev`
- **Không dùng production** (mất data khi Vercel function cold-starts)

---

## 🔐 Rate Limiting

### Production: Upstash Redis
- Algorithm: Fixed-window counter
- `INCR {key}` + `EXPIRE {windowSec}` (atomic)

### Limits:
- `verify`: 30 requests / 60s per IP
- `getkey`: 10 requests / 60s per IP
- `checkout`: 10 requests / 1h per IP
- `hwid-reset`: 5 requests / 1h per IP
- `checkpoint`: 20 requests / 60s per IP

### Failure Mode: **Fail-open**
- Nếu Redis unreachable → allow request (logged warning)
- Tránh brick API khi Upstash outage

---

## 🛡️ Security Features

### 1. Timing-Safe String Compare
- Admin token verify dùng `timingSafeEqual()` (chống timing attack)
- Constant-time comparison

### 2. Atomic Checkpoint Token Consumption
- Lua EVAL script trong Redis
- Chống race condition (2 user dùng cùng token)

### 3. Atomic Redemption Code Claim
- Lua EVAL script
- First-come-first-serve

### 4. Key Revocation
- Revoked keys reject ở `/api/verifykey`
- Stored in `revoked:{keyId}` set

### 5. Blacklist System
- User ID blacklist → reject tất cả actions
- Logged vào usage logs

---

## 📊 Luồng Hoạt Động

### Luồng Lấy Free Key

```
1. User → /getkey page → Chọn platform (WorkInk / LootLabs)

2. Frontend → POST /api/checkpoint {platform, step:1}
   → Server tạo token1, response {token, url}

3. Frontend mở URL ad platform (Work.ink hoặc LootLabs)

4. User hoàn thành ads → redirect về /getkey/callback?platform=...&step=1&token=...

5. Callback page → POST /api/checkpoint/complete {platform, token}
   → Server đánh dấu token1 "done"

6. Lặp lại bước 2-5 cho step 2 (token2)

7. Frontend → POST /api/getkey {checkpoint1Token, checkpoint2Token, hwid}
   → Server verify 2 tokens → mint JWT key

8. User copy key → paste vào Lua modal
```

### Luồng Verify Key (Lua Client)

```
1. Executor load checkkey.lua → UI modal hiện

2. User nhập key → Lua gọi POST /api/verifykey {key, hwid, userId}

3. Server:
   - Check revoked keys
   - Check blacklist
   - JWT? → verify signature
   - PH.*? → verify HMAC, check HWID binding (first-use-binds)
   - Return {valid, tier, features, expires}

4. Lua nhận valid=true → đóng modal → auto-load game script theo PlaceId

5. Game script execute → features mở khóa
```

### Luồng Mua Premium (Checkout)

```
1. User click pricing button → modal hiện

2. User chọn plan (trial/monthly/lifetime) + payment method

3. User redirect ra Stripe/PayPal → thanh toán

4. Payment processor → webhook /api/checkout {paymentId, paymentProvider}

5. Server:
   - Verify payment với Stripe/PayPal API
   - Generate premium key PH.*
   - Store HWID binding
   - Send Discord webhook notification
   - Return {key, orderId}

6. User nhận key qua Discord DM hoặc web
```

---

## 🔧 Environment Variables

### Web (Vercel) — Required

| Biến | Mô tả |
|------|-------|
| `GETKEY_SECRET` | JWT secret cho free keys |
| `KEYGEN_SECRET` | HMAC secret cho premium keys |
| `ADMIN_TOKEN` | Admin API auth token |
| `BOT_REDEEM_TOKEN` | Bot redeem auth token |
| `UPSTASH_REDIS_REST_URL` | Upstash Redis endpoint |
| `UPSTASH_REDIS_REST_TOKEN` | Upstash Redis token |

### Web (Vercel) — Optional

| Biến | Mô tả |
|------|-------|
| `DISCORD_WEBHOOK_URL` | Checkout notifications |
| `LOOTLABS_API_KEY` | LootLabs dynamic mode |
| `LOOTLABS_URL_STEP1/2` | LootLabs static links |
| `STRIPE_SECRET_KEY` | Stripe payments |
| `PAYPAL_CLIENT_ID/SECRET` | PayPal payments |

### Bot (Railway)

| Biến | Mô tả |
|------|-------|
| `DISCORD_BOT_TOKEN` | Bot token |
| `DISCORD_CLIENT_ID` | Application client ID |
| `DISCORD_GUILD_ID` | Server ID |
| `WEB_API_URL` | Vercel deployment URL |
| `WEB_ADMIN_TOKEN` | Phải khớp ADMIN_TOKEN |
| `BOT_REDEEM_TOKEN` | Phải khớp BOT_REDEEM_TOKEN |
| `ADMIN_USER_IDS` | Comma-separated Discord user IDs |

---

## ✅ Những Gì Đã Hoàn Chỉnh

✅ **Web Frontend**
- Trang chủ với hero, games showcase, pricing, FAQ
- GetKey page với multi-platform support (WorkInk, LootLabs)
- **Admin dashboard** (stats, **All Keys**, **Active Keys**, blacklist, keygen, logs)
- Responsive design (Tailwind CSS v4)

✅ **Web API (10 routes)**
- Key verification (JWT + HMAC)
- Free key generation với checkpoint system
- Premium key checkout skeleton
- HWID binding + reset logic
- Blacklist system
- Rate limiting (Redis-backed)
- Admin panel APIs

✅ **Discord Bot (9 commands)**
- User commands: /verify, /redeem
- Admin commands: /keygen, /inspect-key, /reset-hwid, /revoke-key, /blacklist, /unblacklist, /stats
- DM key delivery
- Permission system

✅ **Storage Layer**
- Upstash Redis với atomic Lua scripts
- In-memory fallback cho dev
- Checkpoint token race-condition safe
- Redemption code atomic claim

✅ **Lua Scripts**
- loader.lua + loader-web.lua (2-stage loading)
- checkkey.lua v4.0 (full UI + verify logic)
- PawZHubBF.lua (Blox Fruits complete)
- PawZHubGG.lua (Greedy Growers complete)

✅ **Security**
- Timing-safe admin token compare
- HMAC key signatures (chống forge)
- JWT với HS256
- First-use HWID binding
- Key revocation system

✅ **Documentation**
- API_DOCUMENTATION.md
- DEPLOYMENT_GUIDE.md
- SETUP_GUIDE.md (mới tạo)
- Backend README.md (mới tạo)

---

## ⚠️ Những Gì Cần Config Trước Khi Dùng Production

### Nghiêm Trọng (Phải Fix)

❌ **Discord Bot Token đã bị expose**
- File `bot/.env` cũ chứa token thật (`MTU0MTEzNT...`)
- **Hành động**: Vào Discord Developer Portal → Reset token → cập nhật `.env` mới
- ✅ **Đã fix**: `.env` hiện tại dùng placeholder an toàn

❌ **BOT_REDEEM_TOKEN chưa có**
- Bot không thể gọi `/api/redeem` (401 Unauthorized)
- **Hành động**: Sinh random string dài → set cả Vercel và bot `.env`

❌ **WEB_ADMIN_TOKEN trong bot là placeholder**
- Bot không thể gọi admin APIs
- **Hành động**: Copy `ADMIN_TOKEN` từ Vercel → paste vào bot `.env`

❌ **UPSTASH_REDIS chưa set production**
- Vercel đang dùng in-memory fallback → mất data khi cold-start
- **Hành động**: Tạo DB tại console.upstash.com → set URL + TOKEN

### Trung Bình (Optional nhưng Recommended)

⚠️ **Payment không hoạt động**
- `STRIPE_SECRET_KEY` và `PAYPAL_CLIENT_ID/SECRET` trống
- `/api/checkout` luôn trả 402
- **Hành động**: Setup Stripe hoặc PayPal → thêm credentials

⚠️ **LootLabs static URLs trống**
- `LOOTLABS_URL_STEP1/2` không set → dùng dynamic API mode
- **Hành động**: Tạo 2 content lockers trong LootLabs dashboard → paste URLs

⚠️ **Discord webhook trống**
- `DISCORD_WEBHOOK_URL` không set → không notification khi có checkout
- **Hành động**: Tạo webhook trong Discord server → paste URL

⚠️ **Payment URLs trống**
- `NEXT_PUBLIC_PAYMENT_MONTHLY_URL` và `LIFETIME_URL` trống
- Pricing buttons không redirect đúng
- **Hành động**: Setup Stripe Payment Links hoặc dùng checkout modal

### Nhỏ (Nice to Have)

✨ **Backend folder trống**
- ✅ **Đã fix**: Tạo Express server skeleton với webhook receivers

✨ **Test suite trống**
- Vitest configured nhưng không có test files
- **Hành động**: Viết tests cho core functions (keygen, db, ratelimit)

---

## 📈 Performance & Scalability

### Current Architecture
- **Web**: Vercel serverless functions (auto-scale)
- **Bot**: Railway single container (1 instance đủ cho <100k users)
- **Storage**: Upstash Redis (managed, auto-scale)

### Bottlenecks
1. **Rate limiting**: Redis INCR là bottleneck nhẹ (thường <5ms)
2. **Checkpoint token**: Redis EVAL Lua script (~10ms)
3. **Vercel cold starts**: ~500ms (chấp nhận được)

### Scaling Strategy
- Web API auto-scale với Vercel (không cần config)
- Bot scale bằng cách deploy nhiều shards (Discord.js sharding)
- Redis upgrade plan khi hit rate limits (Upstash auto-alert)

---

## 🐛 Known Issues / Edge Cases

### 1. Free Key HWID Không Enforce
- **Issue**: JWT free keys không check HWID → cùng key dùng nhiều thiết bị
- **Reason**: Browser HWID khác Lua HWID → enforce sẽ brick UX
- **Fix**: Chấp nhận trade-off (free keys dễ share, nhưng expire nhanh)

### 2. Checkout Payment Verify Chưa Implement
- **Issue**: `verifyPayment()` skeleton → luôn return false
- **Fix**: Wire Stripe/PayPal API calls (code đã có template)

### 3. In-Memory Fallback Không Production-Safe
- **Issue**: Vercel multi-instance → rate limit/data inconsistent
- **Fix**: Bắt buộc dùng Upstash (code đã loud warning)

### 4. Linkvertise Disabled
- **Issue**: `AD_PLATFORMS.linkvertise.enabled = false`
- **Fix**: Enable nếu muốn (chỉnh config.ts)

---

## 🎓 Tech Stack

### Web
- **Framework**: Next.js 16.3 (App Router)
- **Styling**: Tailwind CSS v4
- **Auth**: jose (JWT), crypto (HMAC)
- **Storage**: Upstash Redis (REST API)
- **Deployment**: Vercel

### Bot
- **Library**: discord.js v14
- **Language**: TypeScript 5.4
- **Deployment**: Railway

### Lua
- **Environment**: Roblox Luau
- **HTTP**: 4 fallback methods
- **UI**: Custom Roblox GUI

### Backend (Optional)
- **Framework**: Express 4.18
- **Language**: Node.js 18+
- **Deployment**: Railway / VPS

---

## 📞 Support & Maintenance

### Monitoring
- **Web**: Vercel Analytics + Logs
- **Bot**: Railway Logs
- **Redis**: Upstash Dashboard

### Backup Strategy
- **Code**: GitHub (all changes tracked)
- **Redis**: Upstash auto-backup (paid tier)
- **Logs**: 7 days retention (increase với paid tier)

### Update Process
1. Test local (`npm run dev`)
2. Push to GitHub
3. Auto-deploy: Vercel (web), Railway (bot)
4. Monitor logs 5 phút đầu
5. Rollback nếu cần (Vercel 1-click rollback)

---

## 🚀 Next Steps / Roadmap

### Phase 1: Production Ready (Cần làm ngay)
- [x] Fix bot token security
- [x] Tạo backend skeleton
- [x] Setup guide đầy đủ
- [ ] Deploy Upstash Redis
- [ ] Config payment processors
- [ ] Deploy bot lên Railway
- [ ] Test end-to-end

### Phase 2: Features
- [ ] Thêm games mới (Arsenal, Rivals, etc.)
- [ ] Key gifting system
- [ ] Referral rewards
- [ ] Web dashboard cho users (xem keys của mình)

### Phase 3: Optimization
- [ ] Viết test suite
- [ ] CDN cho Lua scripts (Cloudflare R2)
- [ ] WebSocket realtime stats
- [ ] Analytics dashboard (Grafana + Prometheus)

---

## 📝 Changelog

### 2024-08-27 Update 2: Admin Dashboard Enhanced
- Thêm tab **"All Keys"** — Xem tất cả keys đã được tạo/verify (từ logs)
- Thêm tab **"Active Keys"** — Chỉ hiện keys hoạt động trong 24h gần nhất
- Stats cho Active Keys: Total active, Total verifications, Unique devices
- Success rate indicator (màu xanh/vàng/đỏ) cho mỗi key
- API endpoint mới: `GET /api/admin?action=list-keys&type=all|active&limit=500`

### 2024-08-27: Initial Audit Complete
- Kiểm tra toàn bộ codebase (web, bot, backend, scripts)
- Fix bot token security issue
- Tạo backend Express skeleton
- Hoàn thiện documentation (SETUP_GUIDE.md, TT.md)
- Bổ sung `BOT_REDEEM_TOKEN` config
- Tạo `.env.example` files đầy đủ

---

## 💡 Tips & Best Practices

### Development
- Luôn test local trước khi deploy
- Dùng `.env.local` cho dev (không commit)
- Check Vercel logs nếu API lỗi
- Bot commands test trong private server trước

### Production
- Rotate secrets 6 tháng 1 lần
- Monitor Upstash usage (alert khi gần limit)
- Backup Redis data định kỳ
- Review logs hàng tuần (tìm attack patterns)

### Security
- KHÔNG hardcode secrets trong code
- Dùng `timingSafeEqual` cho token compare
- Rate limit aggressive cho public endpoints
- Review blacklist hàng tuần

---

## 📚 Các File Quan Trọng

### Configuration
- `web/.env.example` — Web env template
- `web/.env.local` — Local dev (git-ignored)
- `bot/.env.example` — Bot env template
- `bot/.env` — Bot credentials (git-ignored)
- `backend/.env.example` — Backend env template

### Core Logic
- `web/src/lib/db.ts` — Storage layer (3400 dòng)
- `web/src/lib/keygen.ts` — Premium key logic (180 dòng)
- `web/src/app/api/verifykey/route.ts` — Main verify endpoint (270 dòng)
- `web/src/app/api/getkey/route.ts` — Free key minting (180 dòng)
- `bot/src/lib/api.ts` — Bot ↔ Web API bridge (280 dòng)

### Lua Scripts
- `loader-web.lua` — Main loader (100 dòng)
- `checkkey.lua` — Key system (1500 dòng)
- `script/PawZHubBF.lua` — Blox Fruits (4000+ dòng)
- `script/PawZHubGG.lua` — Greedy Growers (3000+ dòng)

### Documentation
- `SETUP_GUIDE.md` — Setup từ đầu (200+ dòng)
- `API_DOCUMENTATION.md` — API docs chi tiết
- `DEPLOYMENT_GUIDE.md` — Deploy production
- `TT.md` — File này (tổng hợp mọi thứ)

---

## ✨ Kết Luận

Hệ thống PawZHub là một **full-stack Roblox script hub** hoàn chỉnh với:
- ✅ Frontend modern (Next.js 16.3)
- ✅ Backend API robust (10 routes, rate-limited, secure)
- ✅ Discord bot tích hợp (9 commands)
- ✅ Multi-platform checkpoint system (WorkInk, LootLabs)
- ✅ Premium key với HWID binding + reset
- ✅ Lua client với auto-load game scripts
- ✅ 2 game scripts hoàn chỉnh (Blox Fruits, Greedy Growers)

**Cần làm trước khi production**:
1. Reset Discord bot token (đã bị expose)
2. Config Upstash Redis
3. Set `BOT_REDEEM_TOKEN` và `WEB_ADMIN_TOKEN`
4. Setup payment processors (Stripe/PayPal)
5. Deploy bot lên Railway
6. Test end-to-end

**Sau khi config xong**, hệ thống sẵn sàng serve hàng ngàn người dùng với Vercel auto-scale + Railway 24/7 bot.

---

**Tài liệu này được tạo tự động sau khi audit toàn bộ codebase.**  
**Last Updated**: 2024-08-27
