# 🎨 Dashboard Management System

## Tổng Quan

Dashboard quản lý toàn diện cho hệ thống key PawZHub với giao diện hiện đại, sử dụng cùng màu sắc và phong cách thiết kế như website chính.

## ✨ Tính Năng Chính

### 1. **Tổng Quan (Overview)**
- 📊 Thống kê tổng quan hệ thống
  - Tổng số key
  - Key hoạt động
  - Key miễn phí
  - Key premium
  - Key được tạo hôm nay
  - Doanh thu
- 🎯 Quick Actions - Thao tác nhanh
  - Generate Premium Keys
  - Blacklist Manager
  - Usage Analytics
  - System Settings

### 2. **Quản Lý Key (Keys Management)**
- 🔍 Tìm kiếm nâng cao
  - Tìm theo key
  - Tìm theo email
  - Tìm theo Discord
- 🎛️ Bộ lọc thông minh
  - Lọc theo loại (Free/Premium)
  - Lọc theo trạng thái (Active/Expired/Revoked)
- 📋 Bảng quản lý chi tiết
  - Hiển thị thông tin key đầy đủ
  - Thông tin người dùng
  - Lịch sử sử dụng
  - Thao tác nhanh (Xem/Sửa/Xóa)
- ✅ Bulk Actions
  - Chọn nhiều key cùng lúc
  - Thao tác hàng loạt

### 3. **Phân Tích (Analytics)**
- 📈 Biểu đồ thống kê
  - Key Generation Trend - Xu hướng tạo key
  - Key Type Distribution - Phân bố loại key
  - Active vs Expired Keys - So sánh key hoạt động vs hết hạn
  - Revenue Growth - Tăng trưởng doanh thu
- ⏱️ Chọn khoảng thời gian
  - 7 ngày
  - 30 ngày
  - 90 ngày
  - Tất cả
- 📝 Hoạt động gần đây
  - Real-time activity feed
  - Thông báo key mới
  - Thông báo key hết hạn
  - Yêu cầu HWID reset

### 4. **Cài Đặt (Settings)**
- ⚙️ Cấu hình hệ thống key
  - Free Key Duration
  - Premium Monthly Duration
  - Rate Limiting
  - HWID Reset Cooldown
- 🔗 Webhook Configuration
  - Discord Webhook URL
  - Enable Premium Key Notifications
  - Enable HWID Reset Notifications
- 🔒 Security Settings
  - Enable IP Logging
  - Auto-Revoke Suspicious Keys
  - Require Email Verification

## 🎨 Thiết Kế & Giao Diện

### Màu Sắc Chính
```css
--bg: #000                          /* Nền chính */
--surface: rgba(255,255,255,0.03)   /* Nền card */
--surface2: rgba(255,255,255,0.05)  /* Nền hover */
--border: rgba(255,255,255,0.08)    /* Viền */
--border2: rgba(255,255,255,0.12)   /* Viền hover */
--white: #fff                       /* Text chính */
--gray: #a3a3a3                     /* Text phụ */
--muted: #525252                    /* Text mờ */
```

### Badge Colors
- 🆓 **Free Keys**: Green (#4ade80)
- 💎 **Premium Keys**: Purple (#c084fc)
- ✅ **Active**: Green (#4ade80)
- ⏰ **Expired**: Orange (#fb923c)
- 🚫 **Revoked**: Red (#f87171)

### Hiệu Ứng
- Smooth transitions (0.2s - 0.3s)
- Hover effects với transform
- Fade-in animations
- Border glow effects

## 📂 Cấu Trúc File

```
web/src/app/dashboard/
├── page.tsx           # Main dashboard component
├── dashboard.css      # Dashboard styling
└── (components)       # Tab components (embedded)
    ├── OverviewTab
    ├── KeysTab
    ├── AnalyticsTab
    └── SettingsTab
```

## 🚀 Sử Dụng

### Truy Cập Dashboard
```
http://localhost:3000/dashboard
```

### Navigation
- Click vào các tab để chuyển đổi giữa các phần
- Sử dụng search và filters để tìm kiếm keys
- Click vào action buttons để thực hiện thao tác

## 📊 Data Structure

### KeyData Interface
```typescript
interface KeyData {
  id: string;              // Unique identifier
  key: string;             // Key string (e.g., "PH.ABC123DEF456")
  type: 'free' | 'premium'; // Key type
  plan?: 'trial' | 'monthly' | 'lifetime'; // Premium plan
  status: 'active' | 'expired' | 'revoked'; // Key status
  hwid?: string;           // Hardware ID
  email?: string;          // User email
  discord?: string;        // Discord username
  roblox?: string;         // Roblox username
  createdAt: string;       // Creation timestamp
  expiresAt?: string;      // Expiration timestamp
  lastUsed?: string;       // Last usage timestamp
  usageCount: number;      // Total usage count
}
```

### DashboardStats Interface
```typescript
interface DashboardStats {
  totalKeys: number;       // Total number of keys
  activeKeys: number;      // Active keys count
  expiredKeys: number;     // Expired keys count
  freeKeys: number;        // Free keys count
  premiumKeys: number;     // Premium keys count
  todayGenerated: number;  // Keys generated today
  revenue: number;         // Total revenue
}
```

## 🔄 Next Steps

### Tích Hợp API
1. Kết nối với database thực
2. Fetch keys từ API
3. Real-time updates với WebSocket
4. Implement bulk actions

### Tính Năng Mở Rộng
1. Export data (CSV, JSON)
2. Advanced filtering
3. Key generation wizard
4. Email notifications
5. Activity logs
6. User management
7. Role-based access control

### Analytics Nâng Cao
1. Interactive charts với Chart.js
2. Custom date ranges
3. Comparison views
4. Conversion tracking
5. Revenue forecasting

## 💡 Tips

### Performance
- Pagination cho bảng keys
- Virtual scrolling cho danh sách lớn
- Debounce cho search input
- Cache API responses

### Security
- Protect dashboard route với authentication
- Rate limiting cho API calls
- Input validation
- XSS protection

### UX Improvements
- Loading states
- Error handling
- Success notifications
- Confirmation modals
- Keyboard shortcuts

## 📝 Mock Data

Dashboard hiện đang sử dụng mock data để demo. Thay thế bằng API calls thực:

```typescript
// Thay thế mock data
const MOCK_STATS = { ... };
const MOCK_KEYS = [ ... ];

// Với API calls
useEffect(() => {
  fetchStats().then(setStats);
  fetchKeys().then(setKeys);
}, []);
```

## 🎯 Hoàn Thành

✅ Dashboard layout với 4 tabs
✅ Overview tab với stats cards
✅ Keys management với table
✅ Analytics với charts
✅ Settings với configurations
✅ Responsive design
✅ Consistent styling với website
✅ Smooth animations
✅ Search & filters
✅ Mock data structure

---

**Dashboard sẵn sàng sử dụng! Truy cập `/dashboard` để xem.**
