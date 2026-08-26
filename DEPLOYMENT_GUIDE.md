# PawZHub — Production Deployment Guide

Hệ thống đã được audit + fix toàn bộ. Tài liệu này hướng dẫn deploy lên Vercel với Upstash Redis (persistent storage).

---

## 1. Tạo Upstash Redis (free tier)

1. Truy cập <https://console.upstash.com/> → đăng ký/đăng nhập.
2. **Create Database**:
   - Name: `pawzhub`
   - Type: **Regional** (rẻ hơn Global, đủ dùng)
   - Region: chọn gần Vercel region (ví dụ `us-east-1` nếu Vercel project ở US)
   - TLS: bật
3. Sau khi tạo, mở database → tab **REST API**:
   - Copy `UPSTASH_REDIS_REST_URL` (dạng `https://xxx.upstash.io`)
   - Copy `UPSTASH_REDIS_REST_TOKEN` (chuỗi token dài)

## 2. Cấu hình Vercel env vars

Mở **Vercel Dashboard** → Project `pawzhub-web` → **Settings** → **Environment Variables**.

Thêm (đặt cho cả 3 environment: Production, Preview, Development):

| Key | Value | Mô tả |
|-----|-------|--------|
| `NEXT_PUBLIC_SITE_URL` | `https://getpawzhub.vercel.app` | Domain thật |
| `GETKEY_SECRET` | `<random 64+ chars>` | JWT signing secret |
| `KEYGEN_SECRET` | `<random 64+ chars>` | HMAC cho premium keys |
| `ADMIN_TOKEN` | `<random 64+ chars>` | Token truy cập `/api/admin` |
| `DISCORD_WEBHOOK_URL` | (optional) | Báo purchase qua Discord |
| `UPSTASH_REDIS_REST_URL` | (từ bước 1) | Redis URL |
| `UPSTASH_REDIS_REST_TOKEN` | (từ bước 1) | Redis token |
| `LOOTLABS_API_KEY` | `0925af6741885de78da9698d576b83982471754601aa4f4ff20e12927f1606e8` | LootLabs API key |
| `LOOTLABS_APP_ID` | `qVLcXSgW` | LootLabs App ID (từ dashboard) |
| `LOOTLABS_TIER_ID` | `3` | Tier 3 (balance tốt nhất) |
| `LOOTLABS_NUM_TASKS` | `3` | 3 ads/checkpoint |
| `CHECKPOINT_TTL_MINUTES` | `15` | Checkpoint token TTL |
| `GETKEY_TTL_HOURS` | `12` | Free key base duration (override theo platform) |

> **Quan trọng**: Không prefix bất kỳ secret nào bằng `NEXT_PUBLIC_` — sẽ bị leak ra client.

## 3. Deploy

```powershell
cd D:\App\Desktop\PawZHub\web
npx vercel --prod
```

Hoặc push lên GitHub → Vercel tự động build + deploy (nếu đã connect repo).

## 4. Verify sau khi deploy

```bash
# Health check
curl https://getpawzhub.vercel.app/api/getkey

# LootLabs mint link
curl "https://getpawzhub.vercel.app/api/lootlabs?step=1&session=test&hwid=test"

# Issue checkpoint token
curl -X POST "https://getpawzhub.vercel.app/api/checkpoint?platform=linkvertise&step=1"
```

## 5. Smoke test user flow

1. Mở <https://getpawzhub.vercel.app/getkey>
2. Click card **Linkvertise** → Start Checkpoint
3. Hoàn thành Linkvertise (12s) → redirect về `/getkey/callback?platform=linkvertise&step=1&token=...`
4. Callback page tự đóng sau 2s; modal tab gốc hiện ✓ Step 1
5. Lặp lại Step 2
6. Click **Get Key** → key JWT hiện ra
7. Copy key, mở Roblox, chạy loader, paste key → script unlock

## 6. Admin panel

URL: `https://getpawzhub.vercel.app/admin`
- Nhập `ADMIN_TOKEN` đã set ở bước 2.
- Tab **Stats**: xem tổng tokens / HWID bindings / blacklist.
- Tab **Blacklist**: thêm userId bị cấm.
- Tab **Keys**: tạo bulk premium keys.
- Tab **Logs**: xem verification log.

## 7. Rollback khi có sự cố

Vercel giữ mọi deployment. Để rollback:
- Vercel Dashboard → Deployments → chọn deployment cũ → **Promote to Production**.

Hoặc qua CLI:
```bash
npx vercel rollback
```

## 8. Monitoring

- **Logs**: Vercel Dashboard → Logs (function logs cho mỗi API route).
- **Errors**: Function log filter `error` để xem stack trace.
- **Uptime**: Bật Vercel Analytics (miễn phí cho project này).
- **LootLabs earnings**: <https://creators.lootlabs.gg/dashboard>
- **Linkvertise earnings**: <https://linkvertise.com/dashboard>
- **Work.ink earnings**: <https://work.ink/publisher/dashboard>

## 9. Local dev

```bash
cd D:\App\Desktop\PawZHub\web
npx next dev
```

`http://localhost:3000` sẽ chạy với env từ `.env.local`.

> Lưu ý: Vercel env không tự sync xuống local. Bạn cần copy env values vào `.env.local` để dev local dùng đúng secret/Redis. Nếu để trống `UPSTASH_REDIS_REST_URL` thì local sẽ dùng **in-memory fallback** — data mất khi restart dev server nhưng vẫn test được flow.

## 10. Cấu trúc route & file chính

```
web/
├── .env.example             # Template cho env
├── .env.local               # Local dev (KHÔNG commit)
├── src/
│   ├── app/
│   │   ├── api/
│   │   │   ├── getkey/route.ts          # POST: mint JWT key (yêu cầu 2 token)
│   │   │   ├── verifykey/route.ts       # POST: verify key từ Lua
│   │   │   ├── renewkey/route.ts        # POST: gia hạn key (+12h, max 3 lần)
│   │   │   ├── checkpoint/route.ts      # POST: issue server-side token
│   │   │   ├── checkpoint/info/route.ts # GET: check token còn valid
│   │   │   ├── lootlabs/route.ts        # GET: mint LootLabs link
│   │   │   ├── hwid-reset/route.ts      # POST/GET: reset HWID (premium only)
│   │   │   ├── checkout/route.ts        # POST: mint premium key (payment-gated)
│   │   │   └── admin/route.ts           # GET/POST/DELETE: admin actions
│   │   ├── getkey/
│   │   │   ├── page.tsx                 # 3 platform cards
│   │   │   ├── callback/page.tsx        # Linkvertise + LootLabs callback
│   │   │   ├── callback/workink/page.tsx # Work.ink callback (verify Work.ink API)
│   │   │   ├── success/page.tsx         # Legacy success page
│   │   │   └── components/
│   │   │       ├── CheckpointModal.tsx  # Main modal logic
│   │   │       ├── KeyGenCard.tsx       # 3 platform cards UI
│   │   │       └── KeySteps.tsx
│   │   └── admin/page.tsx               # Admin dashboard UI
│   └── lib/
│       ├── config.ts                    # AD_PLATFORMS + URLs
│       ├── db.ts                        # Upstash Redis adapter
│       ├── keygen.ts                    # Premium PH.* key crypto
│       └── ratelimit.ts                 # IP rate limiting
```

---

## Troubleshooting

### "Rate limit exceeded"
- Vượt quá giới hạn /phút. Đợi 60s rồi thử lại.

### "Checkpoint token expired"
- Token hết hạn sau 15 phút (mặc định). Hoàn thành lại checkpoint flow.

### LootLabs link trả về destination_url = `http://localhost:3000/...`
- Biến `NEXT_PUBLIC_SITE_URL` chưa được set đúng trên Vercel. Vercel cần rebuild sau khi đổi env.

### Free key verify trong Lua fail "Invalid signature"
- `GETKEY_SECRET` trên Vercel khác với local. Đảm bảo cùng secret.
- Hoặc key đã cũ trước khi deploy code mới — đợi key expire rồi gen lại.

### Lua script không gọi được API
- Kiểm tra `https://getpawzhub.vercel.app/api/verifykey` trả về JSON. Nếu executor chặn HTTP, user cần đổi executor.
