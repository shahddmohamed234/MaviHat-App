/// FAQ accordion item and full Help Article entity (`27._yard_m_ve_sss` &
/// `28._yard_m_makalesi_detay`).
class HelpArticle {
  const HelpArticle({
    required this.id,
    required this.category,
    required this.categoryLabel,
    required this.question,
    required this.shortAnswer,
    required this.readTimeLabel,
    required this.updatedAtLabel,
    required this.steps,
    required this.importantNotice,
    required this.relatedArticleIds,
    this.isBookmarked = false,
    this.wasHelpful,
  });

  final String id;
  final String category; // 'balance', 'turnstile', 'lost_card', 'subscription'
  final String categoryLabel;
  final String question;
  final String shortAnswer;
  final String readTimeLabel;
  final String updatedAtLabel;
  final List<HelpArticleStep> steps;
  final String importantNotice;
  final List<String> relatedArticleIds;
  final bool isBookmarked;
  final bool? wasHelpful;

  HelpArticle copyWith({
    bool? isBookmarked,
    bool? wasHelpful,
  }) {
    return HelpArticle(
      id: id,
      category: category,
      categoryLabel: categoryLabel,
      question: question,
      shortAnswer: shortAnswer,
      readTimeLabel: readTimeLabel,
      updatedAtLabel: updatedAtLabel,
      steps: steps,
      importantNotice: importantNotice,
      relatedArticleIds: relatedArticleIds,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      wasHelpful: wasHelpful ?? this.wasHelpful,
    );
  }
}

class HelpArticleStep {
  const HelpArticleStep({
    required this.number,
    required this.title,
    required this.description,
  });

  final int number;
  final String title;
  final String description;
}

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.subject,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String subject;
  final String message;
  final DateTime createdAt;
}

