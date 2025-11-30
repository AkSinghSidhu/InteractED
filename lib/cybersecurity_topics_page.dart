import 'package:flutter/material.dart';
import 'theme_notifier.dart';

class CybersecurityTopicsPage extends StatefulWidget {
  const CybersecurityTopicsPage({super.key});

  @override
  State<CybersecurityTopicsPage> createState() => _CybersecurityTopicsPageState();
}

class _CybersecurityTopicsPageState extends State<CybersecurityTopicsPage> {
  final List<String> topics = [
    'Encryption',
    'ARP Spoofing (MITM)',
    'Firewalls',
    'Malware Analysis',
    'Network Security',
    'Penetration Testing',
    'Digital Forensics',
    'Cloud Security',
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
        title: const Text('Cybersecurity Topics'),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${topics[index]} module coming soon!'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: colorScheme.primary,
                  width: 2.0,
                ),
                boxShadow: _isPressed[index]
                    ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.7),
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
                      color: colorScheme.onPrimaryContainer,
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
