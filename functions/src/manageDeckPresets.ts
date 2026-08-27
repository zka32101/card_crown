import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// デッキプリセット管理（サーバー権威）
// ユーザーのデッキ構成を保存・更新・削除する。
// 複数のプリセットを管理でき、デッキビルダーで素早く切り替え可能。
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const MAX_PRESETS_PER_USER = 10;
const MAX_CARDS_PER_DECK = 30;

interface DeckPresetData {
  name: string;
  description?: string;
  cardIds: string[]; // レンタルカード含む
  createdAt?: admin.firestore.Timestamp;
  updatedAt?: admin.firestore.Timestamp;
}

interface SaveDeckPresetRequest {
  presetName: string;
  description?: string;
  cardIds: string[];
}

interface DeleteDeckPresetRequest {
  presetId: string;
}

// デッキプリセットを保存
export const saveDeckPreset = functions
  .region("asia-northeast1")
  .runWith({timeoutSeconds: 30})
  .https.onCall(async (data: SaveDeckPresetRequest, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "認証が必要です");
    }

    const userId = context.auth.uid;
    const {presetName, description, cardIds} = data;

    // バリデーション
    if (!presetName || !Array.isArray(cardIds)) {
      throw new functions.https.HttpsError("invalid-argument", "リクエストが不正です");
    }

    if (presetName.length > 50) {
      throw new functions.https.HttpsError("invalid-argument", "プリセット名は50文字以内です");
    }

    if (cardIds.length === 0 || cardIds.length > MAX_CARDS_PER_DECK) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `デッキには1〜${MAX_CARDS_PER_DECK}枚のカードが必要です`
      );
    }

    const db = admin.firestore();
    const presetsRef = db.collection("users").doc(userId).collection("deckPresets");
    const now = admin.firestore.Timestamp.now();

    try {
      // 既存プリセット数をチェック
      const existingSnap = await presetsRef.count().get();
      if (existingSnap.data().count >= MAX_PRESETS_PER_USER) {
        throw new functions.https.HttpsError(
          "resource-exhausted",
          `デッキプリセットは最大${MAX_PRESETS_PER_USER}個までです`
        );
      }

      // 新しいプリセットを作成
      const presetId = presetsRef.doc().id;
      const presetData: DeckPresetData = {
        name: presetName,
        description: description || "",
        cardIds,
        createdAt: now,
        updatedAt: now,
      };

      await presetsRef.doc(presetId).set(presetData);

      return {
        success: true,
        presetId,
        preset: presetData,
      };
    } catch (error) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      console.error(`Failed to save deck preset for ${userId}:`, error);
      throw new functions.https.HttpsError("internal", "デッキプリセットの保存に失敗しました");
    }
  });

// デッキプリセットを削除
export const deleteDeckPreset = functions
  .region("asia-northeast1")
  .runWith({timeoutSeconds: 30})
  .https.onCall(async (data: DeleteDeckPresetRequest, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "認証が必要です");
    }

    const userId = context.auth.uid;
    const {presetId} = data;

    if (!presetId) {
      throw new functions.https.HttpsError("invalid-argument", "プリセットIDが必要です");
    }

    const db = admin.firestore();
    const presetRef = db.collection("users").doc(userId).collection("deckPresets").doc(presetId);

    try {
      // 存在確認
      const snap = await presetRef.get();
      if (!snap.exists) {
        throw new functions.https.HttpsError("not-found", "プリセットが見つかりません");
      }

      // 削除
      await presetRef.delete();

      return {success: true};
    } catch (error) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      console.error(`Failed to delete deck preset for ${userId}:`, error);
      throw new functions.https.HttpsError("internal", "プリセットの削除に失敗しました");
    }
  });

// デッキプリセットをコピー
export const copyDeckPreset = functions
  .region("asia-northeast1")
  .runWith({timeoutSeconds: 30})
  .https.onCall(async (data: {sourcePresetId: string; newName: string}, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "認証が必要です");
    }

    const userId = context.auth.uid;
    const {sourcePresetId, newName} = data;

    if (!sourcePresetId || !newName) {
      throw new functions.https.HttpsError("invalid-argument", "リクエストが不正です");
    }

    const db = admin.firestore();
    const sourceRef = db.collection("users").doc(userId).collection("deckPresets").doc(sourcePresetId);
    const presetsRef = db.collection("users").doc(userId).collection("deckPresets");

    try {
      const sourceSnap = await sourceRef.get();
      if (!sourceSnap.exists) {
        throw new functions.https.HttpsError("not-found", "ソースプリセットが見つかりません");
      }

      const sourceData = sourceSnap.data() as DeckPresetData;
      const now = admin.firestore.Timestamp.now();

      const newPresetId = presetsRef.doc().id;
      const newPreset: DeckPresetData = {
        ...sourceData,
        name: newName,
        createdAt: now,
        updatedAt: now,
      };

      await presetsRef.doc(newPresetId).set(newPreset);

      return {
        success: true,
        presetId: newPresetId,
        preset: newPreset,
      };
    } catch (error) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      console.error(`Failed to copy deck preset for ${userId}:`, error);
      throw new functions.https.HttpsError("internal", "プリセットのコピーに失敗しました");
    }
  });
