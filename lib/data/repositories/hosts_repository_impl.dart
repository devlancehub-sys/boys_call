import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/parse_utils.dart';
import '../../domain/entities/host_entity.dart';
import '../../domain/repositories/hosts_repository.dart';

class HostsRepositoryImpl implements HostsRepository {
  HostsRepositoryImpl(this._api);

  final ApiService _api;

  @override
  Future<List<HostEntity>> getOnlineHosts() async {
    final res = await _api.get(ApiConstants.hostsOnline);
    return JsonParse.toMapList(res['data'])
        .map(HostEntity.fromMap)
        .toList();
  }

  @override
  Future<List<HostEntity>> getFeaturedHosts() async {
    final res = await _api.get(ApiConstants.hostsFeatured);
    return JsonParse.toMapList(res['data']).map(HostEntity.fromMap).toList();
  }

  @override
  Future<List<HostEntity>> getAllHosts({int page = 1, int limit = 50}) async {
    final res = await _api.get(ApiConstants.hosts, query: {'page': page, 'limit': limit});
    return JsonParse.toMapList(res['data']).map(HostEntity.fromMap).toList();
  }

  @override
  Future<HostEntity?> getHostById(int id) async {
    final res = await _api.get(ApiConstants.hostById(id));
    final data = JsonParse.toMap(res['data']);
    return data != null ? HostEntity.fromMap(data) : null;
  }
}
