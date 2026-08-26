/**
 * Deploy slash commands to Discord.
 * Run once after adding new commands: `npm run deploy`
 *
 * Set DISCORD_GUILD_ID to deploy to a single test server (instant updates).
 * Leave it blank to deploy globally (takes up to 1 hour to propagate).
 */

import 'dotenv/config';
import { REST, Routes } from 'discord.js';
import { readdirSync } from 'fs';
import { join } from 'path';

const commandsDir = join(__dirname, 'commands');
const files = readdirSync(commandsDir).filter((f) => f.endsWith('.ts') || f.endsWith('.js'));
const commands: any[] = [];
for (const file of files) {
  const mod = require(join(commandsDir, file));
  if (mod.data) {
    commands.push(mod.data.toJSON());
  }
}

const token = process.env.DISCORD_BOT_TOKEN;
const clientId = process.env.DISCORD_CLIENT_ID;
const guildId = process.env.DISCORD_GUILD_ID;

if (!token || !clientId) {
  console.error('Missing DISCORD_BOT_TOKEN or DISCORD_CLIENT_ID in .env');
  process.exit(1);
}

const rest = new REST({ version: '10' }).setToken(token);

(async () => {
  try {
    console.log(`[PawZHub] Deploying ${commands.length} command(s)...`);
    if (guildId) {
      const data = (await rest.put(
        Routes.applicationGuildCommands(clientId, guildId),
        { body: commands }
      )) as any[];
      console.log(`[PawZHub] Done — registered ${data.length} guild command(s) for ${guildId}`);
    } else {
      const data = (await rest.put(
        Routes.applicationCommands(clientId),
        { body: commands }
      )) as any[];
      console.log(`[PawZHub] Done — registered ${data.length} global command(s) (may take up to 1h to appear)`);
    }
  } catch (err: any) {
    console.error('[PawZHub] Deploy failed:', err);
    process.exit(1);
  }
})();
