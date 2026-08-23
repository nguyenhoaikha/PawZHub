# 🐾 PawZHub System Documentation

Complete documentation for PawZHub v2.0 - Advanced Key Authentication System

## 📚 Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Architecture](#architecture)
4. [Executor Support](#executor-support)
5. [Getting Started](#getting-started)
6. [API Documentation](#api-documentation)
7. [Security](#security)
8. [FAQ](#faq)

---

## 🎯 Overview

**PawZHub** is a professional Roblox script hub with enterprise-grade key authentication, HWID binding, and universal executor support.

### Key Stats
- **Version**: 2.0.0
- **Supported Executors**: 25+
- **Platforms**: PC, iOS, Android
- **Supported Games**: 2+ (expandable)
- **Security Level**: ⭐⭐⭐⭐⭐

### Entry Point
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main/loader.lua"))()
```

---

## ✨ Features

### 🔐 Authentication System
- ✅ **Key-based authentication** (PAWZ-XXXX-XXXX-XXXX format)
- ✅ **HWID binding** - Keys bound to specific devices
- ✅ **Multi-tier keys** (Free, Premium, Lifetime)
- ✅ **Session management** - 1 hour sessions
- ✅ **Rate limiting** - Anti-spam protection
- ✅ **Blacklist system** - Ban users/IPs
- ✅ **Webhook logging** - Discord notifications
- ✅ **Offline mode** - Fallback keys when server down

### 🎨 User Interface
- ✅ **macOS-style design** - Frosted glass, traffic lights
- ✅ **Responsive layout** - Adapts to PC/Mobile
- ✅ **Touch-optimized** - Perfect for iOS/Android
- ✅ **Smooth animations** - TweenService powered
- ✅ **No full-screen black** - Subtle backdrop blur
- ✅ **Clean notifications** - In-game toast messages

### 🚀 Executor Support
- ✅ **Auto-detection** - Identifies your executor automatically
- ✅ **25+ executors** - Synapse, KRNL, Delta, Arceus, etc.
- ✅ **Cross-platform** - PC, iOS, Android
- ✅ **Platform-specific optimizations** - Mobile UI adapts

### 🔒 Security Features
- ✅ **Advanced HWID** - Multi-factor fingerprinting (FNV-1a hash)
- ✅ **HWID reset system** - 30-day cooldown, 3 max resets
- ✅ **Multi-device support** - Premium keys work on 3+ devices
- ✅ **Fraud detection** - Auto-ban suspicious activity
- ✅ **Encrypted sessions** - Token-based authentication
- ✅ **IP logging** - Track usage patterns
- ✅ **Analytics** - Success rate, failed attempts

### 🌐 Backend API
- ✅ **RESTful API** - Node.js + Express + MongoDB
- ✅ **Key generation** - Automatic via Linkvertise integration
- ✅ **Key verification** - Real-time validation
- ✅ **Admin dashboard** - Manage keys, users, bans
- ✅ **Webhook integration** - Discord notifications
- ✅ **Rate limiting** - 10 requests per 15 minutes
- ✅ **Blacklist API** - Dynamic user blocking

---

## 🏗️ Architecture

### File Structure
```
PawZHub/
├── loader.lua              # Entry point (game detection)
├── checkkey.lua           # Key authentication system
├── script/
│   ├── PawZHubBF.lua     # Blox Fruits script
│   └── PawZHubGG.lua     # Gunfight Arena script
├── backend/
│   ├── server.js         # Node.js API server
│   └── package.json      # Dependencies
└── docs/
    ├── API_GUIDE.md      # Key generation flow
    ├── HWID_SYSTEM.md    # HWID documentation
    ├── SUPPORTED_EXECUTORS.md  # Executor list
    └── SYSTEM.md         # This file
```

### Execution Flow
```
User loads script
    ↓
Detect executor & game
    ↓
Load checkkey.lua
    ↓
Show key UI
    ↓
User enters key
    ↓
Verify with API (+ HWID check)
    ↓
Create session (1 hour)
    ↓
Load game-specific script
    ↓
User uses script features
```

### Session Flow
```
Key Verified → Token Generated → Session Created (1h) → Script Loaded
                                      ↓
                            Check HWID every action
                                      ↓
                            Session expires → Re-authenticate
```

---

## 🚀 Executor Support

### 🖥️ PC Executors (Windows)

**Tier 1 (Premium)**
- ✅ Synapse X
- ✅ Script-Ware

**Tier 2 (Free - Full Support)**
- ✅ KRNL
- ✅ Fluxus
- ✅ Oxygen U
- ✅ Solara
- ✅ Electron
- ✅ Evon
- ✅ Trigon
- ✅ Wave
- ✅ Nezur

**Tier 3 (Basic)**
- ⚠️ JJSploit (Limited features)

### 📱 iOS/iPadOS Executors

- ✅ **Delta** (Most popular)
- ✅ **Flux**
- ✅ **Arceus X iOS**
- ✅ **Zeus**
- ✅ **EonHub**
- ✅ **Appletouchhook**

### 🤖 Android Executors

- ✅ **Arceus X** (Industry standard)
- ✅ **Hydrogen**
- ✅ **Fluxus Android**
- ✅ **Delta Android**
- ✅ **CodeX**
- ✅ **Valyse**

**See [SUPPORTED_EXECUTORS.md](SUPPORTED_EXECUTORS.md) for complete list**

---

## 🎮 Getting Started

### For Users

#### 1. Get a Key
```
Method 1: Linkvertise (Free)
- Click "Get Key" button in UI
- Complete ad tasks
- Receive 24-hour key

Method 2: Discord (Premium)
- Join Discord server
- Purchase premium key
- Receive via DM

Method 3: Website (Lifetime)
- Visit website
- Purchase lifetime key
- Email delivery
```

#### 2. Load Script
```lua
-- Open your executor
-- Paste this code:
loadstring(game:HttpGet("https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main/loader.lua"))()

-- Press Execute
```

#### 3. Enter Key
```
- Key UI will appear
- Enter your key: PAWZ-XXXX-XXXX-XXXX
- Click "Submit"
- Wait for verification
- Script loads automatically!
```

#### 4. Test Keys (For Testing Only)
```lua
PAWZ-FREE-2024-DEMO1  -- Free tier (24h)
PAWZ-PREM-2024-TEST   -- Premium tier (30d)
PAWZ-LIFE-2024-VIP1   -- Lifetime tier (∞)
```

### For Developers

#### Setup Backend
```bash
# Install dependencies
cd backend
npm install

# Configure environment
echo "MONGODB_URI=mongodb://localhost:27017/pawzhub" > .env
echo "DISCORD_WEBHOOK_URL=your_webhook_url" >> .env
echo "ADMIN_TOKEN=your_secret_token" >> .env

# Start server
node server.js
```

#### Add New Game
```lua
-- In loader.lua, add to SUPPORTED_GAMES:
[YOUR_PLACE_ID] = {
    name = "Game Name",
    script = "YourScript.lua",
    displayName = "🎮 Game Name"
}

-- Create script/YourScript.lua with your game logic
```

#### Customize UI
```lua
-- In checkkey.lua, modify createKeyUI() function
-- Change colors, sizes, animations, etc.
```

---

## 📡 API Documentation

### Public Endpoints

#### Generate Key
```http
GET /api/getkey?user={userId}&hwid={hwid}
```
**Response:**
```json
{
    "success": true,
    "key": "PAWZ-A1B2-C3D4-E5F6",
    "expiresAt": "2024-12-25T12:00:00Z"
}
```

#### Verify Key
```http
POST /api/verify
Content-Type: application/json

{
    "key": "PAWZ-A1B2-C3D4-E5F6",
    "hwid": "ABC123...",
    "userId": "123456789",
    "gameId": "2753915549"
}
```
**Response:**
```json
{
    "valid": true,
    "message": "Key verified",
    "tier": "premium",
    "features": ["basic", "advanced"],
    "expiry": "2024-12-25T12:00:00Z"
}
```

#### Get Blacklist
```http
GET /api/blacklist
```

#### Version Check
```http
GET /api/version
```

### Admin Endpoints (Require Bearer Token)

```http
GET  /admin/keys              # List all keys
POST /admin/ban               # Ban a key
POST /admin/blacklist         # Add user to blacklist
POST /admin/generate          # Generate premium key
GET  /admin/stats             # Get statistics
GET  /admin/hwid/stats        # HWID analytics
```

**See [API_GUIDE.md](API_GUIDE.md) for detailed API documentation**

---

## 🔒 Security

### HWID System

**How it works:**
```lua
-- Generate HWID from multiple factors
HWID = Hash(
    Roblox Client ID +
    User ID + Account Age +
    Platform (PC/Mobile) +
    Device fingerprint
)

-- Format: 16-character hex (e.g., A1B2C3D4E5F6G7H8)
```

**Binding:**
1. First use: Key binds to HWID
2. Subsequent uses: HWID must match
3. Mismatch: Access denied + webhook alert

**Multi-Device (Premium):**
- Free keys: 1 device
- Premium keys: 3 devices
- Lifetime keys: 5 devices

**Reset System:**
- Cooldown: 30 days
- Max resets: 3 lifetime
- Manual reset: Admin only

**See [HWID_SYSTEM.md](HWID_SYSTEM.md) for complete documentation**

### Key Tiers

| Tier | Duration | Max Uses | Devices | Features | Price |
|------|----------|----------|---------|----------|-------|
| **Free** | 24h | 1 | 1 | Basic | Free (Linkvertise) |
| **Premium** | 30d | Unlimited | 3 | Basic + Advanced | $5/month |
| **Lifetime** | ∞ | Unlimited | 5 | All features | $20 one-time |

### Rate Limiting
- **Key verification**: 10 requests per 15 minutes
- **Lockout**: 3 failed attempts → 5-minute ban
- **Session refresh**: Every 1 hour

### Fraud Detection
```javascript
// Auto-ban if:
- Key used on 4+ different HWIDs in 1 hour
- 10+ failed login attempts
- Rapid key generation (>5 keys/hour)
- Blacklisted user attempts access
```

---

## ❓ FAQ

### General

**Q: Is PawZHub free?**
A: Yes! Free keys available via Linkvertise. Premium keys for advanced features.

**Q: Which executors are supported?**
A: 25+ executors on PC, iOS, Android. See [SUPPORTED_EXECUTORS.md](SUPPORTED_EXECUTORS.md)

**Q: Can I use on multiple devices?**
A: Free keys: 1 device. Premium: 3 devices. Lifetime: 5 devices.

**Q: How long do keys last?**
A: Free: 24 hours. Premium: 30 days. Lifetime: Forever.

**Q: Is it detected by Roblox?**
A: No executor is 100% undetected. Use at your own risk.

### Technical

**Q: What is HWID?**
A: Hardware ID - unique identifier for your device. Prevents key sharing.

**Q: Can I reset my HWID?**
A: Yes, once every 30 days (max 3 times). Contact admin for manual reset.

**Q: API is down, can I still use?**
A: Yes! Offline mode with fallback keys (test keys only).

**Q: How do I add new games?**
A: Edit `loader.lua` and add your PlaceId + script file.

**Q: Can I customize the UI?**
A: Yes! Edit `checkkey.lua` - modify colors, sizes, animations.

**Q: How secure is the system?**
A: Enterprise-grade: HWID binding, encryption, rate limiting, fraud detection.

### Troubleshooting

**Q: "Key is bound to another device"**
A: Your key is locked to different HWID. Request reset or use on original device.

**Q: "Too many failed attempts"**
A: Wait 5 minutes or contact admin to unlock.

**Q: "Game not supported"**
A: PlaceId not in supported games list. Request support or add yourself.

**Q: "Executor not detected"**
A: Script works anyway! Shows as "Unknown Executor" - full functionality.

**Q: UI not showing?**
A: Check console (F9) for errors. Ensure HTTP requests enabled.

---

## 📞 Support

### Links
- **GitHub**: https://github.com/nguyenhoaikha/PawZHub
- **Discord**: [Join Server](#) (coming soon)
- **Website**: [Visit Site](#) (coming soon)

### Contact
- **GitHub Issues**: Report bugs/suggestions
- **Discord DMs**: Quick support
- **Email**: support@pawzhub.com (coming soon)

---

## 📜 License

**MIT License** - Free to use, modify, and distribute

```
Copyright (c) 2024 PawZHub

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files...
```

---

## 🎉 Credits

**Developed by**: PawZHub Team
**Contributors**: Open source community
**Inspired by**: Delta, Solara, Arceus X

**Special Thanks**:
- Roblox community
- Executor developers
- Beta testers
- Open source contributors

---

## 🔄 Changelog

### v2.0.0 (Current)
- ✅ Universal executor support (25+ executors)
- ✅ Advanced HWID system with multi-device
- ✅ macOS-style UI with animations
- ✅ Mobile-responsive layout
- ✅ Backend API (Node.js + MongoDB)
- ✅ Admin dashboard
- ✅ Fraud detection
- ✅ Discord webhooks
- ✅ Complete documentation

### v1.0.0
- Basic key system
- Simple UI
- 2 supported games

---

**Made with ❤️ by PawZHub Team**

🐾 *The most advanced Roblox script hub with enterprise-grade security*
