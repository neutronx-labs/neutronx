import 'dart:convert';
import 'dart:io';

/// Represents an HTTP response in NeutronX.
///
/// Response objects are immutable and created using factory constructors
/// for common response types (text, json, bytes, redirect, etc.).
///
/// The response can be modified using [copyWith] (useful for middleware
/// that wants to add headers or change status codes).
class Response {
  /// HTTP status code
  final int statusCode;

  /// Response headers
  final Map<String, String> headers;

  /// Response body as bytes
  final List<int> body;

  /// Optional response body as a stream for large/streaming payloads
  final Stream<List<int>>? bodyStream;

  const Response._({
    required this.statusCode,
    required this.headers,
    required this.body,
    this.bodyStream,
  });

  /// Creates a plain text response
  factory Response.text(
    String content, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    final mergedHeaders = {
      'content-type': 'text/plain; charset=utf-8',
      ...?headers,
    };

    return Response._(
      statusCode: statusCode,
      headers: mergedHeaders,
      body: utf8.encode(content),
      bodyStream: null,
    );
  }

  /// Creates a JSON response
  ///
  /// The [data] can be:
  /// - A Map or List (will be encoded using jsonEncode)
  /// - A DTO with a toJson() method (must call toJson() before passing)
  ///
  /// Example:
  /// ```dart
  /// return Response.json({'message': 'Hello'});
  /// return Response.json(userDto.toJson());
  /// ```
  factory Response.json(
    dynamic data, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    final mergedHeaders = {
      'content-type': 'application/json; charset=utf-8',
      ...?headers,
    };

    final jsonString = jsonEncode(data);

    return Response._(
      statusCode: statusCode,
      headers: mergedHeaders,
      body: utf8.encode(jsonString),
      bodyStream: null,
    );
  }

  /// Creates a response with raw bytes
  factory Response.bytes(
    List<int> bytes, {
    int statusCode = 200,
    String contentType = 'application/octet-stream',
    Map<String, String>? headers,
  }) {
    final mergedHeaders = {
      'content-type': contentType,
      ...?headers,
    };

    return Response._(
      statusCode: statusCode,
      headers: mergedHeaders,
      body: bytes,
      bodyStream: null,
    );
  }

  /// Creates a streaming response without buffering the full body in memory
  factory Response.stream(
    Stream<List<int>> stream, {
    int statusCode = 200,
    String contentType = 'application/octet-stream',
    Map<String, String>? headers,
  }) {
    final mergedHeaders = {
      'content-type': contentType,
      ...?headers,
    };

    return Response._(
      statusCode: statusCode,
      headers: mergedHeaders,
      body: const [],
      bodyStream: stream,
    );
  }

  /// Creates a redirect response
  factory Response.redirect(
    String location, {
    int statusCode = 302,
    Map<String, String>? headers,
  }) {
    final mergedHeaders = {
      'location': location,
      ...?headers,
    };

    return Response._(
      statusCode: statusCode,
      headers: mergedHeaders,
      body: [],
      bodyStream: null,
    );
  }

  /// Creates an empty response (useful for 204 No Content, etc.)
  factory Response.empty({
    int statusCode = 204,
    Map<String, String>? headers,
  }) {
    return Response._(
      statusCode: statusCode,
      headers: headers ?? {},
      body: [],
      bodyStream: null,
    );
  }

  /// Creates an HTML response
  factory Response.html(
    String content, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    final mergedHeaders = {
      'content-type': 'text/html; charset=utf-8',
      ...?headers,
    };

    return Response._(
      statusCode: statusCode,
      headers: mergedHeaders,
      body: utf8.encode(content),
      bodyStream: null,
    );
  }

  /// Common status code responses
  static Response notFound([String message = 'Not Found']) {
    return Response.json(
      {'error': message},
      statusCode: 404,
    );
  }

  static Response badRequest([String message = 'Bad Request']) {
    return Response.json(
      {'error': message},
      statusCode: 400,
    );
  }

  static Response unauthorized([String message = 'Unauthorized']) {
    return Response.json(
      {'error': message},
      statusCode: 401,
    );
  }

  static Response forbidden([String message = 'Forbidden']) {
    return Response.json(
      {'error': message},
      statusCode: 403,
    );
  }

  static Response internalServerError([String message = 'Internal Server Error']) {
    return Response.json(
      {'error': message},
      statusCode: 500,
    );
  }

  /// Creates a new Response with updated properties
  ///
  /// This is used by middleware to modify responses (e.g., adding headers)
  Response copyWith({
    int? statusCode,
    Map<String, String>? headers,
    List<int>? body,
    Stream<List<int>>? bodyStream,
  }) {
    return Response._(
      statusCode: statusCode ?? this.statusCode,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      bodyStream: bodyStream ?? this.bodyStream,
    );
  }

  /// Merges additional headers into the response
  Response withHeaders(Map<String, String> additionalHeaders) {
    return copyWith(
      headers: {...headers, ...additionalHeaders},
    );
  }

  /// Writes this response to a dart:io HttpResponse
  Future<void> writeTo(HttpResponse httpResponse) async {
    httpResponse.statusCode = statusCode;

    // Set headers
    headers.forEach((key, value) {
      httpResponse.headers.set(key, value);
    });

    // Write body
    if (bodyStream != null) {
      await httpResponse.addStream(bodyStream!);
    } else if (body.isNotEmpty) {
      httpResponse.add(body);
    }

    await httpResponse.close();
  }

  @override
  String toString() {
    final bodyDescription =
        bodyStream != null ? 'stream' : '${body.length} bytes';
    return 'Response($statusCode, ${headers['content-type']}, $bodyDescription)';
  }
}
