import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../entities/support_entities.dart';
import '../repositories/support_repository.dart';

class GetFaqs {
  const GetFaqs(this._repository);

  final SupportRepository _repository;

  Future<Result<List<HelpArticle>>> call({
    String category = 'all',
    String query = '',
  }) =>
      _repository.getArticles(category: category, query: query);

  List<HelpArticle> sync({
    String category = 'all',
    String query = '',
  }) =>
      _repository.getArticlesSync(category: category, query: query);
}

class GetHelpArticle {
  const GetHelpArticle(this._repository);

  final SupportRepository _repository;

  Future<Result<HelpArticle>> call(String id) => _repository.getArticleById(id);
  HelpArticle sync(String id) => _repository.getArticleByIdSync(id);
}

class ToggleArticleBookmark {
  const ToggleArticleBookmark(this._repository);

  final SupportRepository _repository;

  Future<Result<HelpArticle>> call(String articleId) =>
      _repository.toggleBookmark(articleId);
}

class SubmitArticleFeedback {
  const SubmitArticleFeedback(this._repository);

  final SupportRepository _repository;

  Future<Result<HelpArticle>> call({
    required String articleId,
    required bool isHelpful,
  }) =>
      _repository.submitFeedback(articleId: articleId, isHelpful: isHelpful);
}

class CreateSupportTicket {
  const CreateSupportTicket(this._repository);

  final SupportRepository _repository;

  Future<Result<SupportTicket>> call({
    required String subject,
    required String message,
  }) async {
    if (subject.trim().length < 3) {
      return const Err(
        ValidationFailure(message: 'Lütfen bir destek konusu girin.'),
      );
    }
    if (message.trim().length < 8) {
      return const Err(
        ValidationFailure(
          message: 'Lütfen talebinizi en az 8 karakter ile açıklayın.',
        ),
      );
    }
    return _repository.createSupportTicket(
      subject: subject.trim(),
      message: message.trim(),
    );
  }
}

