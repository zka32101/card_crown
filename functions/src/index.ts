import * as admin from "firebase-admin";

admin.initializeApp();

export {generateCardImage} from "./generateCardImage";
export {generateCardName} from "./generateCardName";
export {pvpMatch} from "./pvpMatch";
export {pvpBattle} from "./pvpBattle";
export {rentCard} from "./rentCard";
export {
  generateDailyEmotionCardName,
  generateDailyEmotionCardImage,
  onDailyEmotionCardCreated,
} from "./dailyEmotionCard";
export {
  sendFriendRequest,
  acceptFriendRequest,
  rejectFriendRequest,
  removeFriend,
  updateFriendMetadata,
  updateFriendCachedData,
} from "./manageFriends";
export {
  createDeckPreset,
  updateDeckPreset,
  deleteDeckPreset,
  activateDeckPreset,
} from "./manageDeckPresets";
export {
  createEventChallenge,
  claimEventChallengeReward,
  recordEventChallengeProgress,
} from "./manageEventChallenges";
export {
  createCardListing,
  buyCard,
  delistCard,
  updateCardListing,
  expireListings,
  createTradeOffer,
  respondToTradeOffer,
  cancelTradeOffer,
  fillCurrencyListing,
} from "./marketplace";
