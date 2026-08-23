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
    max: 10 // 10 requests per window
});

// MongoDB Schema
const keySchema = new mongoose.Schema({
    key: { type: String, required: true, unique: true, index: true },
    
    // User Info
    userId: { type: String, required: true },
    hwid: { type: String, default: null },
    ipAddress: { type: String, default: null },
    
    // Key Info
    tier: { 
        type: String, 
        enum: ['free', 'premium', 'lifetime'], 
        default: 'free' 
    },
    features: { type: [String], default: ['basic'] },
    
    // Timestamps
    createdAt: { type: Date, default: Date.now },
    expiresAt: { type: Date, default: () => Date.now() + 24*60*60*1000 },
    lastUsed: { type: Date, default: null },
    
    // Usage
    uses: { type: Number, default: 0 },
    maxUses: { type: Number, default: 1 },
    
    // Additional
    status: { 
        type: String, 
        enum: ['active', 'banned', 'expired'], 
        default: 'active' 
    },
    source: { type: String, default: 'linkvertise' },
    lastGameId: { type: String, default: null },
    notes: { type: String, default: '' }
});

const Key = mongoose.model('Key', keySchema);

// Blacklist Schema
const blacklistSchema = new mongoose.Schema({
    userId: { type: String, required: true, unique: true },
    reason: { type: String, default: '' },
    addedAt: { type: Date, default: Date.now },
    addedBy: { type: String, default: 'system' }
});

const Blacklist = mongoose.model('Blacklist', blacklistSchema);

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/pawzhub', {
    useNewUrlParser: true,
    useUnifiedTopology: true
}).then(() => {
    console.log('✅ Connected to MongoDB');
}).catch(err => {
    console.error('❌ MongoDB connection error:', err);
});

// ============================================
// UTILITY FUNCTIONS
// ============================================

function generateKey() {
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
    
    axios.post(webhookUrl, { embeds: [embed] }).catch(console.error);
}

async function isBlacklisted(userId) {
    const entry = await Blacklist.findOne({ userId: userId });
    return entry !== null;
}

// ============================================
// API ROUTES
// ============================================

// Health check
app.get('/', (req, res) => {
    res.json({ 
        status: 'online', 
        version: '2.0.0',
        uptime: process.uptime()
    });
});

// Get Key (after Linkvertise)
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
        
        // Check if user already has active key
        const existing = await Key.findOne({
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
        
        // Generate new key
        const key = generateKey();
        
        await Key.create({
            key: key,
            userId: user,
            hwid: hwid || null,
            ipAddress: req.ip,
            tier: 'free',
            features: ['basic'],
            expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours
            maxUses: 1
        });
        
        // Send webhook
        sendDiscordWebhook({
            title: '🔑 New Key Generated',
            color: 3066993,
            fields: [
                { name: 'Key', value: key, inline: true },
                { name: 'User ID', value: user, inline: true },
                { name: 'HWID', value: hwid ? hwid.substr(0, 8) + '...' : 'N/A', inline: true },
                { name: 'Expires', value: '24 hours', inline: true }
            ]
        });
        
        res.json({
            success: true,
            key: key,
            message: 'Key generated successfully',
            expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000)
        });
        
    } catch (error) {
        console.error('Error in /api/getkey:', error);
        res.status(500).json({ 
            success: false, 
            message: 'Internal server error' 
        });
    }
});

// Verify Key
app.post('/api/verify', limiter, async (req, res) => {
    try {
        const { key, hwid, userId, username, gameId, version } = req.body;
        
        if (!key) {
            return res.status(400).json({ 
                valid: false, 
                message: 'Key required' 
            });
        }
        
        // Find key
        const keyData = await Key.findOne({ key: key });
        
        if (!keyData) {
            return res.json({ 
                valid: false, 
                message: 'Invalid key' 
            });
        }
        
        // Check status
        if (keyData.status === 'banned') {
            return res.json({ 
                valid: false, 
                message: 'Key has been banned' 
            });
        }
        
        // Check expiry
        if (keyData.expiresAt && new Date() > keyData.expiresAt) {
            await Key.updateOne({ key: key }, { status: 'expired' });
            return res.json({ 
                valid: false, 
                message: 'Key has expired' 
            });
        }
        
        // Check HWID binding
        if (keyData.hwid && hwid && keyData.hwid !== hwid) {
            sendDiscordWebhook({
                title: '⚠️ HWID Mismatch',
                color: 15158332,
                fields: [
                    { name: 'Key', value: key, inline: true },
                    { name: 'Expected HWID', value: keyData.hwid.substr(0, 8) + '...', inline: true },
                    { name: 'Received HWID', value: hwid.substr(0, 8) + '...', inline: true }
                ]
            });
            
            return res.json({ 
                valid: false, 
                message: 'Key is bound to a different device' 
            });
        }
        
        // Bind HWID if not set
        if (!keyData.hwid && hwid) {
            keyData.hwid = hwid;
        }
        
        // Check max uses
        if (keyData.maxUses !== -1 && keyData.uses >= keyData.maxUses) {
            return res.json({ 
                valid: false, 
                message: 'Key usage limit reached' 
            });
        }
        
        // Update usage
        await Key.updateOne(
            { key: key },
            {
                $inc: { uses: 1 },
                $set: {
                    lastUsed: new Date(),
                    lastGameId: gameId,
                    hwid: keyData.hwid
                }
            }
        );
        
        // Send webhook
        sendDiscordWebhook({
            title: '✅ Key Verified',
            color: 3066993,
            fields: [
                { name: 'Key', value: key.substr(0, 10) + '...', inline: true },
                { name: 'User', value: username || userId, inline: true },
                { name: 'Tier', value: keyData.tier, inline: true },
                { name: 'Game ID', value: gameId || 'N/A', inline: true },
                { name: 'Uses', value: `${keyData.uses + 1}/${keyData.maxUses === -1 ? '∞' : keyData.maxUses}`, inline: true }
            ]
        });
        
        // Return success
        res.json({
            valid: true,
            message: 'Key verified successfully',
            tier: keyData.tier,
            features: keyData.features,
            expiry: keyData.expiresAt
        });
        
    } catch (error) {
        console.error('Error in /api/verify:', error);
        res.status(500).json({ 
            valid: false, 
            message: 'Internal server error' 
        });
    }
});

// Get Blacklist
app.get('/api/blacklist', async (req, res) => {
    try {
        const blacklisted = await Blacklist.find({}, 'userId');
        const userIds = blacklisted.map(b => b.userId);
        
        res.json({
            users: userIds
        });
    } catch (error) {
        console.error('Error in /api/blacklist:', error);
        res.status(500).json({ 
            users: [] 
        });
    }
});

// Version Check
app.get('/api/version', (req, res) => {
    res.json({
        version: '2.0.0',
        changelog: 'Enhanced security and performance improvements',
        required: false,
        downloadUrl: 'https://github.com/nguyenhoaikha/PawZHub'
    });
});

// ============================================
// ADMIN ROUTES (Protected)
// ============================================

const ADMIN_TOKEN = process.env.ADMIN_TOKEN || 'your-secret-admin-token';

function requireAuth(req, res, next) {
    const token = req.headers.authorization;
    if (token !== `Bearer ${ADMIN_TOKEN}`) {
        return res.status(401).json({ error: 'Unauthorized' });
    }
    next();
}

// Get all keys (Admin)
app.get('/admin/keys', requireAuth, async (req, res) => {
    try {
        const keys = await Key.find()
            .sort({ createdAt: -1 })
            .limit(100);
        
        res.json({ 
            count: keys.length, 
            keys: keys 
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Ban key (Admin)
app.post('/admin/ban', requireAuth, async (req, res) => {
    try {
        const { key } = req.body;
        
        await Key.updateOne(
            { key: key },
            { status: 'banned' }
        );
        
        res.json({ success: true, message: 'Key banned' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Add to blacklist (Admin)
app.post('/admin/blacklist', requireAuth, async (req, res) => {
    try {
        const { userId, reason } = req.body;
        
        await Blacklist.create({
            userId: userId,
            reason: reason || 'No reason provided'
        });
        
        res.json({ success: true, message: 'User blacklisted' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Generate premium key (Admin)
app.post('/admin/generate', requireAuth, async (req, res) => {
    try {
        const { userId, tier, duration, hwid } = req.body;
        
        const key = generateKey();
        const durationMs = duration ? duration * 24 * 60 * 60 * 1000 : null;
        
        await Key.create({
            key: key,
            userId: userId,
            hwid: hwid || null,
            tier: tier || 'premium',
            features: tier === 'lifetime' 
                ? ['basic', 'advanced', 'premium', 'exclusive']
                : ['basic', 'advanced'],
            expiresAt: durationMs ? new Date(Date.now() + durationMs) : null,
            maxUses: -1,
            source: 'admin'
        });
        
        res.json({ 
            success: true, 
            key: key 
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Statistics (Admin)
app.get('/admin/stats', requireAuth, async (req, res) => {
    try {
        const totalKeys = await Key.countDocuments();
        const activeKeys = await Key.countDocuments({ 
            status: 'active',
            expiresAt: { $gt: new Date() }
        });
        const expiredKeys = await Key.countDocuments({ 
            status: 'expired' 
        });
        const bannedKeys = await Key.countDocuments({ 
            status: 'banned' 
        });
        const blacklistedUsers = await Blacklist.countDocuments();
        
        res.json({
            totalKeys,
            activeKeys,
            expiredKeys,
            bannedKeys,
            blacklistedUsers
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ============================================
// CLEANUP JOB
// ============================================

// Delete expired keys daily
setInterval(async () => {
    try {
        const result = await Key.deleteMany({
            status: 'expired',
            expiresAt: { $lt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) }
        });
        
        console.log(`🗑️ Cleaned up ${result.deletedCount} expired keys`);
    } catch (error) {
        console.error('Cleanup error:', error);
    }
}, 24 * 60 * 60 * 1000);

// ============================================
// START SERVER
// ============================================

app.listen(PORT, () => {
    console.log(`🚀 PawZHub API running on port ${PORT}`);
});

module.exports = app;
