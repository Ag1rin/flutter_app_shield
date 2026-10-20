import 'package:flutter/material.dart';
import 'package:flutter_app_shield/flutter_app_shield.dart';

void main() {
  runApp(const MyExampleApp());
}

class MyExampleApp extends StatefulWidget {
  const MyExampleApp({super.key});

  @override
  State<MyExampleApp> createState() => _MyExampleAppState();
}

class _MyExampleAppState extends State<MyExampleApp> {
  final _controller = AppShieldController();
  final _events = <String>[];

  void _log(String message) {
    final stamp = DateTime.now().toIso8601String().substring(11, 19);
    setState(() {
      _events.insert(0, '$stamp  $message');
      if (_events.length > 20) _events.removeLast();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShield(
      controller: _controller,
      preventScreenshot: true,
      requireAuthOnResume: true,
      requireAuthOnLaunch: false,
      inactivityTimeout: const Duration(seconds: 45),
      blockOnJailbreak: false,
      blockOnDeveloperMode: false,
      listenToCaptureEvents: true,
      blurAmount: 30.0,
      opacity: 0.85,
      onScreenshot: (e) => _log('Screenshot detected'),
      onScreenRecordingStarted: (e) => _log('Recording started'),
      onScreenRecordingStopped: (e) => _log('Recording stopped'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter App Shield Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: DemoHome(controller: _controller, events: _events, onLog: _log),
      ),
    );
  }
}

class DemoHome extends StatelessWidget {
  const DemoHome({
    super.key,
    required this.controller,
    required this.events,
    required this.onLog,
  });

  final AppShieldController controller;
  final List<String> events;
  final void Function(String message) onLog;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Shield 0.2 Demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            leading: Icon(Icons.shield, color: Colors.indigo, size: 40),
            title: Text('Protected demo'),
            subtitle: Text(
              'Try screenshots, background the app, or wait for auto-lock.',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () async {
                  await controller.lock();
                  onLog('Locked via controller');
                },
                icon: const Icon(Icons.lock),
                label: const Text('Lock'),
              ),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final ok = await controller.unlock();
                  onLog(ok ? 'Unlocked' : 'Unlock failed');
                },
                icon: const Icon(Icons.lock_open),
                label: const Text('Unlock'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final enabled = !controller.isScreenshotPreventionEnabled;
                  await controller.setScreenshotPrevention(enabled);
                  onLog(
                    enabled
                        ? 'Screenshot prevention ON'
                        : 'Screenshot prevention OFF',
                  );
                },
                icon: const Icon(Icons.phonelink_lock),
                label: const Text('Toggle screenshots'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SensitivePage(),
                    ),
                  );
                },
                icon: const Icon(Icons.security),
                label: const Text('SecureScope page'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Event log', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (events.isEmpty)
            const Text('No capture events yet.')
          else
            ...events.map(
              (e) => ListTile(
                dense: true,
                leading: const Icon(Icons.circle, size: 10),
                title: Text(e),
              ),
            ),
        ],
      ),
    );
  }
}

class SensitivePage extends StatelessWidget {
  const SensitivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SecureScope(
      preventScreenshot: true,
      child: Scaffold(
        appBar: AppBar(title: const Text('Sensitive page')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'This route is wrapped in SecureScope.\n'
              'Screenshot prevention stays on while nested scopes are mounted.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
