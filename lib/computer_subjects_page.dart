import 'package:flutter/material.dart';
import 'cybersecurity_topics_page.dart';
import 'ai_subjects_page.dart';
import 'computer_networks_page.dart';
import 'operating_system_page.dart';
import 'theme_notifier.dart';

class ComputerSubjectsPage extends StatefulWidget {
  const ComputerSubjectsPage({super.key});

  @override
  State<ComputerSubjectsPage> createState() => _ComputerSubjectsPageState();
}

class _ComputerSubjectsPageState extends State<ComputerSubjectsPage> {
  final List<String> subSubjects = [
    'Cybersecurity',
    'Computer Networks',
    'Operating System',
    'Web Development',
    'Artificial Intelligence',
    'Software Engineering',
  ];

  late List<bool> _isPressed;

  @override
  void initState() {
    super.initState();
    _isPressed = List<bool>.filled(subSubjects.length, false);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Computer Science'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
        itemCount: subSubjects.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTapDown: (_) => setState(() => _isPressed[index] = true),
            onTapUp: (_) => setState(() => _isPressed[index] = false),
            onTapCancel: () => setState(() => _isPressed[index] = false),
            onTap: () {
              if (subSubjects[index] == 'Cybersecurity') {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                    const CybersecurityTopicsPage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
              } else if (subSubjects[index] == 'Artificial Intelligence') {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                    const AiSubjectsPage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
              } else if (subSubjects[index] == 'Computer Networks') {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                    const ComputerNetworksPage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
              } else if (subSubjects[index] == 'Operating System') {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                    const OperatingSystemPage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
              } else {
                print('${subSubjects[index]} tapped');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${subSubjects[index]} module coming soon!'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: colorScheme.secondary,
                  width: 2.0,
                ),
                boxShadow: _isPressed[index]
                    ? [
                  BoxShadow(
                    color: colorScheme.secondary.withOpacity(0.7),
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
                    subSubjects[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondaryContainer,
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
