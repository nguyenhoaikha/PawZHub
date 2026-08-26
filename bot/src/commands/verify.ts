import { SlashCommandBuilder, ChatInputCommandInteraction, EmbedBuilder } from 'discord.js';
import { verifyKey } from '../lib/api';

export const data = new SlashCommandBuilder()
  .setName('verify')
  .setDescription('Verify a PawZHub key')
  .addStringOption((opt) =>
    opt
      .setName('key')
      .setDescription('The PawZHub key to verify (PH.* or JWT)')
      .setRequired(true)
  )
  .addStringOption((opt) =>
    opt
      .setName('hwid')
      .setDescription('Your HWID (optional for free keys)')
      .setRequired(false)
  );

export async function execute(interaction: ChatInputCommandInteraction) {
  const key = interaction.options.getString('key', true);
  const hwid = interaction.options.getString('hwid') || undefined;
  const userId = interaction.user.id;

  await interaction.deferReply({ ephemeral: true });

  const result = await verifyKey(key, hwid, userId);

  if (!result.ok) {
    const embed = new EmbedBuilder()
      .setColor(0xef4444)
      .setTitle('Verification failed')
      .setDescription(result.error || 'Could not reach the API.')
      .setTimestamp();
    await interaction.editReply({ embeds: [embed] });
    return;
  }

  const r = result.data;
  const color = r.valid ? 0x22c55e : 0xef4444;
  const title = r.valid
    ? `Valid key — ${r.tier || 'free'} (${r.type || 'free'})`
    : `Invalid key`;

  const fields: { name: string; value: string; inline?: boolean }[] = [];
  if (r.valid) {
    if (r.source) fields.push({ name: 'Source', value: r.source, inline: true });
    if (r.remainingHours !== undefined) {
      fields.push({ name: 'Time left', value: `${r.remainingHours}h`, inline: true });
    }
    if (r.features && r.features.length) {
      fields.push({ name: 'Features', value: r.features.join(', '), inline: true });
    }
    if (r.expires) {
      const expDate = new Date(r.expires);
      fields.push({ name: 'Expires', value: `<t:${Math.floor(expDate.getTime() / 1000)}:F>`, inline: false });
    }
  } else {
    fields.push({ name: 'Reason', value: r.message || 'Unknown', inline: false });
  }

  const embed = new EmbedBuilder()
    .setColor(color)
    .setTitle(title)
    .addFields(fields)
    .setFooter({ text: `PawZHub • Requested by ${interaction.user.tag}` })
    .setTimestamp();

  await interaction.editReply({ embeds: [embed] });
}
