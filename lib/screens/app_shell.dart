import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/pawly_theme.dart';
import '../data/pawly_repository.dart';
import '../models/pawly_models.dart';
import '../models/pet_model.dart';
import '../providers/auth_controller.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.user});

  final User user;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(user: widget.user, onNavigate: _setIndex),
      const ServicesPage(),
      const CarePage(),
      const PetsPage(),
      ProfilePage(user: widget.user),
    ];
    const destinations = [
      _Destination(Icons.home_outlined, Icons.home_rounded, 'Home'),
      _Destination(
        Icons.storefront_outlined,
        Icons.storefront_rounded,
        'Services',
      ),
      _Destination(Icons.task_alt_outlined, Icons.task_alt_rounded, 'Care'),
      _Destination(Icons.pets_outlined, Icons.pets_rounded, 'Pets'),
      _Destination(Icons.person_outline, Icons.person_rounded, 'Profile'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 860;
        final content = IndexedStack(index: _index, children: pages);
        if (!useRail) {
          return Scaffold(
            body: content,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _setIndex,
              destinations: destinations
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: _setIndex,
                  labelType: NavigationRailLabelType.all,
                  leading: const Padding(
                    padding: EdgeInsets.only(bottom: 28, top: 8),
                    child: _PawlyMark(),
                  ),
                  destinations: destinations
                      .map(
                        (item) => NavigationRailDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon),
                          label: Text(item.label),
                        ),
                      )
                      .toList(),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: content,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _setIndex(int value) => setState(() => _index = value);
}

class _Destination {
  const _Destination(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _PawlyMark extends StatelessWidget {
  const _PawlyMark();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        height: 42,
        width: 42,
        decoration: const BoxDecoration(
          color: PawlyColors.teal,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.pets_rounded, color: Colors.white),
      ),
      const SizedBox(height: 7),
      const Text('Pawly', style: TextStyle(fontWeight: FontWeight.w900)),
    ],
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.user, required this.onNavigate});

  final User user;
  final ValueChanged<int> onNavigate;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HomeData> _load() async {
    final repo = context.read<PawlyRepository>();
    final results = await Future.wait([
      repo.getProfile(),
      repo.getPets(),
      repo.getTodaysTasks(),
      repo.getBookings(),
    ]);
    return _HomeData(
      results[0] as UserProfile?,
      results[1] as List<Pet>,
      results[2] as List<CareTask>,
      results[3] as List<PawlyBooking>,
    );
  }

  Future<void> _refresh() async => setState(() => _future = _load());

  Future<void> _review(PawlyBooking booking) async {
    final repository = context.read<PawlyRepository>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Provider.value(
        value: repository,
        child: _ReviewSheet(booking: booking),
      ),
    );
    if (saved == true && mounted) {
      await _refresh();
      if (mounted) _showSnack(context, 'Thanks for sharing your review.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const _PageLoader();
        if (snapshot.hasError) return _LoadError(onRetry: _refresh);
        final data = snapshot.data!;
        final name = data.profile?.displayName.isNotEmpty == true
            ? data.profile!.displayName
            : (widget.user.userMetadata?['display_name'] as String? ?? 'there');
        final completed = data.tasks.where((task) => task.isCompleted).length;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            children: [
              Row(
                children: [
                  const _PawlyMark(),
                  const Spacer(),
                  _LocationChip(city: data.profile?.city ?? 'Kuala Lumpur'),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                'Hi, $name 👋',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 8),
              const Text('Everything your pet needs, in one happy place.'),
              const SizedBox(height: 24),
              _CareHero(
                petCount: data.pets.length,
                taskCount: data.tasks.length,
                completedCount: completed,
                onOpenCare: () => widget.onNavigate(2),
              ),
              const SizedBox(height: 28),
              _SectionHeading(
                title: 'Your pets',
                action: data.pets.isEmpty ? 'Add pet' : 'View all',
                onAction: () => widget.onNavigate(3),
              ),
              const SizedBox(height: 12),
              if (data.pets.isEmpty)
                _EmptyPrompt(
                  icon: Icons.pets_outlined,
                  title: 'Start with your best friend',
                  body:
                      'Create a pet profile to begin tracking care and making bookings.',
                  action: 'Add a pet',
                  onAction: () => widget.onNavigate(3),
                )
              else
                SizedBox(
                  height: 148,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: data.pets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) =>
                        _PetPreview(pet: data.pets[index]),
                  ),
                ),
              const SizedBox(height: 30),
              _SectionHeading(
                title: 'Today’s care',
                action: 'See routine',
                onAction: () => widget.onNavigate(2),
              ),
              const SizedBox(height: 12),
              if (data.tasks.isEmpty)
                _EmptyPrompt(
                  icon: Icons.task_alt_outlined,
                  title: 'A calm day ahead',
                  body: data.pets.isEmpty
                      ? 'Add a pet first, then set a routine.'
                      : 'Add meals, walks, or medication reminders for today.',
                  action: data.pets.isEmpty ? 'Add a pet' : 'Add routine',
                  onAction: () => widget.onNavigate(data.pets.isEmpty ? 3 : 2),
                )
              else
                ...data.tasks
                    .take(3)
                    .map((task) => _TaskPreview(task: task, pets: data.pets)),
              const SizedBox(height: 30),
              _SectionHeading(
                title: 'Your bookings',
                action: 'Find care',
                onAction: () => widget.onNavigate(1),
              ),
              const SizedBox(height: 12),
              if (data.bookings.isEmpty)
                _EmptyPrompt(
                  icon: Icons.calendar_month_outlined,
                  title: 'No bookings yet',
                  body:
                      'Choose a verified grooming or boarding partner when you are ready.',
                  action: 'Find care',
                  onAction: () => widget.onNavigate(1),
                )
              else
                ...data.bookings
                    .take(3)
                    .map(
                      (booking) => _BookingPreview(
                        booking: booking,
                        onReview:
                            booking.status == 'completed' && !booking.hasReview
                            ? () => _review(booking)
                            : null,
                      ),
                    ),
              const SizedBox(height: 30),
              _LocalCareBanner(onTap: () => widget.onNavigate(1)),
            ],
          ),
        );
      },
    );
  }
}

class _HomeData {
  const _HomeData(this.profile, this.pets, this.tasks, this.bookings);
  final UserProfile? profile;
  final List<Pet> pets;
  final List<CareTask> tasks;
  final List<PawlyBooking> bookings;
}

class _CareHero extends StatelessWidget {
  const _CareHero({
    required this.petCount,
    required this.taskCount,
    required this.completedCount,
    required this.onOpenCare,
  });

  final int petCount;
  final int taskCount;
  final int completedCount;
  final VoidCallback onOpenCare;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [PawlyColors.teal, PawlyColors.darkTeal],
      ),
      borderRadius: BorderRadius.circular(26),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                petCount == 0
                    ? 'A lovely start'
                    : '$completedCount of $taskCount care tasks done',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                petCount == 0
                    ? 'Your pet’s personalised dashboard is ready when you are.'
                    : 'Keep the little things on track today.',
                style: const TextStyle(color: Color(0xE6FFFFFF), height: 1.35),
              ),
              const SizedBox(height: 18),
              TextButton.icon(
                onPressed: onOpenCare,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(.16),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Open routine'),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        const Icon(Icons.favorite_rounded, color: Color(0xFFFFD9A6), size: 54),
      ],
    ),
  );
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.city});
  final String city;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 180),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.location_on_outlined,
          color: PawlyColors.teal,
          size: 18,
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            city,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.action,
    required this.onAction,
  });
  final String title;
  final String action;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      TextButton(onPressed: onAction, child: Text(action)),
    ],
  );
}

class _PetPreview extends StatelessWidget {
  const _PetPreview({required this.pet});
  final Pet pet;
  @override
  Widget build(BuildContext context) => Container(
    width: 155,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PetAvatar(pet: pet, radius: 28),
        const Spacer(),
        Text(
          pet.name,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          '${pet.species} · ${pet.breed}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}

class _TaskPreview extends StatelessWidget {
  const _TaskPreview({required this.task, required this.pets});
  final CareTask task;
  final List<Pet> pets;
  @override
  Widget build(BuildContext context) {
    final pet = pets
        .where((item) => item.id == task.petId)
        .cast<Pet?>()
        .firstOrNull;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Icon(
            task.isCompleted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: task.isCompleted
                ? PawlyColors.teal
                : const Color(0xFF98A2B3),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pet?.name ?? 'Your pet',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            _timeText(task.dueAt),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _BookingPreview extends StatelessWidget {
  const _BookingPreview({required this.booking, this.onReview});

  final PawlyBooking booking;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: const BoxDecoration(
            color: Color(0x1A167C80),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.calendar_month_outlined,
            color: PawlyColors.teal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.serviceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                '${booking.providerName} · ${_slotText(booking.startsAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 5),
              Text(
                _bookingStatusText(booking.status),
                style: TextStyle(
                  color: _bookingStatusColor(booking.status),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        if (onReview != null)
          TextButton(onPressed: onReview, child: const Text('Review')),
      ],
    ),
  );
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.booking});

  final PawlyBooking booking;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final _comment = TextEditingController();
  int _rating = 5;
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<PawlyRepository>().submitReview(
        bookingId: widget.booking.id,
        serviceId: widget.booking.serviceId,
        rating: _rating,
        comment: _comment.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        _showSnack(
          context,
          'Could not submit your review. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      12,
      24,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              height: 4,
              width: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFD0D5DD),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 19),
          const Text(
            'Rate your visit',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            '${widget.booking.serviceName} · ${widget.booking.providerName}',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 2,
            children: List.generate(
              5,
              (index) => IconButton(
                tooltip: '${index + 1} stars',
                onPressed: () => setState(() => _rating = index + 1),
                icon: Icon(
                  index < _rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: PawlyColors.orange,
                  size: 32,
                ),
              ),
            ),
          ),
          TextField(
            controller: _comment,
            maxLines: 3,
            maxLength: 1000,
            decoration: const InputDecoration(
              labelText: 'Tell other pet parents about it (optional)',
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const _ButtonSpinner()
                : const Text('Publish review'),
          ),
        ],
      ),
    ),
  );
}

class _LocalCareBanner extends StatelessWidget {
  const _LocalCareBanner({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(22),
    child: Ink(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PawlyColors.cream,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Icon(Icons.storefront_rounded, color: PawlyColors.orange, size: 34),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Care, close to home',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 3),
                Text(
                  'Discover trusted partners around Klang Valley.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded),
        ],
      ),
    ),
  );
}

class PetsPage extends StatefulWidget {
  const PetsPage({super.key});
  @override
  State<PetsPage> createState() => _PetsPageState();
}

class _PetsPageState extends State<PetsPage> {
  late Future<List<Pet>> _future;
  @override
  void initState() {
    super.initState();
    _future = context.read<PawlyRepository>().getPets();
  }

  Future<void> _refresh() async =>
      setState(() => _future = context.read<PawlyRepository>().getPets());

  Future<void> _addPet() async {
    final repository = context.read<PawlyRepository>();
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            Provider.value(value: repository, child: const PetEditorPage()),
      ),
    );
    if (saved == true && mounted) {
      await _refresh();
      if (mounted) _showSnack(context, 'Pet profile saved!');
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Pet>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done)
        return const _PageLoader();
      if (snapshot.hasError) return _LoadError(onRetry: _refresh);
      final pets = snapshot.data!;
      return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addPet,
          icon: const Icon(Icons.add),
          label: const Text('Add pet'),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 110),
            children: [
              Text(
                'My pets',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 8),
              const Text(
                'Their profiles travel with every booking and routine.',
              ),
              const SizedBox(height: 24),
              if (pets.isEmpty)
                _EmptyPrompt(
                  icon: Icons.pets_outlined,
                  title: 'Who’s your best friend?',
                  body: 'Add their details once to personalise Pawly.',
                  action: 'Add first pet',
                  onAction: _addPet,
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 760
                        ? 3
                        : constraints.maxWidth >= 480
                        ? 2
                        : 1;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pets.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisExtent: 172,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                      ),
                      itemBuilder: (_, index) => _PetCard(pet: pets[index]),
                    );
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _PetCard extends StatelessWidget {
  const _PetCard({required this.pet});
  final Pet pet;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        _PetAvatar(pet: pet, radius: 38),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                pet.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${pet.species} · ${pet.breed}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 7),
              Text(
                '${pet.weight.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: PawlyColors.teal,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PetAvatar extends StatelessWidget {
  const _PetAvatar({required this.pet, required this.radius});
  final Pet pet;
  final double radius;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: pet.species.toLowerCase() == 'cat'
        ? const Color(0xFFFFF1D8)
        : const Color(0xFFDDF3EF),
    backgroundImage: pet.imageUrl.isNotEmpty
        ? NetworkImage(pet.imageUrl)
        : null,
    child: pet.imageUrl.isEmpty
        ? Text(
            pet.species.toLowerCase() == 'cat' ? '🐱' : '🐶',
            style: TextStyle(fontSize: radius * .95),
          )
        : null,
  );
}

class PetEditorPage extends StatefulWidget {
  const PetEditorPage({super.key});
  @override
  State<PetEditorPage> createState() => _PetEditorPageState();
}

class _PetEditorPageState extends State<PetEditorPage> {
  static const _customBreed = 'Other / custom breed';
  static const _dogBreeds = [
    'Mixed breed',
    'Golden Retriever',
    'Labrador Retriever',
    'German Shepherd',
    'Poodle',
    'Shih Tzu',
    'Pomeranian',
    'Chihuahua',
    'Beagle',
    'French Bulldog',
    'Siberian Husky',
    'Rottweiler',
    'Border Collie',
    'Dachshund',
    'Corgi',
    'Maltese',
    'Yorkshire Terrier',
    'Pug',
    'Doberman',
    'Samoyed',
    'English Bulldog',
    'Jack Russell Terrier',
    'Miniature Pinscher',
    'Bichon Frise',
    'American Bully',
    _customBreed,
  ];
  static const _catBreeds = [
    'Domestic Shorthair',
    'Domestic Longhair',
    'Mixed breed',
    'Ragdoll',
    'Persian',
    'British Shorthair',
    'Maine Coon',
    'Siamese',
    'Scottish Fold',
    'Bengal',
    'Sphynx',
    'American Shorthair',
    'Russian Blue',
    'Norwegian Forest Cat',
    'Abyssinian',
    'Birman',
    'Bombay',
    'Devon Rex',
    'Exotic Shorthair',
    'Himalayan',
    'Munchkin',
    'Oriental Shorthair',
    'Turkish Angora',
    'Singapura',
    'Manx',
    _customBreed,
  ];

  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _customBreedController = TextEditingController();
  final _weight = TextEditingController();
  String _species = 'Dog';
  String _breedOption = _dogBreeds.first;
  String _gender = 'Female';
  DateTime _birthday = DateTime.now();
  bool _saving = false;

  List<String> get _breedOptions => _species == 'Dog' ? _dogBreeds : _catBreeds;

  String get _selectedBreed => _breedOption == _customBreed
      ? _customBreedController.text.trim()
      : _breedOption;

  void _changeSpecies(String species) {
    setState(() {
      _species = species;
      _breedOption = _breedOptions.first;
      _customBreedController.clear();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _customBreedController.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<PawlyRepository>().addPet(
        Pet(
          id: '',
          name: _name.text.trim(),
          species: _species,
          breed: _selectedBreed,
          gender: _gender,
          birthday: _birthday,
          weight: double.tryParse(_weight.text.trim()) ?? 0,
          imageUrl: '',
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted)
        _showSnack(
          context,
          'Couldn’t save the pet profile. Please try again.',
          isError: true,
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create pet profile')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              const Text(
                'Let’s make their Pawly profile.',
                style: TextStyle(fontSize: 17),
              ),
              const SizedBox(height: 26),
              const Text(
                'What kind of pet?',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(child: _speciesCard('Dog', '\u{1F436}', 'Dog')),
                  const SizedBox(width: 12),
                  Expanded(child: _speciesCard('Cat', '\u{1F431}', 'Cat')),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Pet name'),
                validator: _required,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _breedOption,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Breed',
                  helperText: 'Choose from 25 common breeds, or add your own.',
                ),
                items: _breedOptions
                    .map(
                      (breed) => DropdownMenuItem(
                        value: breed,
                        child: Text(breed, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _breedOption = value!),
              ),
              if (_breedOption == _customBreed) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _customBreedController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Your pet\'s breed',
                    hintText: 'Type the breed name',
                  ),
                  validator: _required,
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                          value: 'Not sure',
                          child: Text('Not sure'),
                        ),
                      ],
                      onChanged: (value) => setState(() => _gender = value!),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: _weight,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg, optional)',
                      ),
                      validator: (value) =>
                          value != null &&
                              value.trim().isNotEmpty &&
                              double.tryParse(value) == null
                          ? 'Enter a number'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0x14000000)),
                ),
                tileColor: Colors.white,
                leading: const Icon(Icons.cake_outlined),
                title: const Text('Birthday or estimated birthday'),
                subtitle: Text(
                  '${_birthday.day}/${_birthday.month}/${_birthday.year}',
                ),
                trailing: const Icon(Icons.calendar_month_outlined),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _birthday,
                    firstDate: DateTime(1995),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _birthday = picked);
                },
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const _ButtonSpinner()
                    : const Text('Save pet profile'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _speciesCard(String species, String emoji, String label) {
    final selected = _species == species;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _changeSpecies(species),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE0F4F0) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? PawlyColors.teal : const Color(0x1F000000),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 29)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required' : null;

class CarePage extends StatefulWidget {
  const CarePage({super.key});
  @override
  State<CarePage> createState() => _CarePageState();
}

class _CarePageState extends State<CarePage> {
  late Future<_CareData> _future;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_CareData> _load() async {
    final repo = context.read<PawlyRepository>();
    final results = await Future.wait([repo.getPets(), repo.getTodaysTasks()]);
    return _CareData(results[0] as List<Pet>, results[1] as List<CareTask>);
  }

  Future<void> _refresh() async => setState(() => _future = _load());

  Future<void> _toggle(CareTask task, bool value) async {
    try {
      await context.read<PawlyRepository>().setTaskCompleted(task.id, value);
      await _refresh();
    } catch (_) {
      if (mounted)
        _showSnack(context, 'Couldn’t update this task.', isError: true);
    }
  }

  Future<void> _addTask(List<Pet> pets) async {
    if (pets.isEmpty) {
      _showSnack(
        context,
        'Add a pet before creating a routine.',
        isError: true,
      );
      return;
    }
    final repository = context.read<PawlyRepository>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Provider.value(
        value: repository,
        child: _TaskEditorSheet(pets: pets),
      ),
    );
    if (saved == true && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_CareData>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done)
        return const _PageLoader();
      if (snapshot.hasError) return _LoadError(onRetry: _refresh);
      final data = snapshot.data!;
      final done = data.tasks.where((task) => task.isCompleted).length;
      return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _addTask(data.pets),
          icon: const Icon(Icons.add_task),
          label: const Text('Add routine'),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 110),
            children: [
              Text(
                'Daily care',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text('Today · $done of ${data.tasks.length} complete'),
              const SizedBox(height: 22),
              _ProgressCard(done: done, total: data.tasks.length),
              const SizedBox(height: 27),
              if (data.tasks.isEmpty)
                _EmptyPrompt(
                  icon: Icons.task_alt_outlined,
                  title: 'Nothing scheduled yet',
                  body: data.pets.isEmpty
                      ? 'Add a pet to start their care routine.'
                      : 'Add feeding, walks, medication, or another little reminder.',
                  action: data.pets.isEmpty ? 'Go to pets' : 'Add routine',
                  onAction: () => _addTask(data.pets),
                )
              else
                ...data.tasks.map(
                  (task) => _CareTaskCard(
                    task: task,
                    pets: data.pets,
                    onChanged: (value) => _toggle(task, value),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _CareData {
  const _CareData(this.pets, this.tasks);
  final List<Pet> pets;
  final List<CareTask> tasks;
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.done, required this.total});
  final int done;
  final int total;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: PawlyColors.cream,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today’s gentle rhythm',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          total == 0
              ? 'Your first routine is just one small step away.'
              : '$done task${done == 1 ? '' : 's'} finished. Nice work!',
        ),
        const SizedBox(height: 17),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : done / total,
            minHeight: 10,
            color: PawlyColors.orange,
            backgroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );
}

class _CareTaskCard extends StatelessWidget {
  const _CareTaskCard({
    required this.task,
    required this.pets,
    required this.onChanged,
  });
  final CareTask task;
  final List<Pet> pets;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    final petName =
        pets
            .where((pet) => pet.id == task.petId)
            .map((pet) => pet.name)
            .firstOrNull ??
        'Your pet';
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
      ),
      child: CheckboxListTile(
        value: task.isCompleted,
        onChanged: (value) => onChanged(value ?? false),
        activeColor: PawlyColors.teal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text('$petName · ${_timeText(task.dueAt)}'),
        secondary: _TaskIcon(category: task.category),
      ),
    );
  }
}

class _TaskIcon extends StatelessWidget {
  const _TaskIcon({required this.category});
  final String category;
  @override
  Widget build(BuildContext context) {
    final icon = switch (category) {
      'meal' => Icons.restaurant_rounded,
      'walk' => Icons.directions_walk_rounded,
      'medication' => Icons.medication_outlined,
      _ => Icons.favorite_outline_rounded,
    };
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Color(0x1A167C80),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: PawlyColors.teal),
    );
  }
}

class _TaskEditorSheet extends StatefulWidget {
  const _TaskEditorSheet({required this.pets});
  final List<Pet> pets;
  @override
  State<_TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<_TaskEditorSheet> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  late String _petId;
  String _category = 'meal';
  DateTime _dueAt = DateTime.now();
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _petId = widget.pets.first.id;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<PawlyRepository>().addCareTask(
        petId: _petId,
        title: _title.text,
        category: _category,
        dueAt: _dueAt,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted)
        _showSnack(
          context,
          'Couldn’t add routine. Please try again.',
          isError: true,
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      12,
      24,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SafeArea(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0D5DD),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Add to today’s routine',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _title,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'What needs doing?'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _petId,
              decoration: const InputDecoration(labelText: 'For'),
              items: widget.pets
                  .map(
                    (pet) =>
                        DropdownMenuItem(value: pet.id, child: Text(pet.name)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _petId = value!),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'meal',
                  icon: Icon(Icons.restaurant_rounded),
                  label: Text('Meal'),
                ),
                ButtonSegment(
                  value: 'walk',
                  icon: Icon(Icons.directions_walk_rounded),
                  label: Text('Walk'),
                ),
                ButtonSegment(
                  value: 'medication',
                  icon: Icon(Icons.medication_outlined),
                  label: Text('Medicine'),
                ),
              ],
              selected: {_category},
              onSelectionChanged: (value) =>
                  setState(() => _category = value.first),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const _ButtonSpinner()
                  : const Text('Add routine'),
            ),
          ],
        ),
      ),
    ),
  );
}

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});
  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  late Future<List<ServiceListing>> _future;
  String _query = '';
  String _selectedCategory = 'All';
  @override
  void initState() {
    super.initState();
    _future = context.read<PawlyRepository>().getServices();
  }

  Future<void> _refresh() async =>
      setState(() => _future = context.read<PawlyRepository>().getServices());

  Future<void> _book(ServiceListing service) async {
    final repository = context.read<PawlyRepository>();
    final booked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Provider.value(
        value: repository,
        child: _BookingSheet(service: service),
      ),
    );
    if (booked == true && mounted)
      _showSnack(context, 'Booking request sent to ${service.providerName}.');
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ServiceListing>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done)
        return const _PageLoader();
      if (snapshot.hasError) return _LoadError(onRetry: _refresh);
      final services = snapshot.data!.where((service) {
        final searchText =
            '${service.name} ${service.providerName} ${service.city}'
                .toLowerCase();
        final matchesSearch = searchText.contains(_query.toLowerCase());
        final matchesCategory =
            _selectedCategory == 'All' ||
            _serviceCategory(service) == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
          children: [
            Text(
              'Find pet care',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontSize: 32),
            ),
            const SizedBox(height: 8),
            const Text('Trusted local partners, clear prices in Ringgit.'),
            const SizedBox(height: 22),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search grooming, vets, boarding…',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['All', 'Grooming', 'Boarding', 'Vet care']
                  .map(
                    (category) => ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 22),
            if (services.isEmpty)
              _EmptyPrompt(
                icon: Icons.storefront_outlined,
                title: 'No matching services',
                body: _query.isEmpty
                    ? 'Your partner catalogue will appear here after the Supabase seed is installed.'
                    : 'Try another search, such as “grooming”.',
                action: 'Clear search',
                onAction: () => setState(() {
                  _query = '';
                  _selectedCategory = 'All';
                }),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 870
                      ? 3
                      : constraints.maxWidth >= 560
                      ? 2
                      : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: services.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisExtent: 318,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                    ),
                    itemBuilder: (_, index) => _ServiceCard(
                      service: services[index],
                      onBook: () => _book(services[index]),
                    ),
                  );
                },
              ),
          ],
        ),
      );
    },
  );
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onBook});
  final ServiceListing service;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(13),
              decoration: const BoxDecoration(
                color: Color(0x1A167C80),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _serviceIcon(service.name),
                color: PawlyColors.teal,
                size: 25,
              ),
            ),
            const Spacer(),
            if (service.isVerified)
              const Tooltip(
                message: 'Verified Pawly partner',
                child: Icon(Icons.verified_rounded, color: PawlyColors.teal),
              ),
          ],
        ),
        const SizedBox(height: 17),
        Text(
          service.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: Text(
                service.providerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: PawlyColors.teal,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1FAF7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _serviceCategory(service).toUpperCase(),
                style: const TextStyle(
                  color: PawlyColors.teal,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          service.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, height: 1.3),
        ),
        const Spacer(),
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 15,
              color: Color(0xFF667085),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                service.city,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const Icon(Icons.star_rounded, color: PawlyColors.orange, size: 17),
            Text(
              ' ${service.rating}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                'RM ${_priceText(service.price)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            FilledButton(onPressed: onBook, child: const Text('Book')),
          ],
        ),
      ],
    ),
  );
}

IconData _serviceIcon(String name) {
  final normalized = name.toLowerCase();
  if (normalized.contains('groom')) return Icons.content_cut_rounded;
  if (normalized.contains('vet') || normalized.contains('consult'))
    return Icons.medical_services_outlined;
  if (normalized.contains('board') || normalized.contains('hotel'))
    return Icons.hotel_rounded;
  return Icons.pets_rounded;
}

String _priceText(num price) =>
    price % 1 == 0 ? price.toInt().toString() : price.toStringAsFixed(2);

String _serviceCategory(ServiceListing service) {
  final text = '${service.name} ${service.serviceType}'.toLowerCase();
  if (text.contains('vet') || text.contains('consult')) return 'Vet care';
  if (text.contains('board') || text.contains('hotel')) return 'Boarding';
  return 'Grooming';
}

class _BookingSheet extends StatefulWidget {
  const _BookingSheet({required this.service});
  final ServiceListing service;
  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  late Future<_BookingData> _bookingDataFuture;
  final _notes = TextEditingController();
  String? _petId;
  String? _slotId;
  DateTime? _selectedDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bookingDataFuture = _loadBookingData();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<_BookingData> _loadBookingData() async {
    final repository = context.read<PawlyRepository>();
    final values = await Future.wait<dynamic>([
      repository.getPets(),
      repository.getAvailableSlots(widget.service.id),
      repository.getServiceReviews(widget.service.id),
    ]);
    return _BookingData(
      pets: values[0] as List<Pet>,
      slots: values[1] as List<ServiceSlot>,
      reviews: values[2] as List<ServiceReview>,
    );
  }

  Future<void> _retryLoading() async {
    setState(() => _bookingDataFuture = _loadBookingData());
    await _bookingDataFuture;
  }

  Future<void> _save() async {
    if (_petId == null) {
      _showSnack(context, 'Choose a pet to continue.', isError: true);
      return;
    }
    if (_slotId == null) {
      _showSnack(context, 'Choose an available time slot.', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<PawlyRepository>().createBooking(
        petId: _petId!,
        slotId: _slotId!,
        notes: _notes.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted)
        _showSnack(
          context,
          'Couldn’t submit your booking. Please try again.',
          isError: true,
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      12,
      24,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SafeArea(
      child: FutureBuilder<_BookingData>(
        future: _bookingDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(height: 280, child: _PageLoader());
          }
          if (snapshot.hasError) {
            return SizedBox(
              height: 280,
              child: _LoadError(onRetry: _retryLoading, error: snapshot.error),
            );
          }
          final data = snapshot.data!;
          final availableDates = _bookingDates(data.slots);
          final selectedDate =
              _selectedDate ??
              (availableDates.isEmpty ? null : availableDates.first);
          final slotsForDate = selectedDate == null
              ? <ServiceSlot>[]
              : data.slots
                    .where(
                      (slot) => _sameCalendarDay(slot.startsAt, selectedDate),
                    )
                    .toList();
          ServiceSlot? selectedSlot;
          for (final slot in data.slots) {
            if (slot.id == _slotId) selectedSlot = slot;
          }
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .84,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      height: 4,
                      width: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD0D5DD),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 19),
                  const Text(
                    'Reserve your visit',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 13),
                  _BookingServiceSummary(service: widget.service),
                  const SizedBox(height: 18),
                  if (data.pets.isEmpty)
                    const _BookingNotice(
                      icon: Icons.pets_outlined,
                      text: 'Add a pet profile before you can make a booking.',
                    )
                  else ...[
                    const _BookingStepLabel(
                      number: '1',
                      title: 'Choose your pet',
                    ),
                    const SizedBox(height: 9),
                    DropdownButtonFormField<String>(
                      value: _petId,
                      decoration: const InputDecoration(
                        labelText: 'Pet profile',
                      ),
                      hint: const Text('Choose the pet for this booking'),
                      items: data.pets
                          .map(
                            (pet) => DropdownMenuItem(
                              value: pet.id,
                              child: Text(
                                '${pet.species == 'Cat' ? '🐱' : '🐶'}  ${pet.name}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _petId = value),
                    ),
                    const SizedBox(height: 20),
                    if (data.slots.isEmpty)
                      const _BookingNotice(
                        icon: Icons.event_busy_outlined,
                        text:
                            'No future slots are available yet. Please check again soon.',
                      )
                    else ...[
                      const _BookingStepLabel(
                        number: '2',
                        title: 'Select a date',
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 76,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: availableDates.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 9),
                          itemBuilder: (_, index) {
                            final date = availableDates[index];
                            return _BookingDateChip(
                              date: date,
                              selected:
                                  selectedDate != null &&
                                  _sameCalendarDay(selectedDate, date),
                              onTap: () => setState(() {
                                _selectedDate = date;
                                _slotId = null;
                              }),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _BookingStepLabel(
                        number: '3',
                        title: 'Pick a time',
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: slotsForDate
                            .map(
                              (slot) => ChoiceChip(
                                avatar: const Icon(
                                  Icons.schedule_rounded,
                                  size: 15,
                                ),
                                label: Text(_timeText(slot.startsAt)),
                                selected: _slotId == slot.id,
                                onSelected: (_) =>
                                    setState(() => _slotId = slot.id),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (selectedSlot != null) ...[
                      const SizedBox(height: 16),
                      _BookingSelectionSummary(
                        service: widget.service,
                        slot: selectedSlot,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1FAF7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            color: PawlyColors.teal,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pay at venue',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'No payment is taken in Pawly yet. The partner will confirm your booking first.',
                                  style: TextStyle(fontSize: 12, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notes,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Note for the partner (optional)',
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _saving || data.slots.isEmpty ? null : _save,
                      child: _saving
                          ? const _ButtonSpinner()
                          : const Text('Send booking request'),
                    ),
                  ],
                  const SizedBox(height: 26),
                  const Text(
                    'Recent reviews',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 9),
                  if (data.reviews.isEmpty)
                    const Text(
                      'No reviews yet. Be the first pet parent to share an experience after a completed visit.',
                      style: TextStyle(fontSize: 13, height: 1.35),
                    )
                  else
                    ...data.reviews
                        .take(3)
                        .map((review) => _ServiceReviewTile(review: review)),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _BookingData {
  const _BookingData({
    required this.pets,
    required this.slots,
    required this.reviews,
  });

  final List<Pet> pets;
  final List<ServiceSlot> slots;
  final List<ServiceReview> reviews;
}

class _BookingServiceSummary extends StatelessWidget {
  const _BookingServiceSummary({required this.service});

  final ServiceListing service;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFF1FAF7),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(_serviceIcon(service.name), color: PawlyColors.teal),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _serviceCategory(service).toUpperCase(),
                style: const TextStyle(
                  color: PawlyColors.teal,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                service.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(service.providerName, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'RM ${_priceText(service.price)}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            Text(
              service.durationMinutes >= 720
                  ? 'Overnight'
                  : '${service.durationMinutes} min',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ],
    ),
  );
}

class _BookingStepLabel extends StatelessWidget {
  const _BookingStepLabel({required this.number, required this.title});

  final String number;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: PawlyColors.teal,
          shape: BoxShape.circle,
        ),
        child: Text(
          number,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(width: 9),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
    ],
  );
}

class _BookingDateChip extends StatelessWidget {
  const _BookingDateChip({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: selected ? PawlyColors.teal : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? PawlyColors.teal : const Color(0x1F000000),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _weekdayShort(date),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: selected ? Colors.white : const Color(0xFF101828),
            ),
          ),
          Text(
            _monthShort(date),
            style: TextStyle(
              fontSize: 10,
              color: selected ? Colors.white : const Color(0xFF667085),
            ),
          ),
        ],
      ),
    ),
  );
}

class _BookingSelectionSummary extends StatelessWidget {
  const _BookingSelectionSummary({required this.service, required this.slot});

  final ServiceListing service;
  final ServiceSlot slot;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E9),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0x33D78A18)),
    ),
    child: Row(
      children: [
        const Icon(Icons.receipt_long_rounded, color: PawlyColors.orange),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your booking summary',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                '${_slotText(slot.startsAt)} · ${service.name}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          'RM ${_priceText(service.price)}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _BookingNotice extends StatelessWidget {
  const _BookingNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF6E8),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(icon, color: PawlyColors.orange),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
      ],
    ),
  );
}

class _ServiceReviewTile extends StatelessWidget {
  const _ServiceReviewTile({required this.review});

  final ServiceReview review;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.reviewerName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Icon(Icons.star_rounded, color: PawlyColors.orange, size: 18),
              Text(
                ' ${review.rating}/5',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(review.comment, style: const TextStyle(height: 1.32)),
          ],
        ],
      ),
    ),
  );
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.user});
  final User user;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<UserProfile?> _future;
  @override
  void initState() {
    super.initState();
    _future = context.read<PawlyRepository>().getProfile();
  }

  Future<void> _refresh() async =>
      setState(() => _future = context.read<PawlyRepository>().getProfile());

  Future<void> _edit(UserProfile profile) async {
    final repository = context.read<PawlyRepository>();
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Provider.value(
        value: repository,
        child: _ProfileEditor(profile: profile),
      ),
    );
    if (changed == true && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<UserProfile?>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done)
        return const _PageLoader();
      if (snapshot.hasError) return _LoadError(onRetry: _refresh);
      final profile =
          snapshot.data ??
          UserProfile(
            id: widget.user.id,
            displayName:
                widget.user.userMetadata?['display_name'] as String? ??
                'Pet parent',
            phone: widget.user.userMetadata?['phone'] as String? ?? '',
            city: 'Kuala Lumpur',
          );
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
        children: [
          Text(
            'Profile',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0x1A167C80),
                  child: Text(
                    _initials(profile.displayName),
                    style: const TextStyle(
                      color: PawlyColors.teal,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(widget.user.email ?? ''),
                      const SizedBox(height: 5),
                      Text(
                        profile.city,
                        style: const TextStyle(
                          fontSize: 12,
                          color: PawlyColors.teal,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _edit(profile),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit profile',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Account',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 11),
          _ProfileTile(
            icon: Icons.person_outline,
            title: 'Personal details',
            subtitle: 'Name, mobile number and city',
            onTap: () => _edit(profile),
          ),
          _ProfileTile(
            icon: Icons.mail_outline,
            title: 'Email address',
            subtitle: widget.user.email ?? 'No email address',
          ),
          _ProfileTile(
            icon: Icons.help_outline,
            title: 'Help & support',
            subtitle: 'We’re here for you',
          ),
          const SizedBox(height: 23),
          OutlinedButton.icon(
            onPressed: () => context.read<AuthController>().signOut(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB42318),
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: Color(0x33B42318)),
            ),
          ),
        ],
      );
    },
  );
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
    ),
    child: ListTile(
      leading: Icon(icon, color: PawlyColors.teal),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}

class _ProfileEditor extends StatefulWidget {
  const _ProfileEditor({required this.profile});
  final UserProfile profile;
  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<_ProfileEditor> {
  late final TextEditingController _name = TextEditingController(
    text: widget.profile.displayName,
  );
  late final TextEditingController _phone = TextEditingController(
    text: widget.profile.phone,
  );
  late final TextEditingController _city = TextEditingController(
    text: widget.profile.city,
  );
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<PawlyRepository>().saveProfile(
        UserProfile(
          id: widget.profile.id,
          displayName: _name.text.trim(),
          phone: _phone.text.trim(),
          city: _city.text.trim(),
          avatarUrl: widget.profile.avatarUrl,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted)
        _showSnack(context, 'Couldn’t save your profile.', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      12,
      24,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SafeArea(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0D5DD),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 21),
            const Text(
              'Personal details',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile number',
                hintText: '012-345 6789',
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _city,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'City',
                hintText: 'e.g. Petaling Jaya',
              ),
              validator: _required,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const _ButtonSpinner()
                  : const Text('Save changes'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PageLoader extends StatelessWidget {
  const _PageLoader();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry, this.error});
  final Future<void> Function() onRetry;
  final Object? error;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: PawlyColors.teal,
            size: 44,
          ),
          const SizedBox(height: 16),
          const Text(
            'We couldn’t load this just now.',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check your connection or Supabase configuration, then try again.',
            textAlign: TextAlign.center,
          ),
          if (kDebugMode && error != null) ...[
            const SizedBox(height: 12),
            SelectableText(
              'Debug error: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFB42318),
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 18),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
  });
  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(23),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(13),
          decoration: const BoxDecoration(
            color: Color(0x1A167C80),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: PawlyColors.teal, size: 29),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(height: 1.35),
        ),
        const SizedBox(height: 15),
        TextButton(onPressed: onAction, child: Text(action)),
      ],
    ),
  );
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 21,
    width: 21,
    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
  );
}

void _showSnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? const Color(0xFFB42318) : PawlyColors.teal,
    ),
  );
}

String _timeText(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  return '${hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')} ${value.hour >= 12 ? 'PM' : 'AM'}';
}

List<DateTime> _bookingDates(List<ServiceSlot> slots) {
  final dates = <DateTime>[];
  for (final slot in slots) {
    if (!dates.any((date) => _sameCalendarDay(date, slot.startsAt))) {
      dates.add(
        DateTime(slot.startsAt.year, slot.startsAt.month, slot.startsAt.day),
      );
    }
  }
  dates.sort();
  return dates;
}

bool _sameCalendarDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

String _weekdayShort(DateTime value) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return weekdays[value.weekday - 1];
}

String _monthShort(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[value.month - 1];
}

String _slotText(DateTime value) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${weekdays[value.weekday - 1]}, ${value.day} ${months[value.month - 1]} · ${_timeText(value)}';
}

String _bookingStatusText(String status) => switch (status) {
  'confirmed' => 'CONFIRMED',
  'completed' => 'COMPLETED',
  'cancelled' => 'CANCELLED',
  _ => 'REQUEST SENT',
};

Color _bookingStatusColor(String status) => switch (status) {
  'confirmed' || 'completed' => PawlyColors.teal,
  'cancelled' => const Color(0xFFB42318),
  _ => PawlyColors.orange,
};

String _initials(String name) =>
    name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join()
        .isEmpty
    ? 'P'
    : name
          .trim()
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .take(2)
          .map((part) => part[0].toUpperCase())
          .join();
