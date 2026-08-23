# PawZHub API & Key System Guide

## 🔑 Key Generation Flow (Linkvertise Style)

### Architecture Overview
```
User → Get Key Button → Linkvertise → Complete Tasks → Key Generator API → Unique Key → User
```

### Step-by-Step Process

#### 1. User clicks "Get Key"
```lua
-- In checkkey.lua
getKeyBtn.MouseButton1Click:Connect(function()
    local keyUrl = "https://your-linkvertise.com/12345"
    setclipboard(keyUrl)
    -- Opens browser to linkvertise
end)
```

#### 2. Linkvertise redirects to Key Generator
```
https://linkvertise.com/12345 
    ↓ (after completing ads)
https://your-website.com/getkey?user=<userid>&hwid=<hwid>
```

#### 3. Key Generator API (Backend)
```javascript
// Node.js Example
app.get('/getkey', async (req, res) => {
    const { user, hwid } = req.query;
    
    // Check if user already has active key
    const existing = await db.keys.findOne({ 
        userId: user, 
        expiresAt: { $gt: Date.now() } 
    });
    
    if (existing) {
        return res.json({ 
            success: true, 
            key: existing.key,
            message: "You already have an active key" 
        });
    }
    
    // Generate new key
    const key = generateKey(); // PAWZ-XXXX-XXXX-XXXX
    
    // Store in database
    await db.keys.create({
        key: key,
        userId: user,
        hwid: hwid,
        tier: 'free',
        createdAt: Date.now(),
        expiresAt: Date.now() + (24 * 60 * 60 * 1000), // 24 hours
        uses: 0,
        maxUses: 1
    });
    
    res.json({ 
        success: true, 
        key: key,
        expiresIn: "24 hours"
    });
});
```

#### 4. Key Verification API
```javascript
app.post('/verify', async (req, res) => {
    const { key, hwid, userId, gameId } = req.body;
    
    // Find key in database
    const keyData = await db.keys.findOne({ key: key });
    
    if (!keyData) {
        return res.json({ 
            valid: false, 
            message: "Invalid key" 
        });
    }
    
    // Check expiry
    if (Date.now() > keyData.expiresAt) {
        return res.json({ 
            valid: false, 
            message: "Key expired" 
        });
    }
    
    // Check HWID binding
    if (keyData.hwid && keyData.hwid !== hwid) {
        return res.json({ 
            valid: false, 
            message: "Key bound to different device" 
        });
    }
    
    // Check max uses
    if (keyData.uses >= keyData.maxUses) {
        return res.json({ 
            valid: false, 
            message: "Key usage limit reached" 
        });
    }
    
    // Update usage
    await db.keys.updateOne(
        { key: key },
        { 
            $inc: { uses: 1 },
            $set: { 
                lastUsed: Date.now(),
                lastUserId: userId,
                lastGameId: gameId
            }
        }
    );
    
    // Log to Discord
    sendDiscordWebhook({
        title: "✅ Key Used",
        fields: [
            { name: "Key", value: key.substr(0, 10) + "..." },
            { name: "User", value: userId },
            { name: "Tier", value: keyData.tier }
        ]
    });
    
    res.json({ 
        valid: true,
        message: "Key verified",
        tier: keyData.tier,
        features: keyData.features,
        expiry: keyData.expiresAt
    });
});
```

## 🗄️ Database Schema

### MongoDB Example
```javascript
{
    _id: ObjectId("..."),
    key: "PAWZ-A1B2-C3D4-E5F6",
    
    // User Info
    userId: "123456789",
    hwid: "ABCD1234EFGH5678",
    
    // Key Info
    tier: "premium",              // free, premium, lifetime
    features: ["basic", "advanced"],
    
    // Timestamps
    createdAt: 1234567890,
    expiresAt: 1234571490,
    lastUsed: 1234567900,
    
    // Usage Limits
    uses: 1,
    maxUses: 1,                   // -1 for unlimited
    
    // Additional
    lastGameId: "2753915549",
    ipAddress: "1.2.3.4",
    status: "active",             // active, banned, expired
    
    // Metadata
    source: "linkvertise",
    referrer: null,
    notes: ""
}
```

## 🔐 Key Generation Algorithm

### Method 1: Random (Simple)
```javascript
function generateKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let key = 'PAWZ';
    
    for (let i = 0; i < 3; i++) {
        key += '-';
        for (let j = 0; j < 4; j++) {
            key += chars.charAt(Math.floor(Math.random() * chars.length));
        }
    }
    
    return key; // PAWZ-A1B2-C3D4-E5F6
}
```

### Method 2: Hash-based (Secure)
```javascript
const crypto = require('crypto');

function generateKey(userId, timestamp) {
    // Create unique seed
    const seed = `${userId}-${timestamp}-${Math.random()}`;
    
    // Hash it
    const hash = crypto.createHash('sha256').update(seed).digest('hex');
    
    // Format as key
    return `PAWZ-${hash.substr(0,4)}-${hash.substr(4,4)}-${hash.substr(8,4)}`.toUpperCase();
}
```

### Method 3: UUID-based
```javascript
const { v4: uuidv4 } = require('uuid');

function generateKey() {
    const uuid = uuidv4().replace(/-/g, '').toUpperCase();
    return `PAWZ-${uuid.substr(0,4)}-${uuid.substr(4,4)}-${uuid.substr(8,4)}`;
}
```

## 🌐 Complete Integration Example

### Frontend (Website) - Key Display Page
```html
<!DOCTYPE html>
<html>
<head>
    <title>Your Key - PawZHub</title>
    <style>
        body {
            font-family: 'Segoe UI', system-ui;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            text-align: center;
            max-width: 500px;
        }
        .key {
            font-size: 24px;
            font-weight: bold;
            color: #667eea;
            background: #f0f0f0;
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
            font-family: 'Courier New', monospace;
        }
        button {
            background: #667eea;
            color: white;
            border: none;
            padding: 15px 30px;
            border-radius: 10px;
            font-size: 16px;
            cursor: pointer;
            transition: all 0.3s;
        }
        button:hover {
            background: #5568d3;
            transform: translateY(-2px);
        }
        .info {
            margin-top: 20px;
            color: #666;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 Your Key is Ready!</h1>
        <div class="key" id="keyDisplay">Loading...</div>
        <button onclick="copyKey()">📋 Copy Key</button>
        <div class="info">
            <p>✅ Valid for 24 hours</p>
            <p>🔒 Bound to your device</p>
            <p>🎮 Works on all supported games</p>
        </div>
    </div>
    
    <script>
        // Get user ID from URL parameter
        const urlParams = new URLSearchParams(window.location.search);
        const userId = urlParams.get('user');
        const hwid = urlParams.get('hwid');
        
        // Fetch key from API
        fetch(`/api/getkey?user=${userId}&hwid=${hwid}`)
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    document.getElementById('keyDisplay').textContent = data.key;
                } else {
                    document.getElementById('keyDisplay').textContent = 'Error: ' + data.message;
                }
            });
        
        function copyKey() {
            const key = document.getElementById('keyDisplay').textContent;
            navigator.clipboard.writeText(key);
            alert('Key copied to clipboard!');
        }
    </script>
</body>
</html>
```

## 🔗 Linkvertise Integration

### Step 1: Create Linkvertise Account
1. Go to https://linkvertise.com
2. Create account
3. Get API key

### Step 2: Create Shortened Link
```javascript
const axios = require('axios');

async function createLinkvertiseLink(userId, hwid) {
    const response = await axios.post('https://api.linkvertise.com/v1/link', {
        target_url: `https://your-website.com/getkey?user=${userId}&hwid=${hwid}`,
        alias: `pawzhub-${userId}`,
        type: 'dynamic'
    }, {
        headers: {
            'Authorization': 'Bearer YOUR_LINKVERTISE_API_KEY'
        }
    });
    
    return response.data.full_url;
}
```

### Step 3: In Lua Script
```lua
getKeyBtn.MouseButton1Click:Connect(function()
    local HttpService = game:GetService("HttpService")
    local player = game:GetService("Players").LocalPlayer
    
    -- Generate HWID
    local hwid = getHWID()
    
    -- Get linkvertise URL from your API
    local response = HttpService:GetAsync(
        string.format(
            "https://your-api.com/getlink?user=%d&hwid=%s",
            player.UserId,
            hwid
        )
    )
    
    local data = HttpService:JSONDecode(response)
    
    -- Copy to clipboard
    setclipboard(data.link)
    
    -- Notify user
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Get Key",
        Text = "Link copied! Complete tasks to get key",
        Duration = 5
    })
end)
```

## 📊 Advanced Features

### Premium Keys with Purchase
```javascript
// Stripe/PayPal integration
app.post('/purchase', async (req, res) => {
    const { userId, hwid, plan } = req.body;
    
    // Verify payment (Stripe/PayPal)
    const payment = await verifyPayment(req.body.paymentId);
    
    if (!payment.success) {
        return res.json({ success: false, message: "Payment failed" });
    }
    
    // Generate premium key
    const key = generateKey();
    const duration = plan === 'monthly' ? 30 : 365; // days
    
    await db.keys.create({
        key: key,
        userId: userId,
        hwid: hwid,
        tier: plan === 'lifetime' ? 'lifetime' : 'premium',
        expiresAt: plan === 'lifetime' 
            ? null 
            : Date.now() + (duration * 24 * 60 * 60 * 1000),
        maxUses: -1, // Unlimited
        features: ['basic', 'advanced', 'premium'],
        source: 'purchase',
        amount: payment.amount
    });
    
    // Send key via email
    await sendEmail(payment.email, key);
    
    res.json({ success: true, key: key });
});
```

### Discord Bot Key Generation
```javascript
// Discord.js bot
client.on('messageCreate', async (message) => {
    if (message.content === '!getkey') {
        const userId = message.author.id;
        
        // Check if user has role
        if (!message.member.roles.cache.has('PREMIUM_ROLE_ID')) {
            return message.reply('You need Premium role to get a key!');
        }
        
        // Generate key
        const key = generateKey();
        
        await db.keys.create({
            key: key,
            discordId: userId,
            tier: 'premium',
            expiresAt: Date.now() + (30 * 24 * 60 * 60 * 1000),
            source: 'discord'
        });
        
        // DM the key
        await message.author.send(`Your key: \`${key}\``);
        message.reply('Check your DMs!');
    }
});
```

## 🛡️ Security Best Practices

1. **Rate Limiting**
```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 5 // 5 requests per window
});

app.use('/api/getkey', limiter);
```

2. **HWID Binding**
```lua
-- Lua side
local function getHWID()
    local HttpService = game:GetService("HttpService")
    return HttpService:GenerateGUID(false):gsub("-", ""):sub(1, 16)
end
```

3. **Key Expiry Check**
```javascript
// Check daily and delete expired keys
setInterval(async () => {
    await db.keys.deleteMany({
        expiresAt: { $lt: Date.now() },
        tier: { $ne: 'lifetime' }
    });
}, 24 * 60 * 60 * 1000);
```

## 📱 Full Stack Example

### Tech Stack
- **Frontend**: React/Vue.js (Key display page)
- **Backend**: Node.js + Express (API)
- **Database**: MongoDB (Key storage)
- **Payment**: Stripe (Premium keys)
- **Monetization**: Linkvertise (Free keys)
- **Logging**: Discord Webhooks

### Deployment
```bash
# Backend (Heroku/Railway)
npm install express mongoose discord.js
node server.js

# Frontend (Vercel/Netlify)
npm run build
vercel deploy
```

## 🎯 Summary

**Key Generation Flow:**
1. User clicks "Get Key"
2. Redirect to Linkvertise (or payment)
3. Complete tasks/payment
4. API generates unique key
5. Store in database
6. Display key to user
7. User enters key in script
8. Script verifies with API
9. Create session if valid

This is exactly how big scripts like **Delta**, **Solara**, **Arceus X** handle keys! 🔑
