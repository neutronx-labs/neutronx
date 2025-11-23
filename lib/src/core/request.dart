import 'dart:convert';
import 'dart:io';

/// Represents an HTTP request in NeutronX.
///
/// This is the core request abstraction that wraps dart:io's HttpRequest
/// and provides a cleaner, more functional API.
///
/// Key features:
/// - Immutable request properties (method, uri, path, etc.)
/// - Lazy body parsing with caching
/// - Shared context map for middleware communication
/// - Path parameters and query string parsing
class Request {
  /// The underlying dart:io HttpRequest
  final HttpRequest _httpRequest;

  /// HTTP method (GET, POST, etc.)
  final String method;

  /// Full request URI
  final Uri uri;

  /// Path portion of the URI
  final String path;

  /// Path parameters extracted by the router (e.g., {':id': '123'})
  final Map<String, String> params;

  /// Query parameters from the URI
  final Map<String, String> query;

  /// Request headers
  final Map<String, String> headers;

  /// Request cookies
  final List<Cookie> cookies;

  /// Shared context for middleware to store data (e.g., authenticated user)
  final Map<String, dynamic> context;

  /// Cached body bytes to avoid multiple reads
  List<int>? _cachedBodyBytes;

  /// Cached parsed JSON body
  dynamic _cachedJson;

  Request._({
    required HttpRequest httpRequest,
    required this.method,
    required this.uri,
    required this.path,
    required this.params,
    required this.query,
    required this.headers,
    required this.cookies,
    Map<String, dynamic>? context,
  })  : _httpRequest = httpRequest,
        context = context ?? {};

  /// Creates a test Request without needing an HttpRequest.
  /// This is useful for unit testing handlers and middleware.
  Request.test({
    required this.method,
    required this.uri,
    required this.path,
    this.params = const {},
    this.query = const {},
    this.headers = const {},
    this.cookies = const [],
    Map<String, dynamic>? context,
    List<int>? bodyBytes,
  })  : _httpRequest = _MockHttpRequest._(),
        context = context ?? {},
        _cachedBodyBytes = bodyBytes;

  /// Creates a Request from a dart:io HttpRequest
  static Future<Request> fromHttpRequest(
    HttpRequest httpRequest, {
    Map<String, String>? params,
  }) async {
    final uri = httpRequest.uri;
    final headers = <String, String>{};

    httpRequest.headers.forEach((name, values) {
      headers[name.toLowerCase()] = values.join(', ');
    });

    final query = <String, String>{};
    uri.queryParameters.forEach((key, value) {
      query[key] = value;
    });

    return Request._(
      httpRequest: httpRequest,
      method: httpRequest.method.toUpperCase(),
      uri: uri,
      path: uri.path,
      params: params ?? {},
      query: query,
      headers: headers,
      cookies: httpRequest.cookies,
    );
  }

  /// Returns the raw body bytes.
  ///
  /// This method caches the result so subsequent calls return the same bytes
  /// without re-reading the request body.
  Future<List<int>> bodyBytes() async {
    _cachedBodyBytes ??= await _httpRequest.fold<List<int>>(
      [],
      (previous, element) => previous..addAll(element),
    );
    return _cachedBodyBytes!;
  }

  /// Returns the body as a UTF-8 decoded string
  Future<String> body() async {
    final bytes = await bodyBytes();
    return utf8.decode(bytes);
  }

  /// Parses the body as JSON and returns a dynamic result
  Future<dynamic> json() async {
    if (_cachedJson != null) {
      return _cachedJson;
    }

    final bodyString = await body();
    if (bodyString.isEmpty) {
      _cachedJson = null;
      return _cachedJson;
    }

    try {
      _cachedJson = jsonDecode(bodyString);
      return _cachedJson;
    } catch (e) {
      throw FormatException('Failed to parse JSON body: $e');
    }
  }

  /// Parses the body as JSON and attempts to deserialize it using the provided
  /// factory function.
  ///
  /// This is useful for type-safe DTO deserialization:
  /// ```dart
  /// final userDto = await req.parseJson<UserDto>(
  ///   (json) => UserDto.fromJson(json as Map<String, dynamic>)
  /// );
  /// ```
  Future<T> parseJson<T>(T Function(dynamic) fromJson) async {
    final jsonData = await json();
    if (jsonData == null) {
      throw FormatException('Request body is empty, cannot parse as $T');
    }
    return fromJson(jsonData);
  }

  /// Returns a new Request with updated path parameters.
  ///
  /// This is used internally by the router to inject matched parameters.
  Request copyWith({
    String? path,
    Map<String, String>? params,
    Map<String, dynamic>? context,
  }) {
    return Request._(
      httpRequest: _httpRequest,
      method: method,
      uri: uri,
      path: path ?? this.path,
      params: params ?? this.params,
      query: query,
      headers: headers,
      cookies: cookies,
      context: context ?? this.context,
    );
  }

  /// Convenience getter for Content-Type header
  String? get contentType => headers['content-type'];

  /// Convenience getter for Authorization header
  String? get authorization => headers['authorization'];

  /// Checks if the request is a JSON request
  bool get isJson => contentType?.contains('application/json') ?? false;

  /// Checks if the request is a form data request
  bool get isForm => contentType?.contains('application/x-www-form-urlencoded') ?? false;

  /// Checks if the request is multipart form data
  bool get isMultipart => contentType?.contains('multipart/form-data') ?? false;

  @override
  String toString() {
    return 'Request($method $path)';
  }
}

/// Mock HttpRequest for testing purposes
class _MockHttpRequest implements HttpRequest {
  _MockHttpRequest._();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
        'This is a mock HttpRequest for testing. '
        'The method ${invocation.memberName} should not be called directly. '
        'Use Request.test() constructor for creating test requests.',
      );
}
