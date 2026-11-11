import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/mavihat_header.dart';
import '../../../../core/widgets/status_pill.dart';

/// Screen 27 (`27._yard_m_ve_sss`): Help & FAQ screen with live search,
/// category filter pills, expandable FAQ accordions, support ticket modal,
/// and links to full Help Article Detail (`28._yard_m_makalesi_detay`).
class HelpAndFaqScreen extends ConsumerStatefulWidget {
  const HelpAndFaqScreen({super.key});

  @override
  ConsumerState<HelpAndFaqScreen> createState() => _HelpAndFaqScreenState();
}

class _HelpAndFaqScreenState extends ConsumerState<HelpAndFaqScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showSupportTicketModal() async {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String? errorText;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'ALO 153 / MaviHat Destek Talebi Oluştur',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Konu Başlığı',
                    controller: subjectCtrl,
                    hintText: 'Örn: Bekleyen Dolum Talimatı',
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Mesajınız',
                    controller: messageCtrl,
                    hintText: 'Sorununuzu detaylı açıklayın...',
                    errorText: errorText,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Destek Talebini Gönder',
                    icon: Icons.send_rounded,
                    onPressed: () async {
                      final res =
                          await ref.read(createSupportTicketUseCaseProvider)(
                        subject: subjectCtrl.text,
                        message: messageCtrl.text,
                      );
                      res.fold(
                        onFailure: (f) =>
                            setModalState(() => errorText = f.message),
                        onSuccess: (ticket) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Destek talebiniz oluşturuldu (Takip No: ${ticket.id}).',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;
    final articles = ref.watch(getFaqsUseCaseProvider).sync(
          category: _selectedCategory,
          query: _searchController.text,
        );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MaviHatHeader(
                title: 'Yardım ve SSS',
                showBackButton: true,
                onBackPressed: () => context.pop(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText:
                            'Bakiye yükleme, aktarma, kayıp kart ara...',
                        filled: true,
                        fillColor: mavi.surfaceContainerLow,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  setState(() => _searchController.clear());
                                },
                                icon: const Icon(Icons.clear_rounded),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Category Filter Pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: <(String, String)>[
                          ('all', 'Tümü'),
                          ('balance', 'Bakiye & Yükleme'),
                          ('turnstile', 'Turnike & Geçiş'),
                          ('lost_card', 'Kayıp / Çalıntı'),
                          ('subscription', 'Abonman & İndirim'),
                        ].map((cat) {
                          final selected = _selectedCategory == cat.$1;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                cat.$2,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: selected
                                      ? Colors.white
                                      : scheme.onSurface,
                                ),
                              ),
                              selected: selected,
                              selectedColor: scheme.primary,
                              backgroundColor: mavi.surfaceContainerLow,
                              onSelected: (_) {
                                setState(() => _selectedCategory = cat.$1);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (articles.isEmpty)
                      AppEmptyView(
                        icon: Icons.search_off_rounded,
                        title: 'Aramanızla eşleşen soru bulunamadı',
                        subtitle:
                            'Farklı bir anahtar kelime deneyin veya tüm kategorileri görüntüleyin.',
                        actionLabel: 'Aramayı Sıfırla',
                        onAction: () {
                          setState(() {
                            _searchController.clear();
                            _selectedCategory = 'all';
                          });
                        },
                      )
                    else
                      for (final art in articles)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: mavi.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            clipBehavior: Clip.antiAlias,
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                14,
                              ),
                              title: Text(
                                art.question,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                art.categoryLabel,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.secondary,
                                ),
                              ),
                              children: <Widget>[
                                Text(
                                  art.shortAnswer,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => context.push(
                                      '${RouteNames.helpArticleDetail}?id=${art.id}',
                                    ),
                                    icon: const Icon(
                                      Icons.menu_book_rounded,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Adım Adım Rehberi Oku →',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    const SizedBox(height: 18),
                    // 153 & Support Ticket Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: AppColors.bosphorusCardGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const StatusPill(
                            label: '7/24 İSTANBUL ULAŞIM DESTEK',
                            tone: StatusPillTone.teal,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Aradığınız cevabı bulamadınız mı?',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'ALO 153 Çözüm Merkezi ile iletişime geçebilir veya uygulama içinden yazılı destek talebi bırakabilirsiniz.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          AppButton(
                            label: 'Yazılı Destek Talebi Oluştur',
                            variant: AppButtonVariant.secondary,
                            icon: Icons.support_agent_rounded,
                            height: 46,
                            onPressed: _showSupportTicketModal,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen 28 (`28._yard_m_makalesi_detay`): Help Article Detail screen with
/// persisted bookmark toggle, step-by-step instructions, and helpfulness
/// feedback (`Evet` / `Hayır`).
class HelpArticleDetailScreen extends ConsumerStatefulWidget {
  const HelpArticleDetailScreen({
    super.key,
    required this.articleId,
  });

  final String articleId;

  @override
  ConsumerState<HelpArticleDetailScreen> createState() =>
      _HelpArticleDetailScreenState();
}

class _HelpArticleDetailScreenState
    extends ConsumerState<HelpArticleDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;
    final article =
        ref.watch(getHelpArticleUseCaseProvider).sync(widget.articleId);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MaviHatHeader(
                title: 'Yardım Makalesi',
                showBackButton: true,
                onBackPressed: () => context.pop(),
                trailing: IconButton(
                  tooltip: article.isBookmarked
                      ? 'Kaydedilenlerden Çıkar'
                      : 'Makaleyi Kaydet',
                  onPressed: () async {
                    await ref.read(toggleArticleBookmarkUseCaseProvider)(
                      article.id,
                    );
                    if (!mounted) return;
                    setState(() {});
                  },
                  icon: Icon(
                    article.isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: scheme.primary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    StatusPill(
                      label: article.categoryLabel,
                      tone: StatusPillTone.teal,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      article.question,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.primary,
                              ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${article.readTimeLabel} • ${article.updatedAtLabel}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      article.shortAnswer,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 20),
                    for (final step in article.steps)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: mavi.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: scheme.primary,
                                child: Text(
                                  '${step.number}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      step.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      step.description,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: mavi.tertiaryFixed,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.info_outline_rounded,
                            color: mavi.onTertiaryFixed,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              article.importantNotice,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: mavi.onTertiaryFixed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Helpfulness Feedback Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: mavi.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: <Widget>[
                          const Text(
                            'Bu makale sorununuzu çözmeye yardımcı oldu mu?',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              ChoiceChip(
                                label: const Text('Evet, Yardımcı Oldu'),
                                selected: article.wasHelpful == true,
                                onSelected: (_) async {
                                  await ref.read(
                                    submitArticleFeedbackUseCaseProvider,
                                  )(
                                    articleId: article.id,
                                    isHelpful: true,
                                  );
                                  if (mounted) setState(() {});
                                },
                              ),
                              const SizedBox(width: 10),
                              ChoiceChip(
                                label: const Text('Hayır'),
                                selected: article.wasHelpful == false,
                                onSelected: (_) async {
                                  await ref.read(
                                    submitArticleFeedbackUseCaseProvider,
                                  )(
                                    articleId: article.id,
                                    isHelpful: false,
                                  );
                                  if (mounted) setState(() {});
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

