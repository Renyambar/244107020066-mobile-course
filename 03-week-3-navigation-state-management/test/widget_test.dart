import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week03/main.dart';
import 'package:week03/providers/stats_provider.dart';

void main() {
  setUp(() {
    StatsNotifier.simulationDelay = Duration.zero;
    StatsNotifier.globalForcedFailureRate = 0.0;
  });

  tearDown(() {
    StatsNotifier.globalForcedFailureRate = null;
    StatsNotifier.simulationDelay = const Duration(seconds: 2);
  });

  testWidgets('Menampilkan halaman daftar ToDo dan menambah tugas baru', (tester) async {
    // Jalankan aplikasi dengan ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: Week3App(),
      ),
    );
    await tester.pumpAndSettle();

    // Verifikasi bahwa halaman utama berhasil dirender
    expect(find.text('Daftar Tugas ToDo'), findsOneWidget);
    expect(find.text('Mempelajari Navigasi GoRouter'), findsOneWidget);

    // Tekan tombol FloatingActionButton (Tambah Tugas)
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // Verifikasi dialog input tugas tampil
    expect(find.text('Tambah Tugas Baru'), findsOneWidget);

    // Masukkan judul tugas baru
    await tester.enterText(find.byType(TextField), 'Kerjakan Tugas Praktikum Minggu 3');
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    // Verifikasi tugas baru telah masuk ke dalam list
    expect(find.text('Kerjakan Tugas Praktikum Minggu 3'), findsOneWidget);
  });

  testWidgets('Navigasi antar tab tugas dan tab statistik', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: Week3App(),
      ),
    );
    await tester.pumpAndSettle();

    // Pindah ke tab Statistik melalui NavigationBar
    final statsTab = find.text('Statistik');
    expect(statsTab, findsOneWidget);
    await tester.tap(statsTab);
    await tester.pumpAndSettle();

    // Verifikasi halaman statistik terbuka
    expect(find.text('Statistik Aktivitas'), findsOneWidget);
    expect(find.text('Total Tugas'), findsOneWidget);
  });
}
