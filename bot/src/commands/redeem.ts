import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
} from 'discord.js';
import { redeemCode } from '../lib/api';

export const data = new SlashCommandBuilder()
  .setName('redeem')
  .setDescription('Redeem a PawZHub code to get a premium key')
  .addStringOption((opt) =>
    opt
      .setName('code')
      .setDescription('Your redemption code (e.g. a12e137e)')
      .setRequired(true)
  );

export async function execute(interaction: ChatInputCommandInteraction) {
  const code = interaction.options.getString('code', true).trim().toLowerCase();
  const discordUserId = interaction.user.id;

  await interaction.deferReply({ ephemeral: true });

  const result = await redeemCode(code, discordUserId);

  if (!result.ok) {
    const errorEmbed = new EmbedBuilder()
      .setColor(0xef4444)
      .setTitle('❌ Redemption Failed')
      .setDescription(result.error || 'Unknown error')
      .setTimestamp();

    // Add specific hints based on status code
    if (result.status === 404) {
      errorEmbed.addFields({
        name: 'Hint',
        value: 'Make sure you copied the code correctly. Codes are case-insensitive.',
      });
    } else if (result.status === 409) {
      errorEmbed.addFields({
        name: 'Already Used',
        value: 'This code has already been redeemed. Each code can only be used once.',
      });
    }

    await interaction.editReply({ embeds: [errorEmbed] });
    return;
  }

  const { key, expiresDate, issuedDate, hwidResetCooldownDays } = result.data;

  // Try to DM the key (keeps channel clean)
  let dmOk = false;
  try {
    const dm = await interaction.user.createDM();
    const dmEmbed = new EmbedBuilder()
      .setColor(0xFFD700)
      .setTitle('💎 Your PawZHub Premium Key')
      .setDescription(`\`\`\`${key}\`\`\``)
      .addFields(
        { name: 'Plan', value: '💎 Lifetime', inline: true },
        { name: 'Issued', value: issuedDate.slice(0, 10), inline: true },
        { name: 'Expires', value: expiresDate.slice(0, 10), inline: true },
        { name: 'HWID Reset', value: `Every ${hwidResetCooldownDays} days`, inline: true },
      )
      .setFooter({ text: 'Keep this key safe! It is bound to your Discord account.' })
      .setTimestamp();
    await dm.send({ embeds: [dmEmbed] });
    dmOk = true;
  } catch {
    dmOk = false;
  }

  // Summary in channel
  const embed = new EmbedBuilder()
    .setColor(0x22c55e)
    .setTitle('✅ Code Redeemed Successfully!')
    .setDescription(dmOk
      ? 'Check your DMs for your premium key!'
      : `Couldn't DM you. Here's your key (copy it quickly):\n\`\`\`${key}\`\`\``
    )
    .addFields(
      { name: 'Plan', value: '💎 Lifetime', inline: true },
      { name: 'HWID Reset', value: `Every ${hwidResetCooldownDays} days`, inline: true },
    )
    .setFooter({ text: `Redeemed by ${interaction.user.tag}` })
    .setTimestamp();

  await interaction.editReply({ embeds: [embed] });
}
