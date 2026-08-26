# Work.ink Destination URL — Setup Guide

Bạn đã có 2 link Work.ink:
- `https://work.ink/2TBg/pawzhub-cp1`  → checkpoint 1
- `https://work.ink/2TBg/pawzhub-cp2`  → checkpoint 2

Để hệ thống ghi nhận user đã hoàn thành checkpoint, mỗi link cần một **destination URL** chứa `{TOKEN}` (token do Work.ink tự sinh, single-use).

---

## Bước 1 — Vào Work.ink Publisher Dashboard

Truy cập: <https://work.ink/publisher/dashboard> → đăng nhập.

## Bước 2 — Chỉnh sửa link **pawzhub-cp1**

1. Trong danh sách **Links**, tìm link có shortcode `pawzhub-cp1`.
2. Click **Edit** (hoặc icon bút).
3. Tại mục **Destination URL**, paste chính xác:
   ```
   https://getpawzhub.vercel.app/getkey/callback/workink?token={TOKEN}&step=1
   ```
   - Phải có chữ `{TOKEN}` (viết hoa, trong ngoặc nhọn) — Work.ink sẽ tự thay bằng token thật khi redirect.
   - `step=1` để đánh dấu đây là checkpoint 1.
4. Bật **Key System** (nếu có toggle) hoặc đảm bảo **On Click URL** chỉ dùng destination ở trên.
5. **Save**.

## Bước 3 — Chỉnh sửa link **pawzhub-cp2**

Làm tương tự với `pawzhub-cp2`:
```
https://getpawzhub.vercel.app/getkey/callback/workink?token={TOKEN}&step=2
```
- `step=2` để đánh dấu đây là checkpoint 2.

## Bước 4 — Kiểm tra

1. Mở <https://getpawzhub.vercel.app/getkey> trong trình duyệt.
2. Click card **Work.ink** → **Start Checkpoint** (bước 1).
3. Hoàn thành các bước Work.ink yêu cầu (xem ads / app install / survey).
4. Work.ink redirect về trang callback trên site của bạn.
5. Trang callback báo "✅ Work.ink Verified!" và tự đóng tab sau 2s.
6. Quay lại modal — step 1 đã tick ✓.
7. Lặp lại với checkpoint 2.
8. Click **Get Key** → nhận JWT key.

---

## Lỗi thường gặp

| Lỗi | Nguyên nhân | Cách fix |
|------|-------------|----------|
| Callback báo "No token provided" | Destination URL thiếu `{TOKEN}` | Thêm `{TOKEN}` vào Destination URL rồi Save lại |
| Callback báo "Work.ink token verification failed" | Work.ink token đã bị consume (refresh trang, mở lại) | Hoàn thành lại checkpoint từ đầu |
| Step 1/2 không tick dù đã complete | Modal không nhận được postMessage | Modal tự polling mỗi 2s — chờ thêm vài giây |
| Work.ink link trả về 404 | Shortcode `2TBg` sai hoặc link đã bị xoá | Kiểm tra shortcode trong dashboard |

## Lưu ý kỹ thuật

- Work.ink dùng `?deleteToken=1` khi gọi API verify → token chỉ dùng được **1 lần**. Nếu user F5 callback page, token sẽ bị xoá.
- Callback page (web) chỉ gọi API verify Work.ink **một lần**. Nếu user mở lại callback URL, sẽ thấy "token verification failed" → họ cần quay lại trang chính và bắt đầu lại.
- Domain production: `getpawzhub.vercel.app`. Nếu bạn dùng custom domain, đổi URL trên cho khớp.
