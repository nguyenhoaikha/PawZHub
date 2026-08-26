import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
} from 'discord.js';
import { revokeKey } from '../lib/api';
import { isAdmin } from '../lib/permissions';

export const data = new SlashCommandBuilder()
  .setName('revoke-key')
  .setDescription('Revoke a compromised PawZHub key (admin only)')
  .addStringOption((opt) =>
    opt
      .setName('key')
      .setDescription('The key to revoke (PH.* or JWT)')
      .setRequired(true)
  )
  .addStringOption((opt) =>
    opt
      .setName('reason')
      .setDescription('Why is this key being revoked?')
      .setRequired(true)
  );

export async function execute(interaction: ChatInputCommandInteraction) {
  if (!isAdmin(interaction.user.id)) {
    await interaction.reply({ content: 'Admin only.', ephemeral: true });
    return;
  }

  const key = interaction.options.getString('key', true).trim();
  const reason = interaction.options.getString('reason', true).trim();

  if (!key || !reason) {
    await interaction.reply({
      content: 'Both key and reason are required.',
      ephemeral: true,
    });
    return;
  }

  await interaction.deferReply({ ephemeral: true });

  const actor = `discord:${interaction.user.id}`;
  const result = await revokeKey(key, reason, actor);

  if (!result.ok) {
    const embed = new EmbedBuilder()
      .setColor(0xef4444)
      .setTitle('Revocation failed')
      .setDescription(result.error || 'Unknown error')
      .setTimestamp();
    await interaction.editReply({ embeds: [embed] });
    return;
  }

  const embed = new EmbedBuilder()
    .setColor(0xef4444)
    .setTitle('🔑 Key Revoked')
    .addFields(
      { name: 'Key', value: `\`${key.length > 30 ? key.slice(0, 30) + '…' : key}\``, inline: false },
      { name: 'Reason', value: reason, inline: false },
      { name: 'By', value: `<@${interaction.user.id}>`, inline: true },
    )
    .setDescription(
      'This key will now be rejected by /api/verifykey. ' +
      'The Lua client will show it as invalid.'
    )
    .setTimestamp();

  await interaction.editReply({ embeds: [embed] });
}
