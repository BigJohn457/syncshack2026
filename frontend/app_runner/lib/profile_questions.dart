import 'package:flutter/material.dart';

import 'auth/auth_api.dart';
import 'auth/auth_session.dart';
import 'profiles/profile_api.dart';

class ProfileQuestionsPage extends StatefulWidget {
  const ProfileQuestionsPage({super.key});

  @override
  State<ProfileQuestionsPage> createState() => _ProfileQuestionsPageState();
}

class _ProfileQuestionsPageState extends State<ProfileQuestionsPage> {
  static const _questions = <String, String>{
    'about_me': 'How would you introduce yourself to a new friend?',
    'interests': 'What interests or hobbies make you lose track of time?',
    'ideal_meetup': 'What does your ideal meetup look like?',
    'personality': 'How would people close to you describe your personality?',
    'conversation_topics': 'What topics do you most enjoy talking about?',
  };
  final _formKey = GlobalKey<FormState>();
  final _api = ProfileApi();
  late final Map<String, TextEditingController> _controllers = {
    for (final key in _questions.keys) key: TextEditingController(),
  };
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = AuthSession.currentUserId;
    if (userId == null) {
      setState(() {
        _loading = false;
        _error = 'Please log in again.';
      });
      return;
    }
    try {
      final profile = await _api.fetch(userId);
      for (final entry in profile.personalizationAnswers.entries) {
        _controllers[entry.key]?.text = entry.value;
      }
    } on AuthException catch (error) {
      _error = error.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      await _api.updatePersonalization({
        for (final entry in _controllers.entries)
          entry.key: entry.value.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Personalise your profile')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Help future meetup friends get to know the real you.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                for (final entry in _questions.entries) ...[
                  Text(
                    entry.value,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _controllers[entry.key],
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 1000,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Answer required'
                        : null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving...' : 'Save answers'),
                ),
              ],
            ),
          ),
  );
}
