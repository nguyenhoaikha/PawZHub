/**
 * PawZHub Discord Bot — entry point.
 *
 * Run:   npm run build && npm start
 * Dev:   npm run dev
 *
 * Required env (.env):
 *   DISCORD_BOT_TOKEN
 *   DISCORD_CLIENT_ID
 *   DISCORD_GUILD_ID            (test server; for production, use deploy-commands.ts
 *                                 with empty GUILD_ID for global registration)
 *   WEB_API_URL
 *   WEB_ADMIN_TOKEN
 *   ADMIN_USER_IDS              (comma-separated Discord user IDs)
 */

import 'dotenv/config';
import { Client, GatewayIntentBits, Events } from 'discord.js';
import { readdirSync } from 'fs';
import { join } from 'path';

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
  ],
});

client.once(Events.ClientReady, (c) => {
  console.log(`[PawZHub] Logged in as ${c.user.tag}`);
  console.log(`[PawZHub] Serving ${c.guilds.cache.size} guild(s)`);
});

client.on(Events.InteractionCreate, async (interaction) => {
  if (!interaction.isChatInputCommand()) return;
  const cmd = client.commands?.get(interaction.commandName);
  if (!cmd) {
    console.warn(`[PawZHub] No handler for /${interaction.commandName}`);
    return;
  }
  try {
    await cmd.execute(interaction);
  } catch (err: any) {
    console.error(`[PawZHub] Error in /${interaction.commandName}:`, err);
    const payload = { content: 'Something went wrong while running this command.', ephemeral: true };
    if (interaction.deferred || interaction.replied) {
      await interaction.editReply(payload).catch(() => {});
    } else {
      await interaction.reply(payload).catch(() => {});
    }
  }
});

// Command loader
const commandsDir = join(__dirname, 'commands');
const commandFiles = readdirSync(commandsDir).filter((f) => f.endsWith('.ts') || f.endsWith('.js'));
const loaded: any[] = [];
for (const file of commandFiles) {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const mod = require(join(commandsDir, file));
  if (mod.data && typeof mod.execute === 'function') {
    loaded.push(mod.data);
  }
}
client.commands = new (require('discord.js').Collection)();
for (const file of commandFiles) {
  const mod = require(join(commandsDir, file));
  if (mod.data && typeof mod.execute === 'function') {
    client.commands.set(mod.data.name, mod);
  }
}

const token = process.env.DISCORD_BOT_TOKEN;
if (!token) {
  console.error('[PawZHub] DISCORD_BOT_TOKEN missing in .env');
  process.exit(1);
}

client.login(token).catch((err) => {
  console.error('[PawZHub] Login failed:', err);
  process.exit(1);
});
