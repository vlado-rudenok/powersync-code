import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class PostgrestExceptionChecker {
  bool isFatal(PostgrestException error);
}

@LazySingleton(as: PostgrestExceptionChecker)
class ConcretePostgrestExceptionChecker implements PostgrestExceptionChecker {
  ConcretePostgrestExceptionChecker();

  // https://www.psycopg.org/docs/errors.html

  final RegExp _class22DataException = RegExp(r'^22...$');
  final RegExp _class23IntegrityConstraintViolation = RegExp(r'^23...$');
  final RegExp _class43InsufficientPrivilegeOnly = RegExp(r'^42501$');

  List<RegExp> get _fatalResponseCodes => [
    _class22DataException,
    _class23IntegrityConstraintViolation,
    _class43InsufficientPrivilegeOnly,
  ];

  @override
  bool isFatal(PostgrestException error) {
    if (error.code == null) {
      return false;
    }

    return _fatalResponseCodes.any((e) => e.hasMatch(error.code!));
  }
}
