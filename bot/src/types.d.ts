/**
 * Module augmentation: attach a `commands` Collection to the discord.js
 * Client so the runtime can dispatch slash commands by name.
 */
import type { Collection } from 'discord.js';
import type { ChatInputCommandInteraction } from 'discord.js';

export type CommandModule = {
  data: { name: string; toJSON: () => unknown };
  execute: (interaction: ChatInputCommandInteraction) => Promise<void>;
};

declare module 'discord.js' {
  interface Client {
    commands: Collection<string, CommandModule>;
  }
}
