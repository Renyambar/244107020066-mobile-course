import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const double kWideBreakpoint = 700;

void main() {
  runApp(const DashboardApp());
}

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
        brightness: Brightness.light,
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),

      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

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
        title: const Text('Academic Overview'),
        actions: [
          Semantics(
            label: isDark
                ? 'Mode gelap aktif'
                : 'Mode terang aktif',
            child: Row(
              children: [
                Icon(
                  isDark
                      ? Icons.dark_mode
                      : Icons.light_mode,
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
          ),
        ],
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns =
              constraints.maxWidth >= kWideBreakpoint
                  ? 2
                  : 1;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ProfileHeader(),

                const SizedBox(height: 20),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.6,
                  children: const [
                    InfoCard(
                      title: 'Assignments',
                      value: '8',
                    ),
                    InfoCard(
                      title: 'Attendance',
                      value: '92%',
                    ),
                    InfoCard(
                      title: 'Portfolio',
                      value: 'Ready',
                    ),
                    InfoCard(
                      title: 'Current Week',
                      value: '02',
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Profil mahasiswa',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor:
                  theme.colorScheme.primary,
              child: Icon(
                Icons.person,
                size: 36,
                color:
                    theme.colorScheme.onPrimary,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reny Ambarwati',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'D4 Teknik Informatika',
                    style: theme.textTheme.bodyLarge,
                  ),

                  Text(
                    'Semester 5',
                    style: theme.textTheme.bodyMedium,
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

class InfoCard extends StatelessWidget {
  const InfoCard({
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
                style: theme.textTheme.headlineSmall
                    ?.copyWith(
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