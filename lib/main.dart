import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'learn_page.dart';
import 'theme_notifier.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'InterActED',
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorSchemeSeed: Colors.deepPurple,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: Colors.deepPurple,
          ),
          themeMode: mode,
          home: const LandingPage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _isLearnPressed = false;
  bool _isAboutPressed = false;
  bool _isExitPressed = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(50.0),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            print('Settings button tapped');
          },
        ),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return RotationTransition(
                  turns: Tween<double>(begin: 0.5, end: 1.0).animate(animation),
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: isDarkMode
                  ? const Icon(Icons.nightlight_round, key: ValueKey('dark'))
                  : const Icon(Icons.wb_sunny_outlined, key: ValueKey('light')),
            ),
            onPressed: () {
              themeNotifier.value = isDarkMode ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.school_outlined,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'InteractED',
                textAlign: TextAlign.center,
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Interactive Learning Tool',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),

              GestureDetector(
                onTapDown: (_) => setState(() => _isLearnPressed = true),
                onTapUp: (_) => setState(() => _isLearnPressed = false),
                onTapCancel: () => setState(() => _isLearnPressed = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 250,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.tertiary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(50.0),
                    border: Border.all(
                      color: colorScheme.primaryContainer,
                      width: 2.0,
                    ),
                    boxShadow: _isLearnPressed ? [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.7),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ] : [],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: buttonShape,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const LearnPage(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                    child: Text(
                      'Learn',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                        shadows: [
                          Shadow(
                            blurRadius: 8.0,
                            color: Colors.black.withOpacity(0.4),
                            offset: const Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTapDown: (_) => setState(() => _isAboutPressed = true),
                onTapUp: (_) => setState(() => _isAboutPressed = false),
                onTapCancel: () => setState(() => _isAboutPressed = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 250,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(50.0),
                    border: Border.all(
                      color: colorScheme.tertiary,
                      width: 2.0,
                    ),
                    boxShadow: _isAboutPressed ? [
                      BoxShadow(
                        color: colorScheme.tertiary.withOpacity(0.6),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ] : [],
                  ),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: buttonShape,
                      backgroundColor: Colors.transparent,
                      side: BorderSide.none,
                    ),
                    onPressed: () {
                      print('About button tapped');
                    },
                    child: Text(
                      'About',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTapDown: (_) => setState(() => _isExitPressed = true),
                onTapUp: (_) => setState(() => _isExitPressed = false),
                onTapCancel: () => setState(() => _isExitPressed = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 250,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(50.0),
                    border: Border.all(
                      color: colorScheme.outline,
                      width: 1.5,
                    ),
                    boxShadow: _isExitPressed ? [
                      BoxShadow(
                        color: colorScheme.outline.withOpacity(0.8),
                        blurRadius: 15,
                      ),
                    ] : [],
                  ),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: buttonShape,
                      side: BorderSide.none,
                    ),
                    onPressed: () {
                      print('Exit button tapped');
                      SystemNavigator.pop();
                    },
                    child: Text(
                      'Exit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
