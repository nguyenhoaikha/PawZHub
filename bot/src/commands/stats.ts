import { SlashCommandBuilder, ChatInputCommandInteraction, EmbedBuilder } from 'discord.js';
import { getStats, getBlacklist } from '../lib/api';
import { isAdmin } from '../lib/permissions';

export const data = new SlashCommandBuilder()
  .setName('stats')
  .setDescription('Show PawZHub system statistics (admin only)');

export async function execute(interaction: ChatInputCommandInteraction) {
  if (!isAdmin(interaction.user.id)) {
    await interaction.reply({ content: 'Admin only.', ephemeral: true });
    return;
  }

  await interaction.deferReply({ ephemeral: true });

  const [statsRes, blRes] = await Promise.all([getStats(), getBlacklist()]);

  if (!statsRes.ok) {
    const embed = new EmbedBuilder()
      .setColor(0xef4444)
      .setTitle('Stats fetch failed')
      .setDescription(statsRes.error || 'Unknown error')
      .setTimestamp();
    await interaction.editReply({ embeds: [embed] });
    return;
  }

  const s = statsRes.data;
  const bl = blRes.ok ? blRes.data.blacklist : [];

  const embed = new EmbedBuilder()
    .setColor(0x3b82f6)
    .setTitle('PawZHub system stats')
    .addFields(
      { name: 'Storage', value: s.backend || 'unknown', inline: true },
      { name: 'Checkpoint tokens', value: String(s.totalCheckpointTokens), inline: true },
      { name: '  consumed', value: String(s.usedCheckpointTokens), inline: true },
      { name: 'HWID bindings', value: String(s.totalHWIDBindings), inline: true },
      { name: 'HWID resets', value: String(s.totalHWIDResets), inline: true },
      { name: 'Blacklisted', value: String(s.blacklistedUsers), inline: true },
      { name: 'Usage logs', value: String(s.totalUsageLogs), inline: true }
    )
    .setFooter({ text: `Requested by ${interaction.user.tag}` })
    .setTimestamp();

  if (bl.length > 0) {
    const list = bl
      .slice(0, 8)
      .map((b) => `• \`${b.userId}\` — ${b.reason}`)
      .join('\n');
    embed.addFields({
      name: `Blacklist (showing ${Math.min(bl.length, 8)} of ${bl.length})`,
      value: list,
    });
  }

  await interaction.editReply({ embeds: [embed] });
}
