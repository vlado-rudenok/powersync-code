import 'package:path/path.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/di/injectable.dart';
import '../../../../main.dart';
import '../../../extensions/bool_extension.dart';
import '../../remote/supabase/supabase_accessor.dart';
import '../app_database.dart';
import '../models/power_sync_scheme_provider.dart';
import '../supabase_connector.dart';
import '../sync_database_provider.dart';
import '../sync_mode_provider/sync_mode_provider.dart';

part 'power_sync_connector_factory.dart';

class PowerSyncConnector implements SyncDatabaseProvider {
  PowerSyncConnector._(this.supabase, this.syncModeProvider, this.powerSyncSchemeProvider) {
    bindAuthStateChange();
  }

  static Future<PowerSyncConnector> init(
    SupabaseAccessor supabase,
    SyncModeProvider syncModeProvider,
    PowerSyncSchemeProvider powerSyncSchemeProvider,
  ) async {
    final connector = PowerSyncConnector._(supabase, syncModeProvider, powerSyncSchemeProvider);

    await connector.openDatabase(closeOldDatabase: false);

    return connector;
  }

  @override
  late AppDatabase db;
  late PowerSyncDatabase database;
  final SupabaseAccessor supabase;
  final SyncModeProvider syncModeProvider;
  final PowerSyncSchemeProvider powerSyncSchemeProvider;
  PowerSyncBackendConnector? currentConnector;

  bool get isLoggedIn => supabase.isLoggedIn;

  @override
  String get userId => supabase.userId;

  @override
  Future<void> logout() async {
    await database.disconnectAndClear(clearLocal: false);
    await database.close();

    await syncModeProvider.setSyncEnabled(false);
    await openDatabase();
  }

  @override
  Future<void> connectDatabase({required bool migrateLocalToSync}) async {
    currentConnector = await openConnection(
      isSyncMode: await syncModeProvider.isSyncEnabled(),
      migrateLocalToSync: migrateLocalToSync,
    );
  }

  void bindAuthStateChange() {
    supabase.onAuthStateChange.listen((data) async {
      switch (data.event) {
        case AuthChangeEvent.signedOut:
          currentConnector = null;
          await database.disconnect();
        case AuthChangeEvent.tokenRefreshed:
          await currentConnector?.prefetchCredentials();
        // ignore: no_default_cases
        default:
          break;
      }
    });
  }
}
