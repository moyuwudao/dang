import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'app_logger.dart';

enum NetworkStatus {
  connected,
  disconnected,
  connecting,
}

class NetworkService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _subscription;
  NetworkStatus _status = NetworkStatus.connecting;

  NetworkStatus get status => _status;
  bool get isConnected => _status == NetworkStatus.connected;

  NetworkService() {
    _initConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateStatus(result);
    } catch (e) {
      AppLogger().e('Network', 'Failed to check connectivity: $e');
      _status = NetworkStatus.disconnected;
    }
    notifyListeners();
  }

  void _updateStatus(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.mobile:
      case ConnectivityResult.ethernet:
        _status = NetworkStatus.connected;
        break;
      case ConnectivityResult.none:
        _status = NetworkStatus.disconnected;
        break;
      default:
        _status = NetworkStatus.connecting;
    }
    notifyListeners();
  }

  Future<bool> checkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      AppLogger().e('Network', 'Failed to check connection: $e');
      return false;
    }
  }

  void showConnectionError(BuildContext context) {
    if (_status == NetworkStatus.disconnected) {
      _showErrorToast(context);
    }
  }

  void _showErrorToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(
              Icons.wifi_off,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text('网络连接已断开，请检查网络设置'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFdc2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final networkServiceProvider = Provider<NetworkService>((ref) {
  final service = NetworkService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});