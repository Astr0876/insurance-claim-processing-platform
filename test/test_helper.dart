import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockGotrueAsyncStorage extends GotrueAsyncStorage {
  const MockGotrueAsyncStorage();

  @override
  Future<void> removeItem({required String key}) async {}

  @override
  Future<void> setItem({required String key, required String value}) async {}

  @override
  Future<String?> getItem({required String key}) async => null;
}

Future<void> initializeSupabaseForTest() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://placeholder.supabase.co',
    anonKey: 'placeholder',
    authOptions: const FlutterAuthClientOptions(
      localStorage: EmptyLocalStorage(),
      pkceAsyncStorage: MockGotrueAsyncStorage(),
    ),
  );
}
