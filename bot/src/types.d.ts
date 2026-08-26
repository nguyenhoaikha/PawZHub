/**
 * Module augmentation: attach a `commands` Collection to the discord.js
 * Client so TypeScript and ts-node recognise `client.commands`.
 */
import type { Collection, ChatInputCommandInteraction } from 'discord.js';

export type CommandModule = {
  data: { name: string; toJSON: () => unknown };
  execute: (interaction: ChatInputCommandInteraction) => Promise<void>;
};

declare module 'discord.js' {
  interface Client {
    commands: Collection<string, CommandModule>;
  }
}
