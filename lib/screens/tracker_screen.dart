import 'package:flutter/material.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  // Simple state to hold our daily task completion
  final Map<String, bool> _dailyTasks = {
    'Morning Meal (Dry Kibble)': true,
    'Afternoon Walk (30 mins)': true,
    'Evening Meal (Wet Food)': false,
    'Heartworm Medication': false,
  };

  void _toggleTask(String taskName, bool? value) {
    setState(() {
      _dailyTasks[taskName] = value ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Count completed tasks for the progress bar
    final completedCount = _dailyTasks.values.where((isDone) => isDone).length;
    final progress = _dailyTasks.isNotEmpty ? completedCount / _dailyTasks.length : 0.0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Daily Care",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              // Future: Open calendar to view past logs
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Pet Selector & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.pets, size: 12, color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      Text("Milo", style: TextStyle(fontWeight: FontWeight.bold)),
                      Icon(Icons.keyboard_arrow_down, size: 18),
                    ],
                  ),
                ),
                const Text(
                  "Today, Jun 18",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. Daily Progress Tracker
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Great job!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "You've completed $completedCount of ${_dailyTasks.length} tasks today.",
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 3. To-Do List Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Routine",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Future: Add custom task
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.add, size: 16),
                      SizedBox(width: 4),
                      Text("Add Task"),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Generate Task Cards
            ..._dailyTasks.entries.map((entry) {
              return _buildTaskCard(
                title: entry.key,
                isCompleted: entry.value,
                onChanged: (val) => _toggleTask(entry.key, val),
              );
            }),

            const SizedBox(height: 24),

            // 4. Monthly/Upcoming Reminders
            const Text(
              "Upcoming",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.vaccines, color: Colors.blue),
                ),
                title: const Text("Annual Vaccination", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Due in 2 weeks"),
                trailing: ElevatedButton(
                  onPressed: () {
                    // Future: Link to clinic booking
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text("Book Vet"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard({
    required String title,
    required bool isCompleted,
    required ValueChanged<bool?> onChanged,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        value: isCompleted,
        onChanged: onChanged,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? Colors.grey : Colors.black87,
          ),
        ),
        activeColor: Theme.of(context).colorScheme.primary,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}