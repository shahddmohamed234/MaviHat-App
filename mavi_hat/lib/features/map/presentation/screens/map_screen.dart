import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/map_entities.dart';

/// Screen 21 (`21._harita_son_i_lem_noktas`): Interactive Map tab displaying
/// the card's Last Transaction Station (`Son İşlem Noktası`) on OpenStreetMap
/// tiles with attribution, category filters, search, phone location toggle,
/// and location discrepancy reporting.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  StopCategory _selectedCategory = StopCategory.lastTransaction;
  DeviceLocationState? _deviceLocation;
  TransitStop? _selectedStop;
  double _currentZoom = 14.5;

  static IconData _iconForLastLocation(LastTransactionLocation loc) {
    final text = '${loc.stationName} ${loc.lineDescription}'.toLowerCase();
    if (loc.category == 'tram' ||
        text.contains('tramvay') ||
        text.contains('tünel') ||
        text.contains('t1') ||
        text.contains('f2')) {
      return Icons.tram_rounded;
    }
    if (loc.category == 'bus' ||
        text.contains('iett') ||
        text.contains('otobüs') ||
        text.contains('metrobüs')) {
      return Icons.directions_bus_filled_rounded;
    }
    if (loc.category == 'metro' ||
        text.contains('metro') ||
        text.contains('marmaray')) {
      return Icons.subway_rounded;
    }
    if (loc.category == 'ferry' ||
        text.contains('iskele') ||
        text.contains('vapur') ||
        text.contains('deniz')) {
      return Icons.directions_boat_filled_rounded;
    }
    return Icons.directions_transit_filled_rounded;
  }

  static IconData _iconForStopCategory(StopCategory category) {
    return switch (category) {
      StopCategory.ferry => Icons.directions_boat_filled_rounded,
      StopCategory.tram => Icons.tram_rounded,
      StopCategory.metro => Icons.subway_rounded,
      StopCategory.lastTransaction => Icons.place_rounded,
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _moveMap(double lat, double lng, {double? zoom}) {
    final targetZoom = zoom ?? _currentZoom;
    setState(() => _currentZoom = targetZoom);
    try {
      _mapController.move(LatLng(lat, lng), targetZoom);
    } catch (_) {
      // Safe fallback before FlutterMap first frame
    }
  }

  Future<void> _fetchPhoneLocation() async {
    final res = await ref.read(getDeviceLocationUseCaseProvider)();
    if (!mounted) return;
    res.fold(
      onFailure: (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message)),
        );
      },
      onSuccess: (loc) {
        setState(() {
          _deviceLocation = loc;
          _selectedStop = null;
        });
        _moveMap(loc.latitude, loc.longitude, zoom: 15.2);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.label)),
        );
      },
    );
  }

  Future<void> _showReportDiscrepancyModal(
    LastTransactionLocation lastLoc,
  ) async {
    final noteCtrl = TextEditingController();
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
                    'Konum Tutarsızlığı Bildir (${lastLoc.stationName})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Son işlem noktasındaki turnike koordinatlarında bir hata olduğunu düşünüyorsanız aşağıdan bildirebilirsiniz.',
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Açıklamanız',
                    controller: noteCtrl,
                    hintText: 'Örn: Turnike çıkışı farklı iskelede görünüyor...',
                    errorText: errorText,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Bildirimi Gönder',
                    icon: Icons.send_rounded,
                    onPressed: () async {
                      final res = await ref
                          .read(reportLocationDiscrepancyUseCaseProvider)(
                        transactionId: lastLoc.transactionId,
                        note: noteCtrl.text,
                      );
                      res.fold(
                        onFailure: (f) =>
                            setModalState(() => errorText = f.message),
                        onSuccess: (_) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Konum tutarsızlık bildiriminiz kaydedildi. Teşekkür ederiz.',
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
    final activeCard = ref.watch(transitCardControllerProvider);
    final lastLoc = ref
        .watch(getLastTransactionLocationUseCaseProvider)
        .sync(activeCard.id);
    final stops = ref.watch(getNearbyTransitStopsUseCaseProvider).sync(
          category: _selectedCategory,
          query: _searchController.text,
        );
    final enableNetworkTiles = ref.watch(enableNetworkMapTilesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Top Search & Category Filter Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText:
                                'İskele, metro istasyonu veya hat ara...',
                            filled: true,
                            fillColor: mavi.surfaceContainerLow,
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      setState(() => _searchController.clear());
                                    },
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      size: 18,
                                    ),
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Telefon Konumumu Göster',
                        onPressed: _fetchPhoneLocation,
                        icon: const Icon(Icons.my_location_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: <(StopCategory, String, IconData)>[
                        (
                          StopCategory.lastTransaction,
                          'Son İşlem Noktası',
                          Icons.history_rounded,
                        ),
                        (
                          StopCategory.ferry,
                          'Vapur İskeleleri',
                          Icons.directions_boat_rounded,
                        ),
                        (
                          StopCategory.tram,
                          'Tramvay & Tünel',
                          Icons.tram_rounded,
                        ),
                        (
                          StopCategory.metro,
                          'Metro Hatları',
                          Icons.subway_rounded,
                        ),
                      ].map((chip) {
                        final selected = _selectedCategory == chip.$1;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: Icon(
                              chip.$3,
                              size: 16,
                              color: selected ? Colors.white : scheme.primary,
                            ),
                            label: Text(
                              chip.$2,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color:
                                    selected ? Colors.white : scheme.onSurface,
                              ),
                            ),
                            selected: selected,
                            selectedColor: scheme.primary,
                            backgroundColor: mavi.surfaceContainerLow,
                            onSelected: (_) {
                              setState(() {
                                _selectedCategory = chip.$1;
                                _selectedStop = null;
                              });
                              if (chip.$1 == StopCategory.lastTransaction) {
                                _moveMap(lastLoc.latitude, lastLoc.longitude);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            // Map Canvas + Floating Controls
            Expanded(
              child: Stack(
                children: <Widget>[
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(
                        lastLoc.latitude,
                        lastLoc.longitude,
                      ),
                      initialZoom: _currentZoom,
                    ),
                    children: <Widget>[
                      if (enableNetworkTiles)
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'tr.istanbul.mavihat.app',
                        ),
                      MarkerLayer(
                        markers: <Marker>[
                          // Primary Marker: Last Transaction Station
                          Marker(
                            point: LatLng(lastLoc.latitude, lastLoc.longitude),
                            width: 140,
                            height: 68,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedStop = null);
                                _moveMap(lastLoc.latitude, lastLoc.longitude);
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'SON İŞLEM',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: Icon(
                                      _iconForLastLocation(lastLoc),
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Transit Stop Markers
                          for (final stop in stops)
                            Marker(
                              point: LatLng(stop.latitude, stop.longitude),
                              width: 40,
                              height: 40,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedStop = stop);
                                  _moveMap(stop.latitude, stop.longitude);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _selectedStop?.id == stop.id
                                        ? AppColors.tertiaryContainer
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    _iconForStopCategory(stop.category),
                                    size: 20,
                                    color: _selectedStop?.id == stop.id
                                        ? Colors.white
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          // Optional Device GPS Location Marker
                          if (_deviceLocation != null)
                            Marker(
                              point: LatLng(
                                _deviceLocation!.latitude,
                                _deviceLocation!.longitude,
                              ),
                              width: 42,
                              height: 42,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent
                                      .withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.person_pin_circle_rounded,
                                    color: Colors.blueAccent,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  // OpenStreetMap Mandatory Attribution Pill
                  Positioned(
                    left: 12,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: mavi.surfaceContainerLowest
                            .withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '© OpenStreetMap contributors • Turnike Kaydı (Canlı GPS Değildir)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  // Zoom & Recenter Floating Controls
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Column(
                      children: <Widget>[
                        FloatingActionButton.small(
                          heroTag: 'map_zoom_in',
                          tooltip: 'Yakınlaştır',
                          backgroundColor: mavi.surfaceContainerLowest,
                          foregroundColor: scheme.primary,
                          onPressed: () => _moveMap(
                            lastLoc.latitude,
                            lastLoc.longitude,
                            zoom: (_currentZoom + 1).clamp(10.0, 18.0),
                          ),
                          child: const Icon(Icons.add_rounded),
                        ),
                        const SizedBox(height: 6),
                        FloatingActionButton.small(
                          heroTag: 'map_zoom_out',
                          tooltip: 'Uzaklaştır',
                          backgroundColor: mavi.surfaceContainerLowest,
                          foregroundColor: scheme.primary,
                          onPressed: () => _moveMap(
                            lastLoc.latitude,
                            lastLoc.longitude,
                            zoom: (_currentZoom - 1).clamp(10.0, 18.0),
                          ),
                          child: const Icon(Icons.remove_rounded),
                        ),
                        const SizedBox(height: 6),
                        FloatingActionButton.small(
                          heroTag: 'map_recenter_last',
                          tooltip: 'Son İşlem Noktasına Odakla',
                          backgroundColor: scheme.primary,
                          foregroundColor: Colors.white,
                          onPressed: () {
                            setState(() => _selectedStop = null);
                            _moveMap(
                              lastLoc.latitude,
                              lastLoc.longitude,
                              zoom: 15.0,
                            );
                          },
                          child: const Icon(Icons.center_focus_strong_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Sheet Card: Last Transaction Station Metadata & Actions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                AppSpacing.bottomNavClearance,
              ),
              decoration: BoxDecoration(
                color: mavi.surfaceContainerLowest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: _selectedStop != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Flexible(
                              child: StatusPill(
                                label: _selectedStop!.hasTopUpKiosk
                                    ? 'BİLETMATİK DOLUM NOKTASI VAR'
                                    : 'ULAŞIM DURAĞI',
                                tone: StatusPillTone.teal,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _selectedStop = null),
                              child: const Text('Son İşleme Dön'),
                            ),
                          ],
                        ),
                        Text(
                          _selectedStop!.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_selectedStop!.lineSummary} • ${_selectedStop!.distanceMeters}m mesafede',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Flexible(
                              child: StatusPill(
                                label:
                                    'SON İŞLEM NOKTASI • ${lastLoc.timestampLabel}',
                                tone: StatusPillTone.teal,
                                showDot: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              CurrencyFormatter.formatTl(
                                lastLoc.amountDeducted,
                                showSign: true,
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: mavi.secondaryFixed,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _iconForLastLocation(lastLoc),
                                color: mavi.onSecondaryFixed,
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                lastLoc.stationName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: scheme.primary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${lastLoc.lineDescription} • Cihaz: ${lastLoc.validatorCode}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: AppButton(
                                label: 'İşlem Makbuzunu Gör',
                                icon: Icons.receipt_long_rounded,
                                height: 44,
                                onPressed: () => context.push(
                                  '${RouteNames.transactionDetail}?id=${lastLoc.transactionId}',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AppButton(
                                label: 'Tutarsızlık Bildir',
                                variant: AppButtonVariant.tonal,
                                icon: Icons.flag_outlined,
                                height: 44,
                                onPressed: () =>
                                    _showReportDiscrepancyModal(lastLoc),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

