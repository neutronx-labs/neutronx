import '../repositories/home_repository.dart';

class HomeService {
  final HomeRepository _repository;

  HomeService(this._repository);

  Future<Map<String, dynamic>> welcome() async {
    return _repository.welcome();
  }
}
