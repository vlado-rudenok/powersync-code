part of 'power_sync_connector.dart';

extension on PowerSyncConnector {
  Future<void> openDatabase({bool closeOldDatabase = true}) async {
    final databasePath = join(applicationDocumentsDirectory.path, 'powersync-database.db');
    final isSyncMode = await syncModeProvider.isSyncEnabled();

    database = PowerSyncDatabase(
      schema: powerSyncSchemeProvider.makeSchema(synced: isSyncMode),
      path: databasePath,
      logger: attachedLogger,
    );

    await database.initialize();

    if (closeOldDatabase) {
      await db.close();
    }

    db = AppDatabase(database);

    if (supabase.isLoggedIn) {
      currentConnector = await openConnection(isSyncMode: isSyncMode, migrateLocalToSync: false);
    }
  }

  Future<PowerSyncBackendConnector?> openConnection({
    required bool isSyncMode,
    required bool migrateLocalToSync,
  }) async {
    if (supabase.isLoggedIn.not) {
      log.severe("Can't connect database without being signed in");
    }

    if (!isSyncMode) {
      await powerSyncSchemeProvider.switchToSyncedSchema(
        database,
        supabase.userId,
        migrateLocalToSync: migrateLocalToSync,
      );
    }

    final currentConnector = locator<PowerSyncBackendConnector>();

    await database.connect(connector: currentConnector);

    return currentConnector;
  }
}
