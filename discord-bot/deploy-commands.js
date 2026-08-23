// Register slash commands with Discord API
// Run this once: node deploy-commands.js

const { REST, Routes, SlashCommandBuilder } = require('discord.js');
require('dotenv').config();

const commands = [
    // --- User Commands ---

    new SlashCommandBuilder()
        .setName('redeem')
        .setDescription('Redeem a license code to get your lifetime key')
        .addStringOption(opt =>
            opt.setName('code')
                .setDescription('Your 8-character license code (e.g. a12e137e)')
                .setRequired(true)
        ),

    new SlashCommandBuilder()
        .setName('mykeys')
        .setDescription('View your lifetime keys'),

    new SlashCommandBuilder()
        .setName('resetkey')
        .setDescription('Reset HWID binding on your key (available every 7 days)')
        .addStringOption(opt =>
            opt.setName('key')
                .setDescription('Your 24-character lifetime key')
                .setRequired(true)
        ),

    new SlashCommandBuilder()
        .setName('freekey')
        .setDescription('Generate a free 24-hour key')
        .addStringOption(opt =>
            opt.setName('hwid')
                .setDescription('Your HWID (optional)')
                .setRequired(false)
        ),

    new SlashCommandBuilder()
        .setName('help')
        .setDescription('Show all PawZHub commands'),

    // --- Admin Commands ---

    new SlashCommandBuilder()
        .setName('admin')
        .setDescription('Admin commands for PawZHub')
        .addSubcommand(sub =>
            sub.setName('help')
                .setDescription('Show admin commands')
        )
        .addSubcommand(sub =>
            sub.setName('gen')
                .setDescription('Generate license codes')
                .addIntegerOption(opt =>
                    opt.setName('count')
                        .setDescription('Number of codes (1-100)')
                        .setRequired(true)
                        .setMinValue(1)
                        .setMaxValue(100)
                )
        )
        .addSubcommand(sub =>
            sub.setName('list')
                .setDescription('List licenses')
                .addStringOption(opt =>
                    opt.setName('filter')
                        .setDescription('Filter: unused or redeemed')
                        .addChoices(
                            { name: 'All', value: 'all' },
                            { name: 'Unused', value: 'unused' },
                            { name: 'Redeemed', value: 'redeemed' }
                        )
                )
        )
        .addSubcommand(sub =>
            sub.setName('check')
                .setDescription('Check a license code or lifetime key')
                .addStringOption(opt =>
                    opt.setName('input')
                        .setDescription('License code (8 chars) or lifetime key (24 chars)')
                        .setRequired(true)
                )
        )
        .addSubcommand(sub =>
            sub.setName('ban')
                .setDescription('Ban a lifetime key')
                .addStringOption(opt =>
                    opt.setName('key')
                        .setDescription('The 24-character lifetime key to ban')
                        .setRequired(true)
                )
        )
        .addSubcommand(sub =>
            sub.setName('unban')
                .setDescription('Unban a lifetime key')
                .addStringOption(opt =>
                    opt.setName('key')
                        .setDescription('The 24-character lifetime key to unban')
                        .setRequired(true)
                )
        )
        .addSubcommand(sub =>
            sub.setName('blacklist')
                .setDescription('Blacklist a user from free keys')
                .addStringOption(opt =>
                    opt.setName('userid')
                        .setDescription('Discord user ID')
                        .setRequired(true)
                )
                .addStringOption(opt =>
                    opt.setName('reason')
                        .setDescription('Reason for blacklisting')
                        .setRequired(false)
                )
        )
        .addSubcommand(sub =>
            sub.setName('unblacklist')
                .setDescription('Remove user from blacklist')
                .addStringOption(opt =>
                    opt.setName('userid')
                        .setDescription('Discord user ID')
                        .setRequired(true)
                )
        )
        .addSubcommand(sub =>
            sub.setName('stats')
                .setDescription('Show system statistics')
        )
        .addSubcommand(sub =>
            sub.setName('export')
                .setDescription('Export licenses to file')
        )
].map(cmd => cmd.toJSON());

// Deploy
const token = process.env.DISCORD_BOT_TOKEN;
const clientId = process.env.CLIENT_ID; // Your bot's Application ID

if (!token || !clientId) {
    console.error('[Deploy] Missing DISCORD_BOT_TOKEN or CLIENT_ID in .env');
    process.exit(1);
}

const rest = new REST({ version: '10' }).setToken(token);

(async () => {
    try {
        console.log(`[Deploy] Registering ${commands.length} commands...`);

        await rest.put(
            Routes.applicationCommands(clientId),
            { body: commands }
        );

        console.log('[Deploy] Commands registered successfully!');
        console.log('[Deploy] Commands may take up to 1 hour to propagate globally.');
        console.log('[Deploy] For instant testing, use Routes.applicationGuildCommands() with a guild ID.');
    } catch (error) {
        console.error('[Deploy] Error:', error);
    }
})();
