import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../focus/providers/focus_provider.dart';

class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = false;
  Timer? _refreshTimer;
  StreamSubscription? _blockingSubscription;

  @override
  void initState() {
    super.initState();
    _refreshEvents();
    // Auto-refresh periodic usage stats (historical)
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refreshEvents(),
    );

    // Listen to real-time decisions from native service
    final blockingService = ref.read(blockingServiceProvider);
    _blockingSubscription = blockingService.blockingEventsStream.listen((
      event,
    ) {
      if (event is Map) {
        final pkg = event['packageName'] as String?;
        final isBlocked = event['isBlocked'] as bool?;
        if (pkg != null) {
          if (mounted) {
            setState(() {
              // Insert real-time event at top
              _events.insert(0, {
                'packageName': pkg,
                'eventType': 999, // Custom type for real-time decision
                'timestamp': DateTime.now().millisecondsSinceEpoch,
                'isBlocked': isBlocked,
              });
              if (_events.length > 50) _events.removeLast();
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _blockingSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshEvents() async {
    // Avoid showing loading spinner on periodic refresh to prevent flickering
    if (_events.isEmpty) {
      setState(() => _isLoading = true);
    }

    final blockingService = ref.read(blockingServiceProvider);
    final events = await blockingService.getRecentUsageEvents();

    if (mounted) {
      setState(() => _events = events);
      if (_isLoading) setState(() => _isLoading = false);
    }
  }

  String _formatTimestamp(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  String _getEventName(int type) {
    switch (type) {
      case 1:
        return 'RESUMED';
      case 2:
        return 'PAUSED';
      case 7:
        return 'USER_INTERACTION';
      case 999:
        return 'DETECTED';
      default:
        return 'TYPE_$type';
    }
  }

  Color _getEventColor(int type, {bool? isBlocked}) {
    if (type == 999) {
      if (isBlocked == true) return Colors.red;
      return Colors.green;
    }

    switch (type) {
      case 1:
        return Colors.green; // RESUMED
      case 2:
        return Colors.orange; // PAUSED
      case 7:
        return Colors.blue; // USER_INTERACTION
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshEvents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Last 2 minutes of Usage Events (Auto-refresh: 2s)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref.read(blockingServiceProvider).testBlockingOverlay();
                      },
                      icon: const Icon(Icons.layers_clear),
                      label: const Text('Test Blocking Overlay (Force)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      final pkg = event['packageName'] as String;
                      final type = event['eventType'] as int;
                      final timestamp = event['timestamp'] as int;
                      final isBlocked = event['isBlocked'] as bool?;

                      String statusText = _getEventName(type);
                      if (type == 999) {
                        statusText = isBlocked == true
                            ? 'BLOCKED ⛔'
                            : 'ALLOWED ✅';
                      }

                      return ListTile(
                        leading: Text(
                          _formatTimestamp(timestamp),
                          style: const TextStyle(fontSize: 12),
                        ),
                        title: Text(
                          pkg,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          statusText,
                          style: TextStyle(
                            color: _getEventColor(type, isBlocked: isBlocked),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        dense: true,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
