/**
 * ========================================
 *  GETKEY_SECRET Demo — Mô phỏng cách hệ thống PawZHub tạo & verify key
 * ========================================
 *
 *  Chạy: node demo/getkey-demo.js
 *  Không cần npm install — dùng jose có sẵn trong project
 *
 *  Giả lập flow thật:
 *    1. User hoàn thành checkpoint → POST /api/getkey
 *    2. Server ký JWT bằng GETKEY_SECRET → trả key cho user
 *    3. User đưa key cho Lua script → POST /api/verifykey
 *    4. Server verify bằng GETKEY_SECRET → cho phép hoặc từ chối
 */

const { SignJWT, jwtVerify } = require('jose');

// ─── SECRET (giống hệt env.ts) ───
const GETKEY_SECRET = process.env.GETKEY_SECRET || 'pawzhub-dev-only-getkey-secret';
const JWT_SECRET = new TextEncoder().encode(GETKEY_SECRET);

// ─── BƯỚC 1: TẠO KEY (giống /api/getkey/route.ts) ───
async function createKey({ userId, hwid, source = 'workink', ttlHours = 18 }) {
  const now = Date.now();
  const expiresAt = now + ttlHours * 60 * 60 * 1000;

  console.log(`\n📝 [1] TẠO KEY cho user=${userId}, hwid=${hwid}, source=${source}`);
  console.log(`    Hết hạn: ${new Date(expiresAt).toLocaleString()}`);

  // Ký JWT bằng GETKEY_SECRET
  const token = await new SignJWT({
    tier: 'free',
    source,
    hwid,
    issued: now,
    expires: expiresAt,
    renewCount: 0,
  })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt(Math.floor(now / 1000))
    .setExpirationTime(Math.floor(expiresAt / 1000))
    .sign(JWT_SECRET);

  console.log(`    ✅ Key đã tạo: ${token.substring(0, 60)}...`);
  return token;
}

// ─── BƯỚC 2: VERIFY KEY (giống /api/verifykey/route.ts) ───
async function verifyKey(token, currentHwid) {
  console.log(`\n🔍 [2] VERIFY KEY (hwid gửi lên: ${currentHwid})`);

  try {
    // Verify JWT bằng GETKEY_SECRET
    const { payload } = await jwtVerify(token, JWT_SECRET);

    console.log(`    ✅ Key hợp lệ!`);
    console.log(`    ├── Tier: ${payload.tier}`);
    console.log(`    ├── Source: ${payload.source}`);
    console.log(`    ├── HWID lưu: ${payload.hwid || 'không có'}`);
    console.log(`    ├── Issued: ${new Date(payload.issued).toLocaleString()}`);
    console.log(`    └── Expires: ${new Date(payload.expires * 1000).toLocaleString()}`);

    // Kiểm tra HWID binding
    if (payload.hwid && payload.hwid !== currentHwid) {
      console.log(`    ❌ HWID KHÔNG KHỚP! Key bị gắn với "${payload.hwid}" nhưng gửi lên "${currentHwid}"`);
      return { valid: false, reason: 'HWID mismatch' };
    }

    // Kiểm tra hết hạn
    if (Date.now() > payload.expires * 1000) {
      console.log(`    ❌ Key đã hết hạn!`);
      return { valid: false, reason: 'Expired' };
    }

    return { valid: true, payload };
  } catch (err) {
    console.log(`    ❌ Key KHÔNG hợp lệ: ${err.message}`);
    return { valid: false, reason: err.message };
  }
}

// ─── DEMO ───
async function main() {
  console.log('╔══════════════════════════════════════════════════╗');
  console.log('║   GETKEY_SECRET DEMO — Mô phỏng PawZHub Key    ║');
  console.log('╚══════════════════════════════════════════════════╝');
  console.log(`\n🔑 Secret đang dùng: "${GETKEY_SECRET}"`);

  // ─── TRƯỜNG HỢP 1: Verify đúng ───
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('TRƯỜNG HỢP 1: User gửi đúng key + đúng HWID');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  const key = await createKey({ userId: '123456', hwid: 'ABC-XYZ-789', source: 'workink' });
  await verifyKey(key, 'ABC-XYZ-789');

  // ─── TRƯỜNG HỢP 2: Sai HWID ───
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('TRƯỜNG HỢP 2: User mượn key của người khác (sai HWID)');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  await verifyKey(key, 'HACKED-HWID-999');

  // ─── TRƯỜNG HỢP 3: Key giả (sai secret) ───
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('TRƯỜNG HỢP 3: Hacker tạo key giả với secret khác');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  const fakeKey = await new SignJWT({ tier: 'free', hwid: null })
    .setProtectedHeader({ alg: 'HS256' })
    .sign(new TextEncoder().encode('hacker-secret-12345')); // sai secret!
  await verifyKey(fakeKey, 'ABC-XYZ-789');

  // ─── TRƯỜNG HỢP 4: Key hết hạn ───
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('TRƯỜNG HỢP 4: Key đã hết hạn');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  const expiredKey = await new SignJWT({
    tier: 'free', hwid: 'ABC-XYZ-789',
    issued: Date.now() - 100000,
    expires: Date.now() / 1000 - 1, // đã hết hạn 1 giây
  })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt(Math.floor((Date.now() - 100000) / 1000))
    .setExpirationTime(Math.floor((Date.now() / 1000) - 1))
    .sign(JWT_SECRET);
  await verifyKey(expiredKey, 'ABC-XYZ-789');

  // ─── TÓM TẮT ───
  console.log('\n╔══════════════════════════════════════════════════╗');
  console.log('║                   TÓM TẮT                       ║');
  console.log('╠══════════════════════════════════════════════════╣');
  console.log('║  GETKEY_SECRET = "con dấu" xác thực key         ║');
  console.log('║                                                  ║');
  console.log('║  ✅ Secret đúng + HWID đúng    → Key hợp lệ    ║');
  console.log('║  ❌ Secret đúng + HWID sai     → Key từ chối   ║');
  console.log('║  ❌ Secret sai  (key giả)      → Key từ chối   ║');
  console.log('║  ❌ Key hết hạn                 → Key từ chối   ║');
  console.log('║                                                  ║');
  console.log('║  ⚠️  Thay secret = mất hết key cũ!              ║');
  console.log('╚══════════════════════════════════════════════════╝');
}

main().catch(console.error);
