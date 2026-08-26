import { SlashCommandBuilder, ChatInputCommandInteraction, EmbedBuilder } from 'discord.js';
import { inspectKey } from '../lib/api';
import { isAdmin } from '../lib/permissions';

export const data = new SlashCommandBuilder()
  .setName('inspect-key')
  .setDescription('Inspect a PawZHub key — tier, expiry, HWID binding, recent usage (admin only)')
  .addStringOption((opt) =>
    opt
      .setName('key')
      .setDescription('The PawZHub key to inspect (PH.* or JWT)')
      .setRequired(true)
  );

export async function execute(interaction: ChatInputCommandInteraction) {
  if (!isAdmin(interaction.user.id)) {
    await interaction.reply({ content: 'Admin only.', ephemeral: true });
    return;
  }

  const key = interaction.options.getString('key', true).trim();

  await interaction.deferReply({ ephemeral: true });

  const result = await inspectKey(key);

  if (!result.ok) {
    const embed = new EmbedBuilder()
      .setColor(0xef4444)
      .setTitle('Inspect failed')
      .setDescription(result.error || 'Unknown error')
      .setTimestamp();
    await interaction.editReply({ embeds: [embed] });
    return;
  }

  const r = result.data;
  const embed = new EmbedBuilder()
    .setColor(r.valid === false ? 0xef4444 : 0x3b82f6)
    .setTitle(`Key inspection — ${r.type || 'unknown'}`)
    .setTimestamp();

  // Free (JWT) key — no binding, no resets to show.
  if (r.type === 'free') {
    embed.setDescription(r.message || 'Free key — admin-side inspection not implemented.');
    await interaction.editReply({ embeds: [embed] });
    return;
  }

  // Premium key details
  if (r.payload) {
    const issued = r.issued ? new Date(r.issued) : null;
    const expires = r.expires ? new Date(r.expires) : null;
    embed.addFields(
      { name: 'Plan', value: r.plan || 'unknown', inline: true },
      { name: 'Status', value: r.expired ? 'expired' : (r.valid ? 'valid' : 'invalid'), inline: true },
      { name: 'Bound to', value: r.binding?.hwid ? `\`${r.binding.hwid.slice(0, 16)}…\`` : '*unbound*', inline: true },
      { name: 'Issued', value: issued ? `<t:${Math.floor(issued.getTime() / 1000)}:F>` : '—', inline: true },
      { name: 'Expires', value: expires ? `<t:${Math.floor(expires.getTime() / 1000)}:F>` : '—', inline: true },
      { name: 'Resets used', value: String(r.resets?.length ?? 0), inline: true },
    );
  } else if (r.reason) {
    embed.addFields({ name: 'Parse failure', value: r.reason, inline: false });
  }

  // Most recent usage logs (already capped to 20 by the API)
  if (Array.isArray(r.recentLogs) && r.recentLogs.length > 0) {
    const lines = r.recentLogs
      .slice(0, 5)
      .map((l: any) => {
        const ts = new Date(l.timestamp);
        const tag = l.success ? '✓' : '✗';
        const hwid = l.hwid ? ` hwid=${String(l.hwid).slice(0, 12)}…` : '';
        return `\`${tag}\` <t:${Math.floor(ts.getTime() / 1000)}:R> ${l.action}${hwid} ${l.error ? `— ${l.error}` : ''}`;
      })
      .join('\n');
    embed.addFields({ name: `Recent activity (${r.recentLogs.length})`, value: lines.slice(0, 1024) });
  }

  embed.setFooter({ text: `Requested by ${interaction.user.tag}` });
  await interaction.editReply({ embeds: [embed] });
}
