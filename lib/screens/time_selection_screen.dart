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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Select Date & Time"),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // 1. Horizontal Date Selector
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "June 2026",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _availableDates.length,
              itemBuilder: (context, index) {
                final date = _availableDates[index];
                final isSelected = _selectedDateIndex == index;

                // Simple day formatting
                final weekDay = _getWeekDay(date.weekday);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDateIndex = index;
                      _selectedTime = null; // Reset time when date changes
                    });
                  },
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weekDay,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${date.day}",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
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

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Divider(),
          ),

          // 2. Time Slot Selection
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Morning Slots",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildTimeSlotGrid(_morningSlots),

                  const SizedBox(height: 24),

                  const Text(
                    "Afternoon Slots",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildTimeSlotGrid(_afternoonSlots),
                ],
              ),
            ),
          ),
        ],
      ),

      // 3. Bottom Confirmation Bar
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${widget.selectedServiceCount} items",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  Text(
                    "Total: RM ${widget.totalPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedTime == null ? null : () {
                    // Future: Process Booking & Show Success Screen
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("Confirm Booking"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for time slot buttons
  Widget _buildTimeSlotGrid(List<String> slots) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: slots.map((time) {
        final isSelected = _selectedTime == time;
        return InkWell(
          onTap: () {
            setState(() {
              _selectedTime = time;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: (MediaQuery.of(context).size.width - 56) / 3, // 3 columns
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.white,
              border: Border.all(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              time,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
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