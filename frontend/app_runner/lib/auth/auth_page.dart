import 'package:flutter/material.dart';

import '../main.dart' show HomePage;
import 'auth_api.dart';

const _purple = Color(0xFF7C4DFF);
const _heading = Color(0xFF241B3A);
const _cream = Color(0xFFFBF7F2);

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _api = AuthApi();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _phone = TextEditingController();
  final _idPhoto = TextEditingController();
  final _facePhoto = TextEditingController();

  bool _isSignUp = false;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _lastName,
      _email,
      _password,
      _confirmPassword,
      _phone,
      _idPhoto,
      _facePhoto,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  String? _emailValidator(String? value) {
    final requiredError = _required(value);
    if (requiredError != null) return requiredError;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (value.length > 128) return 'Password cannot exceed 128 characters';
    return null;
  }

  String? _urlValidator(String? value) {
    final requiredError = _required(value);
    if (requiredError != null) return requiredError;
    final uri = Uri.tryParse(value!.trim());
    if (uri == null ||
        !uri.hasAbsolutePath ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'Enter a valid http(s) URL';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isSignUp) {
        await _api.signUp(
          firstName: _firstName.text,
          lastName: _lastName.text,
          email: _email.text,
          password: _password.text,
          phoneNumber: _phone.text,
          idPhoto: _idPhoto.text,
          facePhoto: _facePhoto.text,
        );
        await _api.login(email: _email.text, password: _password.text);
      } else {
        await _api.login(email: _email.text, password: _password.text);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomePage()),
      );
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _switchMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _error = null;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: _purple, size: 32),
                        SizedBox(width: 10),
                        Text(
                          'hey!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: _purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text(
                      _isSignUp ? 'Create your account' : 'Welcome back!',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: _heading,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUp
                          ? 'Join Hey and start meeting up today.'
                          : 'Log in to see what is happening today.',
                      style: TextStyle(
                        color: _heading.withValues(alpha: .6),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (_isSignUp) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              _firstName,
                              'First name',
                              Icons.person_outline,
                              validator: _required,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              _lastName,
                              'Last name',
                              Icons.person_outline,
                              validator: _required,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    _field(
                      _email,
                      'Email',
                      Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      validator: _emailValidator,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      _password,
                      'Password',
                      Icons.lock_outline,
                      obscureText: _obscurePassword,
                      validator: _passwordValidator,
                      suffix: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    if (_isSignUp) ...[
                      const SizedBox(height: 12),
                      _field(
                        _confirmPassword,
                        'Confirm password',
                        Icons.lock_outline,
                        obscureText: true,
                        validator: (value) {
                          if (value != _password.text) {
                            return 'Passwords do not match';
                          }
                          return _required(value);
                        },
                      ),
                      const SizedBox(height: 12),
                      _field(
                        _phone,
                        'Phone number',
                        Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      _field(
                        _idPhoto,
                        'ID photo URL',
                        Icons.badge_outlined,
                        keyboardType: TextInputType.url,
                        validator: _urlValidator,
                      ),
                      const SizedBox(height: 12),
                      _field(
                        _facePhoto,
                        'Face photo URL',
                        Icons.face_outlined,
                        keyboardType: TextInputType.url,
                        validator: _urlValidator,
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(backgroundColor: _purple),
                        child: _loading
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isSignUp ? 'Sign Up' : 'Log In',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loading ? null : _switchMode,
                      child: Text(
                        _isSignUp
                            ? 'Already have an account? Log In'
                            : 'New to Hey? Sign Up',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
