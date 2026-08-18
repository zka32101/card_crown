#!/usr/bin/env node
// アプリアイコン一発生成ツール（Leonardo.ai版、単発・高品質設定）
// シードカード用のgenerate_leonardo.jsと違い1枚だけを高品質(alchemy:true)で作る。
//
// 使い方（PowerShellで事前に $env:LEONARDO_API_KEY="xxxx" 済みなら省略可）:
//   node generate_icon.js

const fs = require('fs');
const path = require('path');

const LEONARDO_API_KEY = process.env.LEONARDO_API_KEY;
const LEONARDO_MODEL_ID = process.env.LEONARDO_MODEL_ID || 'de7d3faf-762f-48e0-b3b7-9d0ac3a3fcf3';
const API_BASE = 'https://cloud.leonardo.ai/api/rest/v1';
const OUTPUT_PATH = path.join(__dirname, 'output', process.argv[2] || 'app_icon_raw_v2.png');

const PROMPT = [
  'Full-bleed square app icon artwork, edge-to-edge, filling the entire canvas with no border, no frame, no margin, no rounded corners.',
  'App icon emblem for a fantasy card battle game called "Card Rivals".',
  'An ornate golden royal crown at the center, with exactly three glowing gemstones set into it:',
  'a bright golden-yellow amber gem on the left (joy), a deep crimson-red gem on the right (anger),',
  'and a deep indigo-blue gem at the very top point (sadness). The center gem must be golden-yellow, not purple.',
  'Below the crown, a subtle stylized playing card spade silhouette.',
  'Background is a deep dark navy night sky (#120E1E) with faint starlight, extending fully to all four edges of the image.',
  'Symmetrical, perfectly centered composition, flat bold vector emblem / game logo style.',
  'High contrast, thick clean silhouette readable at small icon size.',
  'No text, no letters, no watermark, no signature, no decorative corner frame, no picture-frame border.',
].join(' ');

const NEGATIVE_PROMPT = [
  'text, letters, words, watermark, signature, logo text,',
  'border, frame, picture frame, corner ornaments, rounded corners, vignette, margin, padding,',
  'blurry, photorealistic, human face, realistic person,',
  'cluttered background, busy background, low contrast, asymmetrical, off-center,',
  'purple gem, violet gem,',
  'low quality, jpeg artifacts, extra crowns, multiple objects',
].join(' ');

async function generateImage() {
  const createRes = await fetch(`${API_BASE}/generations`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${LEONARDO_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      prompt: PROMPT,
      negative_prompt: NEGATIVE_PROMPT,
      modelId: LEONARDO_MODEL_ID,
      width: 1024,
      height: 1024,
      num_images: 1,
      alchemy: true, // アイコンは1枚だけなので高品質モードを使う
      contrast: 3, // alchemy:true時のPhoenix必須要件（2.5以上）
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

  console.log(`⏳ 生成中... (generationId: ${genId})`);

  let attempts = 0;
  let images = null;
  while (attempts < 45) {
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

async function main() {
  if (!LEONARDO_API_KEY) {
    console.error('❌ LEONARDO_API_KEY が設定されていません。');
    process.exit(1);
  }

  fs.mkdirSync(path.dirname(OUTPUT_PATH), { recursive: true });

  console.log('🎨 Card Rivals アプリアイコンを生成します...');
  const url = await generateImage();
  const res = await fetch(url);
  if (!res.ok) throw new Error(`download failed: ${res.status}`);
  const buf = Buffer.from(await res.arrayBuffer());
  fs.writeFileSync(OUTPUT_PATH, buf);
  console.log(`✅ 保存しました: ${OUTPUT_PATH}`);
}

main().catch((e) => {
  console.error('❌ エラー:', e.message);
  process.exit(1);
});
