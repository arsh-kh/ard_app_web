import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

final connectivityProvider = StreamProvider<bool>((ref) {
  return InternetConnection().onStatusChange.map((status) {
    return status == InternetStatus.connected;
  });
});
