import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_router.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'core/database/daos/history_transfer_dao.dart';
import 'core/repositories/interfaces/i_account_repository.dart';
import 'core/repositories/interfaces/i_category_repository.dart';
import 'core/repositories/interfaces/i_history_repository.dart';
import 'core/repositories/local/account_repository.dart';
import 'core/repositories/local/category_repository.dart';
import 'core/repositories/local/history_repository.dart';
import 'features/history/bloc/add_history_bloc.dart';
import 'features/history/bloc/history_bloc.dart';
import 'features/history/bloc/transfer_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const DompetKuApp());
}

class DompetKuApp extends StatelessWidget {
  const DompetKuApp({super.key});

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
        ],
        child: MaterialApp.router(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          routerConfig: appRouter,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              surface: AppColors.background,
            ),
            textTheme: GoogleFonts.robotoTextTheme(
              Theme.of(context).textTheme,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.darkBlue,
              elevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            scaffoldBackgroundColor: AppColors.background,
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: AppColors.primarySoft,
              foregroundColor: Colors.white,
            ),
            bottomAppBarTheme: const BottomAppBarThemeData(
              color: Colors.white,
              elevation: 8,
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


