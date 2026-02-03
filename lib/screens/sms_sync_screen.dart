import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sms_advanced/sms_advanced.dart';
import '../services/sms_service.dart';
import '../providers/expense_provider.dart';

class SmsSyncScreen extends StatefulWidget {
  const SmsSyncScreen({Key? key}) : super(key: key);

  @override
  State<SmsSyncScreen> createState() => _SmsSyncScreenState();
}

class _SmsSyncScreenState extends State<SmsSyncScreen> {
  final SmsService _smsService = SmsService();
  List<SmsMessage> _messages = [];
  bool _isLoading = false;
  bool _hasPermission = false;
  int _syncedCount = 0;
  int _failedCount = 0;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await _smsService.hasPermission();
    setState(() {
      _hasPermission = hasPermission;
    });

    if (hasPermission) {
      _loadMessages();
    }
  }

  Future<void> _requestPermission() async {
    final granted = await _smsService.requestPermission();
    setState(() {
      _hasPermission = granted;
    });

    if (granted) {
      _loadMessages();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMS permission is required to read messages'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messages = await _smsService.getTransactionMessages(days: 30);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading messages: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _syncMessages() async {
    if (_messages.isEmpty) return;

    setState(() {
      _isLoading = true;
      _syncedCount = 0;
      _failedCount = 0;
    });

    final expenseProvider =
        Provider.of<ExpenseProvider>(context, listen: false);

    for (final message in _messages) {
      if (!_smsService.isExpenseMessage(message.body ?? '')) {
        continue;
      }

      try {
        final success =
            await expenseProvider.parseAndStoreExpense(message.body ?? '');
        if (success) {
          setState(() {
            _syncedCount++;
          });
        } else {
          setState(() {
            _failedCount++;
          });
        }
      } catch (e) {
        setState(() {
          _failedCount++;
        });
      }
    }

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sync Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Synced: $_syncedCount expenses'),
              Text('Failed: $_failedCount messages'),
              Text('Total processed: ${_syncedCount + _failedCount}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to home screen
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _syncSingleMessage(SmsMessage message) async {
    final expenseProvider =
        Provider.of<ExpenseProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      final success =
          await expenseProvider.parseAndStoreExpense(message.body ?? '');

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Expense added successfully'
                : 'Failed to add expense'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync SMS Messages'),
        actions: [
          if (_hasPermission && _messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: _isLoading ? null : _syncMessages,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_hasPermission) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.sms_outlined,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              const Text(
                'SMS Permission Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'This app needs permission to read your SMS messages to automatically track expenses from bank and mobile money notifications.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _requestPermission,
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading && _messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'No Transaction Messages',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No transaction messages found in the last 30 days.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Found ${_messages.length} transaction messages. Tap "Sync All" to add them as expenses.',
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        if (_isLoading)
          LinearProgressIndicator(
            value: _syncedCount > 0 || _failedCount > 0
                ? (_syncedCount + _failedCount) / _messages.length
                : null,
          ),
        Expanded(
          child: ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final isExpense =
                  _smsService.isExpenseMessage(message.body ?? '');

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isExpense ? Colors.red[100] : Colors.green[100],
                    child: Icon(
                      isExpense ? Icons.remove : Icons.add,
                      color: isExpense ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Text(
                    message.address ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        message.body ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message.date?.toString() ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  trailing: isExpense
                      ? IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _isLoading
                              ? null
                              : () => _syncSingleMessage(message),
                        )
                      : null,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(message.address ?? 'Message'),
                        content: SingleChildScrollView(
                          child: Text(message.body ?? ''),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                          if (isExpense)
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _syncSingleMessage(message);
                              },
                              child: const Text('Add as Expense'),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
