import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

class AliyunSigner {
  final String accessKeyId;
  final String accessKeySecret;

  AliyunSigner({
    required this.accessKeyId,
    required this.accessKeySecret,
  });

  /// V2 ROA 风格签名 - 为请求生成 Authorization 头
  ///
  /// 通义听悟使用 V2 ROA 签名机制
  /// 参考文档: https://help.aliyun.com/zh/sdk/product-overview/roa-mechanism
  ///
  /// [method] HTTP 方法: GET, PUT, POST, DELETE
  /// [path] URL 路径, 如 /openapi/tingwu/v2/tasks
  /// [queryParams] URL 查询参数
  /// [body] 请求体
  /// [contentType] Content-Type, 默认 application/json
  /// [apiVersion] API 版本, 如 2023-09-30
  Map<String, String> signRoaRequest({
    required String method,
    required String path,
    Map<String, dynamic>? queryParams,
    String? body,
    String contentType = 'application/json',
    String apiVersion = '2023-09-30',
  }) {
    final now = HttpDate.format(DateTime.now().toUtc());
    final nonce = _generateNonce();

    final contentMd5 = body != null && body.isNotEmpty
        ? base64Encode(md5.convert(utf8.encode(body)).bytes)
        : '';

    final canonicalizedHeaders = _buildCanonicalizedHeaders({
      'x-acs-signature-method': 'HMAC-SHA1',
      'x-acs-signature-nonce': nonce,
      'x-acs-signature-version': '1.0',
      'x-acs-version': apiVersion,
    });

    final canonicalizedResource = _buildCanonicalizedResource(path, queryParams);

    final stringToSign = StringBuffer();
    stringToSign.write('$method\n');
    stringToSign.write('application/json\n');
    stringToSign.write('$contentMd5\n');
    stringToSign.write('$contentType\n');
    stringToSign.write('$now\n');
    stringToSign.write(canonicalizedHeaders);
    stringToSign.write(canonicalizedResource);

    final signature = _hmacSha1(stringToSign.toString());
    final authorization = 'acs $accessKeyId:$signature';

    return {
      'Authorization': authorization,
      'Date': now,
      'Content-MD5': contentMd5,
      'Content-Type': contentType,
      'x-acs-signature-method': 'HMAC-SHA1',
      'x-acs-signature-nonce': nonce,
      'x-acs-signature-version': '1.0',
      'x-acs-version': apiVersion,
      'Accept': 'application/json',
    };
  }

  String _buildCanonicalizedHeaders(Map<String, String> headers) {
    final sortedKeys = headers.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final buffer = StringBuffer();
    for (final key in sortedKeys) {
      buffer.write('${key.toLowerCase()}:${headers[key]}\n');
    }
    return buffer.toString();
  }

  String _buildCanonicalizedResource(String path, Map<String, dynamic>? queryParams) {
    if (queryParams == null || queryParams.isEmpty) {
      return path;
    }

    final sortedKeys = queryParams.keys.toList()..sort();
    final pairs = sortedKeys.map((key) {
      final encodedKey = _percentEncode(key);
      final encodedValue = _percentEncode(queryParams[key].toString());
      return '$encodedKey=$encodedValue';
    }).toList();

    return '$path?${pairs.join('&')}';
  }

  String _hmacSha1(String stringToSign) {
    final key = utf8.encode(accessKeySecret);
    final bytes = utf8.encode(stringToSign);
    final hmacObj = Hmac(sha1, key);
    final digest = hmacObj.convert(bytes);
    return base64Encode(digest.bytes);
  }

  String _percentEncode(String value) {
    String encoded = Uri.encodeComponent(value);
    encoded = encoded.replaceAll('+', '%20');
    encoded = encoded.replaceAll('*', '%2A');
    encoded = encoded.replaceAll('%7E', '~');
    return encoded;
  }

  String _generateNonce() {
    return '${DateTime.now().millisecondsSinceEpoch}-${_randomString(8)}';
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(chars[DateTime.now().microsecond % chars.length]);
    }
    return buffer.toString();
  }
}

class AliyunSignatureInterceptor extends Interceptor {
  final AliyunSigner _signer;

  AliyunSignatureInterceptor({
    required String accessKeyId,
    required String accessKeySecret,
  }) : _signer = AliyunSigner(
          accessKeyId: accessKeyId,
          accessKeySecret: accessKeySecret,
        );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!options.uri.host.contains('tingwu')) {
      handler.next(options);
      return;
    }

    final body = options.data?.toString();
    final signedHeaders = _signer.signRoaRequest(
      method: options.method,
      path: options.uri.path,
      queryParams: options.queryParameters.isNotEmpty
          ? Map<String, dynamic>.from(options.queryParameters)
          : null,
      body: body,
    );

    options.headers.addAll(signedHeaders);

    handler.next(options);
  }
}
