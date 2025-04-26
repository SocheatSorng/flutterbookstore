import 'package:flutter/material.dart';
import 'package:flutterbookstore/services/api_service.dart';
import 'package:flutterbookstore/config/app_config.dart';

class ApiTestPage extends StatefulWidget {
  const ApiTestPage({Key? key}) : super(key: key);

  @override
  State<ApiTestPage> createState() => _ApiTestPageState();
}

class _ApiTestPageState extends State<ApiTestPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String _message = '';
  bool _success = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Key Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API Configuration',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8.0),
                    Text('API URL: ${AppConfig.apiBaseUrl}'),
                    const Divider(),
                    Text(
                      'API Key: ${AppConfig.apiKey.substring(0, 5)}...${AppConfig.apiKey.substring(AppConfig.apiKey.length - 5)}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _isLoading ? null : _testApiConnection,
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Test API Connection'),
            ),
            const SizedBox(height: 20.0),
            if (_message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: _success ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: _success ? Colors.green : Colors.red,
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _success ? 'Success!' : 'Error!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _success ? Colors.green[800] : Colors.red[800],
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(_message),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testApiConnection() async {
    setState(() {
      _isLoading = true;
      _message = '';
      _success = false;
    });

    try {
      final result = await _apiService.checkServerConnection();

      if (result['isConnected'] == true) {
        setState(() {
          _isLoading = false;
          _success = true;
          _message =
              'Successfully connected to the API server.\n'
              'Response Time: ${result['responseTime']}ms\n'
              'Status Code: ${result['statusCode']}';
        });
      } else {
        setState(() {
          _isLoading = false;
          _success = false;
          _message =
              'Failed to connect to the API server.\n'
              'Status Code: ${result['statusCode']}\n'
              'Error: ${result['error'] ?? 'Unknown error'}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _success = false;
        _message = 'Exception occurred: $e';
      });
    }
  }
}
