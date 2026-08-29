import 'package:flutter/material.dart';
import 'searching.dart';

// "hey!" brand palette
const _kPurple = Color(0xFF7C4DFF);
const _kPurpleDark = Color(0xFF6C3CE0);
const _kCream = Color(0xFFFBF7F2);
const _kLavender = Color(0xFFEDE7FA);
const _kLavenderCard = Color(0xFFE7DFFB);
const _kMinuteBg = Color(0xFFEFEAF8);
const _kHeading = Color(0xFF241B3A);

class DateTimeSetupPage extends StatefulWidget {
  final String currentUserAvatarUrl;
  final VoidCallback? onBack;
  final void Function(String activity, String people, String place, int hour,
      int minute, bool isAm)? onRequestMeetup;

  const DateTimeSetupPage({
    super.key,
    this.currentUserAvatarUrl = '',
    this.onBack,
    this.onRequestMeetup,
  });

  @override
  State<DateTimeSetupPage> createState() => _DateTimeSetupPageState();
}

class _DateTimeSetupPageState extends State<DateTimeSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _activityController = TextEditingController();
  final _peopleController = TextEditingController();
  final _placeController = TextEditingController();

  int _hour = 8;
  int _minute = 30;
  bool _isAm = true;

  @override
  void dispose() {
    _activityController.dispose();
    _peopleController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  void _cycleHour() {
    setState(() => _hour = _hour == 12 ? 1 : _hour + 1);
  }

  void _cycleMinute() {
    setState(() => _minute = (_minute + 5) % 60);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCream,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 60,
              right: 120,
              child: Icon(Icons.auto_awesome,
                  color: _kPurple.withOpacity(0.5), size: 22),
            ),
            Positioned(
              top: 92,
              right: 96,
              child: Icon(Icons.auto_awesome,
                  color: _kPurple.withOpacity(0.35), size: 14),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopBar(
                      currentUserAvatarUrl: widget.currentUserAvatarUrl,
                      onBack: widget.onBack,
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'What do you\nwant to do today?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        color: _kHeading,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _FieldPill(
                      icon: Icons.auto_fix_high,
                      hint: 'Activity',
                      controller: _activityController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _FieldPill(
                            icon: Icons.people_alt_rounded,
                            hint: 'Number of people',
                            controller: _peopleController,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final n = int.tryParse(value?.trim() ?? '');
                              if (n == null || n <= 0) {
                                return 'Enter a number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _FieldPill(
                            icon: Icons.location_on_rounded,
                            hint: 'Place',
                            controller: _placeController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SelectTimeCard(
                      hour: _hour,
                      minute: _minute,
                      isAm: _isAm,
                      onHourTap: _cycleHour,
                      onMinuteTap: _cycleMinute,
                      onAmSelected: () => setState(() => _isAm = true),
                      onPmSelected: () => setState(() => _isAm = false),
                      onCancel: () => setState(() {
                        _hour = 8;
                        _minute = 30;
                        _isAm = true;
                      }),
                      onOk: () {
                        FocusScope.of(context).unfocus();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Time set to ${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')} ${_isAm ? 'AM' : 'PM'}',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    _RequestMeetupButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        widget.onRequestMeetup?.call(
                          _activityController.text,
                          _peopleController.text,
                          _placeController.text,
                          _hour,
                          _minute,
                          _isAm,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SearchingPage(
                              activity: _activityController.text,
                              people: _peopleController.text,
                              place: _placeController.text,
                              time:
                                  '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')} ${_isAm ? "AM" : "PM"}',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String currentUserAvatarUrl;
  final VoidCallback? onBack;

  const _TopBar({required this.currentUserAvatarUrl, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 2,
          shadowColor: _kPurpleDark.withOpacity(0.15),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onBack ?? () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.arrow_back, color: _kHeading, size: 20),
            ),
          ),
        ),
        _Avatar(imageUrl: currentUserAvatarUrl, radius: 28),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String imageUrl;
  final double radius;

  const _Avatar({required this.imageUrl, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: _kLavender,
        backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
        child: imageUrl.isEmpty
            ? Icon(Icons.person, color: _kPurple, size: radius)
            : null,
      ),
    );
  }
}

class _FieldPill extends StatelessWidget {
  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FieldPill({
    required this.icon,
    required this.hint,
    required this.controller,
    this.keyboardType,
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
              keyboardType: keyboardType,
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
                errorStyle: const TextStyle(fontSize: 10.5, color: Color(0xFFE0736A)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectTimeCard extends StatelessWidget {
  final int hour;
  final int minute;
  final bool isAm;
  final VoidCallback onHourTap;
  final VoidCallback onMinuteTap;
  final VoidCallback onAmSelected;
  final VoidCallback onPmSelected;
  final VoidCallback onCancel;
  final VoidCallback onOk;

  const _SelectTimeCard({
    required this.hour,
    required this.minute,
    required this.isAm,
    required this.onHourTap,
    required this.onMinuteTap,
    required this.onAmSelected,
    required this.onPmSelected,
    required this.onCancel,
    required this.onOk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        color: _kLavenderCard,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.access_time_filled,
                    color: _kPurple, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Select time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kHeading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _TimeBox(
                value: hour.toString().padLeft(2, '0'),
                highlighted: true,
                onTap: onHourTap,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: _kHeading,
                  ),
                ),
              ),
              _TimeBox(
                value: minute.toString().padLeft(2, '0'),
                highlighted: false,
                onTap: onMinuteTap,
              ),
              const SizedBox(width: 14),
              _AmPmToggle(
                isAm: isAm,
                onAmSelected: onAmSelected,
                onPmSelected: onPmSelected,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: const [
              SizedBox(
                width: 72,
                child: Text('Hour',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: _kHeading)),
              ),
              SizedBox(width: 24),
              SizedBox(
                width: 72,
                child: Text('Minute',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: _kHeading)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onCancel,
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kPurpleDark.withOpacity(0.6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onOk,
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _kPurpleDark,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String value;
  final bool highlighted;
  final VoidCallback onTap;

  const _TimeBox({
    required this.value,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: highlighted ? Colors.white : _kMinuteBg,
          borderRadius: BorderRadius.circular(18),
          border: highlighted ? Border.all(color: _kPurple, width: 2) : null,
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: highlighted ? _kPurple : _kHeading,
          ),
        ),
      ),
    );
  }
}

class _AmPmToggle extends StatelessWidget {
  final bool isAm;
  final VoidCallback onAmSelected;
  final VoidCallback onPmSelected;

  const _AmPmToggle({
    required this.isAm,
    required this.onAmSelected,
    required this.onPmSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 72,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onAmSelected,
              child: Container(
                width: double.infinity,
                color: isAm ? _kPurple : Colors.white,
                alignment: Alignment.center,
                child: Text(
                  'AM',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isAm ? Colors.white : _kHeading,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onPmSelected,
              child: Container(
                width: double.infinity,
                color: !isAm ? _kPurple : Colors.white,
                alignment: Alignment.center,
                child: Text(
                  'PM',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: !isAm ? Colors.white : _kHeading,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestMeetupButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _RequestMeetupButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPurple,
          foregroundColor: Colors.white,
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
            gradient: const LinearGradient(
              colors: [_kPurple, _kPurpleDark],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.people_alt_rounded,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Request Meetup',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
