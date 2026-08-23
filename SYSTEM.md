# PawZHub Authentication System v2.0

## 🔐 Core Features

### 1. **Advanced Key System**
- Multi-tier keys (Free, Premium, Lifetime)
- Key expiry system
- HWID binding for security
- Offline fallback mode
- Key format validation: `XXXX-XXXX-XXXX-XXXX`

### 2. **Security Features**
- **Rate Limiting**: 2-second cooldown between requests
- **Lockout System**: 3 failed attempts → 5 minute lockout
- **HWID Protection**: Keys bound to hardware ID
- **Session Management**: 1-hour sessions with auto-expiry
- **Blacklist System**: User ID blacklisting
- **Anti-Tamper**: Multiple session storage locations

### 3. **Caching System**
- Local key cache (10-minute duration)
- Reduces API calls
- Improves performance
- Auto-invalidation on expiry

### 4. **Analytics & Logging**
- Success/fail login tracking
- Keys checked counter
- Success rate calculation
- Uptime monitoring
- Discord webhook notifications

### 5. **Version Control**
- Automatic update checking
- Version enforcement option
- Update notifications

## 📊 Session Data Structure

```lua
{
    -- Core
    token = "32-char-random-token",
    key = "PAWZ-XXXX-XXXX-XXXX",
    hwid = "16-char-hardware-id",
    timestamp = 1234567890,
    expiresAt = 1234571490,
    
    -- Game
    gameId = 2753915549,
    gameName = "Blox Fruits",
    
    -- User
    userId = 123456,
    username = "Player",
    displayName = "Display",
    accountAge = 365,
    
    -- Key Info
    keyTier = "premium",
    keyExpiry = 1234567890,
    keyFeatures = {"basic", "advanced"},
    
    -- Security
    sessionId = "16-char-id",
    createdAt = "2024-01-01 12:00:00",
    
    -- Stats
    loginCount = 1,
    lastActivity = 1234567890,
}
```

## 🔑 Key Tiers

### Free Tier
```lua
["PAWZ-FREE-2024-DEMO1"] = {
    tier = "free",
    expiry = nil,
    features = {"basic"}
}
```

### Premium Tier
```lua
["PAWZ-PREM-2024-TEST"] = {
    tier = "premium",
    expiry = timestamp + 30_days,
    features = {"basic", "advanced", "priority"}
}
```

### Lifetime Tier
```lua
["PAWZ-LIFE-2024-VIP1"] = {
    tier = "lifetime",
    expiry = nil,
    features = {"basic", "advanced", "premium", "priority", "exclusive"}
}
```

## 🛠️ API Usage

### Check Session
```lua
local valid, session = CheckKeySystem.verifySession()
if valid then
    print("Session active:", session.username)
else
    print("No session:", session)
end
```

### Check Feature Access
```lua
if CheckKeySystem.hasFeature("advanced") then
    -- Enable advanced features
end
```

### Refresh Session
```lua
CheckKeySystem.refreshSession()
```

### Get Analytics
```lua
local stats = CheckKeySystem.getAnalytics()
print("Success Rate:", stats.successRate .. "%")
print("Uptime:", stats.uptime .. "s")
```

## 🔧 Configuration

```lua
local CONFIG = {
    -- Security
    SESSION_DURATION = 3600,
    MAX_RETRY_ATTEMPTS = 3,
    LOCKOUT_DURATION = 300,
    RATE_LIMIT_COOLDOWN = 2,
    ENABLE_HWID_BINDING = true,
    
    -- Caching
    CACHE_DURATION = 600,
    ALLOW_OFFLINE_MODE = true,
    
    -- Version
    CURRENT_VERSION = "2.0.0",
    REQUIRE_LATEST_VERSION = false,
}
```

## 📡 API Endpoints

### Key Verification
```
POST /verify
{
    "key": "PAWZ-XXXX-XXXX-XXXX",
    "hwid": "hardware-id",
    "userId": 123456,
    "username": "Player",
    "gameId": 2753915549,
    "version": "2.0.0",
    "timestamp": 1234567890
}

Response:
{
    "valid": true,
    "message": "Valid key",
    "tier": "premium",
    "expiry": 1234567890,
    "features": ["basic", "advanced"]
}
```

### Blacklist
```
GET /blacklist

Response:
{
    "users": [123456, 789012]
}
```

### Version Check
```
GET /version

Response:
{
    "version": "2.0.0",
    "changelog": "...",
    "required": false
}
```

## 🚨 Security Flow

1. **Pre-Validation**
   - Check lockout status
   - Validate key format
   - Check blacklist
   - Verify version

2. **Verification**
   - Check cache
   - Rate limit check
   - Remote API call
   - Fallback if offline

3. **Post-Verification**
   - Create session
   - Store HWID
   - Cache key
   - Send webhook
   - Update analytics

4. **Session Validation**
   - Check expiry
   - Verify HWID
   - Validate game ID
   - Update activity

## 📈 Analytics Data

- **Keys Checked**: Total verification attempts
- **Successful Logins**: Valid authentications
- **Failed Logins**: Invalid attempts
- **Success Rate**: Percentage of successful logins
- **Uptime**: System runtime in seconds
- **Cache Size**: Number of cached keys

## 🔔 Webhook Events

### ✅ Successful Login
```json
{
    "title": "✅ Successful Login",
    "color": 3066993,
    "fields": [
        {"name": "Key Tier", "value": "premium"},
        {"name": "HWID", "value": "abc123..."},
        {"name": "Session ID", "value": "xyz789"}
    ]
}
```

### ⚠️ HWID Mismatch
```json
{
    "title": "⚠️ HWID Mismatch",
    "color": 15158332
}
```

### 🚫 Blacklisted User
```json
{
    "title": "🚫 Blacklisted User Attempt",
    "color": 10038562
}
```

### ⚠️ Account Locked
```json
{
    "title": "⚠️ Account Locked",
    "description": "Too many failed attempts (3)",
    "color": 15105570
}
```

## 🛡️ Protection Against

- ✅ Key sharing (HWID binding)
- ✅ Brute force (Rate limiting + Lockout)
- ✅ Session hijacking (HWID verification)
- ✅ Replay attacks (Timestamp validation)
- ✅ Script tampering (Multiple storage checks)
- ✅ Unauthorized access (Blacklist system)
- ✅ Outdated versions (Version control)

## 🚀 Performance

- **Cache Hit**: < 1ms (instant)
- **API Call**: 100-500ms (network dependent)
- **Session Check**: < 1ms
- **Fallback Mode**: < 5ms

## 📝 Notes

- Sessions stored in `_G.PawZHubSession`
- HWID automatically generated per device
- Offline mode uses fallback keys
- Analytics reset on script reload
- Webhooks are optional
