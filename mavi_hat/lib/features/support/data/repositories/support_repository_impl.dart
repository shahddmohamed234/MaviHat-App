import '../../../../core/storage/cache_keys.dart';
import '../../../../core/storage/local_cache_datasource.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/support_entities.dart';
import '../../domain/repositories/support_repository.dart';

/// Persistent Hive CE-backed implementation of [SupportRepository].
class SupportRepositoryImpl implements SupportRepository {
  SupportRepositoryImpl(this._cache);

  final LocalCacheDataSource _cache;

  static const List<HelpArticle> _seedArticles = <HelpArticle>[
    HelpArticle(
      id: 'art_pending_topup',
      category: 'balance',
      categoryLabel: 'BAKİYE VE DOLUM REHBERİ',
      question: 'Yüklediğim bakiye kartıma neden hemen yansımadı?',
      shortAnswer:
          'Mobil uygulama üzerinden yapılan yüklemeler hesabınıza anında tanımlanır. Fiziksel kart kullanıyorsanız ilk turnike geçişinde veya NFC/Biletmatik dokunuşunda bakiye karta yazılır.',
      readTimeLabel: '2 dk okuma',
      updatedAtLabel: 'Son güncelleme: 24 Ekim 2026',
      steps: <HelpArticleStep>[
        HelpArticleStep(
          number: 1,
          title: 'Turnike veya Biletmatik Aktivasyonu',
          description:
              'Fiziksel MaviHat kartınızı herhangi bir metro, vapur, metrobüs turnikesine veya Biletmatik cihazına 2 saniye yaklaştırarak bekleyen talimatı aktif edin.',
        ),
        HelpArticleStep(
          number: 2,
          title: 'İşlem Geçmişi ve Referans Kontrolü',
          description:
              'Hareketlerim ekranından yükleme işleminizin TXN referans kodunu ve "Tamamlandı" durumunu doğrulayın.',
        ),
        HelpArticleStep(
          number: 3,
          title: 'Banka Provizyon Süresi',
          description:
              '3D Secure doğrulaması tamamlanmayan işlemlerde kartınızdan tutar çekilmez. Kesinti olduysa 24 saat içinde otomatik iade edilir.',
        ),
      ],
      importantNotice:
          'Bekleyen dolum talimatları 30 gün içinde herhangi bir turnike veya Biletmatik noktasında karta aktarılmazsa banka kartınıza otomatik olarak iade edilir.',
      relatedArticleIds: <String>[
        'art_card_lock',
        'art_transfer_discount',
        'art_subscription_rules',
      ],
    ),
    HelpArticle(
      id: 'art_card_lock',
      category: 'lost_card',
      categoryLabel: 'KAYIP / ÇALINTI VE GÜVENLİK',
      question: 'Kartımı kaybettim veya çaldırdım, bakiyemi nasıl korurum?',
      shortAnswer:
          'Kartım sekmesindeki "Kartı Kilitle" butonu ile kartınızı saniyeler içinde kullanıma kapatabilir ve dilerseniz ALO 153 kayıp bildirimi oluşturabilirsiniz.',
      readTimeLabel: '3 dk okuma',
      updatedAtLabel: 'Son güncelleme: 20 Ekim 2026',
      steps: <HelpArticleStep>[
        HelpArticleStep(
          number: 1,
          title: 'Kartım Ekranından Anında Kilitleyin',
          description:
              'Kartım > Kartı Kilitle adımlarını izleyerek kartınızı geçici veya kalıcı olarak turnike geçişlerine kapatın.',
        ),
        HelpArticleStep(
          number: 2,
          title: 'Mevcut Bakiyeniz Güvence Altına Alınır',
          description:
              'Kişiselleştirilmiş MaviHat kartınızdaki TL bakiyesi ve kalan abonman haklarınız dijital cüzdanınızda korunur.',
        ),
        HelpArticleStep(
          number: 3,
          title: 'SMS Doğrulaması ile Kilidi Kaldırın',
          description:
              'Kartınızı tekrar bulduğunuzda kayıtlı telefonunuza gönderilen 6 haneli SMS kodu ile kilidi anında açabilirsiniz.',
        ),
      ],
      importantNotice:
          'Bu prototip sürümde kart kilitleme işlemi uygulama içi yerel/bulut durumunu günceller; gerçek fiziksel turnike kara liste senkronizasyonu operatör entegrasyonu gerektirir.',
      relatedArticleIds: <String>[
        'art_pending_topup',
        'art_nfc_usage',
      ],
    ),
    HelpArticle(
      id: 'art_nfc_usage',
      category: 'turnstile',
      categoryLabel: 'TURNİKE & TEMASSIZ GEÇİŞ',
      question: 'Telefonumun NFC özelliği ile turnikeden nasıl geçebilirim?',
      shortAnswer:
          'Turnikelerde mobil NFC (HCE / Secure Element) ile doğrudan geçiş, resmi ulaşım operatörü donanım sertifikasyonu gerektirmektedir.',
      readTimeLabel: '2 dk okuma',
      updatedAtLabel: 'Son güncelleme: 18 Ekim 2026',
      steps: <HelpArticleStep>[
        HelpArticleStep(
          number: 1,
          title: 'Operatör Yetkilendirme Gereksinimi',
          description:
              'Fiziksel turnike okuyucuları yalnızca kriptografik olarak imzalanmış DESFire / HCE kimlik bilgilerini kabul eder.',
        ),
        HelpArticleStep(
          number: 2,
          title: 'Prototip Bilgilendirme Ekranı',
          description:
              'Kartım > Temassız Kullan ekranından cihaz uygunluk gereksinimlerini ve çalışma prensibini inceleyebilirsiniz.',
        ),
      ],
      importantNotice:
          'MaviHat prototip sürümü hiçbir zaman sahte NFC turnike geçişi üretmez; özelliği şeffaf biçimde bilgilendirme modunda sunar.',
      relatedArticleIds: <String>[
        'art_pending_topup',
        'art_transfer_discount',
      ],
    ),
    HelpArticle(
      id: 'art_transfer_discount',
      category: 'turnstile',
      categoryLabel: 'TURNİKE & AKTARMA TARİFESİ',
      question: 'Vapur, Metro ve İETT aktarma indirimleri nasıl uygulanır?',
      shortAnswer:
          'İlk binişinizden itibaren 120 dakika içinde farklı bir ulaşım hattına yaptığınız geçişlerde kademeli aktarma indirimi otomatik olarak uygulanır.',
      readTimeLabel: '2 dk okuma',
      updatedAtLabel: 'Son güncelleme: 15 Ekim 2026',
      steps: <HelpArticleStep>[
        HelpArticleStep(
          number: 1,
          title: '120 Dakika Kuralı',
          description:
              'İlk validasyondan sonraki 2 saat içinde farklı hatlara yapılan binişler aktarma kapsamında değerlendirilir.',
        ),
        HelpArticleStep(
          number: 2,
          title: 'Aynı İstasyon İkinci Geçiş',
          description:
              'Aynı kartın arka arkaya ikinci kez basılması durumunda ikinci biniş tam tarife üzerinden ücretlendirilir.',
        ),
      ],
      importantNotice:
          'Aylık MaviHat abonman paketi kullanımlarında ilk geçişte 1 kontör, aktarmalarda indirimli kontör düşümü yapılır.',
      relatedArticleIds: <String>[
        'art_subscription_rules',
        'art_pending_topup',
      ],
    ),
    HelpArticle(
      id: 'art_subscription_rules',
      category: 'subscription',
      categoryLabel: 'ABONMAN & İNDİRİMLİ KARTLAR',
      question: 'Aylık MaviHat abonman paketi (200 Geçiş) ne zaman yenilenir?',
      shortAnswer:
          'Aylık abonman paketiniz tanımlandığı tarihten itibaren 30 gün boyunca geçerlidir ve kalan geçiş hakkınızı Kartım ekranından anlık takip edebilirsiniz.',
      readTimeLabel: '2 dk okuma',
      updatedAtLabel: 'Son güncelleme: 12 Ekim 2026',
      steps: <HelpArticleStep>[
        HelpArticleStep(
          number: 1,
          title: 'Kalan Hak Takibi',
          description:
              'Kartım sekmesindeki Aylık Abonman Durumu kartından kullanılan ve kalan geçiş sayısını görebilirsiniz.',
        ),
        HelpArticleStep(
          number: 2,
          title: 'Öğrenci ve İndirimli Kart Vizesi',
          description:
              'Dijital Öğrenci kartları YÖK / MEB eğitim durumu sorgulaması ile yılda bir kez ücretsiz vize edilir.',
        ),
      ],
      importantNotice:
          '30 günlük abonman süresi sonunda kullanılmayan geçiş hakları bir sonraki aya devretmez.',
      relatedArticleIds: <String>[
        'art_transfer_discount',
        'art_pending_topup',
      ],
    ),
  ];

  Set<String> _readBookmarkIds() {
    final raw = _cache.readList(CacheKeys.bookmarkedArticles);
    return raw
        .map((m) => m['id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Map<String, bool> _readFeedbackMap() {
    final map = _cache.readMap(CacheKeys.articleFeedback);
    if (map == null) return <String, bool>{};
    return map.map((key, value) => MapEntry(key, value == true));
  }

  List<HelpArticle> _hydratedArticles() {
    final bookmarks = _readBookmarkIds();
    final feedback = _readFeedbackMap();
    return _seedArticles.map((art) {
      return art.copyWith(
        isBookmarked: bookmarks.contains(art.id),
        wasHelpful: feedback[art.id],
      );
    }).toList();
  }

  @override
  List<HelpArticle> getArticlesSync({
    String category = 'all',
    String query = '',
  }) {
    var list = _hydratedArticles();
    if (category != 'all' && category.isNotEmpty) {
      list = list.where((a) => a.category == category).toList();
    }
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isNotEmpty) {
      list = list
          .where(
            (a) =>
                a.question.toLowerCase().contains(cleanQuery) ||
                a.shortAnswer.toLowerCase().contains(cleanQuery) ||
                a.categoryLabel.toLowerCase().contains(cleanQuery),
          )
          .toList();
    }
    return list;
  }

  @override
  HelpArticle getArticleByIdSync(String id) {
    final all = _hydratedArticles();
    for (final art in all) {
      if (art.id == id) return art;
    }
    return all.first;
  }

  @override
  Future<Result<List<HelpArticle>>> getArticles({
    String category = 'all',
    String query = '',
  }) async {
    return Success(getArticlesSync(category: category, query: query));
  }

  @override
  Future<Result<HelpArticle>> getArticleById(String id) async {
    return Success(getArticleByIdSync(id));
  }

  @override
  Future<Result<HelpArticle>> toggleBookmark(String articleId) async {
    final bookmarks = _readBookmarkIds();
    if (bookmarks.contains(articleId)) {
      bookmarks.remove(articleId);
    } else {
      bookmarks.add(articleId);
    }
    await _cache.writeList(
      CacheKeys.bookmarkedArticles,
      bookmarks.map((id) => <String, dynamic>{'id': id}).toList(),
    );
    return Success(getArticleByIdSync(articleId));
  }

  @override
  Future<Result<HelpArticle>> submitFeedback({
    required String articleId,
    required bool isHelpful,
  }) async {
    final feedback = _readFeedbackMap();
    feedback[articleId] = isHelpful;
    await _cache.writeMap(
      CacheKeys.articleFeedback,
      feedback.map((key, value) => MapEntry(key, value)),
    );
    return Success(getArticleByIdSync(articleId));
  }

  @override
  Future<Result<SupportTicket>> createSupportTicket({
    required String subject,
    required String message,
  }) async {
    final now = DateTime.now();
    final ticket = SupportTicket(
      id: 'TCK-${now.millisecondsSinceEpoch % 90000 + 10000}',
      subject: subject,
      message: message,
      createdAt: now,
    );
    final existing = _cache.readList(CacheKeys.supportTickets);
    await _cache.writeList(
      CacheKeys.supportTickets,
      <Map<String, dynamic>>[
        ...existing,
        <String, dynamic>{
          'id': ticket.id,
          'subject': ticket.subject,
          'message': ticket.message,
          'createdAt': ticket.createdAt.toIso8601String(),
        },
      ],
    );
    return Success(ticket);
  }
}

