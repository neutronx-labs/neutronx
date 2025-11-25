import 'package:neutronx/neutronx.dart';

import 'home/home_module.dart';
// [MODULE_IMPORTS]

export 'home/home_module.dart';
// [MODULE_EXPORTS]

List<NeutronModule> buildModules() => [
  HomeModule(),
  // [MODULE_REGISTRATIONS]
];
