import '../../../../core/utils/result.dart';
import '../entities/support_entities.dart';

/// Abstract repository for FAQs, help articles, bookmarks, and support tickets.
abstract interface class SupportRepository {
  List<HelpArticle> getArticlesSync({
    String category = 'all',
    String query = '',
  });

  HelpArticle getArticleByIdSync(String id);

  Future<Result<List<HelpArticle>>> getArticles({
    String category = 'all',
    String query = '',
  });

  Future<Result<HelpArticle>> getArticleById(String id);

  Future<Result<HelpArticle>> toggleBookmark(String articleId);

  Future<Result<HelpArticle>> submitFeedback({
    required String articleId,
    required bool isHelpful,
  });

  Future<Result<SupportTicket>> createSupportTicket({
    required String subject,
    required String message,
  });
}

