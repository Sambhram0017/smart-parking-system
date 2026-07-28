import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'api_config.dart';

import 'parking_confirmed_screen.dart'; // ← NEW import

class PaymentScreen extends StatefulWidget {
  final String buildingName;
  final String carNumber;
  final int allocatedSlot;
  final int amount;

  const PaymentScreen({
    Key? key,
    required this.buildingName,
    required this.carNumber,
    required this.allocatedSlot,
    this.amount = 50,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  late Razorpay _razorpay;
  bool _isProcessing = false;

  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _orbController;
  late Animation<double> _pulseAnim;
  late Animation<double> _shimmerAnim;
  late Animation<double> _orbAnim;

  // ─── THEME ───────────────────────────────────────────────────
  static const Color _bg = Color(0xFF06090F);
  static const Color _card = Color(0xFF0D1421);
  static const Color _cardBorder = Color(0xFF1A2740);
  static const Color _accent = Color(0xFF00E5FF);
  static const Color _accentGlow = Color(0xFF00B8CC);
  static const Color _accentDim = Color(0xFF003D47);
  static const Color _gold = Color(0xFFFFCA28);
  static const Color _textPrimary = Color(0xFFECF4F8);
  static const Color _textSecondary = Color(0xFF4A6580);
  static const Color _textMuted = Color(0xFF2A4055);
  static const Color _success = Color(0xFF00E676);

  @override
  void initState() {
    super.initState();

    // Razorpay setup
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Animations
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _shimmerAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    _orbAnim =
        Tween<double>(begin: 0, end: 2 * math.pi).animate(_orbController);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _pulseController.dispose();
    _shimmerController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  // ─── PAYMENT LOGIC ────────────────────────────────────────────

  Future<void> startPayment() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    // Fail-safe timer to prevent infinite loading under any circumstance
    Timer(const Duration(seconds: 3), () {
      if (mounted && _isProcessing) {
        setState(() => _isProcessing = false);
      }
    });

    final orderId = "order_demo_${DateTime.now().millisecondsSinceEpoch}";
    final paymentId = "pay_web_${DateTime.now().millisecondsSinceEpoch}";

    try {
      await http.post(
        Uri.parse("${ApiConfig.baseUrl}/verify-payment"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "order_id": orderId,
          "payment_id": paymentId,
          "signature": "demo_signature",
          "slot": widget.allocatedSlot,
          "car_number": widget.carNumber,
          "building": widget.buildingName,
        }),
      ).timeout(const Duration(seconds: 3));

      if (mounted) setState(() => _isProcessing = false);

      _showSuccessDialog(paymentId);
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
      _showSuccessDialog(paymentId);
    }
  }

  // ─── UPDATED: verify + mark slot + navigate ───────────────────

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    _showSnackBar("✅ Payment received. Verifying...");

    try {
      final verifyResponse = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/verify-payment"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "order_id": response.orderId,
          "payment_id": response.paymentId,
          "signature": response.signature,
          // ← NEW: send slot info so backend can mark it occupied
          "slot": widget.allocatedSlot,
          "car_number": widget.carNumber,
          "building": widget.buildingName,
        }),
      );

      setState(() => _isProcessing = false);

      if (verifyResponse.statusCode == 200) {
        // ← UPDATED: show dialog then navigate to ParkingConfirmedScreen
        _showSuccessDialog(response.paymentId ?? "Unknown");
      } else {
        _showSnackBar("❌ Verification failed. Contact support.");
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showSnackBar("❌ Verification network error.");
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    _showSnackBar("❌ Payment Failed: ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isProcessing = false);
    _showSnackBar("👛 Wallet Selected: ${response.walletName}");
  }

  // ─── UI HELPERS ───────────────────────────────────────────────

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: _textPrimary)),
        backgroundColor: _card,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── UPDATED: success dialog now navigates after tapping Done ─

  void _showSuccessDialog(String paymentId) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (ctx, anim, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: child,
      ),
      pageBuilder: (ctx, _, __) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(28),
              border:
                  Border.all(color: _success.withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _success.withOpacity(0.15),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated check icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _success.withOpacity(0.12),
                    border: Border.all(
                        color: _success.withOpacity(0.5), width: 2),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: _success, size: 44),
                ),
                const SizedBox(height: 24),
                const Text(
                  "BOOKING\nCONFIRMED",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _accentDim,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Slot S${widget.allocatedSlot}  ·  ${widget.carNumber}",
                    style: const TextStyle(
                        color: _accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "TXN: $paymentId",
                  style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 10,
                      letterSpacing: 1),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _success,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      // ← UPDATED: close dialog + navigate to parking pass
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => ParkingConfirmedScreen(
                            buildingName: widget.buildingName,
                            carNumber: widget.carNumber,
                            allocatedSlot: widget.allocatedSlot,
                            paymentId: paymentId,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "VIEW PARKING PASS",
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 2),
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

  // ─── BUILD ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _cardBorder),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _textPrimary, size: 16),
          ),
        ),
        title: const Text(
          "CHECKOUT",
          style: TextStyle(
            color: _textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildSlotBadge(),
                  const SizedBox(height: 20),
                  _buildSummaryCard(),
                  const SizedBox(height: 20),
                  _buildSecurityRow(),
                  const SizedBox(height: 24),
                  _buildPayButton(),
                  const SizedBox(height: 16),
                  _buildFootnote(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BACKGROUND ──────────────────────────────────────────────

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _orbAnim,
      builder: (_, __) {
        return CustomPaint(
          painter: _OrbPainter(_orbAnim.value),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }

  // ─── SLOT BADGE ──────────────────────────────────────────────

  Widget _buildSlotBadge() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Transform.scale(
        scale: _pulseAnim.value,
        child: child,
      ),
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [_accentDim, _accent.withOpacity(0.08)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border:
                Border.all(color: _accent.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_parking_rounded,
                  color: _accent, size: 20),
              const SizedBox(width: 10),
              Text(
                "SLOT  S${widget.allocatedSlot}",
                style: const TextStyle(
                  color: _accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── SUMMARY CARD ────────────────────────────────────────────

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header strip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: const BoxDecoration(
              color: _accentDim,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(23)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded,
                    color: _accent, size: 16),
                const SizedBox(width: 8),
                const Text(
                  "PARKING INVOICE",
                  style: TextStyle(
                    color: _accent,
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
                    color: _accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "UNPAID",
                    style: TextStyle(
                        color: _accent,
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
                _buildDetailRow(
                  icon: Icons.business_rounded,
                  label: "Location",
                  value: widget.buildingName,
                ),
                _buildDivider(),
                _buildDetailRow(
                  icon: Icons.directions_car_rounded,
                  label: "Vehicle",
                  value: widget.carNumber,
                  valueStyle: const TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                _buildDivider(),
                _buildDetailRow(
                  icon: Icons.grid_view_rounded,
                  label: "Slot Number",
                  value: "S${widget.allocatedSlot}",
                ),
                _buildDivider(),
                _buildDetailRow(
                  icon: Icons.access_time_rounded,
                  label: "Duration",
                  value: "24 Hour",
                ),
              ],
            ),
          ),

          // Total strip
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _accent.withOpacity(0.12),
                  _accentDim,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: _accent.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "TOTAL PAYABLE",
                      style: TextStyle(
                          color: _textSecondary,
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            "₹",
                            style: TextStyle(
                                color: _gold,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          "${widget.amount}",
                          style: const TextStyle(
                            color: _gold,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Text(
                            ".00",
                            style: TextStyle(
                                color: _textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Incl. all taxes",
                      style: TextStyle(
                          color: _textSecondary, fontSize: 10),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: _success.withOpacity(0.3),
                            width: 1),
                      ),
                      child: const Text(
                        "✓  GST INCLUDED",
                        style: TextStyle(
                            color: _success,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    TextStyle? valueStyle,
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
        Text(
          label,
          style:
              const TextStyle(color: _textSecondary, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: valueStyle ??
              const TextStyle(
                color: _textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child:
          Container(height: 1, color: _textMuted.withOpacity(0.4)),
    );
  }

  // ─── SECURITY ROW ────────────────────────────────────────────

  Widget _buildSecurityRow() {
    return Row(
      children: [
        _securityBadge(Icons.shield_rounded, "256-bit SSL"),
        const SizedBox(width: 10),
        _securityBadge(Icons.fingerprint_rounded, "PCI DSS"),
        const SizedBox(width: 10),
        _securityBadge(Icons.verified_rounded, "Razorpay"),
      ],
    );
  }

  Widget _securityBadge(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: _textSecondary, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  // ─── PAY BUTTON ──────────────────────────────────────────────

  Widget _buildPayButton() {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (_, child) {
        return GestureDetector(
          onTap: _isProcessing ? null : startPayment,
          child: Container(
            height: 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: _isProcessing
                  ? const LinearGradient(
                      colors: [_accentDim, _accentDim])
                  : const LinearGradient(
                      colors: [
                        _accentGlow,
                        _accent,
                        Color(0xFF80FFFF)
                      ],
                      stops: [0.0, 0.5, 1.0],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              boxShadow: _isProcessing
                  ? []
                  : [
                      BoxShadow(
                        color: _accent.withOpacity(0.35),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Stack(
              children: [
                if (!_isProcessing)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.15),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                        begin:
                            Alignment(_shimmerAnim.value - 1, 0),
                        end: Alignment(_shimmerAnim.value + 1, 0),
                      ).createShader(bounds),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                Center(
                  child: _isProcessing
                      ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            color: _accent,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bolt_rounded,
                                color: Colors.black, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              "PAY  ₹${widget.amount}  NOW",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
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
      },
    );
  }

  // ─── FOOTNOTE ────────────────────────────────────────────────

  Widget _buildFootnote() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded,
              size: 12, color: _textMuted),
          const SizedBox(width: 6),
          Text(
            "Secured & powered by ",
            style: TextStyle(color: _textMuted, fontSize: 11),
          ),
          const Text(
            "Razorpay",
            style: TextStyle(
                color: _textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ─── BACKGROUND ORB PAINTER ──────────────────────────────────────

class _OrbPainter extends CustomPainter {
  final double angle;
  _OrbPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00E5FF).withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * 0.15 + math.cos(angle) * 20,
          size.height * 0.12 + math.sin(angle) * 15,
        ),
        radius: 180,
      ));
    canvas.drawCircle(
      Offset(
        size.width * 0.15 + math.cos(angle) * 20,
        size.height * 0.12 + math.sin(angle) * 15,
      ),
      180,
      paint1,
    );

    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFCA28).withOpacity(0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * 0.85 + math.sin(angle) * 15,
          size.height * 0.75 + math.cos(angle) * 20,
        ),
        radius: 160,
      ));
    canvas.drawCircle(
      Offset(
        size.width * 0.85 + math.sin(angle) * 15,
        size.height * 0.75 + math.cos(angle) * 20,
      ),
      160,
      paint2,
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.angle != angle;
}