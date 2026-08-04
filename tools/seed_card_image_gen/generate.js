#!/usr/bin/env node
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// シードカード画像 一括/サンプル生成ツール（Replicate版）
// lib/data/seed_cards_data.dart から直接カード定義を読み取って
// Replicate (Flux Schnell) で画像を生成、tools/seed_card_image_gen/output/ に保存する。
//
// 使い方:
//   REPLICATE_API_TOKEN=xxxx node generate.js --count 2        # 先頭N枚だけサンプル生成
//   REPLICATE_API_TOKEN=xxxx node generate.js --ids joy_c1_001,anger_c1_001
//   REPLICATE_API_TOKEN=xxxx node generate.js --all            # 50枚すべて
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const fs = require('fs');
const path = require('path');
const { parseSeedCards, buildPrompt } = require('./prompt_builder');

const REPLICATE_API_TOKEN = process.env.REPLICATE_API_TOKEN;
const FLUX_VERSION = '5f24084160c9089501c1b3545d9be3c27883ae2239b6f412990e82d4a6210f8f';
const OUTPUT_DIR = path.join(__dirname, 'output');

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Replicate 呼び出し（標準品質: Flux Schnell, 4 steps, 512x512）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
async function generateImage(prompt, negativePrompt) {
  const createRes = await fetch('https://api.replicate.com/v1/predictions', {
    method: 'POST',
    headers: {
      Authorization: `Token ${REPLICATE_API_TOKEN}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      version: FLUX_VERSION,
      input: {
        prompt,
        negative_prompt: negativePrompt,
        width: 512,
        height: 512,
        num_outputs: 1,
        num_inference_steps: 4,
      },
    }),
  });

  if (!createRes.ok) {
    throw new Error(`Replicate API error: ${createRes.status} ${await createRes.text()}`);
  }

  let result = await createRes.json();
  let attempts = 0;
  while (result.status !== 'succeeded' && result.status !== 'failed' && attempts < 30) {
    await new Promise((r) => setTimeout(r, 2000));
    const poll = await fetch(`https://api.replicate.com/v1/predictions/${result.id}`, {
      headers: { Authorization: `Token ${REPLICATE_API_TOKEN}` },
    });
    result = await poll.json();
    attempts++;
  }

  if (result.status !== 'succeeded' || !result.output || !result.output[0]) {
    throw new Error(`generation failed: ${JSON.stringify(result)}`);
  }

  return result.output[0];
}

async function downloadTo(url, filePath) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`download failed: ${res.status}`);
  const buf = Buffer.from(await res.arrayBuffer());
  fs.writeFileSync(filePath, buf);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CLI
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function parseArgs() {
  const args = process.argv.slice(2);
  const opts = { count: null, ids: null, all: false };
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--count') opts.count = parseInt(args[++i], 10);
    else if (args[i] === '--ids') opts.ids = args[++i].split(',').map((s) => s.trim());
    else if (args[i] === '--all') opts.all = true;
  }
  return opts;
}

async function main() {
  if (!REPLICATE_API_TOKEN) {
    console.error('❌ REPLICATE_API_TOKEN が設定されていません。');
    console.error('   例: $env:REPLICATE_API_TOKEN="r8_xxxx"; node generate.js --count 2');
    process.exit(1);
  }

  const opts = parseArgs();
  const allCards = parseSeedCards();
  console.log(`📋 seed_cards_data.dart から ${allCards.length} 枚のカード定義を読み込みました`);

  let target;
  if (opts.ids) {
    target = allCards.filter((c) => opts.ids.includes(c.cardId));
  } else if (opts.all) {
    target = allCards;
  } else {
    const n = opts.count || 2;
    target = allCards.slice(0, n);
  }

  if (target.length === 0) {
    console.error('❌ 対象カードが見つかりません');
    process.exit(1);
  }

  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  const manifestPath = path.join(OUTPUT_DIR, 'manifest.json');
  const manifest = fs.existsSync(manifestPath)
    ? JSON.parse(fs.readFileSync(manifestPath, 'utf8'))
    : {};

  console.log(`🎨 ${target.length} 枚を生成します（標準品質: Flux Schnell, 512x512, 4 steps）\n`);

  for (const card of target) {
    const { prompt, negativePrompt, rarity, cardType } = buildPrompt(card);
    process.stdout.write(`  ${card.cardId} (${card.nameJp} / ${card.attribute} / ${rarity} / ${cardType}) ... `);
    try {
      const replicateUrl = await generateImage(prompt, negativePrompt);
      const outFile = path.join(OUTPUT_DIR, `${card.cardId}.webp`);
      await downloadTo(replicateUrl, outFile);
      manifest[card.cardId] = {
        nameJp: card.nameJp,
        attribute: card.attribute,
        rarity,
        cardType,
        file: `${card.cardId}.webp`,
        prompt,
        provider: 'replicate-flux-schnell',
        generatedAt: new Date().toISOString(),
      };
      fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));
      console.log('✅');
    } catch (e) {
      console.log(`❌ ${e.message}`);
    }
  }

  console.log(`\n完了。出力先: ${OUTPUT_DIR}`);
}

main().catch((e) => {
  console.error(`❌ 予期しないエラー: ${e.message}`);
  process.exit(1);
});
