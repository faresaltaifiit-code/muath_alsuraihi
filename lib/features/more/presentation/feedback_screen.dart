import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  static const endpoint = String.fromEnvironment('FEEDBACK_ENDPOINT');
  final _message = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _message.text.trim();
    if (message.isEmpty || message.length > 2000) {
      setState(() => _error = 'اكتب ملاحظتك، بحد أقصى ٢٠٠٠ حرف.');
      return;
    }
    if (endpoint.isEmpty) {
      setState(() => _error = 'خدمة الملاحظات غير متاحة حاليًا.');
      return;
    }
    setState(() { _sending = true; _error = null; });
    try {
      final result = await http.post(Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message})).timeout(const Duration(seconds: 20));
      final data = jsonDecode(result.body);
      if (result.statusCode != 200 || data is! Map || data['ok'] != true) {
        throw StateError('send failed');
      }
      if (!mounted) return;
      _message.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شكرًا، تم إرسال ملاحظتك.')));
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر إرسال الملاحظة. تحقق من الاتصال وحاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الملاحظات والاقتراحات')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Text('شاركنا اقتراحك أو المشكلة التي واجهتك.', style: Theme.of(context).textTheme.bodyLarge),
      const SizedBox(height: 16),
      TextField(controller: _message, maxLength: 2000, minLines: 5, maxLines: 8,
        enabled: !_sending, textInputAction: TextInputAction.newline,
        decoration: const InputDecoration(labelText: 'اكتب ملاحظتك هنا', border: OutlineInputBorder())),
      const Text('ستُرسل ملاحظتك إلى فريق التطبيق. لا تكتب معلومات حساسة.'),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 12),
        child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
      const SizedBox(height: 16),
      FilledButton(onPressed: _sending ? null : _send,
        child: Text(_sending ? 'جارٍ الإرسال…' : 'إرسال')),
    ]),
  );
}
