#!/usr/bin/env node
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// シードカード画像 一括/サンプル生成ツール（Leonardo.ai版）
// prompt_builder.js のプロンプト設計をそのまま流用し、
// lib/data/seed_cards_data.dart から直接カード定義を読み取って
// Leonardo.ai API で画像を生成、tools/seed_card_image_gen/output/ に保存する。
//
// コスト最小化のため:
//   - alchemy: false, photoReal: false（どちらもクレジット消費が数倍になる高品質モード）
//     ※ alchemyをtrueにする場合、Phoenixではcontrastを2.5以上に設定する必要がある
//        （公式ドキュメント要件。alchemy:falseの現状は未設定でよい）
//     ※ photoRealはLeonardo Kino XL / Diffusion XL / Vision XL専用でPhoenixには
//        非対応のため、Phoenix利用時は常にfalseにしておくこと
//   - num_images: 1（1回のリクエストで1枚のみ）
//   - 512x512（Leonardoが許容する最小クラスの解像度）
//   - 既存ファイルは自動スキップ（--allを何度実行しても未生成分だけ課金される）
//
// LEONARDO_MODEL_ID のデフォルトは Leonardo Phoenix 1.0 の公式モデルID
// （de7d3faf-762f-48e0-b3b7-9d0ac3a3fcf3、docs.leonardo.ai/docs/phoenix で確認済み）。
// モデルが変更・廃止された場合は $env:LEONARDO_MODEL_ID="別のUUID" で上書きすること。
//
// 使い方:
//   （PowerShellでは事前に $env:LEONARDO_API_KEY="xxxx" を実行しておく）
//   node generate_leonardo.js --count 2               # 先頭2枚だけ（未生成分のみ）
//   node generate_leonardo.js --ids joy_c1_001,anger_c1_001
//   node generate_leonardo.js --all                   # 残り全枚数をまとめて生成（推奨）
//   node generate_leonardo.js --all --force            # 既存分も含めて全部作り直す
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const fs = require('fs');
const path = require('path');
const { parseSeedCards, buildPrompt } = require('./prompt_builder');

const LEONARDO_API_KEY = process.env.LEONARDO_API_KEY;
// デフォルト: Leonardo Phoenix 1.0（要検証・エラー時は環境変数で上書き）
const LEONARDO_MODEL_ID = process.env.LEONARDO_MODEL_ID || 'de7d3faf-762f-48e0-b3b7-9d0ac3a3fcf3';
const OUTPUT_DIR = path.join(__dirname, 'output');
const API_BASE = 'https://cloud.leonardo.ai/api/rest/v1';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Leonardo.ai 呼び出し（コスト最小設定）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
async function generateImage(prompt, negativePrompt) {
  const createRes = await fetch(`${API_BASE}/generations`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${LEONARDO_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      prompt,
      negative_prompt: negativePrompt,
      modelId: LEONARDO_MODEL_ID,
      width: 512,
      height: 512,
      num_images: 1,
      alchemy: false, // 高品質モード（コスト数倍）はオフ
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

  // ポーリング（最大60秒）
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

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CLI
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function parseArgs() {
  const args = process.argv.slice(2);
  const opts = { count: null, ids: null, all: false, force: false };
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--count') opts.count = parseInt(args[++i], 10);
    else if (args[i] === '--ids') opts.ids = args[++i].split(',').map((s) => s.trim());
    else if (args[i] === '--all') opts.all = true;
    else if (args[i] === '--force') opts.force = true;
  }
  return opts;
}

async function main() {
  if (!LEONARDO_API_KEY) {
    console.error('❌ LEONARDO_API_KEY が設定されていません。');
    console.error('   例: $env:LEONARDO_API_KEY="xxxx"; node generate_leonardo.js --count 2');
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

  // API課金の節約: 既に画像ファイルが存在するカードはデフォルトでスキップする
  // （--allを繰り返し実行しても、未生成分だけ課金される＝中断・再開しても安全）
  // 強制的に作り直したい場合は --force を付ける
  let skipped = 0;
  const toGenerate = opts.force
    ? target
    : target.filter((card) => {
        const exists = fs.existsSync(path.join(OUTPUT_DIR, `${card.cardId}.png`));
        if (exists) skipped++;
        return !exists;
      });

  if (skipped > 0) {
    console.log(`⏭️  既存の${skipped}枚をスキップ（再生成するには --force を付けてください）`);
  }
  console.log(`🎨 ${toGenerate.length} 枚を生成します（Leonardo.ai / modelId=${LEONARDO_MODEL_ID} / alchemy=off / 512x512）\n`);

  for (const card of toGenerate) {
    const { prompt, negativePrompt, rarity, cardType } = buildPrompt(card);
    process.stdout.write(`  ${card.cardId} (${card.nameJp} / ${card.attribute} / ${rarity} / ${cardType}) ... `);
    try {
      const imageUrl = await generateImage(prompt, negativePrompt);
      const outFile = path.join(OUTPUT_DIR, `${card.cardId}.png`);
      await downloadTo(imageUrl, outFile);
      manifest[card.cardId] = {
        nameJp: card.nameJp,
        attribute: card.attribute,
        rarity,
        cardType,
        file: `${card.cardId}.png`,
        prompt,
        provider: 'leonardo',
        modelId: LEONARDO_MODEL_ID,
        generatedAt: new Date().toISOString(),
      };
      fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));
      console.log('✅');
    } catch (e) {
      console.log(`❌ ${e.message}`);
    }
  }

  console.log(`\n完了（生成${toGenerate.length}枚 / スキップ${skipped}枚）。出力先: ${OUTPUT_DIR}`);
}

main().catch((e) => {
  console.error(`❌ 予期しないエラー: ${e.message}`);
  process.exit(1);
});
