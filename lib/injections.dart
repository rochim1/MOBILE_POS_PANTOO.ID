import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/_core.dart';
import 'core/network/graphql_client_provider.dart';
import 'core/network/sync_service.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/pos_repository.dart';
import 'domain/repositories/pos_stock_repository.dart';
import 'domain/repositories/pos_product_management_repository.dart';
import 'domain/repositories/pos_promo_repository.dart';
import 'domain/repositories/pos_table_repository.dart';
import 'domain/repositories/pos_settings_repository.dart';
import 'domain/repositories/pos_receipt_repository.dart';
import 'domain/repositories/pos_report_repository.dart';
import 'domain/repositories/pos_order_repository.dart';
import 'domain/repositories/purchase_return_repository.dart';
import 'domain/repositories/pos_inventory_repository.dart';
import 'presentation/bloc/app/app_cubit.dart';
import 'presentation/bloc/auth/auth_cubit.dart';
import 'presentation/bloc/auth/register_cubit.dart';
import 'presentation/bloc/pos/pos_bloc.dart';
import 'presentation/bloc/pos_promo/pos_promo_bloc.dart';
import 'presentation/bloc/pos_return/pos_return_bloc.dart';
import 'presentation/bloc/pos_shift/pos_shift_bloc.dart';
import 'presentation/bloc/pos_stock/pos_stock_bloc.dart';
import 'presentation/bloc/pos_product_management/pos_product_management_bloc.dart';
import 'presentation/bloc/pos_table/pos_table_bloc.dart';
import 'presentation/bloc/pos_settings/pos_settings_bloc.dart';
import 'presentation/bloc/pos_receipt/pos_receipt_bloc.dart';
import 'presentation/bloc/pos_report/pos_report_bloc.dart';
import 'presentation/bloc/pos_order_management/pos_order_management_bloc.dart';

final sl = GetIt.instance;

Future<void> initLocator(FlavorConfig flavorConfig) async {
  // Core
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(
    () => GraphQLClientProvider(
      sl(),
      sl(),
      environment: flavorConfig.environment,
      onUnauthorized: () {
        sl<AuthCubit>().logout();
      },
    ),
  );
  sl.registerLazySingleton(() => SyncService(sl()));

  sl.registerSingleton<FlavorConfig>(flavorConfig);
  sl.registerSingleton<AppTheme>(AppTheme());

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(sl(), sl(), sl()),
  );
  sl.registerLazySingleton<PosRepository>(() => PosRepository(sl(), sl()));
  sl.registerLazySingleton<PosPromoRepository>(() => PosPromoRepository(sl()));
  sl.registerLazySingleton<PosStockRepository>(() => PosStockRepository(sl()));
  sl.registerLazySingleton<PosProductManagementRepository>(
    () => PosProductManagementRepository(sl()),
  );
  sl.registerLazySingleton<PosTableRepository>(() => PosTableRepository(sl()));
  sl.registerLazySingleton<PosSettingsRepository>(
    () => PosSettingsRepository(sl()),
  );
  sl.registerLazySingleton<PosReceiptRepository>(
    () => PosReceiptRepository(sl()),
  );
  sl.registerLazySingleton<PosReportRepository>(
    () => PosReportRepository(sl()),
  );
  sl.registerLazySingleton<PosOrderRepository>(() => PosOrderRepository(sl()));
  sl.registerLazySingleton<PurchaseReturnRepository>(
    () => PurchaseReturnRepository(sl()),
  );
  sl.registerLazySingleton<PosInventoryRepository>(
    () => PosInventoryRepository(sl()),
  );

  // Blocs
  sl.registerLazySingleton<AppCubit>(() => AppCubit());
  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(authRepository: sl<AuthRepository>()),
  );
  sl.registerFactory(() => RegisterCubit(authRepository: sl()));
  sl.registerFactory(() => PosBloc(posRepository: sl()));

  sl.registerFactory(() => PosReturnBloc(posRepository: sl()));

  sl.registerFactory(() => PosPromoBloc(promoRepository: sl()));

  sl.registerFactory(() => PosShiftBloc(posRepository: sl()));

  sl.registerFactory(() => PosStockBloc(repository: sl()));
  sl.registerFactory(() => PosProductManagementBloc(sl()));

  sl.registerFactory(() => PosTableBloc(repository: sl()));

  sl.registerFactory(() => PosSettingsBloc(repository: sl()));

  sl.registerFactory(() => PosReceiptBloc(repository: sl()));

  sl.registerFactory(() => PosReportBloc(repository: sl()));

  sl.registerFactory(() => PosOrderManagementBloc(repository: sl()));
}
