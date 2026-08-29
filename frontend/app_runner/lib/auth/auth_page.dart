import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart' show HomePage;
import '../requests/active_request_store.dart';
import '../searching.dart';
import '../chat.dart';
import '../gp_info.dart';
import '../rate.dart';
import '../uploads/image_upload_api.dart';
import 'auth_api.dart';
import 'auth_session.dart';

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
  final _imagePicker = ImagePicker();
  final _imageUploadApi = ImageUploadApi();

  bool _isSignUp = false;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;
  String? _uploadingPhoto;

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

  Future<void> _pickAndUploadPhoto({required bool isIdPhoto}) async {
    final label = isIdPhoto ? 'ID photo' : 'Face photo';
    final picture = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (picture == null || !mounted) return;
    setState(() {
      _uploadingPhoto = label;
      _error = null;
    });
    try {
      final url = await _imageUploadApi.upload(picture);
      if (!mounted) return;
      setState(() {
        (isIdPhoto ? _idPhoto : _facePhoto).text = url;
      });
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = null);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_isSignUp && (_idPhoto.text.isEmpty || _facePhoto.text.isEmpty)) {
      setState(() => _error = 'Upload both your ID and face photos.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      Map<String, dynamic> loginPayload;
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
        loginPayload = await _api.login(
          email: _email.text,
          password: _password.text,
        );
      } else {
        loginPayload = await _api.login(
          email: _email.text,
          password: _password.text,
        );
      }
      final data = loginPayload['data'];
      if (data is Map<String, dynamic>) {
        AuthSession.currentUserId = data['id']?.toString();
      }
      if (!mounted) return;
      final activeRequest = await ActiveRequestStore.load();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) {
            if (activeRequest == null) return const HomePage();
            switch (activeRequest.stage) {
              case UserMeetupStage.requesting:
                return SearchingPage.fromRequest(activeRequest);
              case UserMeetupStage.chat:
                return ChatPage(
                  activity: activeRequest.activity,
                  place: activeRequest.place,
                  meetupId: activeRequest.meetupId,
                );
              case UserMeetupStage.meetup:
                return GpInfoPage(
                  meetupId: activeRequest.meetupId,
                  meetupTitle: activeRequest.activity,
                  meetupSubtitle: activeRequest.place,
                );
              case UserMeetupStage.rating:
                return RatePage(
                  meetupId: activeRequest.meetupId,
                  meetupType: activeRequest.activity,
                );
            }
          },
        ),
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
                      _photoButton(
                        label: 'ID photo',
                        icon: Icons.badge_outlined,
                        uploaded: _idPhoto.text.isNotEmpty,
                        onPressed: () => _pickAndUploadPhoto(isIdPhoto: true),
                      ),
                      const SizedBox(height: 12),
                      _photoButton(
                        label: 'Face photo',
                        icon: Icons.face_outlined,
                        uploaded: _facePhoto.text.isNotEmpty,
                        onPressed: () => _pickAndUploadPhoto(isIdPhoto: false),
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
                        onPressed: _loading || _uploadingPhoto != null
                            ? null
                            : _submit,
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

  Widget _photoButton({
    required String label,
    required IconData icon,
    required bool uploaded,
    required VoidCallback onPressed,
  }) {
    final uploading = _uploadingPhoto == label;
    return OutlinedButton.icon(
      onPressed: _uploadingPhoto == null ? onPressed : null,
      icon: uploading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(uploaded ? Icons.check_circle : icon),
      label: Text(
        uploading
            ? 'Uploading $label...'
            : uploaded
            ? '$label uploaded — tap to replace'
            : 'Choose and upload $label',
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}
