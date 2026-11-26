import 'package:flutter/material.dart';

import 'core/routing/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/notes/presentation/screens/notes_list_screen.dart';

class RecallApp extends StatelessWidget {
  const RecallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recall',
      navigatorKey: AppRoutes.navigatorKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const NotesListScreen(),
    );
  }
}
