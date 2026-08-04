# シードカード画像 AIプロンプト設計

`generate.js`（および元となった `functions/src/generateCardImage.ts`）が実際に組み立てるプロンプトの構造と例。

## 使用モデル

- **Replicate Flux Schnell**（version: `5f24084160c9089501c1b3545d9be3c27883ae2239b6f412990e82d4a6210f8f`）
- 標準品質設定: `512x512` / `num_inference_steps: 4`
- コスト目安: 1枚あたり約 $0.003〜0.005（0.5〜1円程度）

## プロンプト組み立て順序

```
キャラクター基本形 → カード名埋め込み → タイプ別ポーズ → トーン
→ 背景 → 属性パレット → レアリティ品質句 → TCGカード指定 → 除外指定
```

## 制御軸

| 要素 | 制御軸 | 内容 |
|---|---|---|
| キャラクター像 | 属性（喜/怒/哀） | 黄金の英雄／深紅の戦士／藍色の魔導士 |
| 背景 | 属性 × レアリティ | N=単色グラデーション → UR=天空都市・浮島 |
| ポーズ | ステータス型（攻撃/防御/速度/バランス） | 前傾攻撃姿勢／盾構え／疾走／中央構え |
| トーン | 固定 `cool`（シードカード統一house style） | 鋭い表情・高コントラスト |
| 品質強調句 | レアリティ | N=なし → UR=「legendary epic masterpiece」 |

## 生成例

### 例1: 喜属性・N（無印）カード「太陽の子」

**Prompt:**
```
radiant fantasy hero, golden glowing aura, warm smile, luminous flowing hair,
brilliant sun-motif armor, embodying "Child of Sun", aggressive forward combat
pose, weapon raised, explosive offensive energy burst, sharp defined features,
determined confident expression, high contrast dramatic lighting, solid warm
golden gradient background, warm golden amber sunlit color palette, bright
vivid contrast, digital fantasy TCG card illustration, centered character
portrait, vibrant vivid colors, professional clean artwork, dramatic lighting,
no text no watermark no border
```

### 例2: 怒属性・N カード「炎の精」

属性で差し替わる部分（キャラクター像・背景・パレット）:

**Prompt:**
```
fierce berserker warrior, blazing crimson energy, burning intense eyes,
battle-scarred dark armor with flame runes, embodying "Spirit of Fire",
aggressive forward combat pose, weapon raised, explosive offensive energy
burst, sharp defined features, determined confident expression, high contrast
dramatic lighting, solid deep crimson gradient background, deep crimson dark
orange volcanic color palette, high contrast dramatic, digital fantasy TCG
card illustration, centered character portrait, vibrant vivid colors,
professional clean artwork, dramatic lighting, no text no watermark no border
```

### 例3: 喜属性・UR（最高レア）カード「太陽神」

レアリティが上がると背景が壮大化し、品質強調句が追加される:

**Prompt:**
```
radiant fantasy hero, golden glowing aura, warm smile, luminous flowing hair,
brilliant sun-motif armor, embodying "Sun God", aggressive forward combat
pose, weapon raised, explosive offensive energy burst, sharp defined features,
determined confident expression, high contrast dramatic lighting, celestial
golden sky city, divine floating islands, heavenly aurora, towering radiant
spires, warm golden amber sunlit color palette, bright vivid contrast,
legendary epic masterpiece, extraordinary intricate detail, breathtaking
composition,, digital fantasy TCG card illustration, centered character
portrait, vibrant vivid colors, professional clean artwork, dramatic lighting,
no text no watermark no border
```

> ⚠️ 既知の軽微な不具合: UR品質句の末尾でカンマが二重になる（`breathtaking composition,,`）。
> `functions/src/generateCardImage.ts` から忠実に引き継いだ既存の癖で、Flux生成への実害はないが要修正候補。

## Negative Prompt（全カード共通）

```
text, words, letters, numbers, watermark, signature, card frame, border, UI,
HUD, ugly, blurry, low quality, deformed, mutated, malformed, extra limbs,
bad anatomy, extra fingers, duplicate, oversaturated, washed out
```

## 素材テーブル（抜粋）

### 属性別キャラクター基本形（`ATTR_CHARACTER`）
| 属性 | 内容 |
|---|---|
| joy | radiant fantasy hero, golden glowing aura, warm smile, luminous flowing hair, brilliant sun-motif armor |
| anger | fierce berserker warrior, blazing crimson energy, burning intense eyes, battle-scarred dark armor with flame runes |
| sadness | serene ethereal mage, soft blue-violet glow, gentle melancholic eyes, midnight robes adorned with silver stars |

### レアリティ別背景（`RARITY_BG`、joy属性の例）
| レアリティ | 内容 |
|---|---|
| n | solid warm golden gradient background |
| r | sunlit golden meadow with blooming wildflowers background |
| sr | majestic golden palace, divine light rays through parting clouds, holy atmosphere |
| ur | celestial golden sky city, divine floating islands, heavenly aurora, towering radiant spires |

### タイプ別ポーズ（`TYPE_POSE`）
| タイプ | 内容 |
|---|---|
| attack | aggressive forward combat pose, weapon raised, explosive offensive energy burst |
| defense | firm protective stance, shield raised, radiant barrier aura surrounding body |
| speed | dynamic swift dashing pose, speed trail lines, wind blur motion |
| balance | composed centered stance, balanced power flowing steadily from core |

完全なテーブル（`ATTR_PALETTE` / `RARITY_QUALITY` / anger・sadness属性の背景等）は [generate.js](generate.js) を参照。
