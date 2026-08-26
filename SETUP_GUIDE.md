# PawZHub — Hướng Dẫn Setup Đầy Đủ

Hướng dẫn từng bước để setup và deploy toàn bộ hệ thống PawZHub từ đầu.

## 📋 Tổng Quan Hệ Thống

PawZHub gồm 3 thành phần chính:

1. **Web** (Next.js 16.3) — Frontend + API routes → Deploy lên **Vercel**
2. **Bot** (Discord.js) — Discord bot TypeScript → Deploy lên **Railway**
3. **Backend** (Express) — Optional webhook receiver → Self-host hoặc Railway
4. **Lua Scripts** — Roblox scripts (loader, checkkey, game scripts) → GitHub raw

---

## 🚀 Bước 1: Setup Web (Vercel)

### 1.1. Clone và Install

```bash
cd web
npm install
```

### 1.2. Tạo .env.local cho Dev

```bash
cp .env.example .env.local
```

Sửa `.env.local`:

```bash
# Secrets (sinh random string dài)
GETKEY_SECRET=your-long-random-string-here
KEYGEN_SECRET=another-long-random-string
ADMIN_TOKEN=your-admin-token-here
BOT_REDEEM_TOKEN=your-bot-redeem-token-here

# Upstash Redis (tạo DB miễn phí tại https://console.upstash.com)
UPSTASH_REDIS_REST_URL=https://your-db.upstash.io
UPSTASH_REDIS_REST_TOKEN=your-token

# Discord webhook (tùy chọn — để trống nếu không cần)
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...

# LootLabs (lấy API key tại https://creators.lootlabs.gg)
LOOTLABS_API_KEY=your-lootlabs-api-key
```

### 1.3. Test Local

```bash
npm run dev
```

Mở `http://localhost:3000` — trang chủ phải load được.

### 1.4. Deploy lên Vercel

#### Cách 1: Vercel CLI

```bash
npm install -g vercel
vercel login
cd web
vercel
```

#### Cách 2: GitHub + Vercel Dashboard

1. Push code lên GitHub
2. Vào [vercel.com/new](https://vercel.com/new)
3. Import repo → chọn `web` folder làm root
4. Vào **Settings → Environment Variables** và thêm:
   - `GETKEY_SECRET`
   - `KEYGEN_SECRET`
   - `ADMIN_TOKEN`
   - `BOT_REDEEM_TOKEN`
   - `UPSTASH_REDIS_REST_URL`
   - `UPSTASH_REDIS_REST_TOKEN`
   - `DISCORD_WEBHOOK_URL` (optional)
   - `LOOTLABS_API_KEY`
   - `LOOTLABS_APP_ID=qVLcXSgW`
   - `NEXT_PUBLIC_SITE_URL=https://your-domain.vercel.app`
5. Redeploy

**Quan trọng**: Sau khi deploy, copy URL Vercel (vd: `https://getpawzhub.vercel.app`) — sẽ cần cho Bot config.

---

## 🤖 Bước 2: Setup Discord Bot

### 2.1. Tạo Discord Application

1. Vào [Discord Developer Portal](https://discord.com/developers/applications)
2. **New Application** → đặt tên "PawZHub"
3. Vào **Bot** tab → **Add Bot**
4. **Reset Token** → copy token (sẽ dùng trong `.env`)
5. Bật **Privileged Gateway Intents** → `SERVER MEMBERS INTENT` và `MESSAGE CONTENT INTENT` (tùy chọn)
6. Vào **OAuth2 → General** → copy **Client ID**
7. Vào **OAuth2 → URL Generator**:
   - Scope: `bot`, `applications.commands`
   - Permissions: `Send Messages`, `Use Slash Commands`, `Read Message History`
   - Copy URL → mở trình duyệt → invite bot vào server

### 2.2. Install và Config

```bash
cd bot
npm install
cp .env.example .env
```

Sửa `bot/.env`:

```bash
DISCORD_BOT_TOKEN=YOUR_BOT_TOKEN_FROM_STEP_2.1.4
DISCORD_CLIENT_ID=YOUR_CLIENT_ID_FROM_STEP_2.1.6
DISCORD_GUILD_ID=YOUR_SERVER_ID

WEB_API_URL=https://getpawzhub.vercel.app  # URL Vercel của bạn
WEB_ADMIN_TOKEN=same-as-ADMIN_TOKEN-in-vercel-env
BOT_REDEEM_TOKEN=same-as-BOT_REDEEM_TOKEN-in-vercel-env

ADMIN_USER_IDS=your_discord_user_id  # Chuột phải tên bạn → Copy User ID
```

**Lấy Discord User ID**: Bật Developer Mode (Settings → Advanced → Developer Mode) → chuột phải tên bạn → Copy User ID

### 2.3. Deploy Commands

```bash
npm run build
npm run deploy
```

Output phải hiện: `Successfully registered X application commands.`

### 2.4. Test Local

```bash
npm run dev
```

Bot phải online trong Discord server. Test `/verify` command.

### 2.5. Deploy lên Railway

1. Vào [railway.app](https://railway.app) → đăng nhập GitHub
2. **New Project** → **Deploy from GitHub repo**
3. Chọn repo → **Add variables**:
   - Paste toàn bộ nội dung `.env` của bạn
4. **Settings** → **Start Command**: `npm run build && npm start`
5. **Settings** → **Root Directory**: `bot` (nếu bot nằm trong subfolder)
6. Deploy

Bot sẽ chạy 24/7 trên Railway.

---

## 🗄️ Bước 3: Setup Upstash Redis (BẮT BUỘC cho Production)

Hệ thống dùng Redis để lưu:
- Checkpoint tokens
- HWID bindings
- Blacklist
- Rate limiting
- Redemption codes

### 3.1. Tạo Database

1. Vào [console.upstash.com](https://console.upstash.com)
2. **Create Database** → Region gần bạn (US East/EU) → **Enable TLS**
3. Copy **REST URL** và **REST TOKEN**
4. Paste vào Vercel env vars:
   - `UPSTASH_REDIS_REST_URL`
   - `UPSTASH_REDIS_REST_TOKEN`

### 3.2. Test

```bash
curl -X POST https://your-db.upstash.io/set/testkey/testvalue \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Response: `{"result":"OK"}`

---

## 💳 Bước 4: Setup Payment (Tùy Chọn)

### 4.1. Stripe

1. Vào [dashboard.stripe.com](https://dashboard.stripe.com)
2. **Developers → API Keys** → copy **Secret Key**
3. Thêm vào Vercel env: `STRIPE_SECRET_KEY=sk_live_...`
4. **Webhooks** → **Add endpoint**: `https://your-domain.vercel.app/api/webhooks/stripe`
5. Select events: `payment_intent.succeeded`, `payment_intent.payment_failed`
6. Copy **Signing secret** → `STRIPE_WEBHOOK_SECRET` (nếu dùng backend)

### 4.2. PayPal

1. Vào [developer.paypal.com](https://developer.paypal.com)
2. **My Apps & Credentials** → **Create App**
3. Copy **Client ID** và **Secret**
4. Thêm vào Vercel env:
   - `PAYPAL_CLIENT_ID`
   - `PAYPAL_SECRET`
   - `PAYPAL_MODE=live` (hoặc `sandbox` cho test)

---

## 📱 Bước 5: Setup LootLabs

### 5.1. Dynamic Mode (API)

1. Vào [creators.lootlabs.gg](https://creators.lootlabs.gg)
2. **Settings → API** → copy **API Key**
3. Thêm vào Vercel env: `LOOTLABS_API_KEY`

### 5.2. Static Mode (Recommended)

1. Tạo 2 content lockers trong LootLabs dashboard:
   - Locker 1: Destination = `https://your-domain.vercel.app/getkey/callback?platform=lootlabs&step=1&session={SESSION_ID}&hwid={HWID}`
   - Locker 2: Destination = `https://your-domain.vercel.app/getkey/callback?platform=lootlabs&step=2&session={SESSION_ID}&hwid={HWID}`
2. Copy short URLs (vd: `https://lootdest.org/s?XXXXX`)
3. Thêm vào Vercel env:
   - `LOOTLABS_URL_STEP1=https://lootdest.org/s?XXXXX`
   - `LOOTLABS_URL_STEP2=https://lootdest.org/s?YYYYY`

---

## 🎮 Bước 6: Lua Scripts

Scripts đã có sẵn trong repo. Chỉ cần:

1. Push code lên GitHub (public repo)
2. Loadstring URL: `https://raw.githubusercontent.com/YOUR_USERNAME/PawZHub/main/loader.lua`
3. User paste vào executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/PawZHub/main/loader.lua"))()
```

### Script Flow

```
loader.lua 
  → loader-web.lua 
    → checkkey.lua (modal verify key) 
      → script/PawZHubBF.lua (Blox Fruits) hoặc
      → script/PawZHubGG.lua (Greedy Growers)
```

---

## ✅ Bước 7: Verify Setup

### 7.1. Test Web API

```bash
# Health check
curl https://your-domain.vercel.app/api/health

# Generate checkpoint token
curl -X POST https://your-domain.vercel.app/api/checkpoint \
  -H "Content-Type: application/json" \
  -d '{"platform":"workink","step":1}'
```

### 7.2. Test Bot Commands

Trong Discord:
- `/verify key:YOUR_KEY hwid:test123` → phải verify được
- `/stats` (admin only) → phải hiện stats

### 7.3. Test Lua Script

1. Mở Roblox executor (Solara, Wave, etc.)
2. Paste loadstring và execute
3. Modal key system phải hiện
4. Nhập key → verify thành công → script game load

---

## 🔐 Security Checklist

- [ ] `bot/.env` KHÔNG bị commit lên git (check `.gitignore`)
- [ ] Discord bot token đã reset nếu bị leak
- [ ] `ADMIN_TOKEN`, `GETKEY_SECRET`, `KEYGEN_SECRET` đủ dài (>32 ký tự random)
- [ ] `WEB_ADMIN_TOKEN` trong bot `.env` khớp `ADMIN_TOKEN` trên Vercel
- [ ] `BOT_REDEEM_TOKEN` được set trên cả Vercel và bot `.env`
- [ ] Upstash Redis đã enable TLS
- [ ] Stripe/PayPal webhook có verify signature

---

## 🐛 Troubleshooting

### Bot không online
- Check `DISCORD_BOT_TOKEN` có đúng không
- Bot đã được invite vào server chưa?
- Railway logs: `railway logs`

### /api/verifykey trả về 500
- Check Vercel logs: `vercel logs`
- `UPSTASH_REDIS_REST_URL` có set chưa?

### Checkpoint không hoạt động
- Check LootLabs API key hoặc static URLs
- Callback URL phải khớp: `https://your-domain.vercel.app/getkey/callback`

### Bot commands fail với 401 Unauthorized
- `WEB_ADMIN_TOKEN` trong bot `.env` phải khớp `ADMIN_TOKEN` trên Vercel
- `BOT_REDEEM_TOKEN` phải được set cả 2 bên

---

## 📚 Tài Liệu Liên Quan

- [API_DOCUMENTATION.md](./API_DOCUMENTATION.md) — API routes chi tiết
- [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) — Deploy lên production
- [web/README.md](./web/README.md) — Web frontend docs
- [bot/README.md](./bot/README.md) — Bot commands docs

---

## 💬 Support

- Discord: https://discord.gg/pawzhub
- GitHub Issues: https://github.com/nguyenhoaikha/PawZHub/issues
