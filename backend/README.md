# PawZHub Backend (Optional)

Backend Express server tùy chọn cho PawZHub. **Không bắt buộc** — hầu hết logic API nằm ở `web/` (Next.js + Vercel).

## Khi nào cần Backend này?

1. **Webhook Receivers**: Nhận webhook từ Stripe/PayPal để verify payment (thay vì dùng Vercel serverless)
2. **Self-hosting**: Muốn tự host toàn bộ hệ thống thay vì Vercel
3. **Background Jobs**: Cần chạy scheduled tasks hoặc workers

## Setup

```bash
cd backend
npm install
cp .env.example .env
# Edit .env với giá trị thật
npm run dev
```

Server chạy tại `http://localhost:3001`

## Endpoints

- `GET /health` — Health check
- `GET /success` — Payment success page (redirect từ PayPal/Stripe)
- `POST /webhooks/stripe` — Stripe webhook receiver (placeholder)
- `POST /webhooks/paypal` — PayPal webhook receiver (placeholder)

## Production Deploy

Backend này có thể deploy lên:
- Railway: `railway up`
- Heroku: `git push heroku main`
- VPS: PM2 hoặc systemd service

**Lưu ý**: Nếu bạn dùng Vercel cho web, không cần deploy backend riêng trừ khi muốn webhook processors độc lập.
