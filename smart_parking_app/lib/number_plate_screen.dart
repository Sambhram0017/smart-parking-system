import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'slot_selection_screen.dart';
import 'dart:async';
import 'api_config.dart';

class NumberPlateScreen extends StatefulWidget {
  final String buildingName;

  const NumberPlateScreen({Key? key, required this.buildingName})
      : super(key: key);

  @override
  _NumberPlateScreenState createState() => _NumberPlateScreenState();
}

class _NumberPlateScreenState extends State<NumberPlateScreen>
    with TickerProviderStateMixin {
  final TextEditingController controller = TextEditingController();

  // ── Animation controllers ──────────────────────────────────────
  late AnimationController _animController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _roadController;
  late AnimationController _particleController;

  late Animation<double> _carAnimation;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _pulseAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _roadAnim;
  late Animation<double> _particleAnim;

  bool isLoading = false;
  bool _isFocused = false;

  // ── Color palette ──────────────────────────────────────────────
  static const Color _bg            = Color(0xFF080C14);
  static const Color _card          = Color(0xFF141D2E);
  static const Color _accent        = Color(0xFF00E5FF);
  static const Color _accentSoft    = Color(0xFF0097A7);
  static const Color _gold          = Color(0xFFFFD54F);
  static const Color _textPrimary   = Color(0xFFE8F4F8);
  static const Color _textSecondary = Color(0xFF5A7A8A);
  static const Color _border        = Color(0xFF1E2D40);

  @override
  void initState() {
    super.initState();

    // Car slide-in animation
    _animController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2));
    _carAnimation = Tween<double>(begin: -200, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();

    // Fade + slide-up for entire screen
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn  = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideUp = Tween<double>(begin: 40, end: 0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic));
    _fadeController.forward();

    // Car icon pulse
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // Button glow
    _glowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    // Animated road dashes
    _roadController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
    _roadAnim = Tween<double>(begin: 0, end: 1).animate(_roadController);

    // Floating particles
    _particleController = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _particleAnim =
        Tween<double>(begin: 0, end: 1).animate(_particleController);
  }

  @override
  void dispose() {
    _animController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _roadController.dispose();
    _particleController.dispose();
    controller.dispose();
    super.dispose();
  }

  // ── Validation: basic Indian number plate format ───────────────
  // FIX: Added plate validation so random strings aren't accepted.
  // Valid formats: KA01AB1234 or KA01A1234 (state + district + letters + digits)
  bool _isValidPlate(String plate) {
    final regex = RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{1,3}[0-9]{4}$');
    return regex.hasMatch(plate.toUpperCase());
  }

  // ── Submit ─────────────────────────────────────────────────────
  Future<void> submit() async {
    final carNumber = controller.text.trim().toUpperCase();

    if (carNumber.isEmpty) return;

    // FIX: Validate plate before hitting the server.
    if (!_isValidPlate(carNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Enter a valid plate (e.g. KA01AB1234)",
            style: TextStyle(color: Color(0xFFE8F4F8)),
          ),
          backgroundColor: const Color(0xFF141D2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // NOTE: 10.0.2.2 = Android emulator → host machine.
      // Use 127.0.0.1 for iOS simulator, or your LAN IP for a physical device.
      final response =
          await http.get(Uri.parse("${ApiConfig.baseUrl}/slots"))
              // FIX: Added timeout so the UI doesn't freeze indefinitely.
              .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List slots = data["data"] ?? [];

        // FIX: Check if any slots are actually available before navigating.
        if (slots.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "No slots available right now.",
                style: TextStyle(color: Color(0xFFE8F4F8)),
              ),
              backgroundColor: const Color(0xFF141D2E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          setState(() => isLoading = false);
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SlotSelectionScreen(
              buildingName: widget.buildingName,
              // FIX: Always pass the uppercased, trimmed plate for consistency.
              carNumber: carNumber,
              slots: slots,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Server error (${response.statusCode}). Try again.",
              style: const TextStyle(color: Color(0xFFE8F4F8)),
            ),
            backgroundColor: const Color(0xFF141D2E),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } on TimeoutException {
      // FIX: Handle timeout explicitly with a clear message.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Request timed out. Check your connection.",
              style: TextStyle(color: Color(0xFFE8F4F8)),
            ),
            backgroundColor: const Color(0xFF141D2E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Connection failed. Is the server running?",
              style: TextStyle(color: Color(0xFFE8F4F8)),
            ),
            backgroundColor: const Color(0xFF141D2E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }

    if (mounted) setState(() => isLoading = false);
  }

  // ── BUILD ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      // FIX: Prevent layout shift when the keyboard opens.
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleAnim,
              builder: (_, __) => CustomPaint(
                painter: _ParticlePainter(_particleAnim.value),
              ),
            ),
          ),

          Positioned(
            top: -120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _accent.withOpacity(0.13),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: AnimatedBuilder(
                animation: _slideUp,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _slideUp.value),
                  child: child,
                ),
                child: SingleChildScrollView(
                  // FIX: keyboard padding so the button stays visible when
                  // the soft keyboard is open.
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
                      _buildTitle(),
                      const SizedBox(height: 36),
                      _buildCarCard(),
                      const SizedBox(height: 32),
                      _buildPlateInput(),
                      const SizedBox(height: 28),
                      _buildContinueButton(),
                      const SizedBox(height: 32),
                      _buildFooterHint(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── WIDGETS ────────────────────────────────────────────────────

  Widget _buildTitle() {
    return Column(
      children: [
        // Building name chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _accent.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_rounded,
                  color: _accent, size: 13),
              const SizedBox(width: 5),
              Text(
                widget.buildingName,
                style: const TextStyle(
                  color: _accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_textPrimary, _accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            "Vehicle Access",
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Enter your number plate to request entry",
          style: TextStyle(
            color: _textSecondary,
            fontSize: 13.5,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildCarCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: _accent.withOpacity(0.04),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _carAnimation,
            builder: (_, child) => Transform.translate(
              offset: Offset(_carAnimation.value, 0),
              child: child,
            ),
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Transform.scale(
                scale: _pulseAnim.value,
                child: child,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        _accent.withOpacity(0.18),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                  const Icon(Icons.directions_car_rounded,
                      size: 72, color: _accent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 18,
              child: AnimatedBuilder(
                animation: _roadAnim,
                builder: (_, __) => CustomPaint(
                  painter: _RoadPainter(_roadAnim.value),
                  size: const Size.fromHeight(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "SMART PARKING SYSTEM",
            style: TextStyle(
              color: _textSecondary,
              fontSize: 10,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlateInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            "NUMBER PLATE",
            style: TextStyle(
              color: _textSecondary,
              fontSize: 10.5,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFocused ? _accent.withOpacity(0.6) : _border,
              width: _isFocused ? 1.5 : 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: _accent.withOpacity(0.12),
                      blurRadius: 16,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                // Country / state indicator
                Container(
                  width: 44,
                  color: _accent.withOpacity(0.12),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flag_rounded, color: _accent, size: 16),
                      SizedBox(height: 2),
                      Text(
                        "IN",
                        style: TextStyle(
                          color: _accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Focus(
                    onFocusChange: (v) => setState(() => _isFocused = v),
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 5,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      // FIX: Force uppercase on every keystroke so the display
                      // always matches what gets sent to the server.
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Z0-9a-z]')),
                        TextInputFormatter.withFunction((old, newVal) {
                          return newVal.copyWith(
                              text: newVal.text.toUpperCase());
                        }),
                        LengthLimitingTextInputFormatter(10),
                      ],
                      textAlign: TextAlign.center,
                      cursorColor: _accent,
                      // FIX: Use a number+text keyboard so digits are easier to type.
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      // FIX: Allow submit via keyboard "Done" key.
                      onSubmitted: (_) => isLoading ? null : submit(),
                      decoration: InputDecoration(
                        hintText: "KA01AB1234",
                        hintStyle: TextStyle(
                          color: _textSecondary.withOpacity(0.5),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                        ),
                        filled: true,
                        fillColor: _card,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 12,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                // Tick only appears when plate length looks complete (≥9 chars)
                AnimatedOpacity(
                  opacity: controller.text.length >= 9 ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Icon(
                      Icons.check_circle_rounded,
                      // FIX: Green tick when valid, amber when not yet valid.
                      color: _isValidPlate(controller.text)
                          ? Colors.greenAccent.withOpacity(0.9)
                          : _gold.withOpacity(0.6),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // FIX: Live validation hint below the field.
        if (controller.text.isNotEmpty && !_isValidPlate(controller.text))
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              "Format: KA01AB1234 (state · district · series · number)",
              style: TextStyle(
                color: Colors.orangeAccent.withOpacity(0.8),
                fontSize: 10.5,
                letterSpacing: 0.3,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContinueButton() {
    // FIX: Button is visually dimmed when plate is invalid, giving clear feedback.
    final bool canSubmit = !isLoading && _isValidPlate(controller.text);

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, child) {
        return GestureDetector(
          onTap: canSubmit ? submit : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: canSubmit ? 1.0 : 0.5,
            child: Container(
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [_accentSoft, _accent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: canSubmit
                    ? [
                        BoxShadow(
                          color:
                              _accent.withOpacity(0.25 * _glowAnim.value),
                          blurRadius: 24,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Continue",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 20),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooterHint() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded, color: _textSecondary, size: 13),
        SizedBox(width: 6),
        Text(
          "Secure connection · Verified entry",
          style: TextStyle(
            color: _textSecondary,
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ── Background grid painter ────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E2D40).withOpacity(0.35)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final dotPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.06)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Particle painter ───────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double animationValue;
  _ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final random = math.Random(42);
    for (int i = 0; i < 30; i++) {
      double x = random.nextDouble() * size.width;
      double startY = random.nextDouble() * size.height;
      double speed = 0.5 + random.nextDouble();
      double y = startY - (animationValue * size.height * speed);
      y = y % size.height;
      if (y < 0) y += size.height;
      double radius = 1.0 + random.nextDouble() * 2.0;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

// ── Road painter ───────────────────────────────────────────────────
class _RoadPainter extends CustomPainter {
  final double animationValue;
  _RoadPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF141D2E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final dashPaint = Paint()
      ..color = const Color(0xFF5A7A8A)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square;

    const dashWidth = 20.0;
    const dashSpace = 20.0;
    const totalDash = dashWidth + dashSpace;

    double offsetX = -(animationValue * totalDash);
    double currentX = offsetX;
    double centerY = size.height / 2;

    while (currentX < size.width) {
      if (currentX + dashWidth > 0) {
        canvas.drawLine(
          Offset(math.max(0, currentX), centerY),
          Offset(math.min(size.width, currentX + dashWidth), centerY),
          dashPaint,
        );
      }
      currentX += totalDash;
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}