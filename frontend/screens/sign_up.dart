import 'package:flutter/material.dart';

// "hey!" brand palette
const _kPurple = Color(0xFF7C4DFF);
const _kPurpleDark = Color(0xFF6C3CE0);
const _kCream = Color(0xFFFBF7F2);
const _kLavender = Color(0xFFEDE7FA);
const _kHeading = Color(0xFF241B3A);

class SignUpPage extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onGoToLogIn;
  final void Function(String name, String email, String password)? onSignUp;

  const SignUpPage({
    super.key,
    this.onBack,
    this.onGoToLogIn,
    this.onSignUp,
  });

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCream,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 40,
              right: 40,
              child: Icon(Icons.auto_awesome,
                  color: _kPurple.withOpacity(0.5), size: 20),
            ),
            Positioned(
              top: 76,
              right: 64,
              child: Icon(Icons.auto_awesome,
                  color: _kPurple.withOpacity(0.35), size: 12),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackButton(onTap: widget.onBack),
                  const SizedBox(height: 28),
                  const _BrandMark(),
                  const SizedBox(height: 24),
                  const Text(
                    'Create your account',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      color: _kHeading,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Join "hey!" and start meeting up today.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _kHeading.withOpacity(0.55),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _FieldPill(
                    icon: Icons.person_outline_rounded,
                    hint: 'Full name',
                    controller: _nameController,
                  ),
                  const SizedBox(height: 14),
                  _FieldPill(
                    icon: Icons.mail_outline_rounded,
                    hint: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  _FieldPill(
                    icon: Icons.lock_outline_rounded,
                    hint: 'Password',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    trailing: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _kHeading.withOpacity(0.4),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FieldPill(
                    icon: Icons.lock_outline_rounded,
                    hint: 'Confirm password',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    trailing: IconButton(
                      onPressed: () => setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword),
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _kHeading.withOpacity(0.4),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _PrimaryButton(
                    label: 'Sign Up',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => widget.onSignUp?.call(
                      _nameController.text,
                      _emailController.text,
                      _passwordController.text,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _BottomLink(
                    question: 'Already have an account?',
                    action: 'Log In',
                    onTap: widget.onGoToLogIn,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _BackButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: _kPurpleDark.withOpacity(0.15),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.arrow_back, color: _kHeading, size: 20),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _kPurple,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _kPurple.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        const Text(
          'hey!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _kPurpleDark,
          ),
        ),
      ],
    );
  }
}

class _FieldPill extends StatelessWidget {
  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? trailing;

  const _FieldPill({
    required this.icon,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kPurpleDark.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: _kLavender,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _kPurple, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _kHeading,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _kHeading.withOpacity(0.35),
                ),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ).copyWith(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          shadowColor: WidgetStateProperty.all(Colors.transparent),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kPurple, _kPurpleDark]),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
                const SizedBox(width: 10),
                Icon(icon, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomLink extends StatelessWidget {
  final String question;
  final String action;
  final VoidCallback? onTap;

  const _BottomLink({
    required this.question,
    required this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          Text(
            '$question  ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _kHeading.withOpacity(0.55),
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              action,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _kPurpleDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
