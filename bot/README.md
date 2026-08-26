# PawZHub Discord Bot

Discord companion for the PawZHub Roblox script hub. Connects users to the
admin dashboard via slash commands.

## Features

| Command | Who | What it does |
|---------|-----|--------------|
| `/verify key:<key>` | Anyone | Verify a key (PH.\* or JWT) and show tier/expiry/features |
| `/keygen plan:<trial\|monthly\|lifetime> [count] [email] [roblox]` | Admin | Mint premium keys; sent via DM |
| `/blacklist userid:<id> reason:<reason>` | Admin | Block a user |
| `/unblacklist userid:<id>` | Admin | Unblock a user |
| `/stats` | Admin | Live system stats from the web API |

## Setup

### 1. Create a Discord application

1. <https://discord.com/developers/applications> → **New Application**
2. **Bot** tab → **Add Bot** → copy the **Token** (this is `DISCORD_BOT_TOKEN`)
3. **OAuth2 → URL Generator**:
   - Scopes: `bot`, `applications.commands`
   - Bot permissions: `Send Messages`, `Embed Links`
   - Use the generated URL to invite the bot to your server
4. **General Information** → copy **Application ID** (this is `DISCORD_CLIENT_ID`)
5. Right-click your server icon → **Copy Server ID** (this is `DISCORD_GUILD_ID`)

### 2. Configure the bot

```bash
cd bot
cp .env.example .env
# edit .env with your values
```

Required values:

| Variable | What |
|---|---|
| `DISCORD_BOT_TOKEN` | Bot token from step 1.2 |
| `DISCORD_CLIENT_ID` | Application ID from step 1.4 |
| `DISCORD_GUILD_ID` | Server ID from step 1.5 (use for instant command deploy) |
| `WEB_API_URL` | `https://getpawzhub.vercel.app` (your Vercel deployment) |
| `WEB_ADMIN_TOKEN` | Same as `ADMIN_TOKEN` env var on Vercel |
| `ADMIN_USER_IDS` | Comma-separated Discord user IDs allowed to use admin commands |

### 3. Install + register commands

```bash
cd bot
npm install
npm run build
npm run deploy    # registers slash commands
npm start         # or: npm run dev
```

You should see `[PawZHub] Logged in as <name>` in the terminal.

### 4. Test in Discord

Type `/` in any channel and pick a PawZHub command. Start with
`/verify key:eyJ...` to confirm the bot can talk to your Vercel API.

## Deployment

Free hosting options that work with this bot:

- **Render** — <https://render.com> → **New Web Service** → connect this repo, build `npm install && npm run build`, start `npm start`
- **Railway** — <https://railway.app> → **New Project** → Deploy from GitHub repo
- **fly.io** — <https://fly.io> → `fly launch`, then `fly deploy`
- **VPS** — `node dist/index.js` behind pm2 / systemd

Set the same env vars on the host.

## How the bot talks to your web API

```
Discord user → /verify key:PH.xxx
                ↓
              bot → POST {WEB_API_URL}/api/verifykey
                            (Authorization: Bearer {WEB_ADMIN_TOKEN})
                            { key, hwid?, userId? }
                            ↓
                          Vercel API → returns { valid, tier, features, ... }
                            ↓
              bot → embed with tier/expiry/etc → reply to user
```

Admin commands (`/keygen`, `/blacklist`, `/stats`) use the same `WEB_ADMIN_TOKEN`
on every request. The bot itself is a regular user of the Vercel API; it doesn't
host any state.
