import 'package:flutter/material.dart';

import 'auth/auth_api.dart';
import 'auth/auth_session.dart';
import 'profiles/profile_api.dart';

const _purple = Color(0xFF7C4DFF);
const _cream = Color(0xFFFBF7F2);

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    this.currentName = '',
    this.currentStatus = '',
  });

  // Retained so existing callers remain source-compatible.
  final String currentName;
  final String currentStatus;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _api = ProfileApi();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _radius = TextEditingController();
  final _imageUrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _lastName,
      _email,
      _phone,
      _radius,
      _imageUrl,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final userId = AuthSession.currentUserId;
    if (userId == null || userId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Please log in again to load your profile.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _api.fetch(userId);
      if (!mounted) return;
      _firstName.text = profile.firstName;
      _lastName.text = profile.lastName;
      _email.text = profile.email;
      _phone.text = profile.phone;
      _radius.text = profile.radius == profile.radius.roundToDouble()
          ? profile.radius.toInt().toString()
          : profile.radius.toString();
      _imageUrl.text = profile.profileImageUrl ?? '';
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final profile = UserProfile(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      radius: double.parse(_radius.text.trim()),
      profileImageUrl: _imageUrl.text.trim().isEmpty
          ? null
          : _imageUrl.text.trim(),
    );
    try {
      await _api.update(profile);
      if (!mounted) return;
      Navigator.pop(context, {
        'name': '${profile.firstName} ${profile.lastName}'.trim(),
        'status': widget.currentStatus,
      });
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value, String name, int max) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$name is required';
    if (text.length > max) return '$name is too long';
    return null;
  }

  String? _emailValidator(String? value) {
    final error = _required(value, 'Email', 255);
    if (error != null) return error;
    final email = value!.trim();
    if (!email.contains('@') || email.startsWith('@') || email.endsWith('@')) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _radiusValidator(String? value) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null) return 'Enter a valid radius';
    if (number < 0) return 'Radius cannot be negative';
    return null;
  }

  String? _urlValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri == null ||
        !uri.hasAbsolutePath ||
        !{'http', 'https'}.contains(uri.scheme)) {
      return 'Enter a valid http(s) URL';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: _cream,
        title: const Text('Edit Profile'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _errorView()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  _avatar(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          'First name',
                          Icons.person_outline,
                          _firstName,
                          (v) => _required(v, 'First name', 100),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          'Last name',
                          Icons.person_outline,
                          _lastName,
                          (v) => _required(v, 'Last name', 100),
                        ),
                      ),
                    ],
                  ),
                  _field(
                    'Email',
                    Icons.email_outlined,
                    _email,
                    _emailValidator,
                    type: TextInputType.emailAddress,
                  ),
                  _field(
                    'Phone',
                    Icons.phone_outlined,
                    _phone,
                    (v) => _required(v, 'Phone', 30),
                    type: TextInputType.phone,
                  ),
                  _field(
                    'Discovery radius (km)',
                    Icons.radar,
                    _radius,
                    _radiusValidator,
                    type: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  _field(
                    'Profile image URL (optional)',
                    Icons.image_outlined,
                    _imageUrl,
                    _urlValidator,
                    type: TextInputType.url,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purple,
                        foregroundColor: Colors.white,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field(
    String label,
    IconData icon,
    TextEditingController controller,
    String? Function(String?) validator, {
    TextInputType? type,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _purple),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _avatar() {
    final url = _imageUrl.text.trim();
    return Center(
      child: Container(
        width: 92,
        height: 92,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: Color(0xFFEDE7FA),
          shape: BoxShape.circle,
        ),
        child: url.isEmpty
            ? const Icon(Icons.person, color: _purple, size: 48)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, exception, stackTrace) =>
                    const Icon(Icons.person, color: _purple, size: 48),
              ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_outlined, color: _purple, size: 42),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadProfile, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
