import 'package:flutter/material.dart';

/// Banner "Mode offline" — ditampilkan ketika [visible] (toggle
/// `forceOffline` aktif atau memang sedang tanpa jaringan).
///
/// Pesannya sengaja menenangkan: aplikasi **tetap bisa dibaca & ditulis**,
/// hanya sinkronisasinya yang ditahan.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.visible = true});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.tertiaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.wifi_off_rounded, size: 18, color: scheme.onTertiaryContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Mode offline aktif — catatan tetap bisa dibaca & ditulis '
                  'secara lokal.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onTertiaryContainer,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.sync_problem_rounded,
                  size: 18, color: scheme.onTertiaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}
