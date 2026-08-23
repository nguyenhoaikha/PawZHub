# Free Keys Setup Guide

Complete guide for setting up the free key system with 2 link services.

---

## Overview

Users complete 2 different link tasks to get a free 24h key.

**Flow:**
```
User clicks "Get Key" in executor
    |
    v
Link 1 (Rekonise) - Complete ad task
    |
    v
Link 2 (WorkInk) - Complete ad task
    |
    v
Redirect to /api/getkey?user=USER_ID
    |
    v
API generates PAWZ-XXXX-XXXX-XXXX key (24h)
    |
    v
Display key to user
```

---

## Step 1: Create Linkvertise Accounts

### Link 1: Rekonise
- Go to https://rekonise.com
- Sign up as publisher
- Create a campaign with your redirect URL

### Link 2: WorkInk
- Go to https://work.ink
- Sign up for publisher account
- Create a shortened link with redirect

---

## Step 2: Configure Redirect URLs

When setting up each link, use these redirect URLs:

**Link 1 (Rekonise):**
```
https://your-domain.com/verify?step=1&user=USER_ID
```

**Link 2 (WorkInk):**
```
https://your-domain.com/verify?step=2&user=USER_ID
```

The verification page tracks which step the user completed and auto-redirects to the next link.

---

## Step 3: Update checkkey.lua

Replace the Get Key button handler in your executor script:

```lua
-- Free Key Button Handler (2-link system)
local currentStep = 1
local userId = game:GetService("Players").LocalPlayer.UserId

getKeyBtn.MouseButton1Click:Connect(function()
    local links = {
        {
            name = "Link 1",
            url = string.format("https://rekonise.com/YOUR_CAMPAIGN/%s", userId)
        },
        {
            name = "Link 2", 
            url = string.format("https://work.ink/YOUR_LINK/%s", userId)
        }
    }

    local link = links[currentStep]

    -- Copy link to clipboard
    setclipboard(link.url)

    -- Update button text
    getKeyBtn.Text = string.format("Step %d/2 - %s", currentStep, link.name)

    -- Notify user
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = string.format("Step %d/2 - %s", currentStep, link.name),
        Text = "Link copied! Complete tasks to continue",
        Duration = 8
    })

    -- Advance step
    currentStep = currentStep + 1

    -- After all steps, show verify button
    if currentStep > 2 then
        getKeyBtn.Text = "Verify & Get Key"
        getKeyBtn.BackgroundColor3 = Color3.fromRGB(40, 205, 65)
    end
end)
```

---

## Step 4: Create Verification Page

Create `verify.html` for your website:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Verify - PawZHub</title>
    <style>
        body {
            font-family: system-ui;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 20px;
            text-align: center;
            max-width: 500px;
        }
        .progress {
            background: #f0f0f0;
            height: 10px;
            border-radius: 10px;
            overflow: hidden;
            margin: 30px 0;
        }
        .progress-bar {
            background: linear-gradient(90deg, #667eea, #764ba2);
            height: 100%;
            transition: width 0.5s;
        }
        button {
            background: #667eea;
            color: white;
            border: none;
            padding: 15px 40px;
            border-radius: 10px;
            font-size: 16px;
            cursor: pointer;
            margin-top: 20px;
        }
        button:hover { background: #5568d3; }
    </style>
</head>
<body>
    <div class="container">
        <h1>PawZHub Free Key</h1>
        <p>Complete both steps to get your key</p>

        <div class="progress">
            <div class="progress-bar" id="progressBar"></div>
        </div>

        <p id="statusText"></p>
        <button id="nextBtn" onclick="nextStep()">Continue</button>
    </div>

    <script>
        const params = new URLSearchParams(window.location.search);
        const step = parseInt(params.get('step')) || 1;
        const userId = params.get('user');

        // Update progress
        const progress = (step / 2) * 100;
        document.getElementById('progressBar').style.width = progress + '%';
        document.getElementById('statusText').textContent = 
            step >= 2 ? 'All steps complete! Generating key...' : `Step ${step}/2 completed`;

        function nextStep() {
            if (step < 2) {
                // Redirect to next link
                window.location.href = `/verify?step=2&user=${userId}`;
            } else {
                // All done - generate key
                window.location.href = `/api/getkey?user=${userId}&verified=true`;
            }
        }

        // Auto-redirect after 2 seconds
        setTimeout(() => document.getElementById('nextBtn').click(), 2000);
    </script>
</body>
</html>
```

---

## Step 5: Key Display Page

After completing both links, users see their key on a nice page:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Your Free Key - PawZHub</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', system-ui, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            text-align: center;
            max-width: 500px;
            width: 100%;
        }
        h1 { color: #333; margin-bottom: 10px; }
        .key-display {
            font-size: 24px;
            font-weight: bold;
            color: #667eea;
            background: #f7f7ff;
            padding: 20px;
            border-radius: 12px;
            margin: 20px 0;
            font-family: 'Courier New', monospace;
            letter-spacing: 2px;
        }
        .copy-btn {
            background: #667eea;
            color: white;
            border: none;
            padding: 15px 40px;
            border-radius: 10px;
            font-size: 16px;
            cursor: pointer;
        }
        .copy-btn:hover { background: #5568d3; }
        .info {
            background: #f0f7ff;
            padding: 20px;
            border-radius: 12px;
            margin-top: 20px;
            text-align: left;
            color: #555;
            font-size: 14px;
        }
        .info div { margin: 8px 0; }
        .timer { color: #ff6b6b; font-weight: 600; margin-top: 15px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Your Free Key is Ready</h1>
        <p style="color: #666;">Valid for 24 hours</p>

        <div class="key-display" id="keyDisplay">Loading...</div>
        <button class="copy-btn" onclick="copyKey()" id="copyBtn">Copy Key</button>

        <div class="info">
            <div>Valid for 24 hours</div>
            <div>Works on 1 device (HWID locked)</div>
            <div>Access to basic features</div>
            <div>Unlimited uses within 24h</div>
        </div>

        <div class="timer" id="timer">Expires in: --:--:--</div>
    </div>

    <script>
        const params = new URLSearchParams(window.location.search);
        const userId = params.get('user');

        async function fetchKey() {
            try {
                const res = await fetch(`/api/getkey?user=${userId}`);
                const data = await res.json();

                if (data.success) {
                    document.getElementById('keyDisplay').textContent = data.key;
                    document.getElementById('copyBtn').disabled = false;
                    startCountdown(data.expiresAt);
                } else {
                    document.getElementById('keyDisplay').textContent = 'Error: ' + data.message;
                    document.getElementById('keyDisplay').style.color = '#ff6b6b';
                }
            } catch (e) {
                document.getElementById('keyDisplay').textContent = 'Failed to load key';
                document.getElementById('keyDisplay').style.color = '#ff6b6b';
            }
        }

        function copyKey() {
            const key = document.getElementById('keyDisplay').textContent;
            navigator.clipboard.writeText(key);
            const btn = document.getElementById('copyBtn');
            btn.textContent = 'Copied!';
            btn.style.background = '#4caf50';
            setTimeout(() => {
                btn.textContent = 'Copy Key';
                btn.style.background = '#667eea';
            }, 2000);
        }

        function startCountdown(expiryDate) {
            const expiry = new Date(expiryDate).getTime();
            setInterval(() => {
                const dist = expiry - Date.now();
                const h = Math.floor((dist % 86400000) / 3600000);
                const m = Math.floor((dist % 3600000) / 60000);
                const s = Math.floor((dist % 60000) / 1000);
                document.getElementById('timer').textContent =
                    `Expires in: ${String(h).padStart(2,'0')}:${String(m).padStart(2,'0')}:${String(s).padStart(2,'0')}`;
                if (dist < 0) {
                    document.getElementById('timer').textContent = 'Key Expired';
                    document.getElementById('timer').style.color = '#ff6b6b';
                }
            }, 1000);
        }

        fetchKey();
    </script>
</body>
</html>
```

---

## Revenue Estimate

### Per Link CPM:
- **Rekonise**: $4-6 CPM
- **WorkInk**: $3-5 CPM

### Monthly Projection:
- 100 keys/day = ~$2.50/day = ~$75/month
- 500 keys/day = ~$12.50/day = ~$375/month
- 1000 keys/day = ~$25/day = ~$750/month

---

## Testing Checklist

1. [ ] Create Rekonise account and campaign
2. [ ] Create WorkInk account and shortened link
3. [ ] Set up verify.html on your domain
4. [ ] Set up key display page
5. [ ] Update checkkey.lua with correct URLs
6. [ ] Test: Click Get Key -> Link 1 -> Complete -> Link 2 -> Complete -> Get Key
7. [ ] Verify key works in executor
8. [ ] Verify HWID binding works
9. [ ] Monitor CPM rates in Linkvertise dashboards
