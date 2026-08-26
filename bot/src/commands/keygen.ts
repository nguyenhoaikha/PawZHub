import { SlashCommandBuilder, ChatInputCommandInteraction, EmbedBuilder, PermissionFlagsBits } from 'discord.js';
import { generateKeys } from '../lib/api';
import { isAdmin } from '../lib/permissions';

export const data = new SlashCommandBuilder()
  .setName('keygen')
  .setDescription('Generate premium PawZHub keys (admin only)')
  .addStringOption((opt) =>
    opt
      .setName('plan')
      .setDescription('Plan type')
      .setRequired(true)
      .addChoices(
        { name: 'Trial (7 days)', value: 'trial' },
        { name: 'Monthly (30 days)', value: 'monthly' },
        { name: 'Lifetime (10 years)', value: 'lifetime' }
      )
  )
  .addIntegerOption((opt) =>
    opt
      .setName('count')
      .setDescription('How many keys to generate (1-100)')
      .setRequired(false)
      .setMinValue(1)
      .setMaxValue(100)
  )
  .addStringOption((opt) =>
    opt
      .setName('email')
      .setDescription('Optional customer email')
      .setRequired(false)
  )
  .addStringOption((opt) =>
    opt
      .setName('roblox')
      .setDescription('Optional Roblox username')
      .setRequired(false)
  );

export async function execute(interaction: ChatInputCommandInteraction) {
  if (!isAdmin(interaction.user.id)) {
    await interaction.reply({
      content: 'This command is admin-only.',
      ephemeral: true,
    });
    return;
  }

  const plan = interaction.options.getString('plan', true) as 'trial' | 'monthly' | 'lifetime';
  const count = interaction.options.getInteger('count') ?? 1;
  const email = interaction.options.getString('email') || undefined;
  const roblox = interaction.options.getString('roblox') || undefined;

  await interaction.deferReply({ ephemeral: true });

  const result = await generateKeys(plan, count, email, roblox);

  if (!result.ok) {
    const embed = new EmbedBuilder()
      .setColor(0xef4444)
      .setTitle('Key generation failed')
      .setDescription(result.error || 'Unknown error')
      .setTimestamp();
    await interaction.editReply({ embeds: [embed] });
    return;
  }

  const { keys, count: generated } = result.data;

  // Try to DM the user the keys first (keeps the channel clean)
  let dmOk = false;
  try {
    const dm = await interaction.user.createDM();
    const chunks: string[] = [];
    let buf = '';
    for (const k of keys) {
      const line = `\`${k.key}\`  (${k.expiresDate?.slice(0, 10) || 'n/a'})`;
      if (buf.length + line.length + 1 > 1800) {
        chunks.push(buf);
        buf = '';
      }
      buf = buf ? `${buf}\n${line}` : line;
    }
    if (buf) chunks.push(buf);
    for (const c of chunks) {
      await dm.send(`Generated ${generated} ${plan} key(s):\n${c}`);
    }
    dmOk = true;
  } catch (err) {
    dmOk = false;
  }

  // Show summary in channel (no full keys unless DM failed)
  const embed = new EmbedBuilder()
    .setColor(0x22c55e)
    .setTitle(`Generated ${generated} ${plan} key(s)`)
    .addFields(
      { name: 'Plan', value: plan, inline: true },
      { name: 'Count', value: String(generated), inline: true },
      { name: 'Delivery', value: dmOk ? 'DM sent' : 'shown below', inline: true }
    )
    .setFooter({ text: `Requested by ${interaction.user.tag}` })
    .setTimestamp();

  if (!dmOk) {
    // fallback: show the first 3 keys inline (more than 3 is a lot)
    const shown = keys.slice(0, 3).map((k) => `\`${k.key}\``).join('\n');
    const more = keys.length > 3 ? `\n… and ${keys.length - 3} more (re-run with count=${keys.length} to see all)` : '';
    embed.addFields({ name: 'Keys', value: shown + more });
  }

  await interaction.editReply({ embeds: [embed] });
}
