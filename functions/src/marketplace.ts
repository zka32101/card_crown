import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

const db = admin.firestore();
const PLATFORM_FEE_PERCENT = 10;
const CARD_LISTING_MIN_PRICE = 10;
const CARD_LISTING_MAX_PRICE = 10000;
const CARD_LISTING_EXPIRY_DAYS = 7;
const TRADE_OFFER_EXPIRY_DAYS = 7;
const TRADE_OFFER_MAX_CARDS_PER_SIDE = 5;

interface CardListing {
  listingId: string;
  sellerId: string;
  sellerName: string;
  cardId: string;
  attribute: string;
  cost: number;
  cardName: Record<string, string>;
  imageUrl: string;
  price: number;
  status: 'active' | 'sold' | 'delisted';
  createdAt: admin.firestore.Timestamp;
  soldAt?: admin.firestore.Timestamp;
  buyerId?: string;
  buyerName?: string;
  expiresAt?: admin.firestore.Timestamp;
  views: number;
}

interface MarketplaceTransaction {
  transactionId: string;
  type: 'card_sale' | 'trade_accepted' | 'currency_exchange';
  playerId: string;
  coinsDelta: number;
  gemsDelta: number;
  transactionFeeCoins: number;
  relatedListingId: string;
  counterpartyId?: string;
  counterpartyName?: string;
  createdAt: admin.firestore.Timestamp;
  isSuccessful: boolean;
  errorMessage?: string;
  metadata: Record<string, any>;
}

// ===== CARD LISTINGS =====

/**
 * Create a card listing
 */
export const createCardListing = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');

  const userId = context.auth.uid;
  const { cardId, price } = data;

  // Validate inputs
  if (!cardId || typeof cardId !== 'string') throw new functions.https.HttpsError('invalid-argument', 'Invalid cardId');
  if (!price || typeof price !== 'number') throw new functions.https.HttpsError('invalid-argument', 'Invalid price');
  if (price < CARD_LISTING_MIN_PRICE || price > CARD_LISTING_MAX_PRICE) {
    throw new functions.https.HttpsError('invalid-argument', `Price must be between ${CARD_LISTING_MIN_PRICE} and ${CARD_LISTING_MAX_PRICE}`);
  }

  return await db.runTransaction(async (transaction) => {
    // Verify user owns the card
    const cardRef = db.collection('users').doc(userId).collection('cards').doc(cardId);
    const cardDoc = await transaction.get(cardRef);
    if (!cardDoc.exists) throw new functions.https.HttpsError('not-found', 'Card not found');

    const cardData = cardDoc.data()!;

    // Check if card is already listed
    const existingListingQuery = await db
      .collection('users')
      .doc(userId)
      .collection('marketplace/card_listings')
      .where('cardId', '==', cardId)
      .where('status', '==', 'active')
      .get();

    if (!existingListingQuery.empty) {
      throw new functions.https.HttpsError('already-exists', 'Card already listed');
    }

    // Create listing ID
    const listingId = db.collection('dummy').doc().id;
    const now = admin.firestore.Timestamp.now();
    const expiresAt = new admin.firestore.Timestamp(now.seconds + CARD_LISTING_EXPIRY_DAYS * 24 * 3600, now.nanoseconds);

    // Get seller name (pseudo handle)
    const userRef = db.collection('users').doc(userId);
    const userDoc = await transaction.get(userRef);
    const sellerName = userDoc.exists && userDoc.data()?.displayName
      ? userDoc.data()?.displayName
      : `Player-${userId.substring(0, 6)}`;

    const listing: CardListing = {
      listingId,
      sellerId: userId,
      sellerName,
      cardId,
      attribute: cardData.attribute || 'joy',
      cost: cardData.cost || 1,
      cardName: cardData.cardName || { jp: '', en: '' },
      imageUrl: cardData.imageUrl || '',
      price,
      status: 'active',
      createdAt: now,
      expiresAt,
      views: 0,
    };

    // Write to user collection
    const userListingRef = db.collection('users').doc(userId).collection('marketplace/card_listings').doc(listingId);
    transaction.set(userListingRef, listing);

    // Write to global active listings collection (for browsing)
    const globalListingRef = db.collection('marketplace/active_card_listings').doc(listingId);
    transaction.set(globalListingRef, listing);

    return { listingId };
  });
});

/**
 * Buy a card from marketplace
 */
export const buyCard = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');

  const buyerId = context.auth.uid;
  const { listingId } = data;

  if (!listingId || typeof listingId !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid listingId');
  }

  return await db.runTransaction(async (transaction) => {
    // Get listing
    const globalListingRef = db.collection('marketplace/active_card_listings').doc(listingId);
    const globalListingDoc = await transaction.get(globalListingRef);

    if (!globalListingDoc.exists) throw new functions.https.HttpsError('not-found', 'Listing not found');

    const listing = globalListingDoc.data() as CardListing;

    // Validate
    if (listing.status !== 'active') throw new functions.https.HttpsError('failed-precondition', 'Listing is not active');
    if (listing.sellerId === buyerId) throw new functions.https.HttpsError('invalid-argument', 'Cannot buy your own card');

    // Check buyer has enough coins
    const buyerWalletRef = db.collection('users').doc(buyerId).collection('wallet').doc('balance');
    const buyerWalletDoc = await transaction.get(buyerWalletRef);
    if (!buyerWalletDoc.exists) throw new functions.https.HttpsError('not-found', 'Buyer wallet not found');

    const buyerWallet = buyerWalletDoc.data()!;
    if ((buyerWallet.coinBalance || 0) < listing.price) {
      throw new functions.https.HttpsError('failed-precondition', 'Insufficient coins');
    }

    // Get card from seller
    const cardRef = db.collection('users').doc(listing.sellerId).collection('cards').doc(listing.cardId);
    const cardDoc = await transaction.get(cardRef);
    if (!cardDoc.exists) throw new functions.https.HttpsError('not-found', 'Card no longer exists');

    // Calculate fee
    const platformFee = Math.floor(listing.price * PLATFORM_FEE_PERCENT / 100);
    const sellerReceives = listing.price - platformFee;

    // Transfer card to buyer (create new copy for provenance)
    const buyerCardRef = db.collection('users').doc(buyerId).collection('cards').doc();
    const cardData = cardDoc.data()!;
    transaction.set(buyerCardRef, { ...cardData, id: buyerCardRef.id });

    // Update wallets
    transaction.update(buyerWalletRef, {
      coinBalance: (buyerWallet.coinBalance || 0) - listing.price,
    });

    const sellerWalletRef = db.collection('users').doc(listing.sellerId).collection('wallet').doc('balance');
    const sellerWalletDoc = await transaction.get(sellerWalletRef);
    if (sellerWalletDoc.exists) {
      const sellerWallet = sellerWalletDoc.data()!;
      transaction.update(sellerWalletRef, {
        coinBalance: (sellerWallet.coinBalance || 0) + sellerReceives,
      });
    }

    // Update listing status
    const now = admin.firestore.Timestamp.now();
    const updatedListing = { ...listing, status: 'sold', soldAt: now, buyerId, buyerName: `Player-${buyerId.substring(0, 6)}` };
    transaction.update(globalListingRef, updatedListing);

    // Update user's listing
    const userListingRef = db.collection('users').doc(listing.sellerId).collection('marketplace/card_listings').doc(listingId);
    transaction.update(userListingRef, updatedListing);

    // Create transaction record for buyer
    const buyerTransactionId = db.collection('dummy').doc().id;
    const buyerTransaction: MarketplaceTransaction = {
      transactionId: buyerTransactionId,
      type: 'card_sale',
      playerId: buyerId,
      coinsDelta: -listing.price,
      gemsDelta: 0,
      transactionFeeCoins: 0,
      relatedListingId: listingId,
      counterpartyId: listing.sellerId,
      counterpartyName: listing.sellerName,
      createdAt: now,
      isSuccessful: true,
      metadata: { cardId: listing.cardId, listingPrice: listing.price },
    };
    transaction.set(db.collection('users').doc(buyerId).collection('marketplace/transactions').doc(buyerTransactionId), buyerTransaction);

    // Create transaction record for seller
    const sellerTransactionId = db.collection('dummy').doc().id;
    const sellerTransaction: MarketplaceTransaction = {
      transactionId: sellerTransactionId,
      type: 'card_sale',
      playerId: listing.sellerId,
      coinsDelta: sellerReceives,
      gemsDelta: 0,
      transactionFeeCoins: platformFee,
      relatedListingId: listingId,
      counterpartyId: buyerId,
      counterpartyName: `Player-${buyerId.substring(0, 6)}`,
      createdAt: now,
      isSuccessful: true,
      metadata: { cardId: listing.cardId, listingPrice: listing.price, platformFee },
    };
    transaction.set(db.collection('users').doc(listing.sellerId).collection('marketplace/transactions').doc(sellerTransactionId), sellerTransaction);

    return { success: true, newCardId: buyerCardRef.id };
  });
});

/**
 * Delist a card from marketplace
 */
export const delistCard = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');

  const userId = context.auth.uid;
  const { listingId } = data;

  return await db.runTransaction(async (transaction) => {
    const userListingRef = db.collection('users').doc(userId).collection('marketplace/card_listings').doc(listingId);
    const userListingDoc = await transaction.get(userListingRef);

    if (!userListingDoc.exists) throw new functions.https.HttpsError('not-found', 'Listing not found');

    const listing = userListingDoc.data() as CardListing;
    if (listing.status !== 'active') throw new functions.https.HttpsError('failed-precondition', 'Only active listings can be delisted');

    // Update both collections
    const updatedListing = { ...listing, status: 'delisted' };
    transaction.update(userListingRef, updatedListing);

    const globalListingRef = db.collection('marketplace/active_card_listings').doc(listingId);
    transaction.update(globalListingRef, updatedListing);

    return { success: true };
  });
});

/**
 * Update price of a card listing
 */
export const updateCardListing = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');

  const userId = context.auth.uid;
  const { listingId, newPrice } = data;

  if (!newPrice || typeof newPrice !== 'number') throw new functions.https.HttpsError('invalid-argument', 'Invalid price');
  if (newPrice < CARD_LISTING_MIN_PRICE || newPrice > CARD_LISTING_MAX_PRICE) {
    throw new functions.https.HttpsError('invalid-argument', `Price must be between ${CARD_LISTING_MIN_PRICE} and ${CARD_LISTING_MAX_PRICE}`);
  }

  return await db.runTransaction(async (transaction) => {
    const userListingRef = db.collection('users').doc(userId).collection('marketplace/card_listings').doc(listingId);
    const userListingDoc = await transaction.get(userListingRef);

    if (!userListingDoc.exists) throw new functions.https.HttpsError('not-found', 'Listing not found');

    const listing = userListingDoc.data() as CardListing;
    if (listing.status !== 'active') throw new functions.https.HttpsError('failed-precondition', 'Only active listings can be updated');

    transaction.update(userListingRef, { price: newPrice });

    const globalListingRef = db.collection('marketplace/active_card_listings').doc(listingId);
    transaction.update(globalListingRef, { price: newPrice });

    return { success: true };
  });
});

// ===== CLEANUP JOBS =====

/**
 * Scheduled job to expire old listings (runs daily)
 */
export const expireListings = functions.pubsub.schedule('every day 02:00').onRun(async (context) => {
  const now = admin.firestore.Timestamp.now();
  const expiryThreshold = new admin.firestore.Timestamp(now.seconds - 24 * 3600, now.nanoseconds);

  // Expire active card listings
  const expiredCardListings = await db
    .collectionGroup('card_listings')
    .where('status', '==', 'active')
    .where('createdAt', '<', expiryThreshold)
    .get();

  for (const doc of expiredCardListings.docs) {
    await db.runTransaction(async (transaction) => {
      transaction.update(doc.ref, { status: 'delisted' });

      const listingData = doc.data() as CardListing;
      const globalRef = db.collection('marketplace/active_card_listings').doc(listingData.listingId);
      transaction.update(globalRef, { status: 'delisted' });
    });
  }

  // Note: Trade offers and currency listings will auto-expire via client-side checks
  // Could add similar cleanup here if desired

  console.log(`Expired ${expiredCardListings.docs.length} card listings`);
  return null;
});
