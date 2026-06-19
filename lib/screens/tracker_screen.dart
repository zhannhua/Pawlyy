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
      backgroundColor: Colors.white, // Ultra-clean pure white background
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(), // Native bounce effect
          slivers: [
            // 1. Apple-Style Dynamic Header
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              pinned: true,
              expandedHeight: 100.0,
              flexibleSpace: const FlexibleSpaceBar(
                titlePadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                title: Text(
                  "Daily Care",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    fontSize: 28,
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100, // Flat grey background, no shadow
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.calendar_month_outlined, color: Colors.black87, size: 20),
                    ),
                    onPressed: () {
                      // Future: Open calendar to view past logs
                    },
                  ),
                ),
              ],
            ),

            // 2. Main Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // 1. Pet Selector & Date (Flat Design)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100, // Flat grey, no shadow
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                child: Icon(Icons.pets, size: 14, color: Theme.of(context).colorScheme.primary),
                              ),
                              const SizedBox(width: 8),
                              const Text("Milo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
                            ],
                          ),
                        ),
                        Text(
                          "Today, Jun 18",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 2. Daily Progress Tracker (Sleek Gradient, No Shadow)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primary.withBlue(50).withRed(255), // Slight warm gradient
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        // Removed BoxShadow to match the flat aesthetic
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Great job, Alex!",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "You've completed $completedCount of ${_dailyTasks.length} tasks today.",
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15),
                          ),
                          const SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.black.withOpacity(0.15),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 8,
                            ),
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
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
                          child: const Row(
                            children: [
                              Icon(Icons.add, size: 18),
                              SizedBox(width: 4),
                              Text("Add", style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Generate Task Cards
                    ..._dailyTasks.entries.map((entry) {
                      return _AppleStyleTaskCard(
                        title: entry.key,
                        isCompleted: entry.value,
                        onChanged: (val) => _toggleTask(entry.key, val),
                      );
                    }),

                    const SizedBox(height: 32),

                    // 4. Monthly/Upcoming Reminders
                    const Text(
                      "Upcoming",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAppleStyleUpcomingCard(context),
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

  // Flat Pastel Upcoming Card
  Widget _buildAppleStyleUpcomingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.06), // Flat pastel background, no shadow
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white, // Crisp white pop against pastel
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.vaccines, color: Colors.blue.shade600, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Annual Vaccination", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3)),
                const SizedBox(height: 4),
                Text("Due in 2 weeks", style: TextStyle(color: Colors.blue.shade700, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              // Future: Link to clinic booking / time selection screen
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade600, // Solid pill button
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text("Book", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

// Minimalist Flat Task Card
class _AppleStyleTaskCard extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final ValueChanged<bool?> onChanged;

  const _AppleStyleTaskCard({
    required this.title,
    required this.isCompleted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isCompleted),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isCompleted ? Colors.grey.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted ? Colors.grey.shade200 : Colors.grey.shade300,
            width: 1.5,
          ),
          // Entirely removed BoxShadow for a clean, flat UI
        ),
        child: Row(
          children: [
            // Custom Animated Checkbox (Circle for Apple style)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isCompleted ? Theme.of(context).colorScheme.primary : Colors.transparent,
                shape: BoxShape.circle, // Apple uses circular checkboxes often
                border: Border.all(
                  color: isCompleted ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  color: isCompleted ? Colors.grey.shade500 : Colors.black87,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}