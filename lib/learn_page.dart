import 'package:flutter/material.dart';
import 'computer_subjects_page.dart';
import 'theme_notifier.dart';

class LearnPage extends StatefulWidget {const LearnPage({super.key});

@override
State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  final List<String> subjects = [
    'Computers',
    'Mathematics',
    'Science',
    'History',
  ];

  late List<bool> _isPressed;

  @override
  void initState() {
    super.initState();
    _isPressed = List<bool>.filled(subjects.length, false);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a Subject'),
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
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTapDown: (_) => setState(() => _isPressed[index] = true),
            onTapUp: (_) => setState(() => _isPressed[index] = false),
            onTapCancel: () => setState(() => _isPressed[index] = false),
            onTap: () {
              if (subjects[index] == 'Computers') {
                // APPLY FADE TRANSITION HERE
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                    const ComputerSubjectsPage(),
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
                print('${subjects[index]} tapped');
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    subjects[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
