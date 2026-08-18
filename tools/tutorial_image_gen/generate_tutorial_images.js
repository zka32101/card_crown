#!/usr/bin/env node
// チュートリアル画面イラスト 一括生成ツール（Leonardo.ai版）
// lib/screens/tutorial_screen.dart の9ページに対応するシーンイラストを生成する。
// バッジ(円形メダル)と違い、こちらは正方形のシーンイラスト。
// コスト最小設定（alchemy:false, 512x512）。既存ファイルは自動スキップ（--forceで上書き）。
//
// 使い方（PowerShellで事前に $env:LEONARDO_API_KEY="xxxx" 済みなら省略可）:
//   node generate_tutorial_images.js --all
//   node generate_tutorial_images.js --ids page1_welcome,page5_battle
//   node generate_tutorial_images.js --all --force

const fs = require('fs');
const path = require('path');

const LEONARDO_API_KEY = process.env.LEONARDO_API_KEY;
const LEONARDO_MODEL_ID = process.env.LEONARDO_MODEL_ID || 'de7d3faf-762f-48e0-b3b7-9d0ac3a3fcf3';
const API_BASE = 'https://cloud.leonardo.ai/api/rest/v1';
const OUTPUT_DIR = path.join(__dirname, 'output');

const BASE_PROMPT =
  'Full-bleed square fantasy game illustration, edge-to-edge filling the canvas, no border, no frame, ' +
  'flat bold vector game art style matching a card battle game called Card Rivals, ' +
  'dark navy night-sky background (#120E1E), gold and bronze ornate accents, ' +
  'high contrast, clean readable composition, no text, no letters, no watermark, no UI elements.';

const NEGATIVE_PROMPT =
  'text, letters, words, watermark, signature, blurry, photorealistic, human face close-up, ' +
  'cluttered background, low contrast, low quality, jpeg artifacts, border, picture frame, rounded corners';

const PAGES = [
  { id: 'page1_welcome', motif: 'a grand golden royal crown floating above an ornate castle gate, radiant light rays, welcoming and epic' },
  { id: 'page2_joy', motif: 'a radiant golden sun continent with warm golden-yellow light, a golden gemstone floating above rolling golden hills' },
  { id: 'page3_anger', motif: 'a fiery volcanic continent glowing deep crimson-red, molten lava cracks, a crimson-red gemstone floating above jagged mountains' },
  { id: 'page4_sadness', motif: 'a deep midnight indigo-blue forest under a crescent moon, an indigo-blue gemstone floating above misty dark trees' },
  { id: 'page5_battle', motif: 'two ornate playing cards clashing in the center with a burst of golden energy sparks and small lightning cracks between them' },
  { id: 'page6_deck', motif: 'a fanned hand of five ornate glowing playing cards arranged in a golden arc' },
  { id: 'page7_economy', motif: 'an open golden treasure chest overflowing with glowing coins and gemstones, sparkles rising' },
  { id: 'page8_rating', motif: 'a golden trophy on top of a rising staircase podium, glowing rank stars ascending beside it' },
  { id: 'page9_start', motif: 'a lone armored knight silhouette stepping through a glowing golden portal gate, ready to begin an adventure' },
];

function buildPrompt(motif) {
  return `${BASE_PROMPT} Scene: ${motif}.`;
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
  let target = PAGES;
  if (opts.ids) target = PAGES.filter((p) => opts.ids.includes(p.id));
  else if (!opts.all) target = PAGES.slice(0, 2);

  let done = 0;
  for (const page of target) {
    const outPath = path.join(OUTPUT_DIR, `${page.id}.png`);
    if (fs.existsSync(outPath) && !opts.force) {
      console.log(`⏭  skip (exists): ${page.id}`);
      continue;
    }
    try {
      console.log(`🎨 generating: ${page.id}...`);
      const url = await generateImage(buildPrompt(page.motif));
      await downloadTo(url, outPath);
      console.log(`✅ saved: ${outPath}`);
      done++;
    } catch (e) {
      console.error(`❌ failed (${page.id}): ${e.message}`);
    }
  }
  console.log(`\n完了: ${done}/${target.length} 枚生成`);
}

main().catch((e) => {
  console.error('❌ エラー:', e.message);
  process.exit(1);
});
