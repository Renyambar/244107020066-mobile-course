import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/failures.dart';
import '../../core/format.dart';
import '../../routes.dart';
import '../../features/announcements/presentation/providers/announcements_providers.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/notifications/domain/entities/push_message.dart';
import '../../features/notifications/presentation/providers/notifications_providers.dart';

/// Beranda lintas-fitur: status push, simulator, uji keamanan sesi, dan daftar
/// pengumuman.
///
/// Halaman ini bersih dari akses data mentah — tidak ada pemanggilan jaringan,
/// akses penyimpanan aman, parsing JSON, maupun format tanggal. Semua data &
/// logika datang dari provider tiap fitur; lihat hasil tiga grep sterilitas
/// pada README.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  StreamSubscription<PushMessage>? _messageSub;
  StreamSubscription<PushMessage>? _openedSub;
  PushMessage? _banner;
  bool _busy = false;

  /// Referensi router diambil sekali saat dependensi tersedia, agar navigasi
  /// hasil pesan terminated tidak memakai BuildContext setelah await.
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router ??= GoRouter.of(context);
  }

  @override
  void initState() {
    super.initState();
    final gateway = ref.read(pushGatewayProvider);

    // Foreground: sistem TIDAK menampilkan banner otomatis, jadi tampilkan
    // manual (in-app banner). Pesan hanya-data tidak menampilkan banner.
    _messageSub = gateway.onMessage.listen((message) {
      ref.read(pushProvider.notifier).logForeground(message);
      if (hasNotificationPayload(
        title: message.title,
        body: message.body,
      )) {
        _showBanner(message);
      }
    });

    // Background: banner diklik.
    _openedSub = gateway.onMessageOpenedApp.listen((message) {
      final route = routeFromMessage(message.data);
      ref.read(pushProvider.notifier).logOpenedFromBackground(route);
      _router?.go(route);
    });

    // Terminated: aplikasi dibuka langsung dari notifikasi saat startup.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initial = await gateway.getInitialMessage();
      if (initial == null) return;
      final route = routeFromMessage(initial.data);
      ref.read(pushProvider.notifier).logTerminated(route);
      _router?.go(route);
    });
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _openedSub?.cancel();
    super.dispose();
  }

  void _showBanner(PushMessage message) {
    setState(() => _banner = message);
    Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _banner = null);
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Simulasikan aplikasi dibuka dari notifikasi kondisi terminated.
  Future<void> _terminate(PushMessage message) async {
    final simulator = ref.read(pushSimulatorProvider);
    final gateway = ref.read(pushGatewayProvider);
    simulator?.launchFromTerminated(message);
    final initial = await gateway.getInitialMessage();
    if (initial == null || !mounted) return;
    final route = routeFromMessage(initial.data);
    ref.read(pushProvider.notifier).logTerminated(route);
    _router?.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final push = ref.watch(pushProvider);
    final simulator = ref.watch(pushSimulatorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatusCard(context, push),
              const SizedBox(height: 12),
              _buildTopicCard(context, push),
              if (simulator != null) ...[
                const SizedBox(height: 12),
                _buildSimulatorCard(context, simulator),
              ],
              const SizedBox(height: 12),
              _buildSecurityCard(context),
              const SizedBox(height: 12),
              _buildAnnouncementCard(context),
              if (push.events.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildLogCard(context, push),
              ],
              const SizedBox(height: 24),
            ],
          ),
          if (_banner != null)
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: _InAppBanner(
                message: _banner!,
                onTap: () {
                  final route = routeFromMessage(_banner!.data);
                  setState(() => _banner = null);
                  context.go(route);
                },
              ),
            ),
          if (_busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  // --- kartu ----------------------------------------------------------------

  Widget _buildStatusCard(BuildContext context, PushState push) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_done_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Text('Status Push',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    push.isRealFcm ? 'FCM asli' : 'Simulasi',
                    style: TextStyle(
                      fontSize: 11,
                      color: push.isRealFcm ? scheme.primary : scheme.tertiary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            _kv('Izin notifikasi', push.permission.name),
            _kv('Token FCM', push.token ?? 'belum diambil'),
            _kv('Terdaftar di backend', push.registered ? 'ya' : 'belum'),
            _kv('Log POST /devices', push.lastDeviceLog),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(BuildContext context, PushState push) {
    return Card(
      child: SwitchListTile(
        title: const Text('Topik pengumuman-kampus'),
        subtitle: Text(
          push.subscribed
              ? 'Berlangganan broadcast kampus'
              : 'Tidak berlangganan',
        ),
        value: push.subscribed,
        onChanged: (value) => _run(() async {
          final notifier = ref.read(pushProvider.notifier);
          if (value) {
            await notifier.subscribeTopic('pengumuman-kampus');
          } else {
            await notifier.unsubscribeTopic('pengumuman-kampus');
          }
        }),
      ),
    );
  }

  Widget _buildSimulatorCard(BuildContext context, PushSimulator simulator) {
    void send(PushMessage message) => simulator.emitForeground(message);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Simulator Push (mode demo)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Meniru perilaku FCM agar alur token lifecycle & tiga app state '
              'bisa didemonstrasikan tanpa proyek Firebase aktif.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.notifications_active, size: 18),
                  label: const Text('Minta izin'),
                  onPressed: _busy
                      ? null
                      : () => _run(
                            ref.read(pushProvider.notifier).requestPermission,
                          ),
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.key, size: 18),
                  label: const Text('Ambil token'),
                  onPressed: _busy
                      ? null
                      : () => _run(ref.read(pushProvider.notifier).fetchToken),
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.sync, size: 18),
                  label: const Text('Rotasi token'),
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            await simulator.rotateToken();
                          }),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.launch, size: 18),
                  label: const Text('Foreground'),
                  onPressed: () => send(const PushMessage(
                    title: 'Jadwal kuliah berubah',
                    body: 'Kelas Mobile pindah ke Ruang A2 jam 13.00',
                    data: {'route': '/pengumuman/3', 'id': '3'},
                  )),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Background (klik)'),
                  onPressed: () => simulator.openFromBackground(
                    const PushMessage(
                      title: 'Uts Praktikum',
                      body: 'UTS di lab komputer Lt.3, bawa laptop.',
                      data: {'route': '/pengumuman/2', 'id': '2'},
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.power_settings_new, size: 18),
                  label: const Text('Terminated'),
                  onPressed: () => _terminate(const PushMessage(
                    title: 'Kuliah Pengganti',
                    body: 'Kelas pindah ke Ruang A2 Rabu 13.00.',
                    data: {'route': '/pengumuman/1', 'id': '1'},
                  )),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.data_object, size: 18),
                  label: const Text('Data-only'),
                  onPressed: () => simulator.emitForeground(const PushMessage(
                    data: {'route': '/pengumuman/2', 'id': '2'},
                  )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard(BuildContext context) {
    final check = ref.watch(profileCheckProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Keamanan sesi (refresh token)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'GET /me sengaja dibalas 401 sekali; interceptor refresh lalu '
              'mengulangi request yang sama.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.security, size: 18),
              label: const Text('Uji 401 → refresh → retry'),
              onPressed: _busy
                  ? null
                  : () =>
                      _run(ref.read(profileCheckProvider.notifier).run),
            ),
            if (check.busy) ...[
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
            ],
            if (check.ok) ...[
              const SizedBox(height: 12),
              Text('401 → refresh sekali → retry 200 OK (${check.name})'),
            ],
            if (check.error != null) ...[
              const SizedBox(height: 12),
              Text(check.error!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(BuildContext context) {
    final async = ref.watch(announcementsProvider);
    return Card(
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            error is Failure ? error.message : 'Gagal memuat pengumuman.',
          ),
        ),
        data: (announcements) => Column(
          children: [
            for (final a in announcements)
              ListTile(
                leading: const Icon(Icons.campaign),
                title: Text(a.title),
                subtitle:
                    Text(a.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.announcement(a.id)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, PushState push) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log event push',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final e in push.events)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(e, style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 150, child: Text(k)),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}

/// Banner in-app untuk pesan foreground.
///
/// Pada Android/iOS banner sistem tidak muncul saat aplikasi terbuka, jadi
/// pesan ditampilkan manual. Pada web, plugin notifikasi lokal tidak didukung
/// sehingga banner in-app ini menjadi satu-satunya tampilan.
class _InAppBanner extends StatelessWidget {
  const _InAppBanner({required this.message, required this.onTap});

  final PushMessage message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.inverseSurface,
      borderRadius: BorderRadius.circular(12),
      elevation: 6,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.notifications, color: scheme.onInverseSurface),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.title ?? 'Pengumuman',
                      style: TextStyle(
                        color: scheme.onInverseSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (message.body != null)
                      Text(
                        message.body!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onInverseSurface,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onInverseSurface),
            ],
          ),
        ),
      ),
    );
  }
}
