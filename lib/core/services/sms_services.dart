import 'package:another_telephony/telephony.dart';

class SmsServices {
  final Telephony _telephony = Telephony.instance;
  final List<String> _targetSenders = []; // Add phone numbers to monitor
  final List<String> _keywords = []; // Add keywords to look for in messages

  // Callback when a matching SMS is received
  final Function(SmsMessage)? onSmsReceived;

  SmsServices({this.onSmsReceived});

  // Initialize the SMS monitoring
  Future<bool> initialize() async {
    final granted = await _telephony.requestSmsPermissions ?? false;
    if (!granted) {
      return false;
    }

    _telephony.listenIncomingSms(
      listenInBackground: false,
      onNewMessage: (SmsMessage msg) {
        if (_isTargetMessage(msg)) {
          onSmsReceived?.call(msg);
        }
      },
    );

    return true;
  }

  // Check if the message matches our criteria
  bool _isTargetMessage(SmsMessage message) {
    final sender = message.address ?? '';
    final body = message.body?.toLowerCase() ?? '';
    
    final isFromTargetSender = _targetSenders.isEmpty || 
        _targetSenders.any((senderPattern) => sender.contains(senderPattern));
    
    final containsKeyword = _keywords.isEmpty || 
        _keywords.any((keyword) => body.contains(keyword.toLowerCase()));

    return isFromTargetSender && containsKeyword;
  }

  // Fetch recent messages (optional)
  Future<List<SmsMessage>> getRecentMessages({
    int limit = 10,
    List<String>? senders,
    List<String>? keywords,
  }) async {
    final messages = await _telephony.getInboxSms(
      columns: [
        SmsColumn.ADDRESS,
        SmsColumn.BODY,
        SmsColumn.DATE,
      ],
    );

    final filtered = messages.where((msg) {
      if (senders != null && senders.isNotEmpty) {
        final sender = msg.address ?? '';
        if (!senders.any((s) => sender.contains(s))) {
          return false;
        }
      }
      if (keywords != null && keywords.isNotEmpty) {
        final body = msg.body?.toLowerCase() ?? '';
        if (!keywords.any((k) => body.contains(k.toLowerCase()))) {
          return false;
        }
      }
      return true;
    }).toList();

    if (filtered.length <= limit) return filtered;
    return filtered.take(limit).toList();
  }

  // Add a sender to monitor
  void addTargetSender(String sender) {
    if (!_targetSenders.contains(sender)) {
      _targetSenders.add(sender);
    }
  }

  // Add a keyword to monitor
  void addKeyword(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    if (!_keywords.contains(lowerKeyword)) {
      _keywords.add(lowerKeyword);
    }
  }

  // Clean up
  void dispose() {
    // another_telephony doesn't return a StreamSubscription for listenIncomingSms.
    // If you need start/stop listening, we can add a flag and ignore callbacks.
  }
}