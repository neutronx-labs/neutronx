import 'package:neutronx/neutronx.dart';

/// A handler is a function that receives a Request and returns a Response.
///
/// This is the fundamental building block of NeutronX's request processing.
/// All route handlers, middleware, and the router itself conform to this type.
///
/// Example:
/// ```dart
/// Handler myHandler = (req) async {
///   return Response.json({'message': 'Hello World'});
/// };
/// ```
typedef Handler = Future<Response> Function(Request request);
