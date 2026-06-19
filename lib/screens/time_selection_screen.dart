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
  // Track selected date and time
  int _selectedDateIndex = 0;
  String? _selectedTime;

  // Mock data for dates (Next 7 days)
  final List<DateTime> _availableDates = List.generate(
    7,
        (index) => DateTime.now().add(Duration(days: index)),
  );

  // Mock data for time slots
  final List<String> _morningSlots = ["09:00 AM", "10:30 AM", "11:00 AM"];
  final List<String> _afternoonSlots = ["01:00 PM", "02:30 PM", "04:00 PM", "05:00 PM"];

  // Helper to get Month and Year dynamically
  String _getMonthYear(DateTime date) {
    const months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return "${months[date.month - 1]} ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    // Get the month/year of the currently selected date
    final currentMonthYear = _getMonthYear(_availableDates[_selectedDateIndex]);

    return Scaffold(
      backgroundColor: Colors.white, // Ultra-clean pure white background

      // 1. Sleek Flat Bottom Bar (No Shadows)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1), // Crisp thin top line
          ),
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
                    "${widget.selectedServiceCount} items",
                    style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "RM ${widget.totalPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 22,
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.black87, // Match the premium vibe
                    ),
                  );
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87, // High-end sleek black button
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade100,
                  disabledForegroundColor: Colors.grey.shade400,
                  elevation: 0, // Flat design
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text("Confirm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

            // 2. Dynamic Month Header
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
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _availableDates.length,
                itemBuilder: (context, index) {
                  final date = _availableDates[index];
                  final isSelected = _selectedDateIndex == index;
                  final weekDay = _getWeekDay(date.weekday);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDateIndex = index;
                        _selectedTime = null; // Reset time when date changes
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 75,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                          width: 1.5,
                        ),
                        // NO BOX SHADOW HERE
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            weekDay,
                            style: TextStyle(
                              color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey[500],
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${date.day}",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
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
              child: Divider(height: 1, color: Colors.grey.shade100),
            ),
            const SizedBox(height: 32),

            // 4. Time Slot Selection
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Morning Slots",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 16),
                    _buildTimeSlotGrid(_morningSlots),

                    const SizedBox(height: 32),

                    const Text(
                      "Afternoon Slots",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 16),
                    _buildTimeSlotGrid(_afternoonSlots),

                    const SizedBox(height: 40), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modern Custom Header
  Widget _buildCustomHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Text(
            "Select Time",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Flat Pastel Time Slot Buttons
  Widget _buildTimeSlotGrid(List<String> slots) {
    return Wrap(
      spacing: 12,
      runSpacing: 16,
      children: slots.map((time) {
        final isSelected = _selectedTime == time;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTime = time;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: (MediaQuery.of(context).size.width - 48 - 24) / 3, // Perfect 3 column layout
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              // Pastel primary background when selected, flat white when not
              color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.white,
              border: Border.all(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(16),
              // NO BOX SHADOW HERE
            ),
            alignment: Alignment.center,
            child: Text(
              time,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[700],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getWeekDay(int weekday) {
    switch (weekday) {
      case 1: return "Mon";
      case 2: return "Tue";
      case 3: return "Wed";
      case 4: return "Thu";
      case 5: return "Fri";
      case 6: return "Sat";
      case 7: return "Sun";
      default: return "";
    }
  }
}