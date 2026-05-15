import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_router.dart';
import 'core/constants/app_strings.dart';
import 'core/database/daos/history_transfer_dao.dart';
import 'core/repositories/interfaces/i_account_repository.dart';
import 'core/repositories/interfaces/i_category_repository.dart';
import 'core/repositories/interfaces/i_history_repository.dart';
import 'core/repositories/local/account_repository.dart';
import 'core/repositories/local/category_repository.dart';
import 'core/repositories/local/history_repository.dart';
import 'core/theme/app_theme.dart';
import 'features/history/bloc/add_history_bloc.dart';
import 'features/history/bloc/history_bloc.dart';
import 'features/history/bloc/transfer_bloc.dart';
import 'features/report/bloc/report_bloc.dart';
import 'features/settings/bloc/theme_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final prefs = await SharedPreferences.getInstance();
  runApp(DompetKuApp(prefs: prefs));
}

class DompetKuApp extends StatelessWidget {
  final SharedPreferences prefs;
  const DompetKuApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<IHistoryRepository>(
          create: (_) => HistoryRepository(),
        ),
        RepositoryProvider<IAccountRepository>(
          create: (_) => AccountRepository(),
        ),
        RepositoryProvider<ICategoryRepository>(
          create: (_) => CategoryRepository(),
        ),
        RepositoryProvider<HistoryTransferDao>(
          create: (_) => HistoryTransferDao(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(
            create: (_) => ThemeCubit(prefs),
          ),
          BlocProvider<HistoryBloc>(
            create: (ctx) => HistoryBloc(ctx.read<IHistoryRepository>()),
          ),
          BlocProvider<AddHistoryBloc>(
            create: (ctx) => AddHistoryBloc(
              ctx.read<IHistoryRepository>(),
              ctx.read<IAccountRepository>(),
              ctx.read<ICategoryRepository>(),
            ),
          ),
          BlocProvider<TransferBloc>(
            create: (ctx) => TransferBloc(
              ctx.read<IAccountRepository>(),
              ctx.read<IHistoryRepository>(),
              ctx.read<HistoryTransferDao>(),
            ),
          ),
          BlocProvider<ReportBloc>(
            create: (_) => ReportBloc(),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp.router(
              title: AppStrings.appName,
              debugShowCheckedModeBanner: false,
              routerConfig: appRouter,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: themeMode,
            );
          },
        ),
      ),
    );
  }
}


