import 'app_database.dart';

abstract interface class SyncDatabaseProvider {
  AppDatabase get db;
  String get userId;

  Future<void> connectDatabase({required bool migrateLocalToSync});
  Future<void> logout();
}
