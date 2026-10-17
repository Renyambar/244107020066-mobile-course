/// Pembantu format tampilan (tanpa dependensi `intl` agar ringan).
String formatDateTime(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(dt.day)}/${two(dt.month)}/${dt.year} '
      '${two(dt.hour)}.${two(dt.minute)}';
}

/// "baru saja" / "5 menit lalu" — untuk waktu terakhir dibuka & cache.
String formatRelative(DateTime dt, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  final diff = clock.difference(dt);
  if (diff.inSeconds < 60) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return formatDateTime(dt);
}

/// `2026-09-18T10:30:00.000` → tampilan yang enak dibaca, atau tanda `-`
/// bila belum pernah ada.
String formatIsoOrDash(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return '—';
  return '${formatDateTime(parsed)} (${formatRelative(parsed)})';
}
