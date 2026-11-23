import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/checkout.dart';

CheckoutRequestStore createCheckoutRequestStore(SharedPreferencesAsync _) =>
    FileCheckoutRequestStore(getApplicationSupportDirectory);

class FileCheckoutRequestStore implements CheckoutRequestStore {
  const FileCheckoutRequestStore(this.directory);
  final Future<Directory> Function() directory;

  Future<File> _file(String userId) async {
    final root = await directory();
    final account = base64Url.encode(utf8.encode(userId));
    return File.fromUri(root.uri.resolve('orders-pending-v1/$account.json'));
  }

  @override
  Future<CheckoutRequest?> read(String userId) async {
    final file = await _file(userId);
    if (!await file.exists()) return null;
    return CheckoutRequest.fromJson(
      orderObject(jsonDecode(await file.readAsString())),
    );
  }

  @override
  Future<void> save(String userId, CheckoutRequest request) async {
    final file = await _file(userId);
    await file.parent.create(recursive: true);
    final staging = File('${file.path}.tmp');
    await staging.writeAsString(jsonEncode(request.toJson()), flush: true);
    await staging.rename(file.path);
  }

  @override
  Future<void> clear(String userId) async {
    final file = await _file(userId);
    if (await file.exists()) await file.delete();
  }
}
