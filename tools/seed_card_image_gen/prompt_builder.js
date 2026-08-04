// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// プロンプト組み立て共通モジュール（Replicate/Leonardo共有）
// functions/src/generateCardImage.ts のプロンプト設計をそのまま流用
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const fs = require('fs');
const path = require('path');

const SEED_DATA_PATH = path.join(__dirname, '..', '..', 'lib', 'data', 'seed_cards_data.dart');

// 属性ごとに複数のキャラクター案を用意し、カードIDのハッシュで決定的に選ぶ。
// 単一の固定文言だと全カードの顔立ちがほぼ同じになってしまうため、
// アーキタイプ・髪型・髪色・表情・鎧の意匠を変えたバリエーションを持たせる。
// 前半5個=人型、後半5個=精霊・幻獣・エレメンタル等の非人型（属性の世界観は共通のまま多様化する）。
const ATTR_CHARACTER_VARIANTS = {
  joy: [
    'radiant fantasy hero, golden glowing aura, warm smile, luminous flowing golden hair, brilliant sun-motif armor',
    'cheerful young paladin, golden glowing aura, bright confident grin, short auburn hair, ornate sun-crest breastplate',
    'noble sunlit priestess, golden glowing aura, serene gentle smile, long braided silver-blonde hair, flowing golden vestments',
    'spirited boy warrior, golden glowing aura, energetic beaming grin, spiky bronze hair, sun-emblazoned leather armor',
    'elegant solar knight, golden glowing aura, calm composed expression, wavy chestnut hair, gilded ceremonial plate armor',
    'majestic golden phoenix spirit, golden glowing aura, blazing radiant plumage, fiery sun-crest crown of feathers, no human features',
    'guardian sun lion beast, golden glowing aura, regal golden mane, glowing amber eyes, ornate gold-plated harness, no human features',
    'small radiant sun sprite, golden glowing aura, glowing childlike wisp form, trailing sparks of light, no human features',
    'celestial golden serpent deity, golden glowing aura, gleaming scaled coils, crowned with a solar halo, no human features',
    'living sunflower golem, golden glowing aura, petal-crowned wooden body, radiant core glowing within its chest, no human features',
  ],
  anger: [
    'fierce berserker warrior, blazing crimson energy, burning intense eyes, battle-scarred dark armor with flame runes',
    'towering flame gladiator, blazing crimson energy, snarling fierce expression, shaved head with ember tattoos, spiked obsidian armor',
    'ruthless war chieftain, blazing crimson energy, cold furious glare, long braided black hair, crimson battle-worn plate mail',
    'young hotblooded duelist, blazing crimson energy, wild grinning snarl, messy red hair, scorched leather war vest',
    'stoic flame sentinel, blazing crimson energy, grim determined stare, close-cropped grey hair, ash-blackened iron armor',
    'monstrous crimson dragon warlord, blazing crimson energy, jagged obsidian horns, molten cracks glowing across its hide, no human features',
    'living magma golem, blazing crimson energy, cracked volcanic rock body, rivers of glowing lava within, no human features',
    'infernal fire salamander spirit, blazing crimson energy, serpentine flame-wreathed body, ember-trailing tail, no human features',
    'demonic obsidian oni beast, blazing crimson energy, twisted curved horns, smoldering ember-red eyes, no human features',
    'ferocious ember wolf spirit, blazing crimson energy, flame-licked fur, glowing molten claws, no human features',
  ],
  sadness: [
    'serene ethereal mage, soft blue-violet glow, gentle melancholic eyes, midnight robes adorned with silver stars',
    'solemn moonlit oracle, soft blue-violet glow, downcast tearful gaze, long silver hair, flowing indigo mourning veil',
    'quiet frost wanderer, soft blue-violet glow, distant wistful stare, short pale-blue hair, tattered midnight-blue cloak',
    'melancholic young witch, soft blue-violet glow, soft sorrowful smile, dark wavy hair with silver streaks, star-embroidered violet dress',
    'weary twilight sage, soft blue-violet glow, tired hollow eyes, long unkempt grey-blue hair, faded indigo scholar robes',
    'spectral moon wraith, soft blue-violet glow, translucent flowing ghostly form, hollow starlit eyes, no human features',
    'nine-tailed frost kitsune spirit, soft blue-violet glow, silvery-blue flowing fur, glowing crescent moon markings, no human features',
    'deep-sea leviathan spirit, soft blue-violet glow, bioluminescent trailing fins, ancient sorrowful eyes, no human features',
    'shadow raven familiar, soft blue-violet glow, midnight feathers dusted with starlight, glowing violet eyes, no human features',
    'weeping willow tree spirit, soft blue-violet glow, drooping star-lit branches, a faint sorrowful face in its bark, no human features',
  ],
};

// カードIDから決定的にバリエーションを選ぶ（同じカードは常に同じ見た目になり、再生成時も一貫する）
function pickCharacterVariant(attribute, cardId) {
  const variants = ATTR_CHARACTER_VARIANTS[attribute] || ATTR_CHARACTER_VARIANTS.joy;
  const key = cardId || '';
  let hash = 0;
  for (let i = 0; i < key.length; i++) {
    hash = (hash * 31 + key.charCodeAt(i)) >>> 0;
  }
  return variants[hash % variants.length];
}

const ATTR_PALETTE = {
  joy: 'warm golden amber sunlit color palette, bright vivid contrast',
  anger: 'deep crimson dark orange volcanic color palette, high contrast dramatic',
  sadness: 'midnight blue indigo moonlit silver color palette, cool ethereal tones',
};

const RARITY_BG = {
  joy: {
    n: 'solid warm golden gradient background',
    r: 'sunlit golden meadow with blooming wildflowers background',
    sr: 'majestic golden palace, divine light rays through parting clouds, holy atmosphere',
    ur: 'celestial golden sky city, divine floating islands, heavenly aurora, towering radiant spires',
  },
  anger: {
    n: 'solid deep crimson gradient background',
    r: 'volcanic landscape, glowing lava rivers, molten rocks background',
    sr: 'massive volcanic eruption, fire pillars, crimson storm sky, burning mountain peak',
    ur: 'apocalyptic volcanic world, titanic inferno, ancient obsidian fortress, legendary fire ocean',
  },
  sadness: {
    n: 'solid midnight blue gradient background',
    r: 'moonlit mystical lake, silver mist, ancient gnarled trees background',
    sr: 'ethereal moonlit realm, aurora borealis, mirror-calm ocean, crumbling ancient ruins',
    ur: 'cosmic ocean, enormous full moon, sea of stars, legendary submerged palace glowing in depths',
  },
};

// レアリティ品質句（末尾カンマは呼び出し側の join(', ') で二重カンマになるため付けない）
const RARITY_QUALITY = {
  n: '',
  r: 'detailed illustration, atmospheric lighting',
  sr: 'highly detailed, cinematic dramatic lighting, rich textures',
  ur: 'legendary epic masterpiece, extraordinary intricate detail, breathtaking composition',
};

// 統一トーン（シードカードは運営製のため house style として cool 固定）
const TONE_STYLE = {
  cool: 'sharp defined features, determined confident expression, high contrast dramatic lighting',
};

const TYPE_POSE = {
  attack: 'aggressive forward combat pose, weapon raised, explosive offensive energy burst',
  defense: 'firm protective stance, shield raised, radiant barrier aura surrounding body',
  speed: 'dynamic swift dashing pose, speed trail lines, wind blur motion',
  balance: 'composed centered stance, balanced power flowing steadily from core',
};

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SeedCard データ抽出（lib/data/seed_cards_data.dart を直接読む）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function parseSeedCards() {
  const src = fs.readFileSync(SEED_DATA_PATH, 'utf8');
  const chunks = src.split(/SeedCard\(/).slice(1);

  const getStr = (chunk, key) => {
    // Dart文字列内のエスケープされたアポストロフィ（\'）を値の一部として許容する
    const m = chunk.match(new RegExp(key + ":\\s*'((?:[^'\\\\]|\\\\.)*)'"));
    return m ? m[1].replace(/\\'/g, "'") : null;
  };
  const getNum = (chunk, key) => {
    const m = chunk.match(new RegExp(key + ':\\s*(\\d+)'));
    return m ? parseInt(m[1], 10) : null;
  };

  return chunks
    .map((chunk) => ({
      cardId: getStr(chunk, 'cardId'),
      attribute: getStr(chunk, 'attribute'),
      cost: getNum(chunk, 'cost'),
      attackPower: getNum(chunk, 'attackPower'),
      defensePower: getNum(chunk, 'defensePower'),
      speed: getNum(chunk, 'speed'),
      nameJp: getStr(chunk, 'nameJp'),
      nameEn: getStr(chunk, 'nameEn'),
    }))
    .filter((c) => c.cardId);
}

function costToRarity(cost) {
  if (cost <= 1) return 'n';
  if (cost <= 3) return 'r';
  if (cost === 4) return 'sr';
  return 'ur';
}

function getCardType(atk, def, spd) {
  const max = Math.max(atk, def, spd);
  if (atk === max && atk > def && atk > spd) return 'attack';
  if (def === max && def > atk && def > spd) return 'defense';
  if (spd === max && spd > atk && spd > def) return 'speed';
  return 'balance';
}

function buildPrompt(card) {
  const rarity = costToRarity(card.cost);
  const cardType = getCardType(card.attackPower, card.defensePower, card.speed);

  const character = pickCharacterVariant(card.attribute, card.cardId);
  const palette = ATTR_PALETTE[card.attribute] || ATTR_PALETTE.joy;
  const bg = (RARITY_BG[card.attribute] || RARITY_BG.joy)[rarity] || RARITY_BG.joy.n;
  const pose = TYPE_POSE[cardType] || TYPE_POSE.balance;
  const toneStyle = TONE_STYLE.cool;
  const rarityQuality = RARITY_QUALITY[rarity] || '';

  const charParts = [character, `embodying "${card.nameEn}"`, pose, toneStyle]
    .filter(Boolean)
    .join(', ');

  const prompt = [
    charParts,
    bg,
    palette,
    rarityQuality,
    'digital fantasy TCG card illustration, centered character portrait, vibrant vivid colors, professional clean artwork, dramatic lighting',
    'no text no watermark no border',
  ]
    .filter(Boolean)
    .join(', ');

  const negativePrompt = [
    'text, words, letters, numbers, watermark, signature',
    'card frame, border, UI, HUD',
    'ugly, blurry, low quality, deformed, mutated, malformed',
    'extra limbs, bad anatomy, extra fingers',
    'duplicate, oversaturated, washed out',
  ].join(', ');

  return { prompt, negativePrompt, rarity, cardType };
}

module.exports = { parseSeedCards, buildPrompt, costToRarity, getCardType, SEED_DATA_PATH };
