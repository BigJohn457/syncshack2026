import 'package:flutter/material.dart';

// "hey!" brand palette
const _kPurple = Color(0xFF7C4DFF);
const _kPurpleDark = Color(0xFF6C3CE0);
const _kCream = Color(0xFFFBF7F2);
const _kLavender = Color(0xFFEDE7FA);
const _kHeading = Color(0xFF241B3A);

class EditProfilePage extends StatefulWidget {
  final String currentName;
  final String currentStatus;

  const EditProfilePage({
    super.key,
    required this.currentName,
    required this.currentStatus,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _statusController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _statusController = TextEditingController(text: widget.currentStatus);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'name': _nameController.text.trim(),
      'status': _statusController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                  shadowColor: _kPurpleDark.withOpacity(0.15),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.arrow_back, color: _kHeading, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: _kHeading,
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      color: _kPurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 46),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Name',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kHeading),
                ),
                const SizedBox(height: 8),
                _FieldPill(
                  icon: Icons.person_outline_rounded,
                  hint: 'Full name',
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                const Text(
                  'Status',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kHeading),
                ),
                const SizedBox(height: 8),
                _FieldPill(
                  icon: Icons.auto_awesome,
                  hint: 'e.g. Open for coffee ☕',
                  controller: _statusController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Status is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPurple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldPill extends StatelessWidget {
  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const _FieldPill({
    required this.icon,
    required this.hint,
    required this.controller,
    this.validator,
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
            child: TextFormField(
              controller: controller,
              validator: validator,
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
                errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFE0736A)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
