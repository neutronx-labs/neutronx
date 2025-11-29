import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/request.dart';

/// Signature for WebSocket route handlers.
///
/// A `WebSocketHandler` is invoked when a WebSocket connection is successfully
/// established for a route that matches the incoming request. The handler receives
/// a [WebSocketSession] object, which provides access to the underlying WebSocket,
/// the originating HTTP request, path parameters, and query string.
///
/// Implementations of this handler are typically responsible for setting up
/// listeners on the WebSocket, processing incoming messages, and sending responses
/// as needed. The returned [Future] should complete once the handler has finished
/// its initial setup or processing; the WebSocket connection itself may remain open
/// after the handler's future completes if listeners or other asynchronous operations
/// are still active.
///
/// Errors thrown by the handler will be reported to the client and may result in the
/// WebSocket being closed with an error code.
typedef WebSocketHandler = Future<void> Function(WebSocketSession session);

/// A wrapper around a [WebSocket] that provides convenient access to the 
/// originating HTTP request, path parameters, and query string.
///
/// The session is created when a WebSocket upgrade request is received and
/// matched to a registered WebSocket route. It provides high-level methods
/// for sending messages and closing the connection.
///
/// Example:
/// ```dart
/// router.ws('/chat/:room', (session) async {
///   final room = session.params['room'];
///   session.send('Welcome to room $room!');
///   
///   await for (final message in session.messages) {
///     // Handle incoming messages
///     session.send('Echo: $message');
///   }
/// });
/// ```
///
/// Thread-safety & async notes:
/// - Each [WebSocketSession] instance is intended to be used by a single handler and is not thread-safe.
/// - Message handling is asynchronous; use `await for` to process incoming messages.
/// - Closing the session is also asynchronous and should be awaited if you need to ensure the socket is closed before proceeding.
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
  Stream<dynamic> get messages => socket;

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
    await socket.close(WebSocketStatus.protocolError, error.toString());
  }
}
