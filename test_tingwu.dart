import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

/// 通义听悟 API 连通性测试脚本
///
/// 使用方法:
/// 1. 确保已安装 Dart SDK
/// 2. 运行: dart test_tingwu.dart
///
/// 注意: 需要在代码中填入你的 AccessKey 和 AppKey

void main() async {
  print('=== 通义听悟 API 连通性测试 ===\n');

  // ============================================
  // 配置区域 - 请填入你的密钥
  // ============================================
  const String accessKeyId = 'YOUR_ACCESS_KEY_ID';     // 阿里云 AccessKey ID
  const String accessKeySecret = 'YOUR_ACCESS_KEY_SECRET'; // 阿里云 AccessKey Secret
  const String appKey = 'YOUR_APP_KEY';                   // 通义听悟 AppKey

  if (accessKeyId == 'YOUR_ACCESS_KEY_ID') {
    print('❌ 错误: 请先配置你的阿里云 AccessKey');
    print('   请修改脚本中的 accessKeyId 和 accessKeySecret 变量');
    exit(1);
  }

  final dio = Dio();
  final baseUrl = 'https://tingwu.cn-beijing.aliyuncs.com';

  // 1. 测试签名生成
  print('1. 测试签名生成...');
  try {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final nonce = DateTime.now().millisecondsSinceEpoch.toString();

    final params = {
      'AccessKeyId': accessKeyId,
      'Action': 'CreateTask',
      'Version': '2023-09-30',
      'Timestamp': timestamp,
      'SignatureMethod': 'HMAC-SHA1',
      'SignatureVersion': '1.0',
      'SignatureNonce': nonce,
      'Format': 'JSON',
    };

    // 构建签名字符串
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    final canonicalQueryString = sortedParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final stringToSign = 'GET&${Uri.encodeComponent('/')}&${Uri.encodeComponent(canonicalQueryString)}';

    // HMAC-SHA1 签名
    final key = utf8.encode('$accessKeySecret&');
    final bytes = utf8.encode(stringToSign);
    // 注意: 这里需要 crypto 包，测试脚本中简化处理
    print('   签名字符串: ${stringToSign.substring(0, 50)}...');
    print('   ✅ 签名参数构建成功');
  } catch (e) {
    print('   ❌ 签名生成失败: $e');
  }

  // 2. 测试 API 连通性（使用简单 GET 请求）
  print('\n2. 测试 API 连通性...');
  try {
    // 尝试访问通义听悟 API 根路径
    final response = await dio.get(
      baseUrl,
      options: Options(
        validateStatus: (status) => true, // 接受任何状态码
      ),
    );
    print('   状态码: ${response.statusCode}');
    print('   响应: ${response.data.toString().substring(0, 100)}...');
    print('   ✅ API 可访问');
  } catch (e) {
    print('   ⚠️ 连接测试: $e');
    print('   注意: 可能需要正确的签名才能访问');
  }

  // 3. 测试提交任务（需要正确的签名）
  print('\n3. 测试提交转写任务...');
  print('   注意: 此步骤需要正确的阿里云签名');
  print('   请参考阿里云文档: https://help.aliyun.com/document_detail/2619237.html');

  // 4. 提供测试建议
  print('\n=== 测试建议 ===');
  print('1. 确保阿里云账号已开通通义听悟服务');
  print('2. 在通义听悟控制台创建项目并获取 AppKey');
  print('3. 使用阿里云 SDK 或正确的签名算法调用 API');
  print('4. 测试音频文件需要是公网可访问的 URL');
  print('\n=== 推荐测试方式 ===');
  print('方式1: 使用阿里云 OpenAPI Explorer');
  print('   地址: https://api.aliyun.com/?spm=a2c4g.460666.0.0.14642af6DtQnE5');
  print('   优点: 无需编写代码，可视化测试');
  print('\n方式2: 使用阿里云 SDK');
  print('   安装: npm install @alicloud/tingwu20230930');
  print('   优点: 自动处理签名，简化调用');
  print('\n方式3: 在 App 中配置后测试');
  print('   在设置页面选择"通义听悟"，填入 AppKey');
  print('   录音后选择"通义听悟转写"进行测试');

  print('\n=== 配置检查清单 ===');
  print('□ 阿里云账号已注册');
  print('□ 已开通通义听悟服务');
  print('□ 已创建项目并获取 AppKey');
  print('□ AccessKey 有调用权限');
  print('□ 账户有余额或免费额度未用完');
}
