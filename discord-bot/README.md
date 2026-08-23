# 🤖 PawZHub Discord Bot

Discord bot for license redemption system (BananaHub-style).

## 📋 Features

- ✅ Redeem license codes → Get lifetime keys
- ✅ View your keys with `!mykey`
- ✅ Reset HWID every 7 days
- ✅ Only license owner can manage keys

## 🚀 Setup

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure Environment
```bash
# Copy .env.example to .env
cp .env.example .env

# Edit .env with your values
```

### 3. Create Discord Bot
1. Go to https://discord.com/developers/applications
2. Click "New Application"
3. Go to "Bot" tab → Click "Add Bot"
4. Copy Bot Token → Paste in `.env`
5. Enable "Message Content Intent"
6. Go to "OAuth2" → "URL Generator"
   - Scopes: `bot`
   - Permissions: `Send Messages`, `Read Messages`, `Send Messages in Threads`
7. Copy URL and invite bot to your server

### 4. Start Bot
```bash
npm start
```

## 📝 Commands

### User Commands:

| Command | Description | Example |
|---------|-------------|---------|
| `!redeem <code>` | Redeem license code | `!redeem a12e137e` |
| `!mykey` | View your lifetime keys | `!mykey` |
| `!resetkey <key>` | Reset HWID (7 days cooldown) | `!resetkey f03d3260914a9475faf29b12` |
| `!help` | Show help message | `!help` |

### Admin Commands:

| Command | Description | Example |
|---------|-------------|---------|
| `!admin gen <count>` | Generate license codes (1-100) | `!admin gen 10` |
| `!admin ban <key>` | Ban a lifetime key | `!admin ban f03d3260914a9475faf29b12` |
| `!admin unban <key>` | Unban a lifetime key | `!admin unban f03d3260914a9475faf29b12` |
| `!admin check <code\|key>` | Check license or key status | `!admin check a12e137e` |
| `!admin stats` | Show system statistics | `!admin stats` |
| `!admin help` | Show admin commands | `!admin help` |

**Note**: Admin commands require Administrator permission or "Admin" / "PawZHub Admin" role.

## 🔑 How It Works

### Flow:
```
User buys license → Gets code (a12e137e)
    ↓
User: !redeem a12e137e
    ↓
Bot: Generates lifetime key (f03d3260914a9475faf29b12)
    ↓
Bot: Sends key via DM
    ↓
User enters key in Roblox script
    ↓
Script verifies key with API
    ↓
Key binds to user's HWID
    ↓
After 7 days: User can !resetkey to unbind HWID
```

### License Code Format:
- **8 characters** (hex: 0-9, a-f)
- Example: `a12e137e`, `f3b9c21d`
- Status: `unused` or `redeemed`

### Lifetime Key Format:
- **24 characters** (hex: 0-9, a-f)
- Example: `f03d3260914a9475faf29b12`
- Tied to Discord account
- HWID reset every 7 days

## 🛠️ Admin Tools

### Generate License Codes (Manual)
```javascript
// Run in mongo shell or Node.js
const License = require('./bot').License;

// Generate 10 licenses
for (let i = 0; i < 10; i++) {
    const code = generateLicenseCode();
    await License.create({ code: code });
    console.log('License:', code);
}
```

### Generate License (Script)
Create `generate-licenses.js`:
```javascript
const mongoose = require('mongoose');
require('dotenv').config();

const licenseSchema = new mongoose.Schema({
    code: String,
    status: { type: String, default: 'unused' }
});

const License = mongoose.model('License', licenseSchema);

function generateLicenseCode() {
    const chars = '0123456789abcdef';
    let code = '';
    for (let i = 0; i < 8; i++) {
        code += chars[Math.floor(Math.random() * chars.length)];
    }
    return code;
}

async function generate(count) {
    await mongoose.connect(process.env.MONGODB_URI);
    
    console.log(`Generating ${count} licenses...`);
    
    for (let i = 0; i < count; i++) {
        const code = generateLicenseCode();
        await License.create({ code: code });
        console.log(`${i+1}. ${code}`);
    }
    
    console.log('Done!');
    process.exit(0);
}

generate(10); // Generate 10 licenses
```

Run:
```bash
node generate-licenses.js
```

## 📊 Database Schema

### Licenses Collection:
```javascript
{
    code: "a12e137e",              // 8 chars hex
    status: "unused",              // unused | redeemed
    redeemedBy: null,              // Discord ID
    redeemedAt: null,              // Date
    generatedKey: null             // Lifetime key
}
```

### Lifetime Keys Collection:
```javascript
{
    key: "f03d3260914a9475faf29b12",  // 24 chars hex
    licenseCode: "a12e137e",           // Reference
    discordId: "123456789",            // Owner
    discordTag: "User#1234",
    boundHWIDs: [],                    // Array of HWIDs
    lastHWIDReset: null,
    nextResetAvailable: Date,          // 7 days from last reset
    totalUses: 0,
    status: "active"                   // active | banned
}
```

## 🔒 Security

- ✅ Only license owner (Discord account) can manage keys
- ✅ HWID reset has 7-day cooldown
- ✅ License codes can only be redeemed once
- ✅ Keys sent via DM (private)
- ✅ Database stores all redemptions

## 📞 Support

- **GitHub**: https://github.com/nguyenhoaikha/PawZHub
- **Discord**: [Your Server]

---

Made with ❤️ by PawZHub Team
