import 'package:permission_handler/permission_handler.dart';
import 'package:sms_advanced/sms_advanced.dart';

class SmsService {
  final SmsQuery _query = SmsQuery();

  Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<bool> hasPermission() async {
    final status = await Permission.sms.status;
    return status.isGranted;
  }

  Future<List<SmsMessage>> getRecentMessages({int days = 30}) async {
    if (!await hasPermission()) {
      throw Exception('SMS permission not granted');
    }

    final messages = await _query.querySms(
      kinds: [SmsQueryKind.Inbox],
      count: 500,
    );

    // Filter messages from last N days
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    return messages.where((msg) {
      final msgDate = msg.date ?? DateTime.now();
      return msgDate.isAfter(cutoffDate);
    }).toList();
  }

  Future<List<SmsMessage>> getTransactionMessages({int days = 30}) async {
    final messages = await getRecentMessages(days: days);

    // Filter for transaction-related messages
    final transactionKeywords = [
      'debited',
      'credited',
      'transaction',
      'payment',
      'M-PESA',
      'mpesa',
      'sent to',
      'received from',
      'balance',
      'account',
    ];

    return messages.where((msg) {
      final body = msg.body?.toLowerCase() ?? '';
      return transactionKeywords
          .any((keyword) => body.contains(keyword.toLowerCase()));
    }).toList();
  }

  bool isExpenseMessage(String message) {
    final expenseKeywords = [
      'debited',
      'sent to',
      'paid to',
      'payment',
      'purchase',
      'withdrawal'
    ];
    final lowerMessage = message.toLowerCase();

    return expenseKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  Future<void> startListeningForNewMessages(
      Function(SmsMessage) onMessageReceived) async {
    if (!await hasPermission()) {
      throw Exception('SMS permission not granted');
    }

    final receiver = SmsReceiver();
    receiver.onSmsReceived?.listen((SmsMessage msg) {
      if (isExpenseMessage(msg.body ?? '')) {
        onMessageReceived(msg);
      }
    });
  }
}
