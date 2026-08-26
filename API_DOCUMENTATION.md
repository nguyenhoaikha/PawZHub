# PawZHub Key System API Documentation

## Overview

PawZHub Key System provides a comprehensive solution for managing script access keys with support for:
- **Free Keys**: JWT-based with 12-24 hour expiration
- **Premium Keys**: HMAC-signed with trial/monthly/lifetime plans
- **HWID Binding**: Device-specific key binding
- **Checkpoint Verification**: 2-step verification for free keys
- **Admin Management**: Full administrative control

## Base URL
```
https://getpawzhub.vercel.app/api
```

## Authentication

### Admin Endpoints
Require `Authorization: Bearer <ADMIN_TOKEN>` header.

### Rate Limits
- **Key Verification**: 30 requests/minute per IP
- **Key Generation**: 10 requests/minute per IP  
- **Key Renewal**: 6 requests/minute per IP
- **HWID Reset**: 5 requests/hour per IP
- **Checkout**: 10 requests/hour per IP
- **Admin**: No limit (token-protected)

## Endpoints

### 1. Key Verification
```http
POST /api/verifykey
```

**Request Body:**
```json
{
  "key": "PH.eyJ0IjoxNzM0... or PAWZ-A1B2-C3D4-E5F6",
  "hwid": "ABC123DEF456",
  "userId": "123456789",
  "username": "PlayerName",
  "gameId": "2753915549"
}
```

**Response (Success):**
```json
{
  "valid": true,
  "message": "Premium key verified",
  "tier": "premium",
  "type": "lifetime",
  "features": ["basic", "advanced", "premium", "exclusive"],
  "hwid": "ABC123DEF456",
  "issued": 1734567890123,
  "expires": 1734654290123,
  "remainingHours": 24,
  "hwidResetAvailable": true
}
```

**Response (Error):**
```json
{
  "valid": false,
  "message": "Key expired",
  "tier": "premium",
  "expires": 1734567890123
}
```

### 2. Free Key Generation
```http
POST /api/getkey
```

**Request Body:**
```json
{
  "source": "linkvertise",
  "ttlHours": 12,
  "hwid": "ABC123DEF456",
  "userId": "123456789",
  "checkpoint1Token": "linkvertise_1734567890_abc123",
  "checkpoint2Token": "linkvertise_1734567891_def456"
}
```

**Response:**
```json
{
  "key": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "issued": 1734567890123,
  "expires": 1734611090123,
  "ttlHours": 12,
  "source": "linkvertise",
  "tier": "free",
  "success": true
}
```

### 3. Key Renewal
```http
POST /api/renewkey
```

**Request Body:**
```json
{
  "existingKey": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "checkpoint1Token": "linkvertise_1734567892_ghi789",
  "checkpoint2Token": "linkvertise_1734567893_jkl012",
  "hwid": "ABC123DEF456",
  "platform": "linkvertise",
  "additionalHours": 12
}
```

**Response:**
```json
{
  "success": true,
  "key": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "newExpires": 1734654290123,
  "renewCount": 1,
  "additionalHours": 12
}
```

### 4. Premium Key Checkout
```http
POST /api/checkout
```

**Request Body:**
```json
{
  "plan": "lifetime",
  "email": "user@example.com",
  "roblox": "PlayerName",
  "discord": "User#1234",
  "userId": "123456789",
  "hwid": "ABC123DEF456",
  "paymentId": "pi_1234567890",
  "paymentProvider": "stripe"
}
```

**Response:**
```json
{
  "success": true,
  "orderId": "PH-1A2B3C4D",
  "key": "PH.eyJ0IjoxNzM0NTY3ODkwMTIzLCJlIjoxNzY2MTAzODkwMTIzLCJwIjoyLCJ1IjoiQUJDMTIzREVGNDU2In0.a1b2c3d4e5f6",
  "plan": "lifetime",
  "planName": "Lifetime",
  "tier": "lifetime",
  "issued": 1734567890123,
  "issuedDate": "2024-12-18T12:34:50.123Z",
  "expires": 1766103890123,
  "expiresDate": "2034-12-18T12:34:50.123Z",
  "ttlDays": 3653,
  "email": "user@example.com",
  "robloxUser": "PlayerName",
  "discordUser": "User#1234",
  "webhookSent": true
}
```

### 5. HWID Reset
```http
POST /api/hwid-reset
```

**Request Body:**
```json
{
  "key": "PH.eyJ0IjoxNzM0NTY3ODkwMTIzLCJlIjoxNzY2MTAzODkwMTIzLCJwIjoyLCJ1IjoiQUJDMTIzREVGNDU2In0.a1b2c3d4e5f6",
  "currentHwid": "ABC123DEF456",
  "newHwid": "XYZ789GHI012",
  "userId": "123456789"
}
```

**Response:**
```json
{
  "success": true,
  "message": "HWID reset successful. Your key is now bound to the new device.",
  "previousHwid": "ABC123DEF456",
  "newHwid": "XYZ789GHI012",
  "nextResetAvailable": 1735172290123,
  "nextResetDate": "2024-12-25T12:34:50.123Z",
  "cooldownDays": 7
}
```

**Check Availability:**
```http
GET /api/hwid-reset?key=PH.eyJ0IjoxNzM0...
```

### 6. Checkpoint Tokens
```http
POST /api/checkpoint
```

**Request Body:**
```json
{
  "platform": "linkvertise",
  "step": 1,
  "ttlMinutes": 15
}
```

**Response:**
```json
{
  "success": true,
  "token": "linkvertise_1734567890_abc123",
  "platform": "linkvertise",
  "step": 1,
  "expiresIn": 900,
  "createdAt": 1734567890123
}
```

### 7. Admin API

#### Get Statistics
```http
GET /api/admin?action=stats
Authorization: Bearer <ADMIN_TOKEN>
```

**Response:**
```json
{
  "totalCheckpointTokens": 150,
  "usedCheckpointTokens": 89,
  "totalHWIDBindings": 234,
  "totalHWIDResets": 12,
  "blacklistedUsers": 3,
  "totalUsageLogs": 1547,
  "recentActivity": [...]
}
```

#### Generate Premium Keys
```http
POST /api/admin?action=generate-key
Authorization: Bearer <ADMIN_TOKEN>
```

**Request Body:**
```json
{
  "plan": "lifetime",
  "count": 5,
  "email": "admin@example.com",
  "roblox": "TestUser"
}
```

#### Manage Blacklist
```http
POST /api/admin?action=blacklist
Authorization: Bearer <ADMIN_TOKEN>

{
  "userId": "123456789",
  "reason": "Key sharing",
  "addedBy": "admin"
}
```

```http
DELETE /api/admin?action=blacklist&userId=123456789
Authorization: Bearer <ADMIN_TOKEN>
```

## Error Codes

| Status | Error | Description |
|--------|-------|-------------|
| 400 | Bad Request | Missing or invalid parameters |
| 401 | Unauthorized | Invalid or expired key |
| 403 | Forbidden | Access denied (blacklisted, HWID mismatch) |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server-side error |

## Key Types & Features

### Free Keys (JWT)
- **Format**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
- **Duration**: 12-24 hours
- **Features**: `["basic"]`
- **HWID Reset**: Not supported
- **Renewal**: Up to 3 times with checkpoint verification

### Premium Keys
- **Format**: `PH.{payload}.{signature}`
- **Types**: Trial (7 days), Monthly (30 days), Lifetime (10 years)
- **Features**: 
  - Trial: `["basic"]`
  - Monthly: `["basic", "advanced", "premium"]`
  - Lifetime: `["basic", "advanced", "premium", "exclusive"]`
- **HWID Reset**: Supported (7-day cooldown)

## Integration Example (Lua)

```lua
local HttpService = game:GetService("HttpService")
local player = game:GetService("Players").LocalPlayer

-- Verify key
local function verifyKey(key, hwid)
    local url = "https://getpawzhub.vercel.app/api/verifykey"
    local data = {
        key = key,
        hwid = hwid,
        userId = tostring(player.UserId),
        username = player.Name,
        gameId = tostring(game.PlaceId)
    }
    
    local success, response = pcall(function()
        return HttpService:PostAsync(
            url,
            HttpService:JSONEncode(data),
            Enum.HttpContentType.ApplicationJson
        )
    end)
    
    if success then
        local result = HttpService:JSONDecode(response)
        return result.valid, result
    else
        return false, { message = "Network error" }
    end
end

-- Usage
local valid, result = verifyKey("PH.eyJ0IjoxNzM0...", "ABC123DEF456")
if valid then
    print("Key verified! Tier:", result.tier)
    -- Load script features based on result.features
else
    print("Key verification failed:", result.message)
end
```

## Security Notes

1. **Never hardcode admin tokens** in client-side code
2. **Always validate HWID** on the server side
3. **Use HTTPS only** for all API requests
4. **Rate limiting** is enforced on all endpoints
5. **Blacklisted users** are blocked across all operations
6. **Checkpoint tokens** prevent replay attacks
7. **HMAC signatures** prevent key tampering

## Production Deployment

1. Replace in-memory storage with **Redis** or **MongoDB**
2. Set proper **environment variables**:
   - `GETKEY_SECRET` - JWT signing secret
   - `KEYGEN_SECRET` - Premium key HMAC secret  
   - `ADMIN_TOKEN` - Admin API authentication
   - `DISCORD_WEBHOOK_URL` - Order notifications
3. Configure **rate limiting** with Redis
4. Set up **monitoring** and **logging**
5. Enable **CORS** for your domain only