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
import {
  Client,
  Collection,
  GatewayIntentBits,
  Events,
  ChatInputCommandInteraction,
} from 'discord.js';
import { readdirSync } from 'fs';
import { join } from 'path';

type CommandModule = {
  data: { name: string; toJSON: () => unknown };
  execute: (interaction: ChatInputCommandInteraction) => Promise<void>;
};

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
  ],
});

// Single command loader pass: each .ts/.js file in src/commands/ must
// export `data` (slash command builder) and `execute` (handler).
const commandsDir = join(__dirname, 'commands');
const commandFiles = readdirSync(commandsDir).filter(
  (f) => f.endsWith('.ts') || f.endsWith('.js')
);

client.commands = new Collection<string, CommandModule>();
for (const file of commandFiles) {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const mod: CommandModule = require(join(commandsDir, file));
  if (mod.data && typeof mod.execute === 'function') {
    client.commands.set(mod.data.name, mod);
  } else {
    console.warn(`[PawZHub] Skipping ${file}: missing data or execute export`);
  }
}

client.once(Events.ClientReady, (c) => {
  console.log(`[PawZHub] Logged in as ${c.user.tag}`);
  console.log(`[PawZHub] Serving ${c.guilds.cache.size} guild(s)`);
  console.log(`[PawZHub] ${client.commands.size} command(s) loaded`);
});

client.on(Events.InteractionCreate, async (interaction) => {
  if (!interaction.isChatInputCommand()) return;
  const cmd = client.commands.get(interaction.commandName);
  if (!cmd) {
    console.warn(`[PawZHub] No handler for /${interaction.commandName}`);
    return;
  }
  try {
    await cmd.execute(interaction);
  } catch (err: any) {
    console.error(`[PawZHub] Error in /${interaction.commandName}:`, err);
    const payload = {
      content: 'Something went wrong while running this command.',
      ephemeral: true,
    };
    if (interaction.deferred || interaction.replied) {
      await interaction.editReply(payload).catch(() => {});
    } else {
      await interaction.reply(payload).catch(() => {});
    }
  }
});

const token = process.env.DISCORD_BOT_TOKEN;
if (!token) {
  console.error('[PawZHub] DISCORD_BOT_TOKEN missing in .env');
  process.exit(1);
}

client.login(token).catch((err) => {
  console.error('[PawZHub] Login failed:', err);
  process.exit(1);
});
