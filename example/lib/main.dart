import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dynalinks/dynalinks.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure SDK before runApp
  try {
    await Dynalinks.configure(
      clientAPIKey: const String.fromEnvironment(
        'DYNALINKS_API_KEY',
        defaultValue: 'your-api-key-here',
      ),
      logLevel: DynalinksLogLevel.debug,
      allowSimulatorOrEmulator: true, // Allow testing on simulator
    );
  } on DynalinksException catch (e) {
    debugPrint('Failed to configure Dynalinks: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynalinks Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DeepLinkPage(),
    );
  }
}

class DeepLinkPage extends StatefulWidget {
  const DeepLinkPage({super.key});

  @override
  State<DeepLinkPage> createState() => _DeepLinkPageState();
}

class _DeepLinkPageState extends State<DeepLinkPage> {
  DeepLinkResult? _result;
  String? _error;
  bool _isLoading = false;
  StreamSubscription<DeepLinkResult>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialLink();
    _listenForDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialLink() async {
    // Check for cold start link
    try {
      final initialLink = await Dynalinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLinkResult(initialLink);
        return;
      }
    } on DynalinksException catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Check for deferred deep link
    _checkForDeferredDeepLink();
  }

  void _listenForDeepLinks() {
    _linkSubscription = Dynalinks.onDeepLinkReceived.listen(
      _handleDeepLinkResult,
      onError: (error) {
        debugPrint('Deep link stream error: $error');
      },
    );
  }

  Future<void> _checkForDeferredDeepLink() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await Dynalinks.checkForDeferredDeepLink();
      _handleDeepLinkResult(result);
    } on SimulatorException {
      setState(() {
        _error = 'Deferred deep linking not available on simulator/emulator';
        _isLoading = false;
      });
    } on DynalinksException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  void _handleDeepLinkResult(DeepLinkResult result) {
    setState(() {
      _result = result;
      _isLoading = false;
      _error = null;
    });

    if (result.matched && result.link?.deepLinkValue != null) {
      _showDeepLinkDialog(result);
    }
  }

  void _showDeepLinkDialog(DeepLinkResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deep Link Received'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Navigate to: ${result.link?.deepLinkValue}'),
            if (result.confidence != null)
              Text('Confidence: ${result.confidence!.name}'),
            if (result.matchScore != null)
              Text('Score: ${result.matchScore}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Dynalinks Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SDK Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Version: ${Dynalinks.version}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Result/Error Card
            if (_isLoading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_error != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onErrorContainer,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_result != null)
              _buildResultCard()
            else
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No deep link result yet'),
                ),
              ),

            const SizedBox(height: 24),

            // Actions
            FilledButton.icon(
              onPressed: _checkForDeferredDeepLink,
              icon: const Icon(Icons.refresh),
              label: const Text('Check for Deferred Deep Link'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _result!;
    final link = result.link;

    return Card(
      color: result.matched
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.matched ? 'Match Found!' : 'No Match',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: result.matched
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : null,
                  ),
            ),
            const Divider(),
            _buildInfoRow('Matched', result.matched.toString()),
            if (result.confidence != null)
              _buildInfoRow('Confidence', result.confidence!.name),
            if (result.matchScore != null)
              _buildInfoRow('Score', result.matchScore.toString()),
            _buildInfoRow('Deferred', result.isDeferred.toString()),
            if (link != null) ...[
              const Divider(),
              Text(
                'Link Data',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _buildInfoRow('ID', link.id),
              if (link.name != null) _buildInfoRow('Name', link.name!),
              if (link.path != null) _buildInfoRow('Path', link.path!),
              if (link.deepLinkValue != null)
                _buildInfoRow('Deep Link Value', link.deepLinkValue!),
              if (link.fullUrl != null)
                _buildInfoRow('Full URL', link.fullUrl.toString()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
