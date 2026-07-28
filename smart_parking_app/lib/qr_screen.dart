import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'number_plate_screen.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: QRScreen(),
  ));
}

class QRScreen extends StatefulWidget {
  @override
  _QRScreenState createState() => _QRScreenState();
}

class _QRScreenState extends State<QRScreen>
    with SingleTickerProviderStateMixin {
  bool isScanned = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  // ✅ VALIDATION (Scanner + Manual)
  void handleQR(String code) {
    if (code == "BUILDING_A|10") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NumberPlateScreen(
            buildingName: "BUILDING_A",
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text("Invalid Code", style: TextStyle(fontFamily: 'monospace')),
          ],
        ),
        backgroundColor: const Color(0xFFFF3B5C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );

    isScanned = false;
  }

  // ✅ MANUAL INPUT DIALOG
  void openManualEntry() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D1A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF00F5C4).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00F5C4).withOpacity(0.08),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F5C4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.keyboard_outlined,
                        color: Color(0xFF00F5C4),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Manual Entry",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Text(
                  "Enter the building access code",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 24),

                // Input Field
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF00F5C4).withOpacity(0.2),
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(
                      color: Color(0xFF00F5C4),
                      fontFamily: 'monospace',
                      fontSize: 15,
                      letterSpacing: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: "BUILDING_A|10",
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.2),
                        fontFamily: 'monospace',
                        letterSpacing: 1.2,
                      ),
                      prefixIcon: Icon(
                        Icons.tag_outlined,
                        color: const Color(0xFF00F5C4).withOpacity(0.5),
                        size: 18,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    cursorColor: const Color(0xFF00F5C4),
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          String input = controller.text.trim();
                          Navigator.pop(context);
                          handleQR(input);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00F5C4),
                          foregroundColor: const Color(0xFF0D0D1A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Confirm",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // CAMERA
          MobileScanner(
            onDetect: (barcodeCapture) {
              if (isScanned) return;
              final barcodes = barcodeCapture.barcodes;
              if (barcodes.isNotEmpty) {
                final code = barcodes.first.rawValue;
                if (code != null) {
                  isScanned = true;
                  handleQR(code);
                }
              }
            },
          ),

          // DARK VIGNETTE OVERLAY
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.85),
                ],
                stops: const [0.45, 1.0],
              ),
            ),
          ),

          // TOP: Header Section
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                bottom: 28,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.95),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Logo / Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F5C4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF00F5C4).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00F5C4),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "PARKING ACCESS",
                          style: TextStyle(
                            color: Color(0xFF00F5C4),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    "Scan QR Code",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Position the QR code within the frame",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // CENTER: Scanner Box
          Center(
            child: SizedBox(
              width: 270,
              height: 270,
              child: Stack(
                children: [
                  // Outer glow
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F5C4).withOpacity(0.15),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Corner decorations — Top Left
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _CornerBracket(color: const Color(0xFF00F5C4)),
                  ),
                  // Top Right
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(3.14159),
                      child: _CornerBracket(color: const Color(0xFF00F5C4)),
                    ),
                  ),
                  // Bottom Left
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationX(3.14159),
                      child: _CornerBracket(color: const Color(0xFF00F5C4)),
                    ),
                  ),
                  // Bottom Right
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationZ(3.14159),
                      child: _CornerBracket(color: const Color(0xFF00F5C4)),
                    ),
                  ),

                  // Scan line
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (_, __) {
                      return Positioned(
                        top: 10 + _animationController.value * 250,
                        left: 14,
                        right: 14,
                        child: Column(
                          children: [
                            // Gradient fade above line
                            Container(
                              height: 20,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    const Color(0xFF00F5C4).withOpacity(0.08),
                                  ],
                                ),
                              ),
                            ),
                            // The line
                            Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    const Color(0xFF00F5C4),
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00F5C4)
                                        .withOpacity(0.8),
                                    blurRadius: 12,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // BOTTOM SECTION
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: 32,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).padding.bottom + 32,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.98),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Divider label
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          "OR ENTER MANUALLY",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.8,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Manual Entry Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: openManualEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: const Color(0xFF00F5C4),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: const Color(0xFF00F5C4).withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        elevation: 0,
                      ).copyWith(
                        overlayColor: WidgetStateProperty.all(
                          const Color(0xFF00F5C4).withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.keyboard_outlined, size: 18),
                          SizedBox(width: 10),
                          Text(
                            "Enter Building Code",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Corner Bracket Widget ───────────────────────────────────────────────────
class _CornerBracket extends StatelessWidget {
  final Color color;
  const _CornerBracket({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: CustomPaint(
        painter: _BracketPainter(color: color),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final Color color;
  _BracketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(0, 0);
    path.lineTo(0, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

//////////////////////////////////////////////////////////////
// ✅ PARKING SCREEN
//////////////////////////////////////////////////////////////

class ParkingScreen extends StatefulWidget {
  final String buildingName;
  final int totalSlots;

  const ParkingScreen({
    Key? key,
    required this.buildingName,
    required this.totalSlots,
  }) : super(key: key);

  @override
  _ParkingScreenState createState() => _ParkingScreenState();
}

class _ParkingScreenState extends State<ParkingScreen> {
  late List<String?> parkedCars;
  final TextEditingController carController = TextEditingController();

  @override
  void initState() {
    super.initState();
    parkedCars = List.generate(widget.totalSlots, (_) => null);
  }

  void handleSlotTap(int index) {
    String carNumber = carController.text.trim();

    if (parkedCars[index] != null) {
      setState(() => parkedCars[index] = null);
      return;
    }

    if (carNumber.isEmpty) return;

    setState(() => parkedCars[index] = carNumber);
    carController.clear();
  }

  int get occupiedCount => parkedCars.where((c) => c != null).length;
  int get availableCount => widget.totalSlots - occupiedCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08080F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF08080F),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                size: 14, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.buildingName.replaceAll('_', ' '),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              "Parking Management",
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _StatCard(
                  label: "Total",
                  value: widget.totalSlots.toString(),
                  color: Colors.white.withOpacity(0.6),
                  bgColor: Colors.white.withOpacity(0.05),
                ),
                const SizedBox(width: 10),
                _StatCard(
                  label: "Available",
                  value: availableCount.toString(),
                  color: const Color(0xFF00F5C4),
                  bgColor: const Color(0xFF00F5C4).withOpacity(0.08),
                ),
                const SizedBox(width: 10),
                _StatCard(
                  label: "Occupied",
                  value: occupiedCount.toString(),
                  color: const Color(0xFFFF3B5C),
                  bgColor: const Color(0xFFFF3B5C).withOpacity(0.08),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Car Number Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF12121E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00F5C4).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: carController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        letterSpacing: 1.5,
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter Car Number (e.g. KA01AB1234)",
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.2),
                          fontSize: 13,
                          fontFamily: 'monospace',
                          letterSpacing: 0.5,
                        ),
                        prefixIcon: Icon(
                          Icons.directions_car_outlined,
                          color: const Color(0xFF00F5C4).withOpacity(0.5),
                          size: 18,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                      cursorColor: const Color(0xFF00F5C4),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _LegendDot(
                    color: const Color(0xFF00F5C4), label: "Available"),
                const SizedBox(width: 20),
                _LegendDot(
                    color: const Color(0xFFFF3B5C), label: "Occupied"),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: widget.totalSlots,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                bool occupied = parkedCars[index] != null;

                return GestureDetector(
                  onTap: () => handleSlotTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: occupied
                          ? const Color(0xFFFF3B5C).withOpacity(0.1)
                          : const Color(0xFF00F5C4).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: occupied
                            ? const Color(0xFFFF3B5C).withOpacity(0.4)
                            : const Color(0xFF00F5C4).withOpacity(0.25),
                        width: 1.5,
                      ),
                      boxShadow: occupied
                          ? [
                              BoxShadow(
                                color:
                                    const Color(0xFFFF3B5C).withOpacity(0.1),
                                blurRadius: 12,
                                spreadRadius: 1,
                              )
                            ]
                          : [
                              BoxShadow(
                                color:
                                    const Color(0xFF00F5C4).withOpacity(0.05),
                                blurRadius: 8,
                              )
                            ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          occupied
                              ? Icons.directions_car
                              : Icons.local_parking_outlined,
                          color: occupied
                              ? const Color(0xFFFF3B5C)
                              : const Color(0xFF00F5C4).withOpacity(0.6),
                          size: 22,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          occupied ? parkedCars[index]! : "S${index + 1}",
                          style: TextStyle(
                            color: occupied
                                ? Colors.white
                                : const Color(0xFF00F5C4).withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                            fontSize: occupied ? 11 : 13,
                            fontFamily: 'monospace',
                            letterSpacing: occupied ? 0.5 : 0,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!occupied)
                          Text(
                            "FREE",
                            style: TextStyle(
                              color: const Color(0xFF00F5C4).withOpacity(0.4),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card Widget ─────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: color.withOpacity(0.6),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Legend Dot Widget ────────────────────────────────────────────────────────
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.4), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}