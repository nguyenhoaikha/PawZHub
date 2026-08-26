import { SlashCommandBuilder, ChatInputCommandInteraction, EmbedBuilder } from 'discord.js';
import { addBlacklist } from '../lib/api';
import { isAdmin } from '../lib/permissions';

export const data = new SlashCommandBuilder()
  .setName('blacklist')
  .setDescription('Add a user to the PawZHub blacklist (admin only)')
  .addStringOption((opt) =>
    opt.setName('userid').setDescription('Roblox UserId, Discord ID, HWID, or other identifier').setRequired(true)
  )
  .addStringOption((opt) =>
    opt.setName('reason').setDescription('Why is this user being blacklisted?').setRequired(true)
  );

export async function execute(interaction: ChatInputCommandInteraction) {
  if (!isAdmin(interaction.user.id)) {
    await interaction.reply({ content: 'Admin only.', ephemeral: true });
    return;
  }
  const userId = interaction.options.getString('userid', true).trim();
  const reason = interaction.options.getString('reason', true).trim();
  if (!userId || !reason) {
    await interaction.reply({ content: 'Both userId and reason are required.', ephemeral: true });
    return;
  }

  await interaction.deferReply({ ephemeral: true });
  const result = await addBlacklist(userId, reason, `discord:${interaction.user.id}`);

  if (!result.ok) {
    const embed = new EmbedBuilder()
      .setColor(0xef4444)
      .setTitle('Blacklist failed')
      .setDescription(result.error || 'Unknown error')
      .setTimestamp();
    await interaction.editReply({ embeds: [embed] });
    return;
  }

  const embed = new EmbedBuilder()
    .setColor(0xf97316)
    .setTitle('User blacklisted')
    .addFields(
      { name: 'User', value: `\`${userId}\``, inline: true },
      { name: 'Reason', value: reason, inline: true },
      { name: 'Added by', value: `<@${interaction.user.id}>`, inline: true }
    )
    .setTimestamp();

  await interaction.editReply({ embeds: [embed] });
}
