import 'package:flutter/material.dart';
import 'auth/auth_api.dart';
import 'auth/auth_session.dart';
import 'requests/active_request_store.dart';

// "hey!" brand palette
const _kPurple = Color(0xFF7C4DFF);
const _kPurpleDark = Color(0xFF6C3CE0);
const _kCream = Color(0xFFFBF7F2);
const _kHeading = Color(0xFF241B3A);
const _kMutedRed = Color(0xFFE0736A);

class SettingsPage extends StatefulWidget {
  final VoidCallback onLogOut;

  const SettingsPage({super.key, required this.onLogOut});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushNotifications = true;
  bool _locationSharing = true;
  bool _profileVisible = true;
  bool _loggingOut = false;

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await AuthApi().logout();
      AuthSession.currentUserId = null;
      await ActiveRequestStore.clear();
      if (mounted) widget.onLogOut();
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
              'Settings & Privacy',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _kHeading,
              ),
            ),
            const SizedBox(height: 24),
            _SettingsCard(
              children: [
                _SettingsToggle(
                  icon: Icons.notifications_none_rounded,
                  label: 'Push Notifications',
                  value: _pushNotifications,
                  onChanged: (v) => setState(() => _pushNotifications = v),
                ),
                _SettingsToggle(
                  icon: Icons.location_on_outlined,
                  label: 'Share My Location',
                  value: _locationSharing,
                  onChanged: (v) => setState(() => _locationSharing = v),
                ),
                _SettingsToggle(
                  icon: Icons.visibility_outlined,
                  label: 'Profile Visible to Others',
                  value: _profileVisible,
                  onChanged: (v) => setState(() => _profileVisible = v),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _loggingOut ? null : _logout,
                icon: const Icon(Icons.logout_rounded, color: _kMutedRed),
                label: Text(
                  _loggingOut ? 'Logging out...' : 'Log Out',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kMutedRed,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _kMutedRed),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kPurpleDark.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const _SettingsToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: _kPurple, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: _kHeading,
                  ),
                ),
              ),
              Switch(value: value, onChanged: onChanged, activeColor: _kPurple),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
