import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const double kWideBreakpoint = 700;

void main() => runApp(const DashboardApp());

class DashboardApp extends StatefulWidget {
  const DashboardApp({super.key});

  @override
  State<DashboardApp> createState() => _DashboardAppState();
}

class _DashboardAppState extends State<DashboardApp> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.indigo,
      ),

      themeMode: isDark
          ? ThemeMode.dark
          : ThemeMode.light,

      home: DashboardPage(
        isDark: isDark,
        onDarkChanged: (value) {
          setState(() {
            isDark = value;
          });
        },
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.isDark,
    required this.onDarkChanged,
    super.key,
  });

  final bool isDark;
  final ValueChanged<bool> onDarkChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),

        actions: [
          Row(
            children: [
              Semantics(
                label: isDark
                    ? 'Mode gelap aktif'
                    : 'Mode terang aktif',
                child: Icon(
                  isDark
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
              ),

              const SizedBox(width: 4),

              Semantics(
                label: 'Ubah tema aplikasi',
                child: CupertinoSwitch(
                  value: isDark,
                  onChanged: onDarkChanged,
                ),
              ),

              const SizedBox(width: 12),
            ],
          ),
        ],
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns =
              constraints.maxWidth >= kWideBreakpoint
                  ? 2
                  : 1;

          return GridView.count(
            padding: const EdgeInsets.all(16),

            crossAxisCount: columns,

            crossAxisSpacing: 16,
            mainAxisSpacing: 16,

            childAspectRatio: 2.6,

            children: const [
              DashboardCard(
                title: 'Assignments',
                value: '8',
              ),

              DashboardCard(
                title: 'Attendance',
                value: '92%',
              ),

              DashboardCard(
                title: 'Portfolio',
                value: 'Ready',
              ),

              DashboardCard(
                title: 'Current Week',
                value: '02',
              ),
            ],
          );
        },
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    required this.title,
    required this.value,
    super.key,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$title: $value',

      child: Card(
        child: Container(
          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),

            color: theme
                .colorScheme
                .surfaceContainerHighest,
          ),

          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium,
                ),
              ),

              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}