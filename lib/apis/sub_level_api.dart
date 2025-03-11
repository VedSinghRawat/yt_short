import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/models/models.dart';

abstract class ISubLevelAPI {
  Future<String> getZip(int zipId);
}

class SubLevelAPI implements ISubLevelAPI {
  SubLevelAPI(this.apiService);

  final ApiService apiService;

  @override
  Future<String> getZip(int zipId) async {
    final response = await apiService.call(
      endpoint: '/zips/$zipId.zip',
      customBaseUrl: dotenv.env['S3_BASE_URL'],
      method: ApiMethod.get,
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch zip for zipId $zipId");
    }

    return response.data;
  }
}

final subLevelAPIProvider = Provider<ISubLevelAPI>((ref) {
  return SubLevelAPI(ref.read(apiServiceProvider));
});
