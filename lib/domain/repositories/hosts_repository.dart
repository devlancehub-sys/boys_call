import '../entities/host_entity.dart';

abstract class HostsRepository {
  Future<List<HostEntity>> getOnlineHosts();
  Future<List<HostEntity>> getFeaturedHosts();
  Future<List<HostEntity>> getAllHosts({int page = 1, int limit = 50});
  Future<HostEntity?> getHostById(int id);
}
