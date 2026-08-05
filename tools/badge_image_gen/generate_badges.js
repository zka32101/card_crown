#!/usr/bin/env node
// 実績バッジ画像 一括生成ツール（Leonardo.ai版）
// lib/models/game_enrichment.dart の kBadgeDefinitions に対応する16種の
// 円形メダル風バッジ画像を生成する。コスト最小設定（alchemy:false, 512x512）。
// 既存ファイルは自動スキップ（--forceで上書き）。
//
// 使い方（PowerShellで事前に $env:LEONARDO_API_KEY="xxxx" 済みなら省略可）:
//   node generate_badges.js --all
//   node generate_badges.js --ids first_victory,first_card_created
//   node generate_badges.js --all --force

const fs = require('fs');
const path = require('path');

const LEONARDO_API_KEY = process.env.LEONARDO_API_KEY;
const LEONARDO_MODEL_ID = process.env.LEONARDO_MODEL_ID || 'de7d3faf-762f-48e0-b3b7-9d0ac3a3fcf3';
const API_BASE = 'https://cloud.leonardo.ai/api/rest/v1';
const OUTPUT_DIR = path.join(__dirname, 'output');

// 共通の土台: 円形メダル、金/ブロンズの縁取り、Card Crownの世界観（夜空紺+金箔+羊皮紙）
const BASE_PROMPT =
  'Full-bleed circular game achievement badge/medal icon, edge-to-edge filling the canvas, ' +
  'flat bold vector game icon style, ornate gold or bronze rim, dark navy night-sky background (#120E1E), ' +
  'high contrast, thick clean silhouette readable at small size, no text, no letters, no watermark.';

const NEGATIVE_PROMPT =
  'text, letters, words, watermark, signature, blurry, photorealistic, human face, realistic person, ' +
  'cluttered background, low contrast, off-center, low quality, jpeg artifacts, square shape, rectangular frame';

const BADGES = [
  { id: 'first_victory', motif: 'a golden laurel wreath crossed with a small sword, celebrating a first victory' },
  { id: 'first_card_created', motif: 'a golden paintbrush crossed with a glowing playing card' },
  { id: 'ten_victories', motif: 'a silver medal embossed with a small sword, engraved "10" replaced by ten small stars around the rim' },
  { id: 'fifty_victories', motif: 'a gold medal embossed with crossed swords and a general\'s star' },
  { id: 'hundred_victories', motif: 'a golden crown medal with crossed swords beneath it, radiant light rays behind' },
  { id: 'bronze_rank', motif: 'a bronze shield medallion with a single small star' },
  { id: 'silver_rank', motif: 'a silver shield medallion with two small stars' },
  { id: 'gold_rank', motif: 'a gold shield medallion with three small stars' },
  { id: 'platinum_rank', motif: 'a platinum-white shield medallion set with a sparkling diamond gem' },
  { id: 'diamond_rank', motif: 'a radiant diamond-encrusted crown medallion, the most prestigious rank' },
  { id: 'five_cards', motif: 'a fanned hand of five glowing playing cards' },
  { id: 'all_attributes', motif: 'three gemstones in a triangle: golden-yellow, crimson-red, and indigo-blue, representing three elements' },
  { id: 'seven_day_streak', motif: 'a small flame rising from an open calendar page' },
  { id: 'thirty_day_streak', motif: 'a large blazing flame wrapped around a five-pointed star' },
  { id: 'comeback_win', motif: 'a golden phoenix rising from flames, wings spread wide' },
  { id: 'perfect_victory', motif: 'a pristine golden shield with no cracks, glowing faintly, radiant and untouched' },
];

function buildPrompt(motif) {
  return `${BASE_PROMPT} Central motif: ${motif}.`;
}

async function generateImage(prompt) {
  const createRes = await fetch(`${API_BASE}/generations`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${LEONARDO_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      prompt,
      negative_prompt: NEGATIVE_PROMPT,
      modelId: LEONARDO_MODEL_ID,
      width: 512,
      height: 512,
      num_images: 1,
      alchemy: false,
      photoReal: false,
    }),
  });

  if (!createRes.ok) {
    throw new Error(`Leonardo API error (create): ${createRes.status} ${await createRes.text()}`);
  }

  const created = await createRes.json();
  const genId = created?.sdGenerationJob?.generationId;
  if (!genId) {
    throw new Error(`generationId が取得できませんでした: ${JSON.stringify(created)}`);
  }

  let attempts = 0;
  let images = null;
  while (attempts < 30) {
    await new Promise((r) => setTimeout(r, 2000));
    const poll = await fetch(`${API_BASE}/generations/${genId}`, {
      headers: { Authorization: `Bearer ${LEONARDO_API_KEY}` },
    });
    if (!poll.ok) {
      throw new Error(`Leonardo API error (poll): ${poll.status} ${await poll.text()}`);
    }
    const data = await poll.json();
    const gen = data.generations_by_pk;
    if (gen?.status === 'COMPLETE') {
      images = gen.generated_images;
      break;
    }
    if (gen?.status === 'FAILED') {
      throw new Error(`generation failed: ${JSON.stringify(gen)}`);
    }
    attempts++;
  }

  if (!images || !images[0]?.url) {
    throw new Error('画像生成がタイムアウトしました');
  }

  return images[0].url;
}

async function downloadTo(url, filePath) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`download failed: ${res.status}`);
  const buf = Buffer.from(await res.arrayBuffer());
  fs.writeFileSync(filePath, buf);
}

function parseArgs() {
  const args = process.argv.slice(2);
  const opts = { ids: null, all: false, force: false };
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--ids') opts.ids = args[++i].split(',').map((s) => s.trim());
    else if (args[i] === '--all') opts.all = true;
    else if (args[i] === '--force') opts.force = true;
  }
  return opts;
}

async function main() {
  if (!LEONARDO_API_KEY) {
    console.error('❌ LEONARDO_API_KEY が設定されていません。');
    process.exit(1);
  }
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });

  const opts = parseArgs();
  let target = BADGES;
  if (opts.ids) target = BADGES.filter((b) => opts.ids.includes(b.id));
  else if (!opts.all) target = BADGES.slice(0, 2); // デフォルトはサンプル2枚

  let done = 0;
  for (const badge of target) {
    const outPath = path.join(OUTPUT_DIR, `${badge.id}.png`);
    if (fs.existsSync(outPath) && !opts.force) {
      console.log(`⏭  skip (exists): ${badge.id}`);
      continue;
    }
    try {
      console.log(`🎨 generating: ${badge.id}...`);
      const url = await generateImage(buildPrompt(badge.motif));
      await downloadTo(url, outPath);
      console.log(`✅ saved: ${outPath}`);
      done++;
    } catch (e) {
      console.error(`❌ failed (${badge.id}): ${e.message}`);
    }
  }
  console.log(`\n完了: ${done}/${target.length} 枚生成`);
}

main().catch((e) => {
  console.error('❌ エラー:', e.message);
  process.exit(1);
});
