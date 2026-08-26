import { SlashCommandBuilder, ChatInputCommandInteraction, EmbedBuilder } from 'discord.js';
import { removeBlacklist } from '../lib/api';
import { isAdmin } from '../lib/permissions';

export const data = new SlashCommandBuilder()
  .setName('unblacklist')
  .setDescription('Remove a user from the PawZHub blacklist (admin only)')
  .addStringOption((opt) =>
    opt.setName('userid').setDescription('The identifier that was blacklisted').setRequired(true)
  );

export async function execute(interaction: ChatInputCommandInteraction) {
  if (!isAdmin(interaction.user.id)) {
    await interaction.reply({ content: 'Admin only.', ephemeral: true });
    return;
  }
  const userId = interaction.options.getString('userid', true).trim();
  if (!userId) {
    await interaction.reply({ content: 'userId is required.', ephemeral: true });
    return;
  }

  await interaction.deferReply({ ephemeral: true });
  const result = await removeBlacklist(userId);

  if (!result.ok) {
    const embed = new EmbedBuilder()
      .setColor(0xef4444)
      .setTitle('Unblacklist failed')
      .setDescription(result.error || 'Unknown error')
      .setTimestamp();
    await interaction.editReply({ embeds: [embed] });
    return;
  }

  const embed = new EmbedBuilder()
    .setColor(0x22c55e)
    .setTitle('User removed from blacklist')
    .addFields({ name: 'User', value: `\`${userId}\``, inline: true })
    .setTimestamp();

  await interaction.editReply({ embeds: [embed] });
}
