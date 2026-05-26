import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/storage_service.dart';

final apiConfigProvider = FutureProvider<dynamic>((ref) async {
  return await StorageService.getApiConfig();
});
