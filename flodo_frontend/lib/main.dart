import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/task_list_screen.dart';
import 'screens/task_form_screen.dart';
import 'models/task_model.dart';

void main() {
  runApp(const ProviderScope(child: FlodoApp()));
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const TaskListScreen(),
    ),
    GoRoute(
      path: '/create',
      builder: (context, state) => const TaskFormScreen(),
    ),
    GoRoute(
      path: '/task/:id',
      builder: (context, state) {
        final task = state.extra as Task?;
        return TaskFormScreen(existingTask: task);
      },
    ),
  ],
);

class FlodoApp extends StatelessWidget {
  const FlodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flodo Premium',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), 
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6), 
          secondary: Color(0xFF3B82F6), 
          surface: Color(0xFF1E293B),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
