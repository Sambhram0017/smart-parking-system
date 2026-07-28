import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'payment_screen.dart'; // ✅ FIX: was parking_screen.dart
import 'api_config.dart';

class SlotSelectionScreen extends StatefulWidget {
  final String buildingName;
  final String carNumber;
  final List slots;

  const SlotSelectionScreen({
    Key? key,
    required this.buildingName,
    required this.carNumber,
    required this.slots,
  }) : super(key: key);

  @override
  _SlotSelectionScreenState createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen>
    with TickerProviderStateMixin {
  int? selectedSlot;
  bool isLoading = false;

  late AnimationController _fadeController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _glowAnim;
  late Animation<double> _particleAnim;

  // ── Color palette ──────────────────────────────────────────────
  static const Color _bg            = Color(0xFF080C14);
  static const Color _card          = Color(0xFF141D2E);
  static const Color _accent        = Color(0xFF00E5FF);
  static const Color _accentSoft    = Color(0xFF0097A7);
  static const Color _gold          = Color(0xFFFFD54F);
  static const Color _textPrimary   = Color(0xFFE8F4F8);
  static const Color _textSecondary = Color(0xFF5A7A8A);
  static const Color _border        = Color(0xFF1E2D40);
  static const Color _occupied      = Color(0xFFEF4444);
  static const Color _free          = Color(0xFF22C55E);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn  = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideUp = Tween<double>(begin: 30, end: 0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic));
    _fadeController.forward();

    _glowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    _particleController = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _particleAnim =
        Tween<double>(begin: 0, end: 1).animate(_particleController);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  // ── CONFIRM BOOKING → navigate to PaymentScreen ───────────────
  Future<void> confirmBooking() async {
    if (selectedSlot == null) return;
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/vehicle"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "car": widget.carNumber,
          "building": widget.buildingName,
          "slot_number": selectedSlot,
        }),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        // ✅ FIX: Navigate to PaymentScreen, not ParkingScreen.
        // PaymentScreen handles Razorpay checkout and shows the
        // booking confirmation after payment succeeds.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              buildingName: widget.buildingName,
              carNumber: widget.carNumber,
              allocatedSlot: selectedSlot!,
              amount: 50, // adjust if your server returns a dynamic amount
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Booking failed (${response.statusCode}). Try again.",
              style: const TextStyle(color: Color(0xFFE8F4F8)),
            ),
            backgroundColor: _card,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        final msg = e.toString().contains('TimeoutException')
            ? "Request timed out. Check your connection."
            : "Connection failed. Is the server running?";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg,
                style: const TextStyle(color: Color(0xFFE8F4F8))),
            backgroundColor: _card,
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

  // ── Helpers ───────────────────────────────────────────────────
  int _slotNumber(int index) => index + 1;

  bool _isOccupied(int index) {
    final slotNum = _slotNumber(index);
    try {
      final slot = widget.slots.firstWhere(
        (s) => int.tryParse(s["slot_number"].toString()) == slotNum,
      );
      return slot["is_occupied"] == 1;
    } catch (_) {
      return false;
    }
  }

  int get _freeCount =>
      widget.slots.where((s) => s["is_occupied"] != 1).length;

  // ── BUILD ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
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
            top: -100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _accent.withOpacity(0.10),
                    Colors.transparent,
                  ]),
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
                child: Column(
                  children: [
                    _buildHeader(context),
                    _buildVehicleInfo(),
                    _buildStatsRow(),
                    _buildLegend(),
                    _buildSectionTitle(),
                    Expanded(child: _buildGrid()),
                    _buildConfirmButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _textPrimary, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.buildingName,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: _accent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    const Text("Choose Your Slot",
                        style: TextStyle(
                            color: _textSecondary, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Vehicle info strip ────────────────────────────────────────
  Widget _buildVehicleInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _accent.withOpacity(0.30)),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_car_filled_rounded,
                  color: _accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("YOUR VEHICLE",
                      style: TextStyle(
                          color: _textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 3),
                  Text(widget.carNumber,
                      style: const TextStyle(
                          color: _gold,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3)),
                ],
              ),
            ),
            if (selectedSlot != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _accent.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    const Text("SELECTED",
                        style: TextStyle(
                            color: _accent,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8)),
                    Text("S$selectedSlot",
                        style: const TextStyle(
                            color: _accent,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _border.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: const Text("TAP\nA SLOT",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        height: 1.4)),
              ),
          ],
        ),
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          _statChip("10", "Total", _accent, Icons.local_parking_rounded),
          const SizedBox(width: 8),
          _statChip("$_freeCount", "Available", _free,
              Icons.check_circle_outline_rounded),
          const SizedBox(width: 8),
          _statChip("${10 - _freeCount}", "Occupied", _occupied,
              Icons.directions_car_rounded),
        ],
      ),
    );
  }

  Widget _statChip(
      String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 7),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                Text(label,
                    style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Legend ────────────────────────────────────────────────────
  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          _legendDot(_accent, "Selected"),
          const SizedBox(width: 14),
          _legendDot(_occupied, "Occupied"),
          const SizedBox(width: 14),
          _legendDot(_free, "Available"),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                color: _textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ── Section title ─────────────────────────────────────────────
  Widget _buildSectionTitle() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Text("Select a free slot",
          style: TextStyle(
              color: _textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2)),
    );
  }

  // ── Slot Grid ─────────────────────────────────────────────────
  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      itemCount: 10,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.88,
      ),
      itemBuilder: (context, index) {
        final slotNum = _slotNumber(index);
        final occupied = _isOccupied(index);
        final isSelected = selectedSlot == slotNum;

        return _SlotCard(
          slotNumber: slotNum,
          occupied: occupied,
          isSelected: isSelected,
          onTap: occupied
              ? null
              : () => setState(() {
                    selectedSlot = isSelected ? null : slotNum;
                  }),
          accent: _accent,
          occupiedColor: _occupied,
          freeColor: _free,
          cardColor: _card,
          borderColor: _border,
          textSecondary: _textSecondary,
        );
      },
    );
  }

  // ── Confirm button ────────────────────────────────────────────
  Widget _buildConfirmButton() {
    final bool canBook = selectedSlot != null && !isLoading;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) {
          return GestureDetector(
            onTap: canBook ? confirmBooking : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: canBook
                    ? const LinearGradient(
                        colors: [_accentSoft, _accent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                color: canBook ? null : _card,
                border: Border.all(
                    color: canBook ? Colors.transparent : _border),
                boxShadow: canBook
                    ? [
                        BoxShadow(
                          color:
                              _accent.withOpacity(0.28 * _glowAnim.value),
                          blurRadius: 20,
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
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: canBook
                                  ? Colors.white
                                  : _textSecondary,
                              size: 20),
                          const SizedBox(width: 10),
                          Text(
                            selectedSlot != null
                                ? "Confirm Slot S$selectedSlot"
                                : "Select a slot first",
                            style: TextStyle(
                              color: canBook
                                  ? Colors.white
                                  : _textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Slot Card ─────────────────────────────────────────────────────
class _SlotCard extends StatefulWidget {
  final int slotNumber;
  final bool occupied;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color accent;
  final Color occupiedColor;
  final Color freeColor;
  final Color cardColor;
  final Color borderColor;
  final Color textSecondary;

  const _SlotCard({
    required this.slotNumber,
    required this.occupied,
    required this.isSelected,
    required this.onTap,
    required this.accent,
    required this.occupiedColor,
    required this.freeColor,
    required this.cardColor,
    required this.borderColor,
    required this.textSecondary,
  });

  @override
  State<_SlotCard> createState() => _SlotCardState();
}

class _SlotCardState extends State<_SlotCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
        CurvedAnimation(
            parent: _scaleController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Color get _slotColor => widget.isSelected
      ? widget.accent
      : widget.occupied
          ? widget.occupiedColor
          : widget.freeColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
          widget.onTap != null ? (_) => _scaleController.forward() : null,
      onTapUp: widget.onTap != null
          ? (_) {
              _scaleController.reverse();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: _slotColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color:
                  _slotColor.withOpacity(widget.isSelected ? 0.85 : 0.30),
              width: widget.isSelected ? 2.0 : 1.2,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.accent.withOpacity(0.30),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4,
                  decoration: BoxDecoration(
                    color: _slotColor.withOpacity(0.55),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(13)),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isSelected
                          ? Icons.check_circle_rounded
                          : widget.occupied
                              ? Icons.block_rounded
                              : Icons.local_parking_rounded,
                      color: _slotColor,
                      size: 26,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "S${widget.slotNumber}",
                      style: TextStyle(
                          color: _slotColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _slotColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.isSelected
                            ? "YOURS"
                            : widget.occupied
                                ? "TAKEN"
                                : "FREE",
                        style: TextStyle(
                            color: _slotColor,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Background painters ────────────────────────────────────────────
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

class _ParticlePainter extends CustomPainter {
  final double animationValue;
  _ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.12)
      ..style = PaintingStyle.fill;
    final random = math.Random(42);
    for (int i = 0; i < 25; i++) {
      double x = random.nextDouble() * size.width;
      double startY = random.nextDouble() * size.height;
      double speed = 0.5 + random.nextDouble();
      double y = startY - (animationValue * size.height * speed);
      y = y % size.height;
      if (y < 0) y += size.height;
      double radius = 1.0 + random.nextDouble() * 1.8;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}