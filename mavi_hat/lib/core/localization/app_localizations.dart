import 'package:flutter/material.dart';

/// Turkish (`tr`) localization provider for MaviHat.
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const List<Locale> supportedLocales = <Locale>[
    Locale('tr'),
  ];

  static AppLocalizations of(BuildContext context) {
    return const AppLocalizations(Locale('tr'));
  }

  // Bottom Navigation labels
  String get navHome => 'Ana Sayfa';
  String get navCard => 'Kartım';
  String get navTopUp => 'Yükle';
  String get navMap => 'Harita';
  String get navProfile => 'Profil';

  // Common labels
  String get brandSubtitle => 'İSTANBUL ULAŞIM';
  String get prototypeBadge => 'PROTOTİP SÜRÜM';
  String get greetingPrefix => 'Merhaba';
  String get topUpAction => 'Bakiye Yükle';
  String get recentTransactions => 'Son İşlemler';
  String get seeAll => 'Tümünü Gör';
  String get quickTopUp => 'Hızlı Bakiye Yükle';
  String get settingsAndPrefs => 'Ayarlar ve Tercihler';
  String get personalInfoAndSecurity => 'Kişisel Bilgiler & Güvenlik';
  String get helpAndFaq => 'Yardım ve SSS';
  String get signOut => 'Çıkış Yap';
  String get deleteAccount => 'Hesabı Kapat / Kalıcı Olarak Sil';
}
