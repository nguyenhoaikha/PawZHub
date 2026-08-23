# 🐾 PawZHub v2.0

**Professional Roblox Script Hub** with enterprise-grade authentication system.

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/nguyenhoaikha/PawZHub)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Executors](https://img.shields.io/badge/executors-25+-orange.svg)](SUPPORTED_EXECUTORS.md)
[![Platform](https://img.shields.io/badge/platform-PC%20%7C%20iOS%20%7C%20Android-red.svg)](SUPPORTED_EXECUTORS.md)

---

## ⚡ Quick Start

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main/loader.lua"))()
```

**Test Keys:**
- Free: `PAWZ-FREE-2024-DEMO1` (24h)
- Premium: `PAWZ-PREM-2024-TEST` (30d)
- Lifetime: `PAWZ-LIFE-2024-VIP1` (∞)

---

## 🎯 Features

### 🔐 Authentication
- ✅ **Key-based system** with HWID binding
- ✅ **Multi-tier keys** (Free, Premium, Lifetime)
- ✅ **7-day HWID reset** for lifetime keys
- ✅ **Discord bot redemption** (BananaHub-style)
- ✅ **Session management** (1 hour)
- ✅ **Rate limiting** & blacklist system

### 🚀 Executor Support
- ✅ **25+ executors** auto-detected
- ✅ **PC**: Synapse X, KRNL, Fluxus, Solara, etc.
- ✅ **iOS**: Delta, Flux, Arceus X
- ✅ **Android**: Arceus X, Hydrogen, Fluxus

[View Full List →](SUPPORTED_EXECUTORS.md)

### 🎨 User Interface
- ✅ **macOS-style design** (frosted glass)
- ✅ **Responsive layout** (PC & Mobile)
- ✅ **Touch-optimized** for mobile
- ✅ **Smooth animations** (TweenService)

### 🔒 Security
- ✅ **Advanced HWID** (FNV-1a hash)
- ✅ **Multi-device support** (Premium: 3, Lifetime: unlimited)
- ✅ **Fraud detection** (auto-ban)
- ✅ **Discord webhooks** (logging)
- ✅ **Encrypted sessions**

### 🌐 Backend
- ✅ **REST API** (Node.js + Express)
- ✅ **MongoDB database**
- ✅ **Admin dashboard**
- ✅ **Discord bot** for key management

---

## 📦 System Architecture

```
PawZHub/
├── loader.lua              # Entry point (game detection)
├── checkkey.lua           # Authentication system
├── script/
│   ├── PawZHubBF.lua     # Blox Fruits
│   └── PawZHubGG.lua     # Gunfight Arena
├── backend/
│   ├── server.js         # REST API
│   └── package.json
├── discord-bot/
│   ├── bot.js            # Discord bot
│   ├── generate-licenses.js
│   └── package.json
└── docs/
    ├── SYSTEM.md
    ├── API_GUIDE.md
    ├── HWID_SYSTEM.md
    ├── SUPPORTED_EXECUTORS.md
    ├── KEY_DISTRIBUTION_PLAN.md
    └── FREE_KEYS_SETUP.md
```

---

## 🔑 Key System

### Free Keys (24h)
**3 Link System:**
1. Rekonise → Complete tasks
2. WorkInk → Complete tasks  
3. Loot-Link → Complete tasks
4. Get 24h key

[Setup Guide →](FREE_KEYS_SETUP.md)

### Premium Keys (Lifetime)

**BananaHub-Style:**
1. Purchase license code (8 chars: `a12e137e`)
2. Join Discord server
3. Redeem: `!redeem a12e137e`
4. Receive lifetime key (24 chars: `f03d3260914a9475faf29b12`)
5. Use in script
6. Reset HWID every 7 days: `!resetkey <key>`

**Discord Commands:**
- `!redeem <code>` - Redeem license
- `!mykey` - View your keys
- `!resetkey <key>` - Reset HWID (7 day cooldown)
- `!help` - Show commands

**Admin Commands:**
- `!admin gen <count>` - Generate licenses
- `!admin ban <key>` - Ban key
- `!admin check <code>` - Check status
- `!admin stats` - Statistics

[Discord Bot Guide →](discord-bot/DISCORD_BOT_GUIDE.md)

---

## 🛠️ Installation

### For Users
1. Copy script URL
2. Paste in executor
3. Execute
4. Enter key when prompted

### For Developers

#### Backend API
```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your MongoDB URI
node server.js
```

#### Discord Bot
```bash
cd discord-bot
npm install
cp .env.example .env
# Edit .env with bot token
node bot.js
```

[Full Setup Guide →](SYSTEM.md)

---

## 📊 Key Tiers

| Tier | Duration | Devices | HWID Reset | Price | Get Method |
|------|----------|---------|------------|-------|------------|
| **Free** | 24h | 1 | ❌ | Free | 3 Links |
| **Lifetime** | Forever | Unlimited | ✅ (7 days) | $5-20 | Purchase + Discord |

---

## 🎮 Supported Games

| Game | Place ID | Status | Features |
|------|----------|--------|----------|
| **Blox Fruits** | 2753915549 | ✅ | Auto-farm, ESP, TP |
| **Gunfight Arena** | 4866604015 | ✅ | Aimbot, ESP, Speed |

*More games coming soon!*

---

## 📡 API Endpoints

### Public
```http
POST /api/verify          # Verify key + HWID
GET  /api/getkey          # Generate free key (after 3 links)
GET  /api/blacklist       # Get banned users
GET  /api/version         # Check version
```

### Admin (Bearer Token)
```http
GET  /admin/keys          # List all keys
POST /admin/ban           # Ban key
POST /admin/generate      # Generate premium key
GET  /admin/stats         # Statistics
```

[API Documentation →](API_GUIDE.md)

---

## 🔒 Security Features

### HWID System
- **Fingerprinting**: Roblox Client ID + User ID + Platform + Device
- **Algorithm**: FNV-1a hash (16-char hex)
- **Binding**: Auto-bind on first use
- **Reset**: 7-day cooldown for lifetime keys

[HWID Documentation →](HWID_SYSTEM.md)

### Rate Limiting
- 10 requests per 15 minutes per IP
- 3 failed attempts → 5 minute lockout
- Webhook alerts for suspicious activity

### Fraud Detection
- Auto-ban if key used on 4+ HWIDs in 1 hour
- Blacklist system (users, IPs)
- Discord webhook notifications

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [SYSTEM.md](SYSTEM.md) | Complete system overview |
| [API_GUIDE.md](API_GUIDE.md) | API endpoints & integration |
| [HWID_SYSTEM.md](HWID_SYSTEM.md) | HWID binding & reset system |
| [SUPPORTED_EXECUTORS.md](SUPPORTED_EXECUTORS.md) | All supported executors |
| [KEY_DISTRIBUTION_PLAN.md](KEY_DISTRIBUTION_PLAN.md) | Monetization strategy |
| [FREE_KEYS_SETUP.md](FREE_KEYS_SETUP.md) | Free key 3-link setup |
| [discord-bot/DISCORD_BOT_GUIDE.md](discord-bot/DISCORD_BOT_GUIDE.md) | Discord bot complete guide |

---

## 💰 Revenue Model

### Monthly (Conservative)
- **Free keys** (Linkvertise): $150
- **Lifetime sales** (20/month): $400
- **Total**: ~$550/month

### Yearly (Optimistic)
- **$2,000-3,000/month** passive income after scaling

[Full Monetization Plan →](KEY_DISTRIBUTION_PLAN.md)

---

## 🤖 Discord Bot Setup

```bash
# 1. Install dependencies
cd discord-bot
npm install

# 2. Configure
cp .env.example .env
# Add bot token & MongoDB URI

# 3. Start bot
npm start

# 4. Generate licenses (admin)
node generate-licenses.js 10
```

**Commands:**
- User: `!redeem`, `!mykey`, `!resetkey`
- Admin: `!admin gen`, `!admin ban`, `!admin stats`

[Complete Bot Guide →](discord-bot/DISCORD_BOT_GUIDE.md)

---

## 🎯 Roadmap

### v2.1 (Next)
- [ ] More game support (Adopt Me, Pet Sim, etc.)
- [ ] Web dashboard for key management
- [ ] Stripe integration for automated payments
- [ ] Referral system (15% off)

### v3.0 (Future)
- [ ] Mobile app (key management)
- [ ] Advanced analytics dashboard
- [ ] Multi-language support
- [ ] Custom scripts per game

---

## 📞 Support

- **GitHub Issues**: Bug reports & suggestions
- **Discord**: [Join Server](#) (coming soon)
- **Email**: support@pawzhub.com (coming soon)

---

## 📜 License

MIT License - Free to use, modify, and distribute.

```
Copyright (c) 2024 PawZHub

Permission is hereby granted, free of charge, to any person obtaining a copy...
```

---

## 🏆 Credits

**Inspired by:**
- BananaHub (license redemption system)
- Delta (iOS executor)
- Solara (PC executor)
- Arceus X (Android executor)

**Technologies:**
- Lua (Roblox scripting)
- Node.js + Express (Backend)
- MongoDB (Database)
- Discord.js (Bot)

---

## 🌟 Star History

Give us a ⭐ if you like this project!

---

## 📊 Statistics

- ✅ **25+** supported executors
- ✅ **3** platforms (PC, iOS, Android)
- ✅ **2** supported games (more coming)
- ✅ **1000+** lines of code
- ✅ **100%** open source

---

**Made with ❤️ by PawZHub Team**

🐾 *The most advanced Roblox script hub with enterprise-grade security*

[⬆ Back to Top](#-pawzhub-v20)
