import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/repository/renewal_repository.dart';

/// In-memory repository used in widget and unit tests.
class InMemoryRenewalRepository implements RenewalRepository {
  final List<Renewal> _data = [];

  @override
  Future<List<Renewal>> loadAll() async => List.of(_data);

  @override
  Future<void> insert(Renewal renewal) async => _data.add(renewal);

  @override
  Future<void> update(Renewal renewal) async {
    final i = _data.indexWhere((r) => r.id == renewal.id);
    if (i >= 0) _data[i] = renewal;
  }

  @override
  Future<void> delete(String id) async =>
      _data.removeWhere((r) => r.id == id);

  @override
  Future<void> clearAll() async => _data.clear();

  @override
  Future<List<Map<String, dynamic>>> exportAllRows() async => [];

  @override
  Future<void> replaceAllRows(List<Map<String, dynamic>> rows) async {
    await clearAll();
  }
}
