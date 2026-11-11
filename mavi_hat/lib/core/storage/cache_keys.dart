/// Box and key constants for Hive CE offline cache and persistence.
abstract final class CacheKeys {
  static const String boxName = 'mavihat_cache_v1';

  static const String isSeeded = 'is_seeded_v1';
  static const String currentUser = 'current_user';
  static const String registeredUsers = 'registered_users';
  static const String activeCardId = 'active_card_id';
  static const String transitCards = 'transit_cards';
  static const String paymentMethods = 'payment_methods';
  static const String transactions = 'transactions';
  static const String transactionDisputes = 'transaction_disputes';
  static const String userPreferences = 'user_preferences';
  static const String bookmarkedArticles = 'bookmarked_articles';
  static const String articleFeedback = 'article_feedback';
  static const String supportTickets = 'support_tickets';
  static const String locationReports = 'location_reports';
  static const String announcementDismissed = 'announcement_dismissed';
  static const String isOfflineSimulated = 'is_offline_simulated';
}

