// PawZHub Discord Bot - License Redemption System
// Text-based, no icons/embed images

const { Client, GatewayIntentBits, EmbedBuilder } = require('discord.js');
const mongoose = require('mongoose');
require('dotenv').config();

const client = new Client({
    intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMessages,
        GatewayIntentBits.MessageContent,
        GatewayIntentBits.DirectMessages
    ]
});

// ============================================
// DATABASE SCHEMAS
// ============================================

// License Code Schema (8 char hex, e.g. a12e137e)
const licenseSchema = new mongoose.Schema({
    code: { type: String, required: true, unique: true, lowercase: true },
    status: { type: String, enum: ['unused', 'redeemed'], default: 'unused' },
    redeemedBy: { type: String, default: null },      // Discord ID
    redeemedAt: { type: Date, default: null },
    redeemedTag: { type: String, default: null },      // user#0000
    generatedKey: { type: String, default: null },     // 24 char hex lifetime key
    createdAt: { type: Date, default: Date.now }
});

// Lifetime Key Schema (24 char hex, e.g. f03d3260914a9475faf29b12)
const lifetimeKeySchema = new mongoose.Schema({
    key: { type: String, required: true, unique: true, lowercase: true },
    licenseCode: { type: String, required: true },

    // Owner - only this Discord can use/manage
    discordId: { type: String, required: true },
    discordTag: { type: String, required: true },

    // HWID binding
    boundHWIDs: { type: [String], default: [] },

    // HWID reset (every 7 days)
    lastHWIDReset: { type: Date, default: null },
    nextResetAvailable: { type: Date, default: null },

    // Usage tracking
    totalUses: { type: Number, default: 0 },
    lastUsed: { type: Date, default: null },

    // Status
    status: { type: String, enum: ['active', 'banned'], default: 'active' },
    createdAt: { type: Date, default: Date.now }
});

// Free Key Schema (24h, HWID locked, 1 device)
const freeKeySchema = new mongoose.Schema({
    key: { type: String, required: true, unique: true },
    userId: { type: String, required: true },
    hwid: { type: String, default: null },
    tier: { type: String, default: 'free' },
    features: { type: [String], default: ['basic'] },
    expiresAt: { type: Date, required: true },
    uses: { type: Number, default: 0 },
    maxUses: { type: Number, default: -1 },
    status: { type: String, enum: ['active', 'expired', 'banned'], default: 'active' },
    source: { type: String, default: 'linkvertise' },
    createdAt: { type: Date, default: Date.now }
});

// Blacklist Schema
const blacklistSchema = new mongoose.Schema({
    userId: { type: String, required: true, unique: true },
    reason: { type: String, default: '' },
    addedAt: { type: Date, default: Date.now }
});

const License = mongoose.model('License', licenseSchema);
const LifetimeKey = mongoose.model('LifetimeKey', lifetimeKeySchema);
const FreeKey = mongoose.model('FreeKey', freeKeySchema);
const Blacklist = mongoose.model('Blacklist', blacklistSchema);

// ============================================
// CONSTANTS
// ============================================

const PREFIX = '!';
const HWID_RESET_DAYS = 7;
const FREE_KEY_EXPIRY_HOURS = 24;

const ADMIN_ROLE_IDS = (process.env.ADMIN_ROLE_IDS || '').split(',').filter(Boolean);

// ============================================
// UTILITY FUNCTIONS
// ============================================

function generateLifetimeKey() {
    const chars = '0123456789abcdef';
    let key = '';
    for (let i = 0; i < 24; i++) {
        key += chars[Math.floor(Math.random() * chars.length)];
    }
    return key;
}

function generateLicenseCode() {
    const chars = '0123456789abcdef';
    let code = '';
    for (let i = 0; i < 8; i++) {
        code += chars[Math.floor(Math.random() * chars.length)];
    }
    return code;
}

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

function isAdmin(member) {
    if (member.permissions.has('Administrator')) return true;
    if (ADMIN_ROLE_IDS.length === 0) {
        // Fallback: check for role names
        return member.roles.cache.some(r =>
            r.name === 'Admin' || r.name === 'PawZHub Admin' || r.name === 'Owner'
        );
    }
    return member.roles.cache.some(r => ADMIN_ROLE_IDS.includes(r.id));
}

function daysUntil(date) {
    if (!date) return 0;
    const diff = date.getTime() - Date.now();
    return Math.max(0, Math.ceil(diff / (1000 * 60 * 60 * 24)));
}

function hoursUntil(date) {
    if (!date) return 0;
    const diff = date.getTime() - Date.now();
    return Math.max(0, Math.ceil(diff / (1000 * 60 * 60)));
}

// ============================================
// BOT READY
// ============================================

client.on('ready', () => {
    console.log(`[PawZHub] Bot online: ${client.user.tag}`);
    console.log(`[PawZHub] Servers: ${client.guilds.cache.size}`);
});

// ============================================
// MESSAGE HANDLER
// ============================================

client.on('messageCreate', async (message) => {
    if (message.author.bot) return;
    if (!message.content.startsWith(PREFIX)) return;

    const args = message.content.slice(PREFIX.length).trim().split(/ +/);
    const command = args.shift().toLowerCase();

    try {
        // --- User Commands ---
        switch (command) {
            case 'redeem':
                await cmdRedeem(message, args);
                break;
            case 'mykey':
            case 'keys':
                await cmdMyKeys(message);
                break;
            case 'resetkey':
                await cmdResetKey(message, args);
                break;
            case 'getkey':
            case 'freekey':
                await cmdFreeKey(message, args);
                break;
            case 'help':
                await cmdHelp(message);
                break;

            // --- Admin Commands ---
            case 'admin':
                await handleAdmin(message, args);
                break;
        }
    } catch (err) {
        console.error(`[Error] ${command}:`, err);
        message.reply('An error occurred. Contact admin.').catch(() => {});
    }
});

// ============================================
// USER COMMANDS
// ============================================

// !redeem <license_code> - Redeem license to get lifetime key
async function cmdRedeem(message, args) {
    if (!args[0]) {
        return message.reply(
            'Usage: `!redeem <license_code>`\n' +
            'Example: `!redeem a12e137e`'
        );
    }

    const code = args[0].toLowerCase();

    // Validate format: 8 char hex
    if (!/^[a-f0-9]{8}$/.test(code)) {
        return message.reply(
            'Invalid format.\n' +
            'License code must be 8 characters (hex).\n' +
            'Example: `a12e137e`'
        );
    }

    const license = await License.findOne({ code });

    if (!license) {
        return message.reply('Invalid license code. Check and try again.');
    }

    if (license.status === 'redeemed') {
        return message.reply(
            `This license was already redeemed by <@${license.redeemedBy}>.`
        );
    }

    // Generate lifetime key
    const lifetimeKey = generateLifetimeKey();

    // Create lifetime key in DB
    await LifetimeKey.create({
        key: lifetimeKey,
        licenseCode: code,
        discordId: message.author.id,
        discordTag: message.author.tag,
        nextResetAvailable: new Date(Date.now() + HWID_RESET_DAYS * 24 * 60 * 60 * 1000)
    });

    // Mark license as redeemed
    license.status = 'redeemed';
    license.redeemedBy = message.author.id;
    license.redeemedAt = new Date();
    license.redeemedTag = message.author.tag;
    license.generatedKey = lifetimeKey;
    await license.save();

    // DM the key to user
    const dmEmbed = new EmbedBuilder()
        .setTitle('License Redeemed')
        .setColor(0x00ff00)
        .setDescription('Your Lifetime key has been generated.')
        .addFields(
            { name: 'Lifetime Key', value: `\`${lifetimeKey}\``, inline: false },
            { name: 'License Code', value: `\`${code}\``, inline: true },
            { name: 'Duration', value: 'Lifetime', inline: true },
            { name: 'HWID Reset', value: `Every ${HWID_RESET_DAYS} days`, inline: true }
        )
        .setFooter({ text: 'Keep this key private!' })
        .setTimestamp();

    try {
        await message.author.send({ embeds: [dmEmbed] });
        message.reply('License redeemed! Check your DMs.');
    } catch {
        message.reply(
            'License redeemed but I could not DM you.\n' +
            'Enable DMs from server members and try `!mykey`.'
        );
    }

    console.log(`[Redeem] ${code} -> ${message.author.tag}`);
}

// !mykeys - View your lifetime keys
async function cmdMyKeys(message) {
    const keys = await LifetimeKey.find({ discordId: message.author.id });

    if (keys.length === 0) {
        return message.reply(
            'You have no keys.\n' +
            'Purchase a license and use `!redeem <code>` to get one.'
        );
    }

    const embed = new EmbedBuilder()
        .setTitle('Your Lifetime Keys')
        .setColor(0x667eea)
        .setDescription(`You have **${keys.length}** lifetime key(s).`)
        .setTimestamp();

    for (const k of keys) {
        const resetDays = daysUntil(k.nextResetAvailable);
        const resetText = resetDays > 0 ? `${resetDays}d` : 'Available now';
        const hwidCount = k.boundHWIDs.length;

        embed.addFields({
            name: `Key: \`${k.key.slice(0, 8)}...\` [${k.status}]`,
            value: [
                `License: \`${k.licenseCode}\``,
                `Devices: ${hwidCount} bound`,
                `HWID Reset: ${resetText}`,
                `Uses: ${k.totalUses}`
            ].join('\n'),
            inline: false
        });
    }

    try {
        await message.author.send({ embeds: [embed] });
        message.reply('Check your DMs!');
    } catch {
        message.reply('Could not DM you. Enable DMs from server members.');
    }
}

// !resetkey <lifetime_key> - Reset HWID (every 7 days)
async function cmdResetKey(message, args) {
    if (!args[0]) {
        return message.reply(
            'Usage: `!resetkey <lifetime_key>`\n' +
            'Example: `!resetkey f03d3260914a9475faf29b12`'
        );
    }

    const keyInput = args[0].toLowerCase();

    const keyData = await LifetimeKey.findOne({
        key: keyInput,
        discordId: message.author.id
    });

    if (!keyData) {
        return message.reply('Key not found or you do not own this key.');
    }

    // Check 7-day cooldown
    if (keyData.nextResetAvailable && Date.now() < keyData.nextResetAvailable.getTime()) {
        const hrs = hoursUntil(keyData.nextResetAvailable);
        const dys = daysUntil(keyData.nextResetAvailable);
        return message.reply(
            `HWID reset not available yet.\n` +
            `Available in ${dys} day(s) (${hrs} hours).`
        );
    }

    const clearedCount = keyData.boundHWIDs.length;
    keyData.boundHWIDs = [];
    keyData.lastHWIDReset = new Date();
    keyData.nextResetAvailable = new Date(Date.now() + HWID_RESET_DAYS * 24 * 60 * 60 * 1000);
    await keyData.save();

    const embed = new EmbedBuilder()
        .setTitle('HWID Reset Successful')
        .setColor(0x00ff00)
        .addFields(
            { name: 'Key', value: `\`${keyInput.slice(0, 8)}...\``, inline: true },
            { name: 'Devices Cleared', value: `${clearedCount}`, inline: true },
            { name: 'Next Reset', value: `${HWID_RESET_DAYS} days`, inline: true }
        )
        .setFooter({ text: 'You can now use this key on new devices.' })
        .setTimestamp();

    try {
        await message.author.send({ embeds: [embed] });
        message.reply('HWID reset successful!');
    } catch {
        message.reply('HWID reset successful but could not DM you.');
    }

    console.log(`[HWID Reset] ${keyInput.slice(0, 8)}... by ${message.author.tag}`);
}

// !freekey - Get a free 24h key via Linkvertise
async function cmdFreeKey(message, args) {
    const userId = message.author.id;
    const hwid = args[0] || null;

    // Check blacklist
    const blacklisted = await Blacklist.findOne({ userId });
    if (blacklisted) {
        return message.reply('You are blacklisted from free keys.');
    }

    // Check if user already has active free key
    const existing = await FreeKey.findOne({
        userId,
        status: 'active',
        expiresAt: { $gt: new Date() }
    });

    if (existing) {
        return message.reply(
            `You already have an active key:\n\`${existing.key}\`\n` +
            `Expires: <t:${Math.floor(existing.expiresAt.getTime() / 1000)}:R>`
        );
    }

    // Generate free key (24h)
    const key = generateFreeKey();

    await FreeKey.create({
        key,
        userId,
        hwid,
        tier: 'free',
        features: ['basic'],
        expiresAt: new Date(Date.now() + FREE_KEY_EXPIRY_HOURS * 60 * 60 * 1000),
        maxUses: -1,
        source: 'discord'
    });

    const embed = new EmbedBuilder()
        .setTitle('Free Key Generated')
        .setColor(0x667eea)
        .setDescription(`\`${key}\``)
        .addFields(
            { name: 'Duration', value: `${FREE_KEY_EXPIRY_HOURS} hours`, inline: true },
            { name: 'Devices', value: '1 (HWID locked)', inline: true },
            { name: 'Uses', value: 'Unlimited', inline: true },
            { name: 'Features', value: 'Basic', inline: true }
        )
        .setFooter({ text: 'This key expires in 24 hours.' })
        .setTimestamp();

    try {
        await message.author.send({ embeds: [embed] });
        message.reply('Free key generated! Check your DMs.');
    } catch {
        message.reply('Could not DM you. Enable DMs and try again.');
    }

    console.log(`[FreeKey] ${key} -> ${message.author.tag}`);
}

// !help - Show commands
async function cmdHelp(message) {
    const embed = new EmbedBuilder()
        .setTitle('PawZHub Commands')
        .setColor(0x667eea)
        .setDescription('Available commands:')
        .addFields(
            {
                name: 'User Commands',
                value: [
                    '`!redeem <code>` - Redeem license code for lifetime key',
                    '`!mykeys` - View your lifetime keys',
                    '`!resetkey <key>` - Reset HWID (every 7 days)',
                    '`!freekey` - Get a free 24h key',
                    '`!help` - Show this message'
                ].join('\n'),
                inline: false
            },
            {
                name: 'How to Get Premium',
                value: [
                    '1. Purchase a license code',
                    '2. Use `!redeem <code>` here',
                    '3. Receive your lifetime key via DM',
                    '4. Use the key in your executor'
                ].join('\n'),
                inline: false
            }
        )
        .setFooter({ text: 'PawZHub v2.0' })
        .setTimestamp();

    message.reply({ embeds: [embed] });
}

// ============================================
// ADMIN COMMANDS
// ============================================

async function handleAdmin(message, args) {
    if (!isAdmin(message.member)) {
        return message.reply('You need Admin role to use admin commands.');
    }

    const sub = (args[0] || '').toLowerCase();

    switch (sub) {
        case 'help':
            await adminHelp(message);
            break;
        case 'gen':
        case 'generate':
            await adminGenLicenses(message, args.slice(1));
            break;
        case 'check':
            await adminCheck(message, args.slice(1));
            break;
        case 'ban':
            await adminBan(message, args.slice(1));
            break;
        case 'unban':
            await adminUnban(message, args.slice(1));
            break;
        case 'blacklist':
            await adminBlacklist(message, args.slice(1));
            break;
        case 'unblacklist':
            await adminUnblacklist(message, args.slice(1));
            break;
        case 'stats':
            await adminStats(message);
            break;
        case 'list':
            await adminListLicenses(message, args.slice(1));
            break;
        default:
            await adminHelp(message);
    }
}

// !admin help
async function adminHelp(message) {
    const embed = new EmbedBuilder()
        .setTitle('Admin Commands')
        .setColor(0xff6b6b)
        .addFields(
            { name: '!admin gen <count>', value: 'Generate license codes (1-100)' },
            { name: '!admin list [unused|redeemed]', value: 'List licenses' },
            { name: '!admin check <code|key>', value: 'Check license or lifetime key info' },
            { name: '!admin ban <key>', value: 'Ban a lifetime key' },
            { name: '!admin unban <key>', value: 'Unban a lifetime key' },
            { name: '!admin blacklist <user_id>', value: 'Blacklist user from free keys' },
            { name: '!admin unblacklist <user_id>', value: 'Remove user from blacklist' },
            { name: '!admin stats', value: 'Show system statistics' }
        )
        .setFooter({ text: 'Admin Only' })
        .setTimestamp();

    message.reply({ embeds: [embed] });
}

// !admin gen <count> - Generate license codes
async function adminGenLicenses(message, args) {
    const count = parseInt(args[0]) || 1;

    if (count < 1 || count > 100) {
        return message.reply('Count must be between 1 and 100.');
    }

    const codes = [];

    for (let i = 0; i < count; i++) {
        let code = generateLicenseCode();
        let attempts = 0;

        // Ensure unique
        while (await License.findOne({ code }) && attempts < 100) {
            code = generateLicenseCode();
            attempts++;
        }

        await License.create({ code });
        codes.push(code);
    }

    // Send in chunks (Discord 2000 char limit)
    const chunkSize = 25;
    for (let i = 0; i < codes.length; i += chunkSize) {
        const chunk = codes.slice(i, i + chunkSize);

        const embed = new EmbedBuilder()
            .setTitle(`Generated Licenses (${i + 1}-${Math.min(i + chunkSize, codes.length)} / ${count})`)
            .setColor(0x00ff00)
            .setDescription('```\n' + chunk.join('\n') + '\n```')
            .setFooter({ text: `Generated by ${message.author.tag}` })
            .setTimestamp();

        await message.channel.send({ embeds: [embed] });
    }

    console.log(`[Admin] ${count} licenses generated by ${message.author.tag}`);
}

// !admin list [unused|redeemed]
async function adminListLicenses(message, args) {
    const filter = {};
    if (args[0]) {
        filter.status = args[0].toLowerCase();
    }

    const licenses = await License.find(filter)
        .sort({ createdAt: -1 })
        .limit(50);

    if (licenses.length === 0) {
        return message.reply('No licenses found.');
    }

    const lines = licenses.map(l => {
        const status = l.status === 'unused' ? '[UNUSED]' : `[REDEEMED by ${l.redeemedTag || l.redeemedBy}]`;
        return `${l.code} ${status}`;
    });

    const embed = new EmbedBuilder()
        .setTitle(`Licenses (${licenses.length} shown)`)
        .setColor(0x667eea)
        .setDescription('```\n' + lines.join('\n') + '\n```')
        .setTimestamp();

    message.reply({ embeds: [embed] });
}

// !admin check <code|key>
async function adminCheck(message, args) {
    if (!args[0]) {
        return message.reply('Usage: `!admin check <license_code | lifetime_key>`');
    }

    const input = args[0].toLowerCase();

    // License code: 8 char hex
    if (/^[a-f0-9]{8}$/.test(input)) {
        const license = await License.findOne({ code: input });

        if (!license) {
            return message.reply('License not found.');
        }

        const embed = new EmbedBuilder()
            .setTitle('License Info')
            .setColor(license.status === 'unused' ? 0x00ff00 : 0x999999)
            .addFields(
                { name: 'Code', value: `\`${license.code}\``, inline: true },
                { name: 'Status', value: license.status, inline: true },
                { name: 'Created', value: license.createdAt.toDateString(), inline: true }
            );

        if (license.status === 'redeemed') {
            embed.addFields(
                { name: 'Redeemed By', value: `<@${license.redeemedBy}> (${license.redeemedTag})`, inline: true },
                { name: 'Redeemed At', value: license.redeemedAt.toDateString(), inline: true },
                { name: 'Generated Key', value: `\`${license.generatedKey}\``, inline: false }
            );
        }

        return message.reply({ embeds: [embed] });
    }

    // Lifetime key: 24 char hex
    if (/^[a-f0-9]{24}$/.test(input)) {
        const keyData = await LifetimeKey.findOne({ key: input });

        if (!keyData) {
            return message.reply('Lifetime key not found.');
        }

        const resetDays = daysUntil(keyData.nextResetAvailable);

        const embed = new EmbedBuilder()
            .setTitle('Lifetime Key Info')
            .setColor(keyData.status === 'active' ? 0x00ff00 : 0xff0000)
            .addFields(
                { name: 'Key', value: `\`${keyData.key}\``, inline: false },
                { name: 'Status', value: keyData.status, inline: true },
                { name: 'License', value: `\`${keyData.licenseCode}\``, inline: true },
                { name: 'Owner', value: `<@${keyData.discordId}> (${keyData.discordTag})`, inline: true },
                { name: 'Devices', value: `${keyData.boundHWIDs.length}`, inline: true },
                { name: 'Uses', value: `${keyData.totalUses}`, inline: true },
                { name: 'HWID Reset', value: resetDays > 0 ? `In ${resetDays}d` : 'Available now', inline: true },
                { name: 'Created', value: keyData.createdAt.toDateString(), inline: true }
            );

        if (keyData.lastUsed) {
            embed.addFields({ name: 'Last Used', value: keyData.lastUsed.toDateString(), inline: true });
        }

        if (keyData.boundHWIDs.length > 0) {
            const hwids = keyData.boundHWIDs.map(h => `\`${h.slice(0, 12)}...\``).join('\n');
            embed.addFields({ name: 'Bound HWIDs', value: hwids, inline: false });
        }

        return message.reply({ embeds: [embed] });
    }

    message.reply('Invalid format. License = 8 chars, Lifetime key = 24 chars.');
}

// !admin ban <key>
async function adminBan(message, args) {
    if (!args[0]) {
        return message.reply('Usage: `!admin ban <lifetime_key>`');
    }

    const keyData = await LifetimeKey.findOne({ key: args[0].toLowerCase() });

    if (!keyData) {
        return message.reply('Lifetime key not found.');
    }

    if (keyData.status === 'banned') {
        return message.reply('Key is already banned.');
    }

    keyData.status = 'banned';
    await keyData.save();

    const embed = new EmbedBuilder()
        .setTitle('Key Banned')
        .setColor(0xff0000)
        .addFields(
            { name: 'Key', value: `\`${keyData.key}\``, inline: true },
            { name: 'Owner', value: `<@${keyData.discordId}>`, inline: true },
            { name: 'Banned By', value: message.author.tag, inline: true }
        )
        .setTimestamp();

    message.reply({ embeds: [embed] });
    console.log(`[Admin] Key banned: ${keyData.key.slice(0, 8)}... by ${message.author.tag}`);
}

// !admin unban <key>
async function adminUnban(message, args) {
    if (!args[0]) {
        return message.reply('Usage: `!admin unban <lifetime_key>`');
    }

    const keyData = await LifetimeKey.findOne({ key: args[0].toLowerCase() });

    if (!keyData) {
        return message.reply('Lifetime key not found.');
    }

    if (keyData.status === 'active') {
        return message.reply('Key is not banned.');
    }

    keyData.status = 'active';
    await keyData.save();

    const embed = new EmbedBuilder()
        .setTitle('Key Unbanned')
        .setColor(0x00ff00)
        .addFields(
            { name: 'Key', value: `\`${keyData.key}\``, inline: true },
            { name: 'Owner', value: `<@${keyData.discordId}>`, inline: true },
            { name: 'Unbanned By', value: message.author.tag, inline: true }
        )
        .setTimestamp();

    message.reply({ embeds: [embed] });
    console.log(`[Admin] Key unbanned: ${keyData.key.slice(0, 8)}... by ${message.author.tag}`);
}

// !admin blacklist <user_id>
async function adminBlacklist(message, args) {
    if (!args[0]) {
        return message.reply('Usage: `!admin blacklist <user_id>`');
    }

    const userId = args[0];
    const reason = args.slice(1).join(' ') || 'No reason';

    const exists = await Blacklist.findOne({ userId });
    if (exists) {
        return message.reply('User is already blacklisted.');
    }

    await Blacklist.create({ userId, reason });

    message.reply(`User <@${userId}> blacklisted. Reason: ${reason}`);
    console.log(`[Admin] Blacklisted ${userId} by ${message.author.tag}`);
}

// !admin unblacklist <user_id>
async function adminUnblacklist(message, args) {
    if (!args[0]) {
        return message.reply('Usage: `!admin unblacklist <user_id>`');
    }

    const result = await Blacklist.deleteOne({ userId: args[0] });

    if (result.deletedCount === 0) {
        return message.reply('User is not blacklisted.');
    }

    message.reply(`User <@${args[0]}> removed from blacklist.`);
}

// !admin stats
async function adminStats(message) {
    const totalLicenses = await License.countDocuments();
    const unusedLicenses = await License.countDocuments({ status: 'unused' });
    const redeemedLicenses = await License.countDocuments({ status: 'redeemed' });

    const totalKeys = await LifetimeKey.countDocuments();
    const activeKeys = await LifetimeKey.countDocuments({ status: 'active' });
    const bannedKeys = await LifetimeKey.countDocuments({ status: 'banned' });

    const totalFreeKeys = await FreeKey.countDocuments();
    const activeFreeKeys = await FreeKey.countDocuments({ status: 'active', expiresAt: { $gt: new Date() } });

    const blacklistedUsers = await Blacklist.countDocuments();

    // Aggregate total uses
    const usageResult = await LifetimeKey.aggregate([
        { $group: { _id: null, total: { $sum: '$totalUses' } } }
    ]);
    const totalUses = usageResult.length > 0 ? usageResult[0].total : 0;

    const embed = new EmbedBuilder()
        .setTitle('System Statistics')
        .setColor(0x667eea)
        .addFields(
            { name: '-- Licenses --', value: '\u200b', inline: false },
            { name: 'Total', value: `${totalLicenses}`, inline: true },
            { name: 'Unused', value: `${unusedLicenses}`, inline: true },
            { name: 'Redeemed', value: `${redeemedLicenses}`, inline: true },
            { name: '-- Lifetime Keys --', value: '\u200b', inline: false },
            { name: 'Total', value: `${totalKeys}`, inline: true },
            { name: 'Active', value: `${activeKeys}`, inline: true },
            { name: 'Banned', value: `${bannedKeys}`, inline: true },
            { name: '-- Free Keys --', value: '\u200b', inline: false },
            { name: 'Total', value: `${totalFreeKeys}`, inline: true },
            { name: 'Active', value: `${activeFreeKeys}`, inline: true },
            { name: '-- Other --', value: '\u200b', inline: false },
            { name: 'Total Uses', value: `${totalUses}`, inline: true },
            { name: 'Blacklisted', value: `${blacklistedUsers}`, inline: true },
            { name: 'Bot Uptime', value: `${Math.floor(process.uptime() / 60)}m`, inline: true }
        )
        .setFooter({ text: 'PawZHub System' })
        .setTimestamp();

    message.reply({ embeds: [embed] });
}

// ============================================
// START
// ============================================

async function start() {
    try {
        const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/pawzhub';
        await mongoose.connect(mongoUri);
        console.log('[PawZHub] MongoDB connected');

        await client.login(process.env.DISCORD_BOT_TOKEN);
    } catch (err) {
        console.error('[PawZHub] Startup error:', err);
        process.exit(1);
    }
}

start();
