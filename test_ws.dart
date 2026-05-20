import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/io.dart';

const API_KEY = 'sk-103ddf012c494f5099a10ec41f171253';
const WS_URL = 'wss://dashscope.aliyuncs.com/api-ws/v1/inference/';

String generateTaskId() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random();
  return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
}

void main() async {
  print('Testing DashScope WebSocket with Fun-ASR...');
  print('API Key: ' + API_KEY.substring(0, 10) + '...');

  final taskId = generateTaskId();
  print('Task ID: ' + taskId);

  try {
    final channel = IOWebSocketChannel.connect(
      Uri.parse(WS_URL),
      headers: {
        'Authorization': 'Bearer ' + API_KEY,
      },
    );

    print('WebSocket connected!');

    final runTaskMessage = {
      'header': {
        'action': 'run-task',
        'task_id': taskId,
        'streaming': 'duplex',
      },
      'payload': {
        'task_group': 'audio',
        'task': 'asr',
        'function': 'recognition',
        'model': 'fun-asr-realtime',
        'parameters': {
          'sample_rate': 16000,
          'format': 'wav',
        },
        'input': {},
      },
    };

    print('Sending run-task: ' + jsonEncode(runTaskMessage));
    channel.sink.add(jsonEncode(runTaskMessage));

    await for (final message in channel.stream) {
      print('Received: ' + message.toString());

      try {
        final data = jsonDecode(message as String) as Map<String, dynamic>;
        final event = data['header']?['event'] as String?;
        print('Event: ' + (event ?? 'null'));

        if (event == 'task-started') {
          print('Task started! Sending finish-task...');
          final finishTaskMessage = {
            'header': {
              'action': 'finish-task',
              'task_id': taskId,
              'streaming': 'duplex',
            },
            'payload': {
              'input': {},
            },
          };
          channel.sink.add(jsonEncode(finishTaskMessage));
        }

        if (event == 'task-finished') {
          print('Task finished successfully!');
          break;
        }

        if (event == 'task-failed') {
          final error = data['header']?['error_message'] ?? 'Unknown error';
          print('Task failed: ' + error);
          break;
        }
      } catch (e) {
        print('Parse error: ' + e.toString());
      }
    }

    channel.sink.close();
    print('Connection closed');
  } catch (e) {
    print('Error: ' + e.toString());
  }
}
