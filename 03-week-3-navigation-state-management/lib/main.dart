import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';

void main() {
  // ProviderScope adalah wadah global yang menyimpan semua state provider Riverpod.
  // Wajib membungkus root aplikasi agar ref dapat diakses di seluruh widget tree.
  runApp(
    const ProviderScope(
      child: Week3App(),
    ),
  );
}

/// Root Widget aplikasi Week 3
class Week3App extends StatelessWidget {
  const Week3App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Week 3 - Navigation & State Management',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
    );
  }
}
