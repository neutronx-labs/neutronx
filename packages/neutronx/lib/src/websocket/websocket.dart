import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/request.dart';

/// Signature for websocket route handlers.
typedef WebSocketHandler = Future<void> Function(WebSocketSession session);

/// Minimal wrapper around a [WebSocket] that also exposes the originating
/// HTTP request, path params, and query string.
class WebSocketSession {
  final WebSocket socket;
  final Request request;
  final Map<String, String> params;
  final Map<String, String> query;

  WebSocketSession({
    required this.socket,
    required this.request,
    Map<String, String>? params,
    Map<String, String>? query,
  })  : params = Map.unmodifiable(params ?? const {}),
        query = Map.unmodifiable(query ?? const {});

  /// Stream of inbound messages.
  Stream get messages => socket;

  /// Whether the websocket has been closed.
  bool get isClosed => socket.closeCode != null;

  /// Send a text frame.
  void send(String message) => socket.add(message);

  /// Send a JSON-encoded frame.
  void sendJson(dynamic data) => socket.add(jsonEncode(data));

  /// Close the socket with an optional code and reason.
  Future<void> close([int? code, String? reason]) => socket.close(code, reason);

  /// Close after reporting an error to the client.
  Future<void> closeWithError(Object error, [StackTrace? stackTrace]) async {
    socket.addError(error, stackTrace);
    await socket.close(WebSocketStatus.protocolError, error.toString());
  }
}
