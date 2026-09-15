import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});
  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _faqSearch = TextEditingController();
  final _subject = TextEditingController();
  final _description = TextEditingController();
  late final ApiClient _api;
  Map<String, dynamic> _config = {};
  List<Map<String, dynamic>> _faqs = [];
  List<Map<String, dynamic>> _tickets = [];
  Set<int> _expanded = {};
  bool _loading = true;
  bool _submitting = false;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _api = getIt<ApiClient>();
    _load();
  }

  @override
  void dispose() {
    _faqSearch.dispose();
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _load({String? search}) async {
    setState(() => _loading = true);
    try {
      final responses = await Future.wait([
        _api.get<dynamic>('/help/config'),
        _api.get<dynamic>('/help/faqs',
            query: search?.trim().isNotEmpty == true
                ? {'search': search!.trim()}
                : null),
        _api.get<dynamic>('/help/tickets'),
      ]);
      if (!mounted) return;
      setState(() {
        _config = _map(responses[0].data);
        _faqs = _list(responses[1].data);
        _tickets = _list(responses[2].data);
        _loading = false;
        _notice = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _config = _fallbackConfig;
        _faqs = _fallbackFaqs;
        _tickets = [];
        _loading = false;
        _notice = 'Some live support data could not be loaded.';
      });
    }
  }

  Future<void> _chat() async {
    try {
      final response = await _api.post<dynamic>('/help/chat/sessions');
      if (!mounted) return;
      final data = _map(response.data);
      await showDialog<void>(
          context: context,
          builder: (_) => _ChatDialog(
              api: _api,
              sessionId: '${data['sessionId'] ?? ''}',
              messages: _list(data['messages'])));
      _load();
    } catch (_) {
      _message('Live chat is unavailable. Please call or email support.');
    }
  }

  Future<void> _submitTicket() async {
    if (_subject.text.trim().isEmpty || _description.text.trim().length < 10) {
      _message(
          'Add a subject and at least 10 characters describing the issue.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await _api.post<dynamic>('/help/tickets', data: {
        'subject': _subject.text.trim(),
        'description': _description.text.trim(),
        'priority': 'Normal'
      });
      if (!mounted) return;
      _subject.clear();
      _description.clear();
      Navigator.pop(context);
      _message('Support case created.');
      _load();
    } catch (_) {
      _message('Unable to create the support case. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _newTicket() {
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Create support case', style: AppTextStyles.h4),
                const SizedBox(height: 16),
                TextField(
                    controller: _subject,
                    decoration: const InputDecoration(labelText: 'Subject')),
                const SizedBox(height: 12),
                TextField(
                    controller: _description,
                    maxLines: 5,
                    decoration:
                        const InputDecoration(labelText: 'How can we help?')),
                const SizedBox(height: 16),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                        onPressed: _submitting ? null : _submitTicket,
                        child: _submitting
                            ? const CircularProgressIndicator()
                            : const Text('Submit case'))),
              ]),
            ));
  }

  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _value(String key, String fallback) => '${_config[key] ?? fallback}';
  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : {};
  static List<Map<String, dynamic>> _list(dynamic value) => value is List
      ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
      : [];

  @override
  Widget build(BuildContext context) {
    final phone = _value('phone', '+44 20 1234 5678');
    final email = _value('email', 'support@carltonleisure.com');
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                if (_notice != null) _noticeBox(_notice!),
                Text('How can we help?', style: AppTextStyles.h3),
                Text('Find answers or contact our support team.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                      child: _contact(Icons.chat_bubble_outline, 'Live Chat',
                          'Instant help', _chat)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _contact(Icons.phone_outlined, 'Call Us', phone,
                          () => _message('Call us at $phone'))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _contact(Icons.email_outlined, 'Email', email,
                          () => _message('Email us at $email')))
                ]),
                const SizedBox(height: 12),
                _section(
                    'Search FAQs',
                    Icons.search,
                    TextField(
                        controller: _faqSearch,
                        onSubmitted: (value) => _load(search: value),
                        decoration: const InputDecoration(
                            hintText: 'Search for help...',
                            prefixIcon: Icon(Icons.search)))),
                const SizedBox(height: 12),
                _section(
                    'My Support Cases',
                    Icons.assignment_outlined,
                    Column(children: [
                      if (_tickets.isEmpty)
                        const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('You have no support cases yet.')),
                      ..._tickets.map((ticket) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                              Icons.confirmation_number_outlined,
                              color: AppColors.primary),
                          title: Text(
                              '${ticket['ticketNumber'] ?? ticket['subject'] ?? 'Support case'}'),
                          subtitle: Text(
                              '${ticket['status'] ?? 'Open'} · ${ticket['createdAt'] ?? ''}'))),
                      SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                              onPressed: _newTicket,
                              icon: const Icon(Icons.add),
                              label: const Text('Create support case'))),
                    ])),
                const SizedBox(height: 12),
                _section('Frequently Asked Questions', Icons.help_outline,
                    Column(children: _faqs.map(_faq).toList())),
                const SizedBox(height: 12),
                _section(
                    'Support hours',
                    Icons.schedule_outlined,
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_value('phoneHoursWeekday',
                              'Monday - Friday: 8:00 AM - 8:00 PM GMT')),
                          Text(_value('phoneHoursWeekend',
                              'Saturday - Sunday: 9:00 AM - 6:00 PM GMT')),
                          const SizedBox(height: 8),
                          Text(_value('liveChatHours', 'Available 24/7')),
                          Text(_value('liveChatResponseTime',
                              'Average response time: < 2 minutes'))
                        ])),
              ]),
            ),
    );
  }

  Widget _contact(
          IconData icon, String title, String detail, VoidCallback onTap) =>
      Card(
          child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(children: [
                    Icon(icon, color: AppColors.primary),
                    const SizedBox(height: 6),
                    Text(title,
                        style: AppTextStyles.bodySmall
                            .copyWith(fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center),
                    Text(detail,
                        style: AppTextStyles.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center)
                  ]))));
  Widget _section(String title, IconData icon, Widget child) => Card(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.h4)
            ]),
            const SizedBox(height: 14),
            child
          ])));
  Widget _noticeBox(String text) => Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.16),
          borderRadius: BorderRadius.circular(12)),
      child: Text(text));
  Widget _faq(Map<String, dynamic> item) {
    final id = int.tryParse('${item['id'] ?? 0}') ?? 0;
    return ExpansionTile(
        title: Text('${item['question'] ?? ''}',
            style:
                AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text('${item['category'] ?? 'General'}',
            style: AppTextStyles.caption),
        initiallyExpanded: _expanded.contains(id),
        onExpansionChanged: (open) => setState(() {
              if (open) {
                _expanded.add(id);
              } else {
                _expanded.remove(id);
              }
            }),
        children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${item['answer'] ?? ''}')))
        ]);
  }

  static const _fallbackConfig = {
    'phone': '+44 20 1234 5678',
    'email': 'support@carltonleisure.com',
    'phoneHoursWeekday': 'Monday - Friday: 8:00 AM - 8:00 PM GMT',
    'phoneHoursWeekend': 'Saturday - Sunday: 9:00 AM - 6:00 PM GMT',
    'liveChatHours': 'Available 24/7',
    'liveChatResponseTime': 'Average response time: < 2 minutes'
  };
  static const _fallbackFaqs = [
    {
      'id': 1,
      'category': 'Booking',
      'question': 'How do I modify my booking?',
      'answer':
          'Open My Bookings, select your booking, and choose the available modification option.'
    },
    {
      'id': 2,
      'category': 'Refunds',
      'question': 'How long do refunds take?',
      'answer':
          'Approved refunds are usually returned to the original payment method within 5 to 10 business days.'
    },
    {
      'id': 3,
      'category': 'Check-in',
      'question': 'When can I check in online?',
      'answer':
          'Online check-in typically opens 24 to 48 hours before departure, depending on the airline.'
    },
    {
      'id': 4,
      'category': 'General',
      'question': 'How do I contact support?',
      'answer':
          'Use live chat for the fastest response, call us during support hours, or email our support team.'
    }
  ];
}

class _ChatDialog extends StatefulWidget {
  const _ChatDialog(
      {required this.api, required this.sessionId, required this.messages});
  final ApiClient api;
  final String sessionId;
  final List<Map<String, dynamic>> messages;
  @override
  State<_ChatDialog> createState() => _ChatDialogState();
}

class _ChatDialogState extends State<_ChatDialog> {
  final _input = TextEditingController();
  late final List<Map<String, dynamic>> _messages = [...widget.messages];
  bool _sending = false;
  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    _input.clear();
    setState(() {
      _sending = true;
      _messages.add({'sender': 'user', 'text': text});
    });
    try {
      final response = await widget.api.post<dynamic>('/help/chat/messages',
          data: {'sessionId': widget.sessionId, 'message': text});
      final reply =
          response.data is Map ? (response.data as Map)['reply'] : null;
      if (mounted)
        setState(() => _messages.add(reply is Map
            ? Map<String, dynamic>.from(reply)
            : {'sender': 'agent', 'text': 'We will get back to you shortly.'}));
    } catch (_) {
      if (mounted)
        setState(() => _messages.add({
              'sender': 'agent',
              'text': 'Please call or email support for help.'
            }));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Live Chat'),
        content: SizedBox(
          width: double.maxFinite,
          height: 360,
          child: Column(children: [
            Expanded(
                child: ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (_, index) {
                      final message = _messages[index];
                      final user = message['sender'] == 'user';
                      return Align(
                          alignment: user
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: user
                                      ? AppColors.primary
                                      : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12)),
                              child: Text('${message['text'] ?? ''}',
                                  style: TextStyle(
                                      color: user
                                          ? Colors.white
                                          : AppColors.textPrimary))));
                    })),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: _input,
                      onSubmitted: (_) => _send(),
                      decoration:
                          const InputDecoration(hintText: 'Type a message'))),
              IconButton(
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send))
            ]),
          ]),
        ),
      );
}
