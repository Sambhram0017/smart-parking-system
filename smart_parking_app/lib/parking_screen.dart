import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

class ParkingScreen extends StatefulWidget {
  final String buildingName;
  final String carNumber;
  final int allocatedSlot;

  const ParkingScreen({
    Key? key,
    required this.buildingName,
    required this.carNumber,
    required this.allocatedSlot,
  }) : super(key: key);

  @override
  _ParkingScreenState createState() => _ParkingScreenState();
}

class _ParkingScreenState extends State<ParkingScreen>
    with SingleTickerProviderStateMixin {
  List slots = [];
  bool isLoading = true;
  late AnimationController _animationController;

  // ── Color palette ──────────────────────────────────────────
  static const Color _bg = Color(0xFF0D1117);
  static const Color _surface = Color(0xFF161B22);
  static const Color _cardBg = Color(0xFF1C2128);
  static const Color _mySlot = Color(0xFF3B82F6);
  static const Color _occupied = Color(0xFFEF4444);
  static const Color _free = Color(0xFF22C55E);
  static const Color _textPrimary = Color(0xFFF0F6FC);
  static const Color _textSecondary = Color(0xFF8B949E);
  static const Color _divider = Color(0xFF30363D);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    fetchSlots();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ── UNCHANGED logic ────────────────────────────────────────
  Future<void> fetchSlots() async {
    try {
      final response =
          await http.get(Uri.parse("${ApiConfig.baseUrl}/slots"));
      final data = jsonDecode(response.body);
      setState(() {
        slots = data["data"];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }
  // ──────────────────────────────────────────────────────────

  int get _freeCount =>
      slots.where((s) => s["is_occupied"] != 1).length;
  int get _occupiedCount =>
      slots.where((s) => s["is_occupied"] == 1).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            if (!isLoading) _buildStatsRow(),
            if (!isLoading) _buildVehicleCard(),
            const SizedBox(height: 8),
            _buildLegend(),
            const SizedBox(height: 12),
            _buildSlotLabel(),
            Expanded(child: _buildGrid()),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _divider, width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _divider),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _textPrimary,
                size: 16,
              ),
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
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: _free,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "Live Parking View",
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => isLoading = true);
              fetchSlots();
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _divider),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: _textSecondary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _statChip(
            label: "Total",
            value: "10",
            color: _mySlot,
            icon: Icons.local_parking_rounded,
          ),
          const SizedBox(width: 10),
          _statChip(
            label: "Available",
            value: "$_freeCount",
            color: _free,
            icon: Icons.check_circle_outline_rounded,
          ),
          const SizedBox(width: 10),
          _statChip(
            label: "Occupied",
            value: "$_occupiedCount",
            color: _occupied,
            icon: Icons.directions_car_rounded,
          ),
        ],
      ),
    );
  }

  Widget _statChip({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Vehicle card ──────────────────────────────────────────
  Widget _buildVehicleCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _mySlot.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: _mySlot.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _mySlot.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.directions_car_filled_rounded,
                color: _mySlot,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your Vehicle",
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.carNumber,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _mySlot.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _mySlot.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  const Text(
                    "SLOT",
                    style: TextStyle(
                      color: _mySlot,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    "S${widget.allocatedSlot}",
                    style: const TextStyle(
                      color: _mySlot,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
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

  // ── Legend ────────────────────────────────────────────────
  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          _legendDot(_mySlot, "Your Slot"),
          const SizedBox(width: 16),
          _legendDot(_occupied, "Occupied"),
          const SizedBox(width: 16),
          _legendDot(_free, "Available"),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Section label ─────────────────────────────────────────
  Widget _buildSlotLabel() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Text(
        "Parking Floor",
        style: TextStyle(
          color: _textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  // ── Grid ──────────────────────────────────────────────────
  Widget _buildGrid() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _mySlot,
          strokeWidth: 2.5,
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: 10,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.88,
      ),
      itemBuilder: (context, index) {
        // ── UNCHANGED slot logic ──────────────────────────
        final slot = index < slots.length ? slots[index] : null;
        bool occupied = slot != null && slot["is_occupied"] == 1;
        bool isMySlot =
            (slot != null &&
                slot["slot_number"] == widget.allocatedSlot) ||
            (slot == null && (index + 1) == widget.allocatedSlot);
        // ─────────────────────────────────────────────────

        final Color slotColor =
            isMySlot ? _mySlot : occupied ? _occupied : _free;
        final String slotLabel =
            "S${slot != null ? slot["slot_number"] : index + 1}";

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final delay = index * 0.06;
            final animValue = Curves.easeOutCubic.transform(
              (_animationController.value - delay).clamp(0.0, 1.0) /
                  (1.0 - delay).clamp(0.01, 1.0),
            );
            return Opacity(
              opacity: animValue,
              child: Transform.translate(
                offset: Offset(0, 18 * (1 - animValue)),
                child: child,
              ),
            );
          },
          child: _SlotCard(
            label: slotLabel,
            color: slotColor,
            isMySlot: isMySlot,
            occupied: occupied,
          ),
        );
      },
    );
  }
}

// ── Slot Card Widget ──────────────────────────────────────────
class _SlotCard extends StatelessWidget {
  final String label;
  final Color color;
  final bool isMySlot;
  final bool occupied;

  const _SlotCard({
    required this.label,
    required this.color,
    required this.isMySlot,
    required this.occupied,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(isMySlot ? 0.8 : 0.35),
          width: isMySlot ? 2.0 : 1.2,
        ),
        boxShadow: isMySlot
            ? [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          // Top strip
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: color.withOpacity(0.6),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
            ),
          ),
          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isMySlot
                      ? Icons.directions_car_filled_rounded
                      : occupied
                          ? Icons.block_rounded
                          : Icons.local_parking_rounded,
                  color: color,
                  size: 26,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isMySlot
                        ? "YOURS"
                        : occupied
                            ? "TAKEN"
                            : "FREE",
                    style: TextStyle(
                      color: color,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}