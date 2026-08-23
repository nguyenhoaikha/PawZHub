// ============================================
// PawZHub Discord Bot v2.1 Pro
// Slash commands + Buttons + Select Menus + Pagination
// No emoji - Unicode symbols only
// ============================================

const {
    Client,
    GatewayIntentBits,
    EmbedBuilder,
    ActionRowBuilder,
    ButtonBuilder,
    ButtonStyle,
    StringSelectMenuBuilder,
    ComponentType,
    AttachmentBuilder
} = require('discord.js');
const mongoose = require('mongoose');
const fs = require('fs');
require('dotenv').config();

// ============================================
// CLIENT
// ============================================

const client = new Client({
    intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMessages,
        GatewayIntentBits.MessageContent,
        GatewayIntentBits.DirectMessages
    ]
});

// ============================================
// CONSTANTS
// ============================================

const HWID_RESET_DAYS = 7;
const FREE_KEY_EXPIRY_HOURS = 24;
const ADMIN_ROLE_IDS = (process.env.ADMIN_ROLE_IDS || '').split(',').filter(Boolean);
const ITEMS_PER_PAGE = 10;

const ICON = {
    KEY:    '[KEY]',
    OK:     '[OK]',
    ERR:    '[X]',
    WARN:   '[!]',
    INFO:   '[i]',
    ARROW:  '>>',
    LOCK:   '[LOCK]',
    UNLOCK: '[UNLOCK]',
    BAN:    '[BAN]',
    UNBAN:  '[UNBAN]',
    STATS:  '[STATS]',
    USER:   '[USER]',
    SHIELD: '[SHIELD]',
    STAR:   '[*]',
    CLOCK:  '[CLOCK]',
    DEV:    '[DEV]',
    LIST:   '[LIST]',
    GEN:    '[GEN]',
    SEARCH: '[?]',
    PAGE:   '[PAGE]',
    FILE:   '[FILE]',
    COPY:   '[COPY]'
};

const COLORS = {
    GREEN:  0x00ff00,
    RED:    0xff0000,
    BLUE:   0x667eea,
    ORANGE: 0xff9900,
    GRAY:   0x999999,
    PURPLE: 0x9b59b6
};

// ============================================
// COOLDOWN SYSTEM
// ============================================

const cooldowns = new Map();

function checkCooldown(userId, command, seconds = 5) {
    const key = `${userId}:${command}`;
    const now = Date.now();
    const cooldownEnd = cooldowns.get(key) || 0;

    if (now < cooldownEnd) {
        return { allowed: false, remaining: Math.ceil((cooldownEnd - now) / 1000) };
    }

    cooldowns.set(key, now + seconds * 1000);
    return { allowed: true };
}

// ============================================
// LOGGING SYSTEM
// ============================================

async function logAction(action, details) {
    const logChannel = client.channels.cache.get(process.env.LOG_CHANNEL_ID);
    if (!logChannel) return;

    const embed = new EmbedBuilder()
        .setTitle(`${ICON.INFO} ${action}`)
        .setColor(COLORS.BLUE)
        .addFields(
            { name: `${ICON.USER} Admin`, value: details.admin || 'System', inline: true },
            { name: `${ICON.INFO} Details`, value: details.message || 'N/A', inline: false }
        )
        .setTimestamp();

    if (details.target) {
        embed.addFields({ name: `${ICON.USER} Target`, value: details.target, inline: true });
    }

    logChannel.send({ embeds: [embed] }).catch(() => {});
}

// ============================================
// DATABASE SCHEMAS
// ============================================

const licenseSchema = new mongoose.Schema({
    code:        { type: String, required: true, unique: true, lowercase: true },
    status:      { type: String, enum: ['unused', 'redeemed'], default: 'unused' },
    redeemedBy:  { type: String, default: null },
    redeemedAt:  { type: Date, default: null },
    redeemedTag: { type: String, default: null },
    generatedKey:{ type: String, default: null },
    createdAt:   { type: Date, default: Date.now }
});

const lifetimeKeySchema = new mongoose.Schema({
    key:                { type: String, required: true, unique: true, lowercase: true },
    licenseCode:        { type: String, required: true },
    discordId:          { type: String, required: true },
    discordTag:         { type: String, required: true },
    boundHWIDs:         { type: [String], default: [] },
    lastHWIDReset:      { type: Date, default: null },
    nextResetAvailable: { type: Date, default: null },
    totalUses:          { type: Number, default: 0 },
    lastUsed:           { type: Date, default: null },
    status:             { type: String, enum: ['active', 'banned'], default: 'active' },
    createdAt:          { type: Date, default: Date.now }
});

const freeKeySchema = new mongoose.Schema({
    key:       { type: String, required: true, unique: true },
    userId:    { type: String, required: true },
    hwid:      { type: String, default: null },
    tier:      { type: String, default: 'free' },
    features:  { type: [String], default: ['basic'] },
    expiresAt: { type: Date, required: true },
    uses:      { type: Number, default: 0 },
    maxUses:   { type: Number, default: -1 },
    status:    { type: String, enum: ['active', 'expired', 'banned'], default: 'active' },
    source:    { type: String, default: 'discord' },
    createdAt: { type: Date, default: Date.now }
});

const blacklistSchema = new mongoose.Schema({
    userId:   { type: String, required: true, unique: true },
    reason:   { type: String, default: '' },
    addedAt:  { type: Date, default: Date.now }
});

const License     = mongoose.model('License', licenseSchema);
const LifetimeKey = mongoose.model('LifetimeKey', lifetimeKeySchema);
const FreeKey     = mongoose.model('FreeKey', freeKeySchema);
const Blacklist   = mongoose.model('Blacklist', blacklistSchema);

// ============================================
// UTILITY FUNCTIONS
// ============================================

function generateLifetimeKey() {
    const chars = '0123456789abcdef';
    return Array.from({ length: 24 }, () => chars[Math.floor(Math.random() * 16)]).join('');
}

function generateLicenseCode() {
    const chars = '0123456789abcdef';
    return Array.from({ length: 8 }, () => chars[Math.floor(Math.random() * 16)]).join('');
}

function generateFreeKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    const part = () => Array.from({ length: 4 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
    return `PAWZ-${part()}-${part()}-${part()}`;
}

function isAdmin(member) {
    if (member.permissions.has('Administrator')) return true;
    if (ADMIN_ROLE_IDS.length === 0) {
        return member.roles.cache.some(r => ['Admin', 'PawZHub Admin', 'Owner'].includes(r.name));
    }
    return member.roles.cache.some(r => ADMIN_ROLE_IDS.includes(r.id));
}

function daysUntil(date) {
    if (!date) return 0;
    return Math.max(0, Math.ceil((date.getTime() - Date.now()) / 86400000));
}

function hoursUntil(date) {
    if (!date) return 0;
    return Math.max(0, Math.ceil((date.getTime() - Date.now()) / 3600000));
}

function formatDate(date) {
    if (!date) return 'N/A';
    return date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
}

function createConfirmButtons(id) {
    return new ActionRowBuilder().addComponents(
        new ButtonBuilder()
            .setCustomId(`${id}_confirm`)
            .setLabel('Confirm')
            .setStyle(ButtonStyle.Danger),
        new ButtonBuilder()
            .setCustomId(`${id}_cancel`)
            .setLabel('Cancel')
            .setStyle(ButtonStyle.Secondary)
    );
}

function createPaginationButtons(page, totalPages) {
    return new ActionRowBuilder().addComponents(
        new ButtonBuilder()
            .setCustomId('page_first')
            .setLabel('<< First')
            .setStyle(ButtonStyle.Secondary)
            .setDisabled(page === 1),
        new ButtonBuilder()
            .setCustomId('page_prev')
            .setLabel('< Prev')
            .setStyle(ButtonStyle.Primary)
            .setDisabled(page === 1),
        new ButtonBuilder()
            .setCustomId('page_info')
            .setLabel(`${page} / ${totalPages}`)
            .setStyle(ButtonStyle.Secondary)
            .setDisabled(true),
        new ButtonBuilder()
            .setCustomId('page_next')
            .setLabel('Next >')
            .setStyle(ButtonStyle.Primary)
            .setDisabled(page === totalPages),
        new ButtonBuilder()
            .setCustomId('page_last')
            .setLabel('Last >>')
            .setStyle(ButtonStyle.Secondary)
            .setDisabled(page === totalPages)
    );
}

// ============================================
// BOT READY
// ============================================

client.on('ready', () => {
    console.log(`[PawZHub] Bot online: ${client.user.tag}`);
    console.log(`[PawZHub] Servers: ${client.guilds.cache.size}`);
    console.log(`[PawZHub] Commands: slash commands ready`);
});

// ============================================
// COMMAND HANDLER
// ============================================

client.on('interactionCreate', async (interaction) => {
    // Handle slash commands
    if (interaction.isChatInputCommand()) {
        const handlers = {
            redeem:   handleRedeem,
            mykeys:   handleMyKeys,
            resetkey: handleResetKey,
            freekey:  handleFreeKey,
            help:     handleHelp,
            admin:    handleAdmin
        };

        const handler = handlers[interaction.commandName];
        if (!handler) return;

        try {
            await handler(interaction);
        } catch (err) {
            console.error(`[Error] ${interaction.commandName}:`, err);
            const msg = { content: `${ICON.ERR} An error occurred. Contact admin.`, ephemeral: true };
            if (interaction.replied || interaction.deferred) {
                await interaction.followUp(msg).catch(() => {});
            } else {
                await interaction.reply(msg).catch(() => {});
            }
        }
    }

    // Handle buttons
    if (interaction.isButton()) {
        await handleButton(interaction);
    }

    // Handle select menus
    if (interaction.isStringSelectMenu()) {
        await handleSelectMenu(interaction);
    }
});

// ============================================
// BUTTON HANDLER
// ============================================

async function handleButton(interaction) {
    const [action, id, extra] = interaction.customId.split('_');

    try {
        switch (action) {
            case 'page':
                await handlePagination(interaction);
                break;
            case 'copy':
                await handleCopyButton(interaction);
                break;
            case 'ban':
            case 'unban':
                if (extra === 'confirm') await handleBanConfirm(interaction, action);
                else if (extra === 'cancel') await handleBanCancel(interaction);
                break;
            case 'bl':
                if (extra === 'confirm') await handleBlacklistConfirm(interaction);
                else if (extra === 'cancel') await handleBlacklistCancel(interaction);
                break;
        }
    } catch (err) {
        console.error('[Button Error]', err);
        await interaction.reply({ content: `${ICON.ERR} Error processing action.`, ephemeral: true }).catch(() => {});
    }
}

// Pagination
async function handlePagination(interaction) {
    const page = parseInt(interaction.message.embeds[0]?.footer?.text?.match(/\d+/)?.[0] || 1);
    const totalPages = parseInt(interaction.message.embeds[0]?.footer?.text?.match(/\/ (\d+)/)?.[1] || 1);

    let newPage = page;
    switch (interaction.customId) {
        case 'page_first': newPage = 1; break;
        case 'page_prev':  newPage = Math.max(1, page - 1); break;
        case 'page_next':  newPage = Math.min(totalPages, page + 1); break;
        case 'page_last':  newPage = totalPages; break;
    }

    await interaction.deferUpdate();

    const licenses = await License.find().sort({ createdAt: -1 });
    const start = (newPage - 1) * ITEMS_PER_PAGE;
    const chunk = licenses.slice(start, start + ITEMS_PER_PAGE);

    const lines = chunk.map((l, i) => {
        const num = start + i + 1;
        const status = l.status === 'unused' ? '[UNUSED]' : `[USED]`;
        return `${num}. ${l.code} ${status}`;
    });

    const embed = new EmbedBuilder()
        .setTitle(`${ICON.LIST} Licenses (Page ${newPage}/${totalPages})`)
        .setColor(COLORS.BLUE)
        .setDescription('```\n' + lines.join('\n') + '\n```')
        .setFooter({ text: `Page ${newPage} / ${totalPages} | Total: ${licenses.length}` })
        .setTimestamp();

    await interaction.editReply({
        embeds: [embed],
        components: [createPaginationButtons(newPage, totalPages)]
    });
}

// Copy key button
async function handleCopyButton(interaction) {
    const key = interaction.customId.replace('copy_', '');
    await interaction.reply({ content: `${ICON.COPY} Key copied to clipboard!\n\`${key}\``, ephemeral: true });
}

// Ban confirm
async function handleBanConfirm(interaction, action) {
    await interaction.deferUpdate();

    const keyInput = interaction.message.embeds[0]?.fields?.find(f => f.name.includes('Key'))?.value?.replace(/[`]/g, '');
    if (!keyInput) return;

    const keyData = await LifetimeKey.findOne({ key: keyInput });
    if (!keyData) return;

    if (action === 'ban') {
        keyData.status = 'banned';
        await keyData.save();

        const embed = new EmbedBuilder()
            .setTitle(`${ICON.BAN} Key Banned`)
            .setColor(COLORS.RED)
            .setDescription(`${ICON.OK} Key has been banned successfully.`)
            .addFields(
                { name: `${ICON.KEY} Key`,    value: `\`${keyData.key}\``,        inline: true },
                { name: `${ICON.USER} Owner`, value: `<@${keyData.discordId}>`,   inline: true },
                { name: `${ICON.SHIELD} By`,  value: interaction.user.tag,        inline: true }
            )
            .setTimestamp();

        await interaction.editReply({ embeds: [embed], components: [] });
        await logAction('Key Banned', { admin: interaction.user.tag, target: `\`${keyData.key}\``, message: `Banned key owned by <@${keyData.discordId}>` });
    } else {
        keyData.status = 'active';
        await keyData.save();

        const embed = new EmbedBuilder()
            .setTitle(`${ICON.UNBAN} Key Unbanned`)
            .setColor(COLORS.GREEN)
            .setDescription(`${ICON.OK} Key has been unbanned successfully.`)
            .addFields(
                { name: `${ICON.KEY} Key`,    value: `\`${keyData.key}\``,        inline: true },
                { name: `${ICON.USER} Owner`, value: `<@${keyData.discordId}>`,   inline: true },
                { name: `${ICON.SHIELD} By`,  value: interaction.user.tag,        inline: true }
            )
            .setTimestamp();

        await interaction.editReply({ embeds: [embed], components: [] });
        await logAction('Key Unbanned', { admin: interaction.user.tag, target: `\`${keyData.key}\``, message: `Unbanned key owned by <@${keyData.discordId}>` });
    }
}

// Ban cancel
async function handleBanCancel(interaction) {
    await interaction.deferUpdate();
    const embed = new EmbedBuilder()
        .setTitle(`${ICON.CANCEL} Action Cancelled`)
        .setColor(COLORS.GRAY)
        .setDescription(`${ICON.INFO} The action has been cancelled.`)
        .setTimestamp();
    await interaction.editReply({ embeds: [embed], components: [] });
}

// Blacklist confirm
async function handleBlacklistConfirm(interaction) {
    await interaction.deferUpdate();

    const userId = interaction.message.embeds[0]?.fields?.find(f => f.name.includes('User'))?.value?.replace(/[<@>]/g, '');
    const reason = interaction.message.embeds[0]?.fields?.find(f => f.name.includes('Reason'))?.value || 'No reason';

    if (!userId) return;

    const exists = await Blacklist.findOne({ userId });
    if (exists) {
        return interaction.editReply({ content: `${ICON.WARN} User is already blacklisted.`, embeds: [], components: [] });
    }

    await Blacklist.create({ userId, reason });

    const embed = new EmbedBuilder()
        .setTitle(`${ICON.BAN} User Blacklisted`)
        .setColor(COLORS.RED)
        .setDescription(`${ICON.OK} User has been blacklisted successfully.`)
        .addFields(
            { name: `${ICON.USER} User`,   value: `<@${userId}>`,      inline: true },
            { name: `${ICON.INFO} Reason`, value: reason,              inline: true },
            { name: `${ICON.SHIELD} By`,   value: interaction.user.tag, inline: true }
        )
        .setTimestamp();

    await interaction.editReply({ embeds: [embed], components: [] });
    await logAction('User Blacklisted', { admin: interaction.user.tag, target: `<@${userId}>`, message: `Reason: ${reason}` });
}

// Blacklist cancel
async function handleBlacklistCancel(interaction) {
    await interaction.deferUpdate();
    const embed = new EmbedBuilder()
        .setTitle(`${ICON.WARN} Action Cancelled`)
        .setColor(COLORS.GRAY)
        .setDescription(`${ICON.INFO} The action has been cancelled.`)
        .setTimestamp();
    await interaction.editReply({ embeds: [embed], components: [] });
}

// ============================================
// SELECT MENU HANDLER
// ============================================

async function handleSelectMenu(interaction) {
    if (interaction.customId === 'select_license') {
        const code = interaction.values[0];
        const license = await License.findOne({ code });

        if (!license) {
            return interaction.reply({ content: `${ICON.ERR} License not found.`, ephemeral: true });
        }

        const embed = new EmbedBuilder()
            .setTitle(`${ICON.SEARCH} License Info`)
            .setColor(license.status === 'unused' ? COLORS.GREEN : COLORS.GRAY)
            .addFields(
                { name: `${ICON.KEY} Code`,      value: `\`${license.code}\``,          inline: true },
                { name: `${ICON.INFO} Status`,   value: license.status,                 inline: true },
                { name: `${ICON.CLOCK} Created`, value: formatDate(license.createdAt),  inline: true }
            );

        if (license.status === 'redeemed') {
            embed.addFields(
                { name: `${ICON.USER} Redeemed By`,  value: `<@${license.redeemedBy}>`, inline: true },
                { name: `${ICON.CLOCK} Redeemed At`, value: formatDate(license.redeemedAt), inline: true },
                { name: `${ICON.KEY} Generated Key`, value: `\`${license.generatedKey}\``, inline: false }
            );
        }

        await interaction.reply({ embeds: [embed], ephemeral: true });
    }
}

// ============================================
// USER COMMANDS
// ============================================

// /redeem <code>
async function handleRedeem(interaction) {
    const cd = checkCooldown(interaction.user.id, 'redeem', 10);
    if (!cd.allowed) {
        return interaction.reply({ content: `${ICON.WARN} Please wait ${cd.remaining}s before using this command again.`, ephemeral: true });
    }

    await interaction.deferReply();

    const code = interaction.options.getString('code').toLowerCase();

    if (!/^[a-f0-9]{8}$/.test(code)) {
        return interaction.editReply(
            `${ICON.ERR} Invalid format. License code must be 8 hex characters.\nExample: \`a12e137e\``
        );
    }

    const license = await License.findOne({ code });
    if (!license) {
        return interaction.editReply(`${ICON.ERR} Invalid license code. Check and try again.`);
    }

    if (license.status === 'redeemed') {
        return interaction.editReply(`${ICON.WARN} This license was already redeemed by <@${license.redeemedBy}>.`);
    }

    const lifetimeKey = generateLifetimeKey();

    await LifetimeKey.create({
        key: lifetimeKey,
        licenseCode: code,
        discordId: interaction.user.id,
        discordTag: interaction.user.tag,
        nextResetAvailable: new Date(Date.now() + HWID_RESET_DAYS * 86400000)
    });

    license.status = 'redeemed';
    license.redeemedBy = interaction.user.id;
    license.redeemedAt = new Date();
    license.redeemedTag = interaction.user.tag;
    license.generatedKey = lifetimeKey;
    await license.save();

    const copyButton = new ActionRowBuilder().addComponents(
        new ButtonBuilder()
            .setCustomId(`copy_${lifetimeKey}`)
            .setLabel('Copy Key')
            .setStyle(ButtonStyle.Success)
    );

    const dmEmbed = new EmbedBuilder()
        .setTitle(`${ICON.KEY} License Redeemed`)
        .setColor(COLORS.GREEN)
        .setDescription(`${ICON.OK} Your Lifetime key has been generated.`)
        .addFields(
            { name: `${ICON.KEY} Lifetime Key`,    value: `\`${lifetimeKey}\``,             inline: false },
            { name: `${ICON.INFO} License Code`,   value: `\`${code}\``,                    inline: true },
            { name: `${ICON.CLOCK} Duration`,      value: `Lifetime`,                       inline: true },
            { name: `${ICON.DEVICE} HWID Reset`,   value: `Every ${HWID_RESET_DAYS} days`,  inline: true }
        )
        .setFooter({ text: `${ICON.LOCK} Keep this key private!` })
        .setTimestamp();

    try {
        await interaction.user.send({ embeds: [dmEmbed], components: [copyButton] });
        await interaction.editReply(`${ICON.OK} License redeemed! Check your DMs.`);
    } catch {
        await interaction.editReply(
            `${ICON.OK} License redeemed but I could not DM you.\n` +
            `Enable DMs from server members, then use \`/mykeys\`.`
        );
    }

    await logAction('License Redeemed', {
        admin: interaction.user.tag,
        target: `\`${code}\``,
        message: `Generated key: \`${lifetimeKey.slice(0, 8)}...\``
    });

    console.log(`[Redeem] ${code} -> ${interaction.user.tag}`);
}

// /mykeys
async function handleMyKeys(interaction) {
    await interaction.deferReply({ ephemeral: true });

    const keys = await LifetimeKey.find({ discordId: interaction.user.id });

    if (keys.length === 0) {
        return interaction.editReply(
            `${ICON.INFO} You have no keys.\n` +
            `Purchase a license and use \`/redeem <code>\` to get one.`
        );
    }

    const embed = new EmbedBuilder()
        .setTitle(`${ICON.KEY} Your Lifetime Keys`)
        .setColor(COLORS.BLUE)
        .setDescription(`${ICON.OK} You have **${keys.length}** lifetime key(s).`)
        .setTimestamp();

    for (const k of keys) {
        const resetDays = daysUntil(k.nextResetAvailable);
        const resetText = resetDays > 0 ? `In ${resetDays}d` : `${ICON.OK} Available now`;

        embed.addFields({
            name: `${ICON.KEY} \`${k.key.slice(0, 8)}...\` [${k.status}]`,
            value: [
                `${ICON.INFO} License: \`${k.licenseCode}\``,
                `${ICON.DEVICE} Devices: ${k.boundHWIDs.length} bound`,
                `${ICON.CLOCK} HWID Reset: ${resetText}`,
                `${ICON.STATS} Uses: ${k.totalUses}`
            ].join('\n'),
            inline: false
        });
    }

    try {
        await interaction.user.send({ embeds: [embed] });
        await interaction.editReply(`${ICON.OK} Check your DMs!`);
    } catch {
        await interaction.editReply(`${ICON.ERR} Could not DM you. Enable DMs from server members.`);
    }
}

// /resetkey <key>
async function handleResetKey(interaction) {
    const cd = checkCooldown(interaction.user.id, 'resetkey', 10);
    if (!cd.allowed) {
        return interaction.reply({ content: `${ICON.WARN} Please wait ${cd.remaining}s.`, ephemeral: true });
    }

    await interaction.deferReply();

    const keyInput = interaction.options.getString('key').toLowerCase();

    const keyData = await LifetimeKey.findOne({
        key: keyInput,
        discordId: interaction.user.id
    });

    if (!keyData) {
        return interaction.editReply(`${ICON.ERR} Key not found or you do not own this key.`);
    }

    if (keyData.nextResetAvailable && Date.now() < keyData.nextResetAvailable.getTime()) {
        const hrs = hoursUntil(keyData.nextResetAvailable);
        const dys = daysUntil(keyData.nextResetAvailable);
        return interaction.editReply(
            `${ICON.WARN} HWID reset not available yet.\nAvailable in ${dys} day(s) (${hrs} hours).`
        );
    }

    const clearedCount = keyData.boundHWIDs.length;
    keyData.boundHWIDs = [];
    keyData.lastHWIDReset = new Date();
    keyData.nextResetAvailable = new Date(Date.now() + HWID_RESET_DAYS * 86400000);
    await keyData.save();

    const embed = new EmbedBuilder()
        .setTitle(`${ICON.OK} HWID Reset Successful`)
        .setColor(COLORS.GREEN)
        .setDescription(`${ICON.OK} All devices cleared. You can now use this key on new devices.`)
        .addFields(
            { name: `${ICON.KEY} Key`,              value: `\`${keyInput.slice(0, 8)}...\``, inline: true },
            { name: `${ICON.DEVICE} Devices Cleared`, value: `${clearedCount}`,               inline: true },
            { name: `${ICON.CLOCK} Next Reset`,     value: `${HWID_RESET_DAYS} days`,        inline: true }
        )
        .setFooter({ text: `${ICON.UNLOCK} Key is now unbound from all devices.` })
        .setTimestamp();

    try {
        await interaction.user.send({ embeds: [embed] });
        await interaction.editReply(`${ICON.OK} HWID reset successful! Check your DMs.`);
    } catch {
        await interaction.editReply(`${ICON.OK} HWID reset successful but could not DM you.`);
    }

    await logAction('HWID Reset', {
        admin: interaction.user.tag,
        target: `\`${keyInput.slice(0, 8)}...\``,
        message: `Cleared ${clearedCount} device(s)`
    });

    console.log(`[HWID Reset] ${keyInput.slice(0, 8)}... by ${interaction.user.tag}`);
}

// /freekey [hwid]
async function handleFreeKey(interaction) {
    const cd = checkCooldown(interaction.user.id, 'freekey', 30);
    if (!cd.allowed) {
        return interaction.reply({ content: `${ICON.WARN} Please wait ${cd.remaining}s.`, ephemeral: true });
    }

    await interaction.deferReply();

    const userId = interaction.user.id;
    const hwid = interaction.options.getString('hwid') || null;

    const blacklisted = await Blacklist.findOne({ userId });
    if (blacklisted) {
        return interaction.editReply(`${ICON.BAN} You are blacklisted from free keys.`);
    }

    const existing = await FreeKey.findOne({
        userId,
        status: 'active',
        expiresAt: { $gt: new Date() }
    });

    if (existing) {
        return interaction.editReply(
            `${ICON.WARN} You already have an active key:\n` +
            `\`${existing.key}\`\n` +
            `Expires: <t:${Math.floor(existing.expiresAt.getTime() / 1000)}:R>`
        );
    }

    const key = generateFreeKey();

    await FreeKey.create({
        key,
        userId,
        hwid,
        tier: 'free',
        features: ['basic'],
        expiresAt: new Date(Date.now() + FREE_KEY_EXPIRY_HOURS * 3600000),
        maxUses: -1,
        source: 'discord'
    });

    const copyButton = new ActionRowBuilder().addComponents(
        new ButtonBuilder()
            .setCustomId(`copy_${key}`)
            .setLabel('Copy Key')
            .setStyle(ButtonStyle.Success)
    );

    const embed = new EmbedBuilder()
        .setTitle(`${ICON.KEY} Free Key Generated`)
        .setColor(COLORS.BLUE)
        .setDescription(`\`${key}\``)
        .addFields(
            { name: `${ICON.CLOCK} Duration`, value: `${FREE_KEY_EXPIRY_HOURS} hours`,   inline: true },
            { name: `${ICON.DEVICE} Device`,  value: `1 (HWID locked)`,                  inline: true },
            { name: `${ICON.STATS} Uses`,     value: `Unlimited`,                        inline: true },
            { name: `${ICON.STAR} Features`,  value: `Basic`,                            inline: true }
        )
        .setFooter({ text: `${ICON.CLOCK} This key expires in 24 hours.` })
        .setTimestamp();

    try {
        await interaction.user.send({ embeds: [embed], components: [copyButton] });
        await interaction.editReply(`${ICON.OK} Free key generated! Check your DMs.`);
    } catch {
        await interaction.editReply(`${ICON.ERR} Could not DM you. Enable DMs and try again.`);
    }

    console.log(`[FreeKey] ${key} -> ${interaction.user.tag}`);
}

// /help
async function handleHelp(interaction) {
    const embed = new EmbedBuilder()
        .setTitle(`${ICON.SHIELD} PawZHub Commands`)
        .setColor(COLORS.BLUE)
        .setDescription(`${ICON.INFO} Available slash commands:`)
        .addFields(
            {
                name: `${ICON.USER} User Commands`,
                value: [
                    `${ICON.ARROW} \`/redeem <code>\` - Redeem license code for lifetime key`,
                    `${ICON.ARROW} \`/mykeys\` - View your lifetime keys`,
                    `${ICON.ARROW} \`/resetkey <key>\` - Reset HWID (every 7 days)`,
                    `${ICON.ARROW} \`/freekey\` - Get a free 24h key`,
                    `${ICON.ARROW} \`/help\` - Show this message`
                ].join('\n'),
                inline: false
            },
            {
                name: `${ICON.STAR} How to Get Premium`,
                value: [
                    `${ICON.ARROW} 1. Purchase a license code`,
                    `${ICON.ARROW} 2. Use \`/redeem <code>\` here`,
                    `${ICON.ARROW} 3. Receive your lifetime key via DM`,
                    `${ICON.ARROW} 4. Use the key in your executor`
                ].join('\n'),
                inline: false
            }
        )
        .setFooter({ text: 'PawZHub v2.1 Pro' })
        .setTimestamp();

    await interaction.reply({ embeds: [embed], ephemeral: true });
}

// ============================================
// ADMIN COMMANDS
// ============================================

async function handleAdmin(interaction) {
    if (!isAdmin(interaction.member)) {
        return interaction.reply({ content: `${ICON.SHIELD} You need Admin role.`, ephemeral: true });
    }

    const sub = interaction.options.getSubcommand();
    const adminHandlers = {
        help:        adminHelp,
        gen:         adminGen,
        list:        adminList,
        check:       adminCheck,
        ban:         adminBan,
        unban:       adminUnban,
        blacklist:   adminBlacklist,
        unblacklist: adminUnblacklist,
        stats:       adminStats,
        export:      adminExport
    };

    const handler = adminHandlers[sub];
    if (handler) await handler(interaction);
}

// /admin help
async function adminHelp(interaction) {
    const embed = new EmbedBuilder()
        .setTitle(`${ICON.SHIELD} Admin Commands`)
        .setColor(COLORS.RED)
        .setDescription(`${ICON.INFO} Administrative commands for PawZHub`)
        .addFields(
            { name: `${ICON.GEN} Generate`,     value: `\`/admin gen <count>\` - Generate license codes (1-100)`,           inline: false },
            { name: `${ICON.LIST} List`,        value: `\`/admin list [filter]\` - List licenses (all/unused/redeemed)`,     inline: false },
            { name: `${ICON.SEARCH} Check`,     value: `\`/admin check <input>\` - Check license or lifetime key info`,      inline: false },
            { name: `${ICON.BAN} Ban`,          value: `\`/admin ban <key>\` - Ban a lifetime key (with confirmation)`,      inline: false },
            { name: `${ICON.UNBAN} Unban`,      value: `\`/admin unban <key>\` - Unban a lifetime key (with confirmation)`,  inline: false },
            { name: `${ICON.USER} Blacklist`,   value: `\`/admin blacklist <userid>\` - Blacklist user (with confirmation)`,  inline: false },
            { name: `${ICON.USER} Unblacklist`, value: `\`/admin unblacklist <userid>\` - Remove user from blacklist`,        inline: false },
            { name: `${ICON.STATS} Stats`,      value: `\`/admin stats\` - Show system statistics`,                          inline: false },
            { name: `${ICON.FILE} Export`,      value: `\`/admin export\` - Export licenses to file`,                        inline: false }
        )
        .setFooter({ text: `${ICON.SHIELD} Admin Only` })
        .setTimestamp();

    await interaction.reply({ embeds: [embed], ephemeral: true });
}

// /admin gen <count>
async function adminGen(interaction) {
    await interaction.deferReply();

    const count = interaction.options.getInteger('count');
    const codes = [];

    for (let i = 0; i < count; i++) {
        let code = generateLicenseCode();
        let attempts = 0;
        while (await License.findOne({ code }) && attempts < 100) {
            code = generateLicenseCode();
            attempts++;
        }
        await License.create({ code });
        codes.push(code);
    }

    const chunkSize = 25;
    for (let i = 0; i < codes.length; i += chunkSize) {
        const chunk = codes.slice(i, i + chunkSize);
        const embed = new EmbedBuilder()
            .setTitle(`${ICON.GEN} Generated Licenses (${i + 1}-${Math.min(i + chunkSize, codes.length)} / ${count})`)
            .setColor(COLORS.GREEN)
            .setDescription('```\n' + chunk.join('\n') + '\n```')
            .setFooter({ text: `${ICON.USER} Generated by ${interaction.user.tag}` })
            .setTimestamp();
        await interaction.channel.send({ embeds: [embed] });
    }

    await interaction.editReply(`${ICON.OK} Generated ${count} license(s).`);
    await logAction('Licenses Generated', { admin: interaction.user.tag, message: `Generated ${count} license(s)` });
    console.log(`[Admin] ${count} licenses generated by ${interaction.user.tag}`);
}

// /admin list [filter]
async function adminList(interaction) {
    await interaction.deferReply({ ephemeral: true });

    const filter = {};
    const filterVal = interaction.options.getString('filter');
    if (filterVal && filterVal !== 'all') filter.status = filterVal;

    const licenses = await License.find(filter).sort({ createdAt: -1 }).limit(100);

    if (licenses.length === 0) {
        return interaction.editReply(`${ICON.INFO} No licenses found.`);
    }

    const totalPages = Math.ceil(licenses.length / ITEMS_PER_PAGE);
    const chunk = licenses.slice(0, ITEMS_PER_PAGE);

    const lines = chunk.map((l, i) => {
        const status = l.status === 'unused' ? '[UNUSED]' : `[USED]`;
        return `${i + 1}. ${l.code} ${status}`;
    });

    const embed = new EmbedBuilder()
        .setTitle(`${ICON.LIST} Licenses (Page 1/${totalPages})`)
        .setColor(COLORS.BLUE)
        .setDescription('```\n' + lines.join('\n') + '\n```')
        .setFooter({ text: `Page 1 / ${totalPages} | Total: ${licenses.length}` })
        .setTimestamp();

    const components = totalPages > 1 ? [createPaginationButtons(1, totalPages)] : [];

    await interaction.editReply({ embeds: [embed], components });
}

// /admin check <input>
async function adminCheck(interaction) {
    await interaction.deferReply({ ephemeral: true });

    const input = interaction.options.getString('input').toLowerCase();

    // License code: 8 char hex
    if (/^[a-f0-9]{8}$/.test(input)) {
        const license = await License.findOne({ code: input });
        if (!license) return interaction.editReply(`${ICON.ERR} License not found.`);

        const embed = new EmbedBuilder()
            .setTitle(`${ICON.SEARCH} License Info`)
            .setColor(license.status === 'unused' ? COLORS.GREEN : COLORS.GRAY)
            .addFields(
                { name: `${ICON.KEY} Code`,      value: `\`${license.code}\``,          inline: true },
                { name: `${ICON.INFO} Status`,   value: license.status,                 inline: true },
                { name: `${ICON.CLOCK} Created`, value: formatDate(license.createdAt),  inline: true }
            );

        if (license.status === 'redeemed') {
            embed.addFields(
                { name: `${ICON.USER} Redeemed By`,  value: `<@${license.redeemedBy}>`, inline: true },
                { name: `${ICON.CLOCK} Redeemed At`, value: formatDate(license.redeemedAt), inline: true },
                { name: `${ICON.KEY} Generated Key`, value: `\`${license.generatedKey}\``, inline: false }
            );
        }

        return interaction.editReply({ embeds: [embed] });
    }

    // Lifetime key: 24 char hex
    if (/^[a-f0-9]{24}$/.test(input)) {
        const keyData = await LifetimeKey.findOne({ key: input });
        if (!keyData) return interaction.editReply(`${ICON.ERR} Lifetime key not found.`);

        const resetDays = daysUntil(keyData.nextResetAvailable);

        const embed = new EmbedBuilder()
            .setTitle(`${ICON.SEARCH} Lifetime Key Info`)
            .setColor(keyData.status === 'active' ? COLORS.GREEN : COLORS.RED)
            .addFields(
                { name: `${ICON.KEY} Key`,        value: `\`${keyData.key}\``,                              inline: false },
                { name: `${ICON.INFO} Status`,    value: keyData.status,                                    inline: true },
                { name: `${ICON.KEY} License`,    value: `\`${keyData.licenseCode}\``,                      inline: true },
                { name: `${ICON.USER} Owner`,     value: `<@${keyData.discordId}> (${keyData.discordTag})`,  inline: true },
                { name: `${ICON.DEVICE} Devices`, value: `${keyData.boundHWIDs.length}`,                    inline: true },
                { name: `${ICON.STATS} Uses`,     value: `${keyData.totalUses}`,                             inline: true },
                { name: `${ICON.CLOCK} HWID Reset`, value: resetDays > 0 ? `In ${resetDays}d` : `${ICON.OK} Available now`, inline: true },
                { name: `${ICON.CLOCK} Created`,  value: formatDate(keyData.createdAt),                     inline: true }
            );

        if (keyData.lastUsed) {
            embed.addFields({ name: `${ICON.CLOCK} Last Used`, value: formatDate(keyData.lastUsed), inline: true });
        }

        if (keyData.boundHWIDs.length > 0) {
            const hwids = keyData.boundHWIDs.map(h => `\`${h.slice(0, 12)}...\``).join('\n');
            embed.addFields({ name: `${ICON.DEVICE} Bound HWIDs`, value: hwids, inline: false });
        }

        return interaction.editReply({ embeds: [embed] });
    }

    await interaction.editReply(`${ICON.ERR} Invalid format. License = 8 chars, Lifetime key = 24 chars.`);
}

// /admin ban <key> (with confirmation)
async function adminBan(interaction) {
    const cd = checkCooldown(interaction.user.id, 'admin_ban', 5);
    if (!cd.allowed) {
        return interaction.reply({ content: `${ICON.WARN} Please wait ${cd.remaining}s.`, ephemeral: true });
    }

    await interaction.deferReply();

    const keyInput = interaction.options.getString('key').toLowerCase();
    const keyData = await LifetimeKey.findOne({ key: keyInput });

    if (!keyData) return interaction.editReply(`${ICON.ERR} Lifetime key not found.`);
    if (keyData.status === 'banned') return interaction.editReply(`${ICON.WARN} Key is already banned.`);

    const embed = new EmbedBuilder()
        .setTitle(`${ICON.WARN} Confirm Ban`)
        .setColor(COLORS.ORANGE)
        .setDescription(`${ICON.WARN} Are you sure you want to ban this key?`)
        .addFields(
            { name: `${ICON.KEY} Key`,    value: `\`${keyData.key}\``,        inline: true },
            { name: `${ICON.USER} Owner`, value: `<@${keyData.discordId}>`,   inline: true },
            { name: `${ICON.SHIELD} By`,  value: interaction.user.tag,        inline: true }
        )
        .setTimestamp();

    const row = createConfirmButtons('ban');

    await interaction.editReply({ embeds: [embed], components: [row] });
}

// /admin unban <key> (with confirmation)
async function adminUnban(interaction) {
    const cd = checkCooldown(interaction.user.id, 'admin_unban', 5);
    if (!cd.allowed) {
        return interaction.reply({ content: `${ICON.WARN} Please wait ${cd.remaining}s.`, ephemeral: true });
    }

    await interaction.deferReply();

    const keyInput = interaction.options.getString('key').toLowerCase();
    const keyData = await LifetimeKey.findOne({ key: keyInput });

    if (!keyData) return interaction.editReply(`${ICON.ERR} Lifetime key not found.`);
    if (keyData.status === 'active') return interaction.editReply(`${ICON.WARN} Key is not banned.`);

    const embed = new EmbedBuilder()
        .setTitle(`${ICON.WARN} Confirm Unban`)
        .setColor(COLORS.ORANGE)
        .setDescription(`${ICON.WARN} Are you sure you want to unban this key?`)
        .addFields(
            { name: `${ICON.KEY} Key`,    value: `\`${keyData.key}\``,        inline: true },
            { name: `${ICON.USER} Owner`, value: `<@${keyData.discordId}>`,   inline: true },
            { name: `${ICON.SHIELD} By`,  value: interaction.user.tag,        inline: true }
        )
        .setTimestamp();

    const row = createConfirmButtons('unban');

    await interaction.editReply({ embeds: [embed], components: [row] });
}

// /admin blacklist <userid> [reason] (with confirmation)
async function adminBlacklist(interaction) {
    const cd = checkCooldown(interaction.user.id, 'admin_blacklist', 5);
    if (!cd.allowed) {
        return interaction.reply({ content: `${ICON.WARN} Please wait ${cd.remaining}s.`, ephemeral: true });
    }

    await interaction.deferReply();

    const userId = interaction.options.getString('userid');
    const reason = interaction.options.getString('reason') || 'No reason';

    const exists = await Blacklist.findOne({ userId });
    if (exists) return interaction.editReply(`${ICON.WARN} User is already blacklisted.`);

    const embed = new EmbedBuilder()
        .setTitle(`${ICON.WARN} Confirm Blacklist`)
        .setColor(COLORS.ORANGE)
        .setDescription(`${ICON.WARN} Are you sure you want to blacklist this user?`)
        .addFields(
            { name: `${ICON.USER} User`,   value: `<@${userId}>`,  inline: true },
            { name: `${ICON.INFO} Reason`, value: reason,          inline: true },
            { name: `${ICON.SHIELD} By`,   value: interaction.user.tag, inline: true }
        )
        .setTimestamp();

    const row = createConfirmButtons('bl');

    await interaction.editReply({ embeds: [embed], components: [row] });
}

// /admin unblacklist <userid>
async function adminUnblacklist(interaction) {
    await interaction.deferReply();

    const userId = interaction.options.getString('userid');
    const result = await Blacklist.deleteOne({ userId });

    if (result.deletedCount === 0) return interaction.editReply(`${ICON.INFO} User is not blacklisted.`);

    const embed = new EmbedBuilder()
        .setTitle(`${ICON.UNBAN} User Unblacklisted`)
        .setColor(COLORS.GREEN)
        .addFields(
            { name: `${ICON.USER} User`,   value: `<@${userId}>`,       inline: true },
            { name: `${ICON.SHIELD} By`,   value: interaction.user.tag, inline: true }
        )
        .setTimestamp();

    await interaction.editReply({ embeds: [embed] });
    await logAction('User Unblacklisted', { admin: interaction.user.tag, target: `<@${userId}>` });
}

// /admin stats
async function adminStats(interaction) {
    await interaction.deferReply({ ephemeral: true });

    const [
        totalLicenses, unusedLicenses, redeemedLicenses,
        totalKeys, activeKeys, bannedKeys,
        totalFreeKeys, activeFreeKeys, blacklistedUsers
    ] = await Promise.all([
        License.countDocuments(),
        License.countDocuments({ status: 'unused' }),
        License.countDocuments({ status: 'redeemed' }),
        LifetimeKey.countDocuments(),
        LifetimeKey.countDocuments({ status: 'active' }),
        LifetimeKey.countDocuments({ status: 'banned' }),
        FreeKey.countDocuments(),
        FreeKey.countDocuments({ status: 'active', expiresAt: { $gt: new Date() } }),
        Blacklist.countDocuments()
    ]);

    const usageResult = await LifetimeKey.aggregate([
        { $group: { _id: null, total: { $sum: '$totalUses' } } }
    ]);
    const totalUses = usageResult.length > 0 ? usageResult[0].total : 0;

    const embed = new EmbedBuilder()
        .setTitle(`${ICON.STATS} System Statistics`)
        .setColor(COLORS.BLUE)
        .setDescription(`${ICON.INFO} Current system overview`)
        .addFields(
            {
                name: `${ICON.KEY} Licenses`,
                value: `\`\`\`\nTotal:     ${totalLicenses}\nUnused:    ${unusedLicenses}\nRedeemed:  ${redeemedLicenses}\n\`\`\``,
                inline: true
            },
            {
                name: `${ICON.KEY} Lifetime Keys`,
                value: `\`\`\`\nTotal:     ${totalKeys}\nActive:    ${activeKeys}\nBanned:    ${bannedKeys}\n\`\`\``,
                inline: true
            },
            {
                name: `${ICON.KEY} Free Keys`,
                value: `\`\`\`\nTotal:     ${totalFreeKeys}\nActive:    ${activeFreeKeys}\n\`\`\``,
                inline: true
            },
            {
                name: `${ICON.STATS} Usage`,
                value: `\`\`\`\nTotal Uses:      ${totalUses}\nBlacklisted:    ${blacklistedUsers}\nBot Uptime:     ${Math.floor(process.uptime() / 60)}m\n\`\`\``,
                inline: false
            }
        )
        .setFooter({ text: 'PawZHub System v2.1 Pro' })
        .setTimestamp();

    await interaction.editReply({ embeds: [embed] });
}

// /admin export
async function adminExport(interaction) {
    await interaction.deferReply({ ephemeral: true });

    const licenses = await License.find().sort({ createdAt: -1 });

    if (licenses.length === 0) {
        return interaction.editReply(`${ICON.INFO} No licenses to export.`);
    }

    const lines = licenses.map(l => {
        const status = l.status === 'unused' ? 'UNUSED' : 'REDEEMED';
        const redeemedBy = l.redeemedBy || 'N/A';
        return `${l.code} | ${status} | ${redeemedBy} | ${formatDate(l.createdAt)}`;
    });

    const header = 'CODE | STATUS | REDEEMED_BY | CREATED\n';
    const content = header + lines.join('\n');

    const file = new AttachmentBuilder(Buffer.from(content, 'utf-8'), { name: `licenses-${Date.now()}.txt` });

    const embed = new EmbedBuilder()
        .setTitle(`${ICON.FILE} Licenses Exported`)
        .setColor(COLORS.GREEN)
        .setDescription(`${ICON.OK} Exported ${licenses.length} license(s) to file.`)
        .setTimestamp();

    await interaction.editReply({ embeds: [embed], files: [file] });
    await logAction('Licenses Exported', { admin: interaction.user.tag, message: `Exported ${licenses.length} license(s)` });
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
