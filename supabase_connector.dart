import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../keys/api_keys.dart';
import '../../extensions/bool_extension.dart';
import 'postgrest_exception_checker.dart';

final log = Logger('powersync-supabase');

@Injectable(as: PowerSyncBackendConnector)
class SupabaseConnector extends PowerSyncBackendConnector {
  SupabaseConnector(this.supabaseClient, this.postgrestExceptionChecker);

  final SupabaseClient supabaseClient;
  final PostgrestExceptionChecker postgrestExceptionChecker;

  Future<void>? _refreshFuture;

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    await _refreshFuture;

    final session = supabaseClient.auth.currentSession;

    if (session == null) {
      return null;
    }

    final userId = session.user.id;
    final expiresAt = session.expiresAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);

    return PowerSyncCredentials(
      endpoint: ApiKeys.powersyncUrl,
      token: session.accessToken,
      userId: userId,
      expiresAt: expiresAt,
    );
  }

  @override
  void invalidateCredentials() {
    _refreshFuture = supabaseClient.auth
        // ignore: discarded_futures
        .refreshSession()
        // ignore: discarded_futures
        .timeout(const Duration(seconds: 5))
        // ignore: discarded_futures
        .then((response) => null, onError: (error) => null);
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();

    if (transaction == null) {
      return;
    }

    final rest = supabaseClient.rest;
    CrudEntry? lastOp;
    try {
      for (final op in transaction.crud) {
        lastOp = op;

        final table = rest.from(op.table);
        if (op.op == UpdateType.put) {
          final data = Map<String, dynamic>.of(op.opData!);
          data['id'] = op.id;
          await table.upsert(data);
        } else if (op.op == UpdateType.patch) {
          await table.update(op.opData!).eq('id', op.id);
        } else if (op.op == UpdateType.delete) {
          await table.delete().eq('id', op.id);
        }
      }

      await transaction.complete();
    } on PostgrestException catch (e) {
      if (postgrestExceptionChecker.isFatal(e).not) {
        rethrow;
      }

      log.severe('Data upload error - discarding $lastOp', e);
      await transaction.complete();
    }
  }
}
