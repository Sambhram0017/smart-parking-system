import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

// ─────────────────────────────────────────────────────────────────
//  ParkingConfirmedScreen
//  Shown after payment is verified and slot is marked occupied.
//
//  HOW TO NAVIGATE HERE (from payment_screen.dart):
//    Navigator.of(context).pushReplacement(
//      MaterialPageRoute(
//        builder: (_) => ParkingConfirmedScreen(
//          buildingName: widget.buildingName,
//          carNumber:    widget.carNumber,
//          allocatedSlot: widget.allocatedSlot,
//          paymentId:    paymentId,
//        ),
//      ),
//    );
// ─────────────────────────────────────────────────────────────────

class ParkingConfirmedScreen extends StatefulWidget {
  final String buildingName;
  final String carNumber;
  final int allocatedSlot;
  final String paymentId;

  const ParkingConfirmedScreen({
    Key? key,
    required this.buildingName,
    required this.carNumber,
    required this.allocatedSlot,
    required this.paymentId,
  }) : super(key: key);

  @override
  State<ParkingConfirmedScreen> createState() =>
      _ParkingConfirmedScreenState();
}

class _ParkingConfirmedScreenState extends State<ParkingConfirmedScreen>
    with TickerProviderStateMixin {
  // ─── Animation controllers ────────────────────────────────────
  late AnimationController _entranceController;
  late AnimationController _pulseController;
  late AnimationController _orbController;

  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _orbAnim;

  // Booking time — set once when screen loads
  late final DateTime _bookedAt;
  late final DateTime _expiresAt;

  // ─── THEME (matches PaymentScreen) ───────────────────────────
  static const Color _bg = Color(0xFF06090F);
  static const Color _card = Color(0xFF0D1421);
  static const Color _cardBorder = Color(0xFF1A2740);
  static const Color _accent = Color(0xFF00E5FF);
  static const Color _accentDim = Color(0xFF003D47);
  static const Color _gold = Color(0xFFFFCA28);
  static const Color _textPrimary = Color(0xFFECF4F8);
  static const Color _textSecondary = Color(0xFF4A6580);
  static const Color _textMuted = Color(0xFF2A4055);
  static const Color _success = Color(0xFF00E676);

  @override
  void initState() {
    super.initState();

    _bookedAt = DateTime.now();
    _expiresAt = _bookedAt.add(const Duration(hours: 24));

    // Entrance animation — card slides up + fades in
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _slideAnim = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    // Pulsing glow on slot number
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Background orbs
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _orbAnim =
        Tween<double>(begin: 0, end: 2 * math.pi).animate(_orbController);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  // ─── BUILD ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      // No back button — booking is complete
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "PARKING PASS",
          style: TextStyle(
            color: _textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
        actions: [
          // Copy TXN ID
          GestureDetector(
            onTap: _copyTxnId,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _cardBorder),
              ),
              child: const Icon(Icons.copy_rounded,
                  color: _textSecondary, size: 16),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Background orbs ──
          AnimatedBuilder(
            animation: _orbAnim,
            builder: (_, __) => CustomPaint(
              painter: _ConfirmedOrbPainter(_orbAnim.value),
              size: MediaQuery.of(context).size,
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: AnimatedBuilder(
              animation: _entranceController,
              builder: (_, child) => Opacity(
                opacity: _fadeAnim.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnim.value),
                  child: Transform.scale(
                    scale: _scaleAnim.value,
                    child: child,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // ── Big slot number hero ──
                    _buildSlotHero(),

                    const SizedBox(height: 24),

                    // ── Parking pass card ──
                    _buildPassCard(),

                    const SizedBox(height: 20),

                    // ── Active booking timer ──
                    _buildActiveTimer(),

                    const SizedBox(height: 20),

                    // ── Location info ──
                    _buildLocationCard(),

                    const SizedBox(height: 28),

                    // ── Done button ──
                    _buildDoneButton(),

                    const SizedBox(height: 12),
                    Text(
                      "Keep this screen as your parking receipt",
                      style: TextStyle(
                          color: _textMuted,
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SLOT HERO ───────────────────────────────────────────────

  Widget _buildSlotHero() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity(0.12 * _pulseAnim.value),
                blurRadius: 80,
                spreadRadius: 20,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _card,
          border: Border.all(color: _accent.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "SLOT",
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
                letterSpacing: 4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "S${widget.allocatedSlot}",
              style: const TextStyle(
                color: _accent,
                fontSize: 64,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "ACTIVE",
                    style: TextStyle(
                      color: _success,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── PASS CARD ───────────────────────────────────────────────

  Widget _buildPassCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _success.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _success.withOpacity(0.06),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: _success.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(23)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: _success, size: 16),
                const SizedBox(width: 8),
                const Text(
                  "BOOKING CONFIRMED",
                  style: TextStyle(
                    color: _success,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "PAID",
                    style: TextStyle(
                        color: _success,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2),
                  ),
                ),
              ],
            ),
          ),

          // Detail rows
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _detailRow(
                  icon: Icons.directions_car_rounded,
                  label: "Vehicle",
                  value: widget.carNumber,
                  valueBold: true,
                  valueLetterSpacing: 2,
                ),
                _divider(),
                _detailRow(
                  icon: Icons.grid_view_rounded,
                  label: "Slot",
                  value: "S${widget.allocatedSlot}",
                  valueColor: _accent,
                ),
                _divider(),
                _detailRow(
                  icon: Icons.business_rounded,
                  label: "Building",
                  value: widget.buildingName,
                ),
                _divider(),
                _detailRow(
                  icon: Icons.calendar_today_rounded,
                  label: "Booked",
                  value: _formatDateTime(_bookedAt),
                ),
                _divider(),
                _detailRow(
                  icon: Icons.schedule_rounded,
                  label: "Valid until",
                  value: _formatDateTime(_expiresAt),
                  valueColor: _gold,
                ),
              ],
            ),
          ),

          // TXN strip
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _accentDim,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_rounded,
                    color: _textSecondary, size: 14),
                const SizedBox(width: 8),
                const Text(
                  "TXN: ",
                  style: TextStyle(
                      color: _textSecondary,
                      fontSize: 11,
                      letterSpacing: 1),
                ),
                Expanded(
                  child: Text(
                    widget.paymentId,
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: _copyTxnId,
                  child: const Icon(Icons.copy_rounded,
                      color: _textSecondary, size: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── ACTIVE TIMER ────────────────────────────────────────────

  Widget _buildActiveTimer() {
    final duration = _expiresAt.difference(DateTime.now());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _accentDim,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.timer_rounded,
                color: _accent, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Time remaining",
                style: TextStyle(
                    color: _textSecondary,
                    fontSize: 11,
                    letterSpacing: 1),
              ),
              const SizedBox(height: 2),
              Text(
                "${hours}h ${minutes}m",
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "Duration",
                style: TextStyle(
                    color: _textSecondary,
                    fontSize: 11,
                    letterSpacing: 1),
              ),
              const SizedBox(height: 2),
              const Text(
                "24 hours",
                style: TextStyle(
                  color: _gold,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── LOCATION CARD ───────────────────────────────────────────

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _accentDim,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: _accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Parking location",
                  style: TextStyle(
                      color: _textSecondary,
                      fontSize: 11,
                      letterSpacing: 1),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.buildingName,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Slot S${widget.allocatedSlot} · Ground floor",
                  style: const TextStyle(
                      color: _textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.directions_rounded,
              color: _textSecondary, size: 20),
        ],
      ),
    );
  }

  // ─── DONE BUTTON ─────────────────────────────────────────────

  Widget _buildDoneButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: () {
          // Go back to the very first screen (home)
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        child: const Text(
          "BACK TO HOME",
          style: TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool valueBold = false,
    double? valueLetterSpacing,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _accentDim,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _accent, size: 16),
        ),
        const SizedBox(width: 14),
        Text(label,
            style: const TextStyle(
                color: _textSecondary, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? _textPrimary,
            fontSize: 14,
            fontWeight:
                valueBold ? FontWeight.w700 : FontWeight.w600,
            letterSpacing: valueLetterSpacing,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
          height: 1, color: _textMuted.withOpacity(0.4)),
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return "${dt.day} ${months[dt.month - 1]} · $h:$m";
  }

  void _copyTxnId() {
    Clipboard.setData(ClipboardData(text: widget.paymentId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("TXN ID copied",
            style: TextStyle(color: Color(0xFFECF4F8))),
        backgroundColor: const Color(0xFF0D1421),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─── ORB PAINTER (matches PaymentScreen style) ───────────────────

class _ConfirmedOrbPainter extends CustomPainter {
  final double angle;
  _ConfirmedOrbPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    // Top-right green/success orb
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00E676).withOpacity(0.07),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * 0.85 + math.cos(angle) * 18,
          size.height * 0.08 + math.sin(angle) * 12,
        ),
        radius: 200,
      ));
    canvas.drawCircle(
      Offset(
        size.width * 0.85 + math.cos(angle) * 18,
        size.height * 0.08 + math.sin(angle) * 12,
      ),
      200,
      paint1,
    );

    // Bottom-left cyan orb
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00E5FF).withOpacity(0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * 0.1 + math.sin(angle) * 15,
          size.height * 0.8 + math.cos(angle) * 20,
        ),
        radius: 180,
      ));
    canvas.drawCircle(
      Offset(
        size.width * 0.1 + math.sin(angle) * 15,
        size.height * 0.8 + math.cos(angle) * 20,
      ),
      180,
      paint2,
    );
  }

  @override
  bool shouldRepaint(_ConfirmedOrbPainter old) =>
      old.angle != angle;
}