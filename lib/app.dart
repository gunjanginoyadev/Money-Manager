import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_branding.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/budget_message_toast_listener.dart';
import 'features/budget/data/budget_local_data_source.dart';
import 'features/budget/data/budget_repository.dart';
import 'features/budget/data/firebase_sync_service.dart';
import 'features/budget/presentation/screens/home_shell.dart';
import 'features/budget/presentation/viewmodels/budget_view_model.dart';

class MoneyManagerApp extends StatelessWidget {
  const MoneyManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<BudgetRepository>(
          create: (_) => BudgetRepository(
            localDataSource: BudgetLocalDataSource(),
            firebaseSyncService: FirebaseSyncService(),
          ),
        ),
        ChangeNotifierProvider<BudgetViewModel>(
          create: (context) => BudgetViewModel(context.read<BudgetRepository>())
            ..initialize(),
        ),
      ],
      child: MaterialApp(
        title: kAppDisplayName,
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const BudgetMessageToastListener(child: HomeShell()),
      ),
    );
  }
}
