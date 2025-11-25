import 'package:neutronx/neutronx.dart';
import '../services/home_service.dart';

class HomeController {
  final HomeService _service;

  HomeController(this._service);

  void register(Router router) {
    router.get('/', _welcome);
  }

  Future<Response> _welcome(Request req) async {
    final data = await _service.welcome();
    return Response.json(data);
  }
}
