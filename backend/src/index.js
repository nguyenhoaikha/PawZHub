/**
 * PawZHub Backend — Express server (optional)
 *
 * Chức năng chính:
 *   - Nhận webhook từ Stripe / PayPal (verify và notify)
 *   - Serve trang success.html cho payment redirect
 *   - Health check endpoint
 *
 * Hầu hết logic API nằm ở web/ (Next.js + Vercel).
 * Server này chỉ cần nếu bạn muốn:
 *   1) Nhận webhook payment processor ngoài Vercel
 *   2) Chạy background jobs
 *   3) Self-host thay vì Vercel
 *
 * Setup:
 *   cp .env.example .env
 *   npm install
 *   npm run dev
 */

require('dotenv').config();
const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3001;

// ── Middleware ──────────────────────────────────────────────────
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// CORS — chỉ allow từ web Vercel hoặc localhost dev
app.use((req, res, next) => {
  const allowed = [
    process.env.DOMAIN || 'https://getpawzhub.vercel.app',
    'http://localhost:3000',
  ];
  const origin = req.headers.origin || '';
  if (allowed.includes(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type,Authorization');
  }
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
});

// ── Static files ─────────────────────────────────────────────────
app.use(express.static(path.join(__dirname, '..', 'public')));

// ── Health check ─────────────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'PawZHub Backend',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

// ── Payment success redirect ──────────────────────────────────────
// PayPal / Stripe redirect người dùng về đây sau khi thanh toán xong.
// Trang này hiển thị thông báo thành công và hướng dẫn check Discord DM.
app.get('/success', (req, res) => {
  res.sendFile(path.join(__dirname, '..', 'public', 'success.html'));
});

// ── Stripe webhook (placeholder) ─────────────────────────────────
app.post('/webhooks/stripe', (req, res) => {
  // TODO: Verify Stripe signature với STRIPE_WEBHOOK_SECRET
  // const sig = req.headers['stripe-signature'];
  // const event = stripe.webhooks.constructEvent(req.rawBody, sig, process.env.STRIPE_WEBHOOK_SECRET);
  //
  // switch (event.type) {
  //   case 'payment_intent.succeeded':
  //     // Forward lên Web API hoặc xử lý trực tiếp
  //     break;
  // }
  console.log('[Stripe Webhook] Received event:', req.body?.type || 'unknown');
  res.json({ received: true });
});

// ── PayPal webhook (placeholder) ──────────────────────────────────
app.post('/webhooks/paypal', (req, res) => {
  // TODO: Verify PayPal signature
  console.log('[PayPal Webhook] Received event:', req.body?.event_type || 'unknown');
  res.json({ received: true });
});

// ── 404 fallback ─────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// ── Start server ─────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`[PawZHub Backend] Running on port ${PORT}`);
  console.log(`[PawZHub Backend] Domain: ${process.env.DOMAIN || 'not set'}`);
});

module.exports = app;
