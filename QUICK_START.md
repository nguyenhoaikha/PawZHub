# 🚀 Quick Start - PawZHub

## Hệ thống của bạn ĐÃ SẴN SÀNG! ✅

Domain: **https://getpawzhub.vercel.app**

---

## 📝 Bước 1: Test ngay

### Test Web:
```
1. Mở: https://getpawzhub.vercel.app/getkey
2. Click button "Linkvertise" 
3. Complete checkpoint (30 giây)
4. Key hiện ra → Copy
```

### Test trong Roblox:
```lua
-- Join bất kỳ game nào, paste vào executor:
loadstring(game:HttpGet("https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main/loader.lua"))()

-- Key UI hiện ra
-- Click "Get Key" → link copied
-- Mở link → Complete Linkvertise → Paste key
```

---

## 💰 Kiếm tiền ngay

### Linkvertise đang active!
- Mỗi user complete = bạn được trả
- Check earnings: https://linkvertise.com/dashboard
- CPM: $3-10 tùy quốc gia

### Enable thêm platform:

**Work.ink** (18h keys, higher CPM):
1. Đăng ký: https://work.ink
2. Update ID trong `web/src/lib/config.ts` line 23
3. Set `NEXT_PUBLIC_WORKINK_ENABLED=true` trong Vercel
4. Redeploy

**Lootlabs** (24h keys, highest CPM):
1. Đăng ký: https://loot-labs.com
2. Update ID trong `web/src/lib/config.ts` line 30
3. Set `NEXT_PUBLIC_LOOTLABS_ENABLED=true` trong Vercel
4. Redeploy

---

## 🔧 Vercel Settings

### Environment Variables (CRITICAL!):

```bash
GETKEY_SECRET=change-this-to-random-string-now
NEXT_PUBLIC_SITE_URL=https://getpawzhub.vercel.app
GETKEY_TTL_HOURS=12
```

Set tại: Vercel Dashboard → Project → Settings → Environment Variables

---

## 📊 File Structure

```
✅ WEB (Vercel)
├── web/src/lib/config.ts         - URLs đã update
├── web/src/app/getkey/            - Get key pages
│   ├── page.tsx                   - Main page
│   ├── success/page.tsx           - After Linkvertise
│   └── components/KeyGenCard.tsx  - 3 platform UI
└── web/src/app/api/
    ├── getkey/route.ts            - Generate key
    └── verifykey/route.ts         - Verify key

✅ LUA SCRIPTS (GitHub)
├── loader.lua        - Entry point (no changes needed)
└── checkkey.lua      - URLs updated to Vercel
```

---

## ✅ Everything Working:

- ✅ Web: https://getpawzhub.vercel.app
- ✅ Linkvertise: ID 3444039 active
- ✅ API: /api/getkey, /api/verifykey
- ✅ Lua: checkkey.lua → Vercel API
- ✅ Flow: Roblox → Web → Linkvertise → Key → Verify → Unlock

---

## 🎯 Revenue Potential

**Current (Linkvertise only):**
- 100 users/day × 80% complete = 80 keys
- 80 keys × $0.05 average = **$4/day**
- **~$120/month**

**With all 3 platforms:**
- **~$195/month**
- **~$2,370/year**

*Actual revenue depends on traffic, country, season*

---

## 📞 Support

- Discord: https://discord.gg/pawzhub
- Issues: Check `SETUP_COMPLETE.md`
- Docs: All `.md` files in project root

---

## 🎉 You're Done!

Hệ thống hoàn chỉnh với:
- ✅ Multi-platform getkey (3 revenue streams)
- ✅ Stateless key system (no database)
- ✅ HWID binding (device locked)
- ✅ Auto key generation
- ✅ API verification
- ✅ Beautiful UI

**Start promoting your script and watch revenue grow! 🚀**

---

**Domain**: https://getpawzhub.vercel.app  
**Status**: 🟢 LIVE  
**Revenue**: 💰 Active
