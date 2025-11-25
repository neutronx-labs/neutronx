class HomeRepository {
  Future<Map<String, dynamic>> welcome() async {
    return {
      'module': 'home',
      'message': 'Hello from HomeModule',
    };
  }
}
