import 'package:flutter/material.dart';
import 'theme_notifier.dart';
import 'virtual_memory_page.dart';

class OperatingSystemPage extends StatefulWidget {
  const OperatingSystemPage({super.key});

  @override
  State<OperatingSystemPage> createState() => _OperatingSystemPageState();
}

class _OperatingSystemPageState extends State<OperatingSystemPage> {
  final List<String> topics = [
    'Virtual Memory',
    'Process Scheduling',
    'Deadlocks',
    'File Systems',
    'Concurrency',
    'Boot Sequence',
  ];

  late List<bool> _isPressed;

  @override
  void initState() {
    super.initState();
    _isPressed = List<bool>.filled(topics.length, false);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operating Systems'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              themeNotifier.value = isDarkMode ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20.0),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: topics.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTapDown: (_) => setState(() => _isPressed[index] = true),
            onTapUp: (_) => setState(() => _isPressed[index] = false),
            onTapCancel: () => setState(() => _isPressed[index] = false),
            onTap: () {
              if (topics[index] == 'Virtual Memory') {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, a, sa) => const VirtualMemoryPage(),
                    transitionsBuilder: (context, a, sa, child) {
                      return FadeTransition(opacity: a, child: child);
                    },
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${topics[index]} module coming soon!'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: colorScheme.tertiary,
                  width: 2.0,
                ),
                boxShadow: _isPressed[index]
                    ? [
                  BoxShadow(
                    color: colorScheme.tertiary.withOpacity(0.7),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
                    : [],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    topics[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
