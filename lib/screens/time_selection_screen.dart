import 'package:flutter/material.dart';

class TimeSelectionScreen extends StatefulWidget {
  final double totalPrice;
  final int selectedServiceCount;

  const TimeSelectionScreen({
    super.key,
    required this.totalPrice,
    required this.selectedServiceCount,
  });

  @override
  State<TimeSelectionScreen> createState() => _TimeSelectionScreenState();
}

class _TimeSelectionScreenState extends State<TimeSelectionScreen> {
  // Brand colors from Pawly logo
  static const Color brandTeal = Color(0xFF2E8C9A);
  static const Color brandOrange = Color(0xFFF5A524);

  int _selectedDateIndex = 0;
  String? _selectedTime;

  final List<DateTime> _availableDates = List.generate(
    7,
        (index) => DateTime.now().add(Duration(days: index)),
  );

  final List<String> _morningSlots = ["09:00 AM", "10:30 AM", "11:00 AM"];
  final List<String> _afternoonSlots = ["01:00 PM", "02:30 PM", "04:00 PM", "05:00 PM"];

  String _getMonthYear(DateTime date) {
    const months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return "${months[date.month - 1]} ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final currentMonthYear = _getMonthYear(_availableDates[_selectedDateIndex]);

    return Scaffold(
      backgroundColor: Colors.white,

      // 1. Sleek Flat Bottom Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${widget.selectedServiceCount} items selected",
                    style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "RM ${widget.totalPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _selectedTime == null ? null : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Booking Confirmed! 🎉", style: TextStyle(fontWeight: FontWeight.bold)),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: brandTeal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Confirm", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomHeader(context),
            const SizedBox(height: 16),

            // 2. Month Display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                currentMonthYear,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Flat Horizontal Date Selector
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _availableDates.length,
                itemBuilder: (context, index) {
                  final date = _availableDates[index];
                  final isSelected = _selectedDateIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDateIndex = index;
                        _selectedTime = null;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 65,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? brandTeal : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? brandTeal : Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getWeekDay(date.weekday),
                            style: TextStyle(
                              color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey[500],
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${date.day}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Divider(color: Colors.grey.shade100),
            ),
            const SizedBox(height: 24),

            // 4. Time Slot Grid
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Morning Slots", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 16),
                    _buildTimeSlotGrid(_morningSlots),
                    const SizedBox(height: 32),
                    const Text("Afternoon Slots", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 16),
                    _buildTimeSlotGrid(_afternoonSlots),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          const Text("Select Time", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildTimeSlotGrid(List<String> slots) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: slots.map((time) {
        final isSelected = _selectedTime == time;
        return GestureDetector(
          onTap: () => setState(() => _selectedTime = time),
          child: Container(
            width: (MediaQuery.of(context).size.width - 60) / 3,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? brandTeal.withOpacity(0.08) : Colors.white,
              border: Border.all(
                color: isSelected ? brandTeal : Colors.grey.shade200,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              time,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
                color: isSelected ? brandTeal : Colors.grey[700],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getWeekDay(int weekday) {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[weekday - 1];
  }
}