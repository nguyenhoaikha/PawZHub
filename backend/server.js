// PawZHub Backend API Server
// Node.js + Express + MongoDB

const express = require('express');
const mongoose = require('mongoose');
const crypto = require('crypto');
const rateLimit = require('express-rate-limit');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(cors());

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 20
});

// ============================================
// DATABASE SCHEMAS
// ============================================

// Free Key Schema (24h, HWID locked)
const freeKeySchema = new mongoose.Schema({
    key: { type: String, required: true, unique: true, index: true },
    userId: { type: String, required: true },
    hwid: { type: String, default: null },
    ipAddress: { type: String, default: null },
    tier: { type: String, default: 'free' },
    features: { type: [String], default: ['basic'] },
    expiresAt: { type: Date, required: true },
    uses: { type: Number, default: 0 },
    maxUses: { type: Number, default: -1 },
    status: { type: String, enum: ['active', 'expired', 'banned'], default: 'active' },
    source: { type: String, default: 'linkvertise' },
    lastGameId: { type: String, default: null },
    createdAt: { type: Date, default: Date.now }
});

// Lifetime Key Schema (from Discord bot license redemption)
const lifetimeKeySchema = new mongoose.Schema({
    key: { type: String, required: true, unique: true, index: true },
    licenseCode: { type: String, required: true },
    discordId: { type: String, required: true },
    discordTag: { type: String, required: true },
    boundHWIDs: { type: [String], default: [] },
    lastHWIDReset: { type: Date, default: null },
    nextResetAvailable: { type: Date, default: null },
    totalUses: { type: Number, default: 0 },
    lastUsed: { type: Date, default: null },
    status: { type: String, enum: ['active', 'banned'], default: 'active' },
    createdAt: { type: Date, default: Date.now }
});

// License Code Schema (managed by Discord bot)
const licenseSchema = new mongoose.Schema({
    code: { type: String, required: true, unique: true, lowercase: true },
    status: { type: String, enum: ['unused', 'redeemed'], default: 'unused' },
    redeemedBy: { type: String, default: null },
    redeemedAt: { type: Date, default: null },
    redeemedTag: { type: String, default: null },
    generatedKey: { type: String, default: null },
    createdAt: { type: Date, default: Date.now }
});

// Blacklist Schema
const blacklistSchema = new mongoose.Schema({
    userId: { type: String, required: true, unique: true },
    reason: { type: String, default: '' },
    addedAt: { type: Date, default: Date.now }
});

const FreeKey = mongoose.model('FreeKey', freeKeySchema);
const LifetimeKey = mongoose.model('LifetimeKey', lifetimeKeySchema);
const License = mongoose.model('License', licenseSchema);
const Blacklist = mongoose.model('Blacklist', blacklistSchema);

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/pawzhub', {
    useNewUrlParser: true,
    useUnifiedTopology: true
}).then(() => {
    console.log('[PawZHub] MongoDB connected');
}).catch(err => {
    console.error('[PawZHub] MongoDB error:', err);
});

// ============================================
// UTILITY FUNCTIONS
// ============================================

function generateFreeKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let key = 'PAWZ';
    for (let i = 0; i < 3; i++) {
        key += '-';
        for (let j = 0; j < 4; j++) {
            key += chars.charAt(Math.floor(Math.random() * chars.length));
        }
    }
    return key;
}

function sendDiscordWebhook(data) {
    const webhookUrl = process.env.DISCORD_WEBHOOK_URL;
    if (!webhookUrl) return;

    const axios = require('axios');

    const embed = {
        title: data.title || 'PawZHub Event',
        description: data.description || '',
        color: data.color || 3447003,
        fields: data.fields || [],
        footer: { text: 'PawZHub API' },
        timestamp: new Date().toISOString()
    };

    axios.post(webhookUrl, { embeds: [embed] }).catch(() => {});
}

async function isBlacklisted(userId) {
    const entry = await Blacklist.findOne({ userId });
    return entry !== null;
}

// ============================================
// PUBLIC API ROUTES
// ============================================

// Health check
app.get('/', (req, res) => {
    res.json({
        status: 'online',
        version: '2.1.0',
        uptime: process.uptime()
    });
});

// -------------------------------------------
// FREE KEY: Get Key (after Linkvertise)
// -------------------------------------------
app.get('/api/getkey', limiter, async (req, res) => {
    try {
        const { user, hwid } = req.query;

        if (!user) {
            return res.status(400).json({
                success: false,
                message: 'User ID required'
            });
        }

        // Check blacklist
        if (await isBlacklisted(user)) {
            return res.status(403).json({
                success: false,
                message: 'User is blacklisted'
            });
        }

        // Check if user already has active free key
        const existing = await FreeKey.findOne({
            userId: user,
            status: 'active',
            expiresAt: { $gt: new Date() }
        });

        if (existing) {
            return res.json({
                success: true,
                key: existing.key,
                message: 'You already have an active key',
                expiresAt: existing.expiresAt
            });
        }

        // Generate new free key (24h)
        const key = generateFreeKey();

        await FreeKey.create({
            key,
            userId: user,
            hwid: hwid || null,
            ipAddress: req.ip,
            tier: 'free',
            features: ['basic'],
            expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
            maxUses: -1
        });

        sendDiscordWebhook({
            title: 'New Free Key Generated',
            color: 3066993,
            fields: [
                { name: 'Key', value: key, inline: true },
                { name: 'User ID', value: user, inline: true },
                { name: 'HWID', value: hwid ? hwid.substr(0, 12) + '...' : 'N/A', inline: true }
            ]
        });

        res.json({
            success: true,
            key,
            message: 'Key generated successfully',
            expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000)
        });

    } catch (error) {
        console.error('[/api/getkey]', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
});

// -------------------------------------------
// VERIFY KEY (called by executor scripts)
// -------------------------------------------
app.post('/api/verify', limiter, async (req, res) => {
    try {
        const { key, hwid, userId, username, gameId, version } = req.body;

        if (!key) {
            return res.status(400).json({ valid: false, message: 'Key required' });
        }

        // Check if it's a lifetime key (24 char hex)
        if (/^[a-f0-9]{24}$/i.test(key)) {
            const lifetimeKey = await LifetimeKey.findOne({ key: key.toLowerCase() });

            if (!lifetimeKey) {
                return res.json({ valid: false, message: 'Invalid key' });
            }

            if (lifetimeKey.status === 'banned') {
                return res.json({ valid: false, message: 'Key has been banned' });
            }

            // HWID binding
            if (hwid) {
                if (lifetimeKey.boundHWIDs.length === 0) {
                    // First use - bind HWID
                    lifetimeKey.boundHWIDs.push(hwid);
                } else if (!lifetimeKey.boundHWIDs.includes(hwid)) {
                    // Check if HWID mismatch
                    sendDiscordWebhook({
                        title: 'HWID Mismatch Attempt',
                        color: 15158332,
                        fields: [
                            { name: 'Key', value: `\`${key.slice(0, 8)}...\``, inline: true },
                            { name: 'Owner', value: lifetimeKey.discordTag, inline: true },
                            { name: 'Bound HWIDs', value: `${lifetimeKey.boundHWIDs.length}`, inline: true }
                        ]
                    });
                    return res.json({
                        valid: false,
                        message: 'HWID mismatch. Use !resetkey in Discord to reset.'
                    });
                }
            }

            // Update usage
            lifetimeKey.totalUses += 1;
            lifetimeKey.lastUsed = new Date();
            await lifetimeKey.save();

            return res.json({
                valid: true,
                message: 'Lifetime key verified',
                tier: 'lifetime',
                features: ['basic', 'advanced', 'premium', 'exclusive'],
                expiry: null,
                hwidResetAvailable: lifetimeKey.nextResetAvailable
                    ? lifetimeKey.nextResetAvailable < new Date()
                    : true
            });
        }

        // Regular free key (PAWZ-XXXX-XXXX-XXXX format)
        const keyData = await FreeKey.findOne({ key: key.toUpperCase() });

        if (!keyData) {
            return res.json({ valid: false, message: 'Invalid key' });
        }

        if (keyData.status === 'banned') {
            return res.json({ valid: false, message: 'Key has been banned' });
        }

        // Check expiry
        if (keyData.expiresAt && new Date() > keyData.expiresAt) {
            await FreeKey.updateOne({ key: keyData.key }, { status: 'expired' });
            return res.json({ valid: false, message: 'Key has expired' });
        }

        // HWID binding for free keys
        if (keyData.hwid && hwid && keyData.hwid !== hwid) {
            sendDiscordWebhook({
                title: 'Free Key HWID Mismatch',
                color: 15158332,
                fields: [
                    { name: 'Key', value: keyData.key, inline: true },
                    { name: 'User', value: keyData.userId, inline: true }
                ]
            });
            return res.json({ valid: false, message: 'Key is bound to a different device' });
        }

        if (!keyData.hwid && hwid) {
            keyData.hwid = hwid;
        }

        // Update usage
        await FreeKey.updateOne(
            { key: keyData.key },
            {
                $inc: { uses: 1 },
                $set: {
                    lastUsed: new Date(),
                    lastGameId: gameId,
                    hwid: keyData.hwid
                }
            }
        );

        sendDiscordWebhook({
            title: 'Free Key Verified',
            color: 3066993,
            fields: [
                { name: 'Key', value: keyData.key, inline: true },
                { name: 'User', value: username || userId || keyData.userId, inline: true },
                { name: 'Game', value: gameId || 'N/A', inline: true }
            ]
        });

        res.json({
            valid: true,
            message: 'Key verified successfully',
            tier: 'free',
            features: ['basic'],
            expiry: keyData.expiresAt
        });

    } catch (error) {
        console.error('[/api/verify]', error);
        res.status(500).json({ valid: false, message: 'Internal server error' });
    }
});

// -------------------------------------------
// HWID RESET (for executor scripts)
// -------------------------------------------
app.post('/api/hwid-reset', limiter, async (req, res) => {
    try {
        const { key, hwid } = req.body;

        if (!key) {
            return res.status(400).json({ success: false, message: 'Key required' });
        }

        // Only lifetime keys support HWID reset
        if (!/^[a-f0-9]{24}$/i.test(key)) {
            return res.json({
                success: false,
                message: 'HWID reset is only available for lifetime keys. Use !resetkey in Discord.'
            });
        }

        const lifetimeKey = await LifetimeKey.findOne({ key: key.toLowerCase() });

        if (!lifetimeKey) {
            return res.json({ success: false, message: 'Invalid key' });
        }

        if (lifetimeKey.status === 'banned') {
            return res.json({ success: false, message: 'Key has been banned' });
        }

        // Check 7-day cooldown
        if (lifetimeKey.nextResetAvailable && Date.now() < lifetimeKey.nextResetAvailable.getTime()) {
            const hoursLeft = Math.ceil((lifetimeKey.nextResetAvailable.getTime() - Date.now()) / (1000 * 60 * 60));
            const daysLeft = Math.ceil(hoursLeft / 24);
            return res.json({
                success: false,
                message: `HWID reset available in ${daysLeft} day(s) (${hoursLeft} hours)`
            });
        }

        // Reset HWIDs
        const clearedCount = lifetimeKey.boundHWIDs.length;
        lifetimeKey.boundHWIDs = [];

        // Add new HWID if provided
        if (hwid) {
            lifetimeKey.boundHWIDs.push(hwid);
        }

        lifetimeKey.lastHWIDReset = new Date();
        lifetimeKey.nextResetAvailable = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
        await lifetimeKey.save();

        sendDiscordWebhook({
            title: 'HWID Reset via API',
            color: 3066993,
            fields: [
                { name: 'Key', value: `\`${key.slice(0, 8)}...\``, inline: true },
                { name: 'Cleared', value: `${clearedCount} device(s)`, inline: true },
                { name: 'Owner', value: lifetimeKey.discordTag, inline: true }
            ]
        });

        res.json({
            success: true,
            message: 'HWID reset successful',
            nextResetAvailable: lifetimeKey.nextResetAvailable,
            newHWID: hwid || null
        });

    } catch (error) {
        console.error('[/api/hwid-reset]', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
});

// -------------------------------------------
// Blacklist (for executor check)
// -------------------------------------------
app.get('/api/blacklist', async (req, res) => {
    try {
        const blacklisted = await Blacklist.find({}, 'userId');
        res.json({ users: blacklisted.map(b => b.userId) });
    } catch (error) {
        res.json({ users: [] });
    }
});

// -------------------------------------------
// Version Check
// -------------------------------------------
app.get('/api/version', (req, res) => {
    res.json({
        version: '2.1.0',
        changelog: 'License redemption system with HWID reset',
        required: false,
        downloadUrl: 'https://github.com/nguyenhoaikha/PawZHub'
    });
});

// ============================================
// ADMIN API ROUTES (Protected)
// ============================================

const ADMIN_TOKEN = process.env.ADMIN_TOKEN || 'your-secret-admin-token';

function requireAuth(req, res, next) {
    const token = req.headers.authorization;
    if (token !== `Bearer ${ADMIN_TOKEN}`) {
        return res.status(401).json({ error: 'Unauthorized' });
    }
    next();
}

// Get all free keys (Admin)
app.get('/admin/keys', requireAuth, async (req, res) => {
    try {
        const keys = await FreeKey.find().sort({ createdAt: -1 }).limit(100);
        res.json({ count: keys.length, keys });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get all lifetime keys (Admin)
app.get('/admin/lifetime-keys', requireAuth, async (req, res) => {
    try {
        const keys = await LifetimeKey.find().sort({ createdAt: -1 }).limit(100);
        res.json({ count: keys.length, keys });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get all licenses (Admin)
app.get('/admin/licenses', requireAuth, async (req, res) => {
    try {
        const licenses = await License.find().sort({ createdAt: -1 }).limit(100);
        res.json({ count: licenses.length, licenses });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Ban key (Admin)
app.post('/admin/ban', requireAuth, async (req, res) => {
    try {
        const { key } = req.body;

        // Try free key first, then lifetime key
        let result = await FreeKey.updateOne({ key }, { status: 'banned' });
        if (result.modifiedCount === 0) {
            result = await LifetimeKey.updateOne({ key: key.toLowerCase() }, { status: 'banned' });
        }

        res.json({ success: true, message: 'Key banned' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Add to blacklist (Admin)
app.post('/admin/blacklist', requireAuth, async (req, res) => {
    try {
        const { userId, reason } = req.body;
        await Blacklist.create({ userId, reason: reason || 'No reason' });
        res.json({ success: true, message: 'User blacklisted' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Statistics (Admin)
app.get('/admin/stats', requireAuth, async (req, res) => {
    try {
        const totalFreeKeys = await FreeKey.countDocuments();
        const activeFreeKeys = await FreeKey.countDocuments({ status: 'active', expiresAt: { $gt: new Date() } });
        const expiredFreeKeys = await FreeKey.countDocuments({ status: 'expired' });
        const bannedFreeKeys = await FreeKey.countDocuments({ status: 'banned' });

        const totalLifetimeKeys = await LifetimeKey.countDocuments();
        const activeLifetimeKeys = await LifetimeKey.countDocuments({ status: 'active' });
        const bannedLifetimeKeys = await LifetimeKey.countDocuments({ status: 'banned' });

        const totalLicenses = await License.countDocuments();
        const unusedLicenses = await License.countDocuments({ status: 'unused' });
        const redeemedLicenses = await License.countDocuments({ status: 'redeemed' });

        const blacklistedUsers = await Blacklist.countDocuments();

        res.json({
            freeKeys: { total: totalFreeKeys, active: activeFreeKeys, expired: expiredFreeKeys, banned: bannedFreeKeys },
            lifetimeKeys: { total: totalLifetimeKeys, active: activeLifetimeKeys, banned: bannedLifetimeKeys },
            licenses: { total: totalLicenses, unused: unusedLicenses, redeemed: redeemedLicenses },
            blacklistedUsers
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ============================================
// CLEANUP JOB
// ============================================

// Delete expired free keys older than 7 days
setInterval(async () => {
    try {
        const result = await FreeKey.deleteMany({
            status: 'expired',
            expiresAt: { $lt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) }
        });
        if (result.deletedCount > 0) {
            console.log(`[Cleanup] Removed ${result.deletedCount} expired free keys`);
        }
    } catch (error) {
        console.error('[Cleanup]', error);
    }
}, 24 * 60 * 60 * 1000);

// ============================================
// START SERVER
// ============================================

app.listen(PORT, () => {
    console.log(`[PawZHub] API running on port ${PORT}`);
});

module.exports = app;
