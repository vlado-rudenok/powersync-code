import 'package:powersync/powersync.dart' as powersync;
import 'package:uuid/uuid.dart';

import 'models/drift_scheme.dart';

part 'app_database.g.dart';

class Id {
  Id._();

  static String get uuid => const Uuid().v4();
}

@DriftDatabase(
  tables: [
    Notes,
    HighlightColors,
    HistoryEntries,
    Bookmarks,
    LineHighlights,
    SermonHighlights,
    AudioLastPositions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(powersync.PowerSyncDatabase db) : super(SqliteAsyncDriftConnection(db));

  @override
  int get schemaVersion => 1;
}
