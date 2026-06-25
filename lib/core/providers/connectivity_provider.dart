import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final connectivityProvider = StreamProvider<bool>((ref) async* {
  // 1. Instantly check the current status
  final initial = await Connectivity().checkConnectivity();
  yield !initial.contains(ConnectivityResult.none);

  // 2. Listen for any future changes
  await for (final results in Connectivity().onConnectivityChanged) {
    yield !results.contains(ConnectivityResult.none);
  }
});
