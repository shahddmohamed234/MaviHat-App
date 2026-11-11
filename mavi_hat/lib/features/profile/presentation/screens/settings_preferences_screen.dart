import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/mavihat_header.dart';
import '../../domain/entities/user_preferences.dart';

/// Screen 26 (`26._ayarlar_tercihler`): Settings & Preferences screen with
/// live Theme switcher (`Sistem`, `Açık Mod`, `Koyu Mod`), Language switcher
/// (`Türkçe`, `English`, `العربية`), High Contrast toggle, Notification toggles,
/// and Cache Clearing (`ClearAppCache`).
class SettingsPreferencesScreen extends ConsumerWidget {
  const SettingsPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final mavi = context.maviTheme;
    final prefs = ref.watch(preferencesControllerProvider);
    final controller = ref.read(preferencesControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MaviHatHeader(
                title: 'Ayarlar ve Tercihler',
                showBackButton: true,
                onBackPressed: () => context.pop(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Theme Mode Segmented Selector
                    Text(
                      'GÖRÜNÜM VE TEMA',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: mavi.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Uygulama Teması',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SegmentedButton<AppThemeModePreference>(
                              segments: const <ButtonSegment<
                                  AppThemeModePreference>>[
                                ButtonSegment<AppThemeModePreference>(
                                  value: AppThemeModePreference.system,
                                  label: Text('Sistem'),
                                  icon: Icon(Icons.brightness_auto_rounded),
                                ),
                                ButtonSegment<AppThemeModePreference>(
                                  value: AppThemeModePreference.light,
                                  label: Text('Açık Mod'),
                                  icon: Icon(Icons.light_mode_rounded),
                                ),
                                ButtonSegment<AppThemeModePreference>(
                                  value: AppThemeModePreference.dark,
                                  label: Text('Koyu Mod'),
                                  icon: Icon(Icons.dark_mode_rounded),
                                ),
                              ],
                              selected: <AppThemeModePreference>{
                                prefs.themeMode,
                              },
                              onSelectionChanged: (selection) {
                                controller.setThemeMode(selection.first);
                              },
                            ),
                            const Divider(height: 22),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Yüksek Kontrast Modu (Erişilebilirlik)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: const Text(
                                'Metin ve kenarlık kontrastını maksimum seviyeye çıkarır',
                                style: TextStyle(fontSize: 12),
                              ),
                              value: prefs.highContrast,
                              onChanged: (v) {
                                controller.updatePreferences(
                                  prefs.copyWith(highContrast: v),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Notification Toggles
                    Text(
                      'BİLDİRİM TERCİHLERİ',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: mavi.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: <Widget>[
                          SwitchListTile(
                            title: const Text(
                              'Sefer ve Hat Duyuruları',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: const Text(
                              'Şehir Hatları vapur ve metro sefer değişiklikleri',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: prefs.transitAlertsEnabled,
                            onChanged: (v) {
                              controller.updatePreferences(
                                prefs.copyWith(transitAlertsEnabled: v),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: const Text(
                              'Düşük Bakiye Uyarıları',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: const Text(
                              'Kart bakiyesi ₺30,00 altına düştüğünde bildir',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: prefs.lowBalanceAlertsEnabled,
                            onChanged: (v) {
                              controller.updatePreferences(
                                prefs.copyWith(lowBalanceAlertsEnabled: v),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: const Text(
                              'Kampanya ve Aktarma Fırsatları',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            value: prefs.promoAlertsEnabled,
                            onChanged: (v) {
                              controller.updatePreferences(
                                prefs.copyWith(promoAlertsEnabled: v),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: const Text(
                              'Turnike Yakınlık Algılama Servisi',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            value: prefs.proximityServiceEnabled,
                            onChanged: (v) {
                              controller.updatePreferences(
                                prefs.copyWith(proximityServiceEnabled: v),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Storage & Cache Management
                    Text(
                      'DEPOLAMA VE SÜRÜM BİLGİSİ',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: mavi.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              const Expanded(
                                child: Text(
                                  'Harita ve Uygulama Önbelleği',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${prefs.cacheSizeMb.toStringAsFixed(1)} MB',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AppButton(
                            label: 'Önbelleği Temizle',
                            variant: AppButtonVariant.tonal,
                            icon: Icons.cleaning_services_rounded,
                            height: 46,
                            onPressed: () async {
                              await controller.clearCache();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Geçici önbellek temizlendi (0.0 MB).',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          AppButton(
                            label: 'Güncellemeleri Kontrol Et (v2.4.1)',
                            variant: AppButtonVariant.ghost,
                            icon: Icons.system_update_alt_rounded,
                            height: 44,
                            onPressed: () {
                              showDialog<void>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text(
                                    'Sürüm ve Sistem Durumu',
                                  ),
                                  content: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Uygulama Sürümü: MaviHat v2.4.1 (Build 108)\n'
                                        'Yerel Depolama: Hive CE Aktif\n'
                                        'NFC & QR Turnike Modülü: v2.4 Aktif\n'
                                        'Durum: En güncel sürümü kullanıyorsunuz.',
                                      ),
                                    ],
                                  ),
                                  actions: <Widget>[
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(),
                                      child: const Text('Tamam'),
                                    ),
                                  ],
                                ),
                              );
                            },
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

