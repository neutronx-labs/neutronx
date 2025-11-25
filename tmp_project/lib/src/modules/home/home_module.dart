import 'package:neutronx/neutronx.dart';
import 'controllers/home_controller.dart';
import 'services/home_service.dart';
import 'repositories/home_repository.dart';
// [CONTROLLER_IMPORTS]

class HomeModule extends NeutronModule {
  @override
  String get name => 'home';

  @override
  Future<void> register(ModuleContext ctx) async {
    // Register dependencies
    ctx.container.registerLazySingleton<HomeRepository>(
      (c) => HomeRepository(),
    );

    ctx.container.registerLazySingleton<HomeService>(
      (c) => HomeService(c.get<HomeRepository>()),
    );

    // Wire routes via controller
    final service = ctx.container.get<HomeService>();
    HomeController(service).register(ctx.router);
    // [CONTROLLER_REGISTRATIONS]
  }
}
