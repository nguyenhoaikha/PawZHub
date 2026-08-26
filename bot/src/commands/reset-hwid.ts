import { SlashCommandBuilder, ChatInputCommandInteraction, EmbedBuilder } from 'discord.js';
import { adminResetHWID } from '../lib/api';
import { isAdmin } from '../lib/permissions';

export const data = new SlashCommandBuilder()
  .setName('reset-hwid')
  .setDescription('Force-reset a premium key HWID, bypassing the 7-day cooldown (admin only)')
  .addStringOption((opt) =>
    opt
      .setName('key')
      .setDescription('The premium key (PH.*) to reset')
      .setRequired(true)
  )
  .addStringOption((opt) =>
    opt
      .setName('new-hwid')
      .setDescription('The new HWID to bind (any identifier — UUID, Roblox UserId, etc.)')
      .setRequired(true)
  )
  .addStringOption((opt) =>
    opt
      .setName('reason')
      .setDescription('Why is this reset needed? (recorded in audit log)')
      .setRequired(false)
  );

export async function execute(interaction: ChatInputCommandInteraction) {
  if (!isAdmin(interaction.user.id)) {
    await interaction.reply({ content: 'Admin only.', ephemeral: true });
    return;
  }

  const key = interaction.options.getString('key', true).trim();
  const newHwid = interaction.options.getString('new-hwid', true).trim();
  const reason = interaction.options.getString('reason')?.trim() || null;

  if (!key.startsWith('PH.')) {
    await interaction.reply({
      content: 'Only premium (PH.*) keys support HWID reset.',
      ephemeral: true,
    });
    return;
  }

  if (newHwid.length < 4) {
    await interaction.reply({
      content: 'new-hwid is too short. Use the real device identifier (>= 4 chars).',
      ephemeral: true,
    });
    return;
  }

  await interaction.deferReply({ ephemeral: true });

  const actor = `discord:${interaction.user.id}${reason ? ` (${reason})` : ''}`;
  const result = await adminResetHWID(key, newHwid, actor);

  if (!result.ok) {
    const embed = new EmbedBuilder()
      .setColor(0xef4444)
      .setTitle('HWID reset failed')
      .setDescription(result.error || 'Unknown error')
      .setTimestamp();
    await interaction.editReply({ embeds: [embed] });
    return;
  }

  const r = result.data;
  const embed = new EmbedBuilder()
    .setColor(0x22c55e)
    .setTitle('HWID force-reset')
    .addFields(
      { name: 'Key', value: `\`${r.keyId.slice(0, 24)}…\``, inline: false },
      { name: 'Previous HWID', value: r.previousHwid ? `\`${r.previousHwid}\`` : '*none (first binding)*', inline: true },
      { name: 'New HWID', value: `\`${r.newHwid}\``, inline: true },
      { name: 'Key expires', value: `<t:${Math.floor(new Date(r.expires).getTime() / 1000)}:F>`, inline: true },
      { name: 'By', value: `<@${interaction.user.id}>`, inline: true },
      { name: 'Reason', value: reason || '—', inline: true },
    )
    .setFooter({ text: `Cooldown bypassed: ${r.cooldownBypassed}` })
    .setTimestamp();
  await interaction.editReply({ embeds: [embed] });
}
