import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/pawly_theme.dart';
import '../data/pawly_repository.dart';
import '../models/pawly_models.dart';
import '../models/pet_model.dart';
import '../providers/auth_controller.dart';
import 'merchant/merchant_shell.dart';

/// Routes a verified partner account to its secure operational workspace.
/// Every other authenticated account receives the pet-parent experience.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) => FutureBuilder<ProviderProfile?>(
    future: context.read<PawlyRepository>().getMerchantProvider(),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return CustomerAppShell(user: user);
      }
      final provider = snapshot.data;
      return provider == null
          ? CustomerAppShell(user: user)
          : MerchantShell(provider: provider);
    },
  );
}

/// Phase 1 pet-parent experience: discovery, booking, care records and pets.
class CustomerAppShell extends StatefulWidget {
  const CustomerAppShell({super.key, required this.user});

  final User user;

  @override
  State<CustomerAppShell> createState() => _CustomerAppShellState();
}

class _CustomerAppShellState extends State<CustomerAppShell> {
  int _index = 0;

  void _goTo(int value) => setState(() => _index = value);

  @override
  Widget build(BuildContext context) {
    final pages = [
      _TodayPage(user: widget.user, onNavigate: _goTo),
      const _DiscoverPage(),
      _CareHubPage(onNavigate: _goTo),
      const _PetsPage(),
      _AccountPage(user: widget.user),
    ];
    const destinations = [
      _NavDestination('Today', Icons.home_outlined, Icons.home_rounded),
      _NavDestination('Find care', Icons.search_outlined, Icons.search_rounded),
      _NavDestination(
        'Care hub',
        Icons.favorite_border_rounded,
        Icons.favorite_rounded,
      ),
      _NavDestination('Pets', Icons.pets_outlined, Icons.pets_rounded),
      _NavDestination(
        'Account',
        Icons.person_outline_rounded,
        Icons.person_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 960;
        final content = IndexedStack(index: _index, children: pages);
        if (!isWide) {
          return Scaffold(
            body: content,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _goTo,
              destinations: [
                for (final item in destinations)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: item.label,
                  ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  minWidth: 124,
                  selectedIndex: _index,
                  onDestinationSelected: _goTo,
                  labelType: NavigationRailLabelType.all,
                  leading: const Padding(
                    padding: EdgeInsets.fromLTRB(12, 18, 12, 34),
                    child: _PawlyBrand(compact: true),
                  ),
                  destinations: [
                    for (final item in destinations)
                      NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: Text(item.label),
                      ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }
}

class _NavDestination {
  const _NavDestination(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _PawlyBrand extends StatelessWidget {
  const _PawlyBrand({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Pawly home',
    image: true,
    child: Image.asset(
      'assets/branding/pawly-logo.png',
      width: compact ? 84 : 116,
      height: compact ? 54 : 66,
      fit: BoxFit.contain,
    ),
  );
}

class _PageCanvas extends StatelessWidget {
  const _PageCanvas({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final gutter = constraints.maxWidth >= 720 ? 36.0 : 20.0;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: child,
            ),
          ),
        );
      },
    ),
  );
}

/// HOME CONTRACT
/// THESIS: Pawly begins with care discovery, not a generic dashboard.
/// OWN-WORLD: real pet photography, quiet mist surfaces, decisive teal type,
/// and editorial service rows rather than a grid of floating cards.
/// STORY: a pet parent quickly chooses the kind of care they need, sees local
/// options, then keeps an eye on their next booking and today's routine.
/// FIRST VIEWPORT: a real-photo discovery panel leads; care choices and the
/// primary Find care action sit immediately below it.
class _TodayPage extends StatefulWidget {
  const _TodayPage({required this.user, required this.onNavigate});
  final User user;
  final ValueChanged<int> onNavigate;

  @override
  State<_TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<_TodayPage> {
  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardData> _load() async {
    final repo = context.read<PawlyRepository>();
    final results = await Future.wait([
      repo.getProfile(),
      repo.getPets(),
      repo.getTodaysTasks(),
      repo.getBookings(),
      repo.getServices(),
    ]);
    return _DashboardData(
      profile: results[0] as UserProfile?,
      pets: results[1] as List<Pet>,
      tasks: results[2] as List<CareTask>,
      bookings: results[3] as List<PawlyBooking>,
      services: results[4] as List<ServiceListing>,
    );
  }

  Future<void> _reload() async => setState(() => _future = _load());

  Future<void> _review(PawlyBooking booking) async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Provider.value(
        value: context.read<PawlyRepository>(),
        child: _ReviewSheet(booking: booking),
      ),
    );
    if (submitted == true && mounted) {
      await _reload();
      if (mounted) {
        _notice(context, 'Thanks - your review helps other pet parents.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => _PageCanvas(
    child: FutureBuilder<_DashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _ScreenLoader();
        }
        if (snapshot.hasError) {
          return _LoadFailure(onRetry: _reload, error: snapshot.error);
        }
        final data = snapshot.data!;
        final name = data.profile?.displayName.trim().isNotEmpty == true
            ? data.profile!.displayName.trim().split(' ').first
            : ((widget.user.userMetadata?['display_name'] as String?)
                      ?.split(' ')
                      .first ??
                  'there');
        return _DiscoveryFirstHome(
          name: name,
          city: data.profile?.city ?? 'Kuala Lumpur',
          pets: data.pets,
          tasks: data.tasks,
          bookings: data.bookings,
          services: data.services,
          onRefresh: _reload,
          onFindCare: () => widget.onNavigate(1),
          onOpenCare: () => widget.onNavigate(data.pets.isEmpty ? 3 : 2),
          onReview: _review,
        );
      },
    ),
  );
}

class _DiscoveryFirstHome extends StatelessWidget {
  const _DiscoveryFirstHome({
    required this.name,
    required this.city,
    required this.pets,
    required this.tasks,
    required this.bookings,
    required this.services,
    required this.onRefresh,
    required this.onFindCare,
    required this.onOpenCare,
    required this.onReview,
  });

  final String name;
  final String city;
  final List<Pet> pets;
  final List<CareTask> tasks;
  final List<PawlyBooking> bookings;
  final List<ServiceListing> services;
  final RefreshCallback onRefresh;
  final VoidCallback onFindCare;
  final VoidCallback onOpenCare;
  final ValueChanged<PawlyBooking> onReview;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final upcoming =
        bookings
            .where((booking) => booking.startsAt.isAfter(DateTime.now()))
            .toList()
          ..sort((first, second) => first.startsAt.compareTo(second.startsAt));
    final reviewBooking = bookings
        .where((booking) => booking.status == 'completed' && !booking.hasReview)
        .toList()
        .firstOrNull;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 18, bottom: 48),
        children: [
          Row(
            children: [
              const _PawlyBrand(),
              const Spacer(),
              _LocationPill(city: city),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            '$greeting, $name',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 30,
              letterSpacing: -1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Make room for the care that keeps them well.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          _CareDiscoveryHero(onFindCare: onFindCare),
          const SizedBox(height: 42),
          Text(
            'What does your pet need?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 27,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Start with a care type, then choose the right local provider.',
          ),
          const SizedBox(height: 18),
          _CareCategoryMenu(onFindCare: onFindCare),
          const SizedBox(height: 44),
          _RowHeader(
            title: 'Nearby care',
            action: 'View all',
            onAction: onFindCare,
          ),
          const SizedBox(height: 4),
          if (services.isEmpty)
            _HomeInlineEmpty(onFindCare: onFindCare)
          else
            ...services
                .take(3)
                .map(
                  (service) =>
                      _NearbyCareRow(service: service, onTap: onFindCare),
                ),
          const SizedBox(height: 42),
          if (upcoming.isNotEmpty)
            _AppointmentPreview(booking: upcoming.first, onTap: onFindCare)
          else
            _NoBookingPrompt(onFindCare: onFindCare),
          const SizedBox(height: 38),
          _RoutinePreview(
            petCount: pets.length,
            taskCount: tasks.length,
            completedCount: completedTasks,
            onOpenCare: onOpenCare,
          ),
          if (reviewBooking != null) ...[
            const SizedBox(height: 24),
            _ReviewNudge(
              booking: reviewBooking,
              onTap: () => onReview(reviewBooking),
            ),
          ],
        ],
      ),
    );
  }
}

class _CareDiscoveryHero extends StatelessWidget {
  const _CareDiscoveryHero({required this.onFindCare});
  final VoidCallback onFindCare;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 680;
        final photo = Semantics(
          image: true,
          label: 'A dog enjoying a relaxed day of care',
          child: Image.asset(
            'assets/images/pawly-care-real.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        );
        final copy = Container(
          color: PawlyColors.darkTeal,
          padding: EdgeInsets.all(wide ? 34 : 26),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Care, thoughtfully arranged.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 29,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.05,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Compare verified local grooming, boarding and veterinary care before you book.',
                style: TextStyle(color: Color(0xD9FFFFFF), height: 1.45),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: PawlyColors.darkTeal,
                  minimumSize: const Size(0, 48),
                ),
                onPressed: onFindCare,
                icon: const Icon(Icons.search_rounded, size: 19),
                label: const Text('Find pet care'),
              ),
            ],
          ),
        );
        return wide
            ? SizedBox(
                height: 288,
                child: Row(
                  children: [
                    Expanded(flex: 9, child: photo),
                    Expanded(flex: 11, child: copy),
                  ],
                ),
              )
            : Column(
                children: [
                  SizedBox(height: 210, width: double.infinity, child: photo),
                  copy,
                ],
              );
      },
    ),
  );
}

class _CareCategoryMenu extends StatelessWidget {
  const _CareCategoryMenu({required this.onFindCare});
  final VoidCallback onFindCare;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final vertical = constraints.maxWidth >= 760;
      final choices = [
        _CareCategoryLink(
          icon: Icons.content_cut_rounded,
          tint: PawlyColors.apricotSoft,
          iconColor: PawlyColors.apricot,
          title: 'Grooming',
          detail: 'Baths, trims and tidy-ups.',
          vertical: vertical,
          onTap: onFindCare,
        ),
        _CareCategoryLink(
          icon: Icons.bed_outlined,
          tint: PawlyColors.tealSoft,
          iconColor: PawlyColors.teal,
          title: 'Boarding',
          detail: 'Comfortable overnight care.',
          vertical: vertical,
          onTap: onFindCare,
        ),
        _CareCategoryLink(
          icon: Icons.medical_services_outlined,
          tint: const Color(0xFFE8EEF9),
          iconColor: const Color(0xFF3D65A8),
          title: 'Veterinary',
          detail: 'Consultations and check-ups.',
          vertical: vertical,
          onTap: onFindCare,
        ),
      ];
      return vertical
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: choices[0]),
                const VerticalDivider(width: 1, indent: 10, endIndent: 10),
                Expanded(child: choices[1]),
                const VerticalDivider(width: 1, indent: 10, endIndent: 10),
                Expanded(child: choices[2]),
              ],
            )
          : Column(
              children: [
                choices[0],
                const Divider(height: 1),
                choices[1],
                const Divider(height: 1),
                choices[2],
              ],
            );
    },
  );
}

class _CareCategoryLink extends StatelessWidget {
  const _CareCategoryLink({
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.title,
    required this.detail,
    required this.vertical,
    required this.onTap,
  });
  final IconData icon;
  final Color tint;
  final Color iconColor;
  final String title;
  final String detail;
  final bool vertical;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconBox = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: iconColor),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(detail, style: const TextStyle(fontSize: 12.5, height: 1.3)),
      ],
    );
    return Semantics(
      button: true,
      label: 'Explore $title care',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: vertical
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      iconBox,
                      const SizedBox(height: 14),
                      text,
                      const SizedBox(height: 12),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: PawlyColors.teal,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      iconBox,
                      const SizedBox(width: 14),
                      Expanded(child: text),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: PawlyColors.teal,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _NearbyCareRow extends StatelessWidget {
  const _NearbyCareRow({required this.service, required this.onTap});
  final ServiceListing service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: PawlyColors.line)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ServiceIcon(
              icon: _homeServiceIcon(service.serviceType),
              background: service.serviceType == 'boarding'
                  ? PawlyColors.tealSoft
                  : service.serviceType == 'veterinary'
                  ? const Color(0xFFE8EEF9)
                  : PawlyColors.apricotSoft,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${service.providerName} · ${service.city}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: PawlyColors.teal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      _Meta(
                        icon: Icons.schedule_outlined,
                        label: _durationText(service.durationMinutes),
                      ),
                      if (service.isVerified)
                        const _Meta(
                          icon: Icons.verified_rounded,
                          label: 'Verified',
                          accent: PawlyColors.teal,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'RM ${_money(service.price)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: PawlyColors.darkTeal,
                  ),
                ),
                const SizedBox(height: 9),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: PawlyColors.teal,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _HomeInlineEmpty extends StatelessWidget {
  const _HomeInlineEmpty({required this.onFindCare});
  final VoidCallback onFindCare;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 22),
    child: Row(
      children: [
        const Icon(Icons.storefront_outlined, color: PawlyColors.teal),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Care listings will appear here when a partner is available.',
          ),
        ),
        TextButton(onPressed: onFindCare, child: const Text('Explore')),
      ],
    ),
  );
}

class _AppointmentPreview extends StatelessWidget {
  const _AppointmentPreview({required this.booking, required this.onTap});
  final PawlyBooking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: PawlyColors.apricotSoft,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                color: PawlyColors.apricot,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your next booking',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: PawlyColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking.serviceName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${booking.providerName} · ${_bookingDateText(booking.startsAt)}',
                    style: const TextStyle(fontSize: 12.5, height: 1.35),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: PawlyColors.darkTeal,
            ),
          ],
        ),
      ),
    ),
  );
}

class _NoBookingPrompt extends StatelessWidget {
  const _NoBookingPrompt({required this.onFindCare});
  final VoidCallback onFindCare;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onFindCare,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: PawlyColors.line),
            bottom: BorderSide(color: PawlyColors.line),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: PawlyColors.teal),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nothing booked yet',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Choose a date and time when you find the right care.',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: PawlyColors.teal),
          ],
        ),
      ),
    ),
  );
}

class _ReviewNudge extends StatelessWidget {
  const _ReviewNudge({required this.booking, required this.onTap});
  final PawlyBooking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: PawlyColors.line),
            bottom: BorderSide(color: PawlyColors.line),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.rate_review_outlined, color: PawlyColors.teal),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tell other pet parents about ${booking.serviceName}.',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: PawlyColors.teal),
          ],
        ),
      ),
    ),
  );
}

class _RoutinePreview extends StatelessWidget {
  const _RoutinePreview({
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
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(7, (index) => today.add(Duration(days: index)));
    final summary = petCount == 0
        ? 'Add a pet profile to begin a simple routine.'
        : taskCount == 0
        ? 'No routine is scheduled for today.'
        : '$completedCount of $taskCount tasks complete today.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RowHeader(
          title: 'Today\'s routine',
          action: petCount == 0 ? 'Add pet' : 'Open care hub',
          onAction: onOpenCare,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            color: PawlyColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: PawlyColors.line),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  for (final day in days)
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _weekday(day),
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: PawlyColors.muted,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _sameDay(day, today)
                                  ? PawlyColors.teal
                                  : PawlyColors.mist,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _sameDay(day, today)
                                    ? Colors.white
                                    : PawlyColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.favorite_border_rounded,
                    color: PawlyColors.teal,
                    size: 20,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(summary, style: const TextStyle(fontSize: 13)),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: PawlyColors.teal,
                    size: 19,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

IconData _homeServiceIcon(String serviceType) => switch (serviceType) {
  'boarding' => Icons.bed_outlined,
  'veterinary' => Icons.medical_services_outlined,
  _ => Icons.content_cut_rounded,
};

class _DashboardData {
  const _DashboardData({
    required this.profile,
    required this.pets,
    required this.tasks,
    required this.bookings,
    required this.services,
  });
  final UserProfile? profile;
  final List<Pet> pets;
  final List<CareTask> tasks;
  final List<PawlyBooking> bookings;
  final List<ServiceListing> services;
}

class _DiscoverPage extends StatefulWidget {
  const _DiscoverPage();
  @override
  State<_DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<_DiscoverPage> {
  late Future<List<ServiceListing>> _future;
  String _query = '';
  _ServiceFilter _filter = _ServiceFilter.all;

  @override
  void initState() {
    super.initState();
    _future = context.read<PawlyRepository>().getServices();
  }

  Future<void> _reload() async =>
      setState(() => _future = context.read<PawlyRepository>().getServices());

  bool _matches(ServiceListing service) {
    final term = _query.toLowerCase().trim();
    final searchMatch =
        term.isEmpty ||
        '${service.name} ${service.providerName} ${service.city} ${service.description}'
            .toLowerCase()
            .contains(term);
    final serviceName = '${service.name} ${service.providerName}'.toLowerCase();
    final filterMatch = switch (_filter) {
      _ServiceFilter.all => true,
      _ServiceFilter.grooming =>
        service.serviceType == 'grooming' && !serviceName.contains('vet'),
      _ServiceFilter.boarding => service.serviceType == 'boarding',
      _ServiceFilter.vet => service.serviceType == 'veterinary',
    };
    return searchMatch && filterMatch;
  }

  Future<void> _openBooking(ServiceListing service) async {
    final completed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Provider.value(
        value: context.read<PawlyRepository>(),
        child: _BookingSheet(service: service),
      ),
    );
    if (completed == true && mounted)
      _notice(
        context,
        'Booking request sent. The provider will confirm it soon.',
      );
  }

  @override
  Widget build(BuildContext context) => _PageCanvas(
    child: FutureBuilder<List<ServiceListing>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const _ScreenLoader();
        if (snapshot.hasError)
          return _LoadFailure(onRetry: _reload, error: snapshot.error);
        final services = snapshot.data!.where(_matches).toList();
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 24, bottom: 40),
            children: [
              const _SectionHeader(
                eyebrow: 'KLANG VALLEY',
                title: 'Find care you can trust',
              ),
              const SizedBox(height: 8),
              const Text(
                'Compare services, choose a suitable date and time, then send a clear booking request.',
              ),
              const SizedBox(height: 20),
              const _DiscoveryEditorial(),
              const SizedBox(height: 24),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  labelText: 'Search care',
                  hintText: 'Grooming, boarding, vet clinic...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final item in _ServiceFilter.values) ...[
                      _FilterChip(
                        label: item.label,
                        icon: item.icon,
                        selected: _filter == item,
                        onTap: () => setState(() => _filter = item),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _RowHeader(
                title:
                    '${services.length} available service${services.length == 1 ? '' : 's'}',
              ),
              const SizedBox(height: 12),
              if (services.isEmpty)
                _EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No care matches that search',
                  body:
                      'Try another term or select All care to see every active partner.',
                  action: 'Show all care',
                  onAction: () => setState(() {
                    _query = '';
                    _filter = _ServiceFilter.all;
                  }),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 860 ? 2 : 1;
                    if (columns == 1) {
                      return Column(
                        children: [
                          for (final service in services) ...[
                            _ServiceCard(
                              service: service,
                              onBook: () => _openBooking(service),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      );
                    }
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: services.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.62,
                          ),
                      itemBuilder: (context, index) => _ServiceCard(
                        service: services[index],
                        onBook: () => _openBooking(services[index]),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 22),
              const _DisclosureNote(),
            ],
          ),
        );
      },
    ),
  );
}

class _DiscoveryEditorial extends StatelessWidget {
  const _DiscoveryEditorial();

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: SizedBox(
      height: 170,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/pawly-care-real.jpg', fit: BoxFit.cover),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              color: const Color(0xEFFFFFFF),
              child: const Text(
                'Thoughtful care starts locally.',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

enum _ServiceFilter {
  all('All care', Icons.grid_view_rounded),
  grooming('Grooming', Icons.content_cut_rounded),
  boarding('Boarding', Icons.bed_outlined),
  vet('Vet', Icons.medical_services_outlined);

  const _ServiceFilter(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _CareHubPage extends StatefulWidget {
  const _CareHubPage({required this.onNavigate});

  final ValueChanged<int> onNavigate;
  @override
  State<_CareHubPage> createState() => _CareHubPageState();
}

class _CareHubPageState extends State<_CareHubPage> {
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

  Future<void> _reload() async => setState(() => _future = _load());

  Future<void> _addTask(List<Pet> pets) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Provider.value(
        value: context.read<PawlyRepository>(),
        child: _CareTaskSheet(pets: pets),
      ),
    );
    if (added == true && mounted) await _reload();
  }

  Future<void> _toggle(CareTask task, bool value) async {
    try {
      await context.read<PawlyRepository>().setTaskCompleted(task.id, value);
      if (mounted) await _reload();
    } catch (_) {
      if (mounted)
        _notice(
          context,
          'That task could not be updated. Please try again.',
          error: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) => _PageCanvas(
    child: FutureBuilder<_CareData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const _ScreenLoader();
        if (snapshot.hasError)
          return _LoadFailure(onRetry: _reload, error: snapshot.error);
        final data = snapshot.data!;
        final remaining = data.tasks.where((task) => !task.isCompleted).length;
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 24, bottom: 40),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: _SectionHeader(
                      eyebrow: 'PET CARE HUB',
                      title: 'Today\'s routine',
                    ),
                  ),
                  Semantics(
                    label: 'Add a care task',
                    button: true,
                    child: IconButton.filled(
                      tooltip: 'Add care task',
                      onPressed: data.pets.isEmpty
                          ? null
                          : () => _addTask(data.pets),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data.pets.isEmpty
                    ? 'Add a pet profile first, then create care reminders.'
                    : '$remaining task${remaining == 1 ? '' : 's'} still need your attention.',
              ),
              const SizedBox(height: 20),
              _CareProgressCard(
                total: data.tasks.length,
                complete: data.tasks.where((task) => task.isCompleted).length,
              ),
              const SizedBox(height: 28),
              _RowHeader(
                title: 'Schedule for today',
                action: data.pets.isEmpty ? null : 'Add task',
                onAction: data.pets.isEmpty ? null : () => _addTask(data.pets),
              ),
              const SizedBox(height: 12),
              if (data.pets.isEmpty)
                _EmptyState(
                  icon: Icons.pets_outlined,
                  title: 'Build a profile before a routine',
                  body:
                      'A pet profile keeps tasks, bookings and health details connected to the right pet.',
                  action: 'Open pets',
                  onAction: () => widget.onNavigate(3),
                )
              else if (data.tasks.isEmpty)
                _EmptyState(
                  icon: Icons.schedule_outlined,
                  title: 'Make today easier',
                  body:
                      'Add a meal, medication, walk or care reminder. You can tick it off when it is done.',
                  action: 'Add a care task',
                  onAction: () => _addTask(data.pets),
                )
              else
                ...data.tasks.map(
                  (task) => _CareTaskTile(
                    task: task,
                    onChanged: (value) => _toggle(task, value),
                  ),
                ),
              const SizedBox(height: 28),
              _CareHubInfo(pets: data.pets),
            ],
          ),
        );
      },
    ),
  );
}

class _CareData {
  const _CareData(this.pets, this.tasks);
  final List<Pet> pets;
  final List<CareTask> tasks;
}

class _PetsPage extends StatefulWidget {
  const _PetsPage();
  @override
  State<_PetsPage> createState() => _PetsPageState();
}

class _PetsPageState extends State<_PetsPage> {
  late Future<List<Pet>> _future;
  @override
  void initState() {
    super.initState();
    _future = context.read<PawlyRepository>().getPets();
  }

  Future<void> _reload() async =>
      setState(() => _future = context.read<PawlyRepository>().getPets());

  Future<void> _addPet() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Provider.value(
        value: context.read<PawlyRepository>(),
        child: const _PetProfileSheet(),
      ),
    );
    if (saved == true && mounted) {
      await _reload();
      if (mounted) _notice(context, 'Pet profile saved.');
    }
  }

  Future<void> _editPet(Pet pet) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Provider.value(
        value: context.read<PawlyRepository>(),
        child: _PetProfileSheet(pet: pet),
      ),
    );
    if (saved == true && mounted) {
      await _reload();
      if (mounted) _notice(context, 'Pet profile updated.');
    }
  }

  Future<void> _deletePet(Pet pet) async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${pet.name}?'),
        content: const Text(
          'This removes the pet profile and its care reminders. Existing booking records are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep profile'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: PawlyColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (delete != true || !mounted) return;
    try {
      await context.read<PawlyRepository>().deletePet(pet.id);
      await _reload();
      if (mounted) _notice(context, '${pet.name} has been removed.');
    } catch (_) {
      if (mounted) {
        _notice(
          context,
          'This pet has a booking or could not be removed.',
          error: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => _PageCanvas(
    child: FutureBuilder<List<Pet>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const _ScreenLoader();
        if (snapshot.hasError)
          return _LoadFailure(onRetry: _reload, error: snapshot.error);
        final pets = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 24, bottom: 40),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: _SectionHeader(
                      eyebrow: 'PET PROFILES',
                      title: 'Every pet, remembered',
                    ),
                  ),
                  Semantics(
                    label: 'Add a pet profile',
                    button: true,
                    child: IconButton.filled(
                      tooltip: 'Add a pet',
                      onPressed: _addPet,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Use a profile when you make a booking or set care reminders.',
              ),
              const SizedBox(height: 24),
              if (pets.isEmpty)
                _EmptyState(
                  icon: Icons.pets_outlined,
                  title: 'Add your first pet',
                  body:
                      'Keep their name, species, breed and basic details ready for every future booking.',
                  action: 'Create pet profile',
                  onAction: _addPet,
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final count = constraints.maxWidth >= 850
                        ? 3
                        : constraints.maxWidth >= 520
                        ? 2
                        : 1;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pets.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: count,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: count == 1 ? 2.7 : 1.2,
                      ),
                      itemBuilder: (context, index) => _PetProfileCard(
                        pet: pets[index],
                        onEdit: () => _editPet(pets[index]),
                        onDelete: () => _deletePet(pets[index]),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 22),
              _InfoCard(
                icon: Icons.verified_user_outlined,
                title: 'Your pet details stay private',
                body:
                    'Pawly keeps profiles linked to your signed-in account. Providers see the information needed for a booking, not your full account data.',
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _AccountPage extends StatefulWidget {
  const _AccountPage({required this.user});
  final User user;
  @override
  State<_AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<_AccountPage> {
  late Future<UserProfile?> _future;
  @override
  void initState() {
    super.initState();
    _future = context.read<PawlyRepository>().getProfile();
  }

  Future<void> _reload() async =>
      setState(() => _future = context.read<PawlyRepository>().getProfile());

  Future<void> _edit(UserProfile profile) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Provider.value(
        value: context.read<PawlyRepository>(),
        child: _ProfileSheet(profile: profile),
      ),
    );
    if (saved == true && mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) => _PageCanvas(
    child: FutureBuilder<UserProfile?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const _ScreenLoader();
        if (snapshot.hasError)
          return _LoadFailure(onRetry: _reload, error: snapshot.error);
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
          padding: const EdgeInsets.only(top: 24, bottom: 40),
          children: [
            const _SectionHeader(
              eyebrow: 'YOUR ACCOUNT',
              title: 'Profile and support',
            ),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    _InitialAvatar(name: profile.displayName, size: 62),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.displayName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 3),
                          Text(widget.user.email ?? 'No email address'),
                          const SizedBox(height: 4),
                          Text(
                            profile.city,
                            style: const TextStyle(
                              color: PawlyColors.teal,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit profile',
                      onPressed: () => _edit(profile),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            _AccountTile(
              icon: Icons.person_outline_rounded,
              title: 'Personal details',
              subtitle: 'Name, mobile number and city',
              onTap: () => _edit(profile),
            ),
            _AccountTile(
              icon: Icons.mail_outline_rounded,
              title: 'Email address',
              subtitle: widget.user.email ?? 'No email address',
            ),
            _AccountTile(
              icon: Icons.help_outline_rounded,
              title: 'Help and booking support',
              subtitle: 'Questions about a service or booking?',
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: PawlyColors.danger,
                side: const BorderSide(color: Color(0x55B42318)),
              ),
              onPressed: () => context.read<AuthController>().signOut(),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ],
        );
      },
    ),
  );
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onBook});
  final ServiceListing service;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final icon = switch (service.serviceType) {
      'boarding' => Icons.bed_outlined,
      _ when _isVet(service) => Icons.medical_services_outlined,
      _ => Icons.content_cut_rounded,
    };
    final tag = _isVet(service)
        ? 'VET CARE'
        : service.serviceType.toUpperCase();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 340;
            final details = Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _ServiceIcon(
                        icon: icon,
                        background: service.serviceType == 'boarding'
                            ? PawlyColors.apricotSoft
                            : PawlyColors.tealSoft,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _ServiceTag(tag: tag)),
                      if (service.isVerified)
                        const Tooltip(
                          message: 'Verified Pawly partner',
                          child: Icon(
                            Icons.verified_rounded,
                            color: PawlyColors.teal,
                            size: 19,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    service.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.providerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PawlyColors.teal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    service.description.isEmpty
                        ? 'Service details are available when you book.'
                        : service.description,
                    maxLines: narrow ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _Meta(
                        icon: Icons.location_on_outlined,
                        label: service.city,
                      ),
                      _Meta(
                        icon: Icons.schedule_outlined,
                        label: _durationText(service.durationMinutes),
                      ),
                      _Meta(
                        icon: Icons.star_rounded,
                        label: service.rating == 0
                            ? 'New partner'
                            : service.rating.toStringAsFixed(1),
                        accent: PawlyColors.apricot,
                      ),
                    ],
                  ),
                ],
              ),
            );
            final booking = Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'RM ${_money(service.price)}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: PawlyColors.darkTeal),
                ),
                const SizedBox(height: 2),
                const Text(
                  'per service',
                  style: TextStyle(fontSize: 11, color: PawlyColors.muted),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: onBook,
                  child: const Text('Choose time'),
                ),
              ],
            );
            return narrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      details,
                      const SizedBox(height: 16),
                      Align(alignment: Alignment.centerRight, child: booking),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [details, const SizedBox(width: 12), booking],
                  );
          },
        ),
      ),
    );
  }
}

class _BookingSheet extends StatefulWidget {
  const _BookingSheet({required this.service});
  final ServiceListing service;
  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  late Future<_BookingFormData> _future;
  Pet? _pet;
  DateTime? _date;
  ServiceSlot? _slot;
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_BookingFormData> _load() async {
    final repo = context.read<PawlyRepository>();
    final results = await Future.wait([
      repo.getPets(),
      repo.getAvailableSlots(widget.service.id),
    ]);
    final pets = results[0] as List<Pet>;
    final slots = results[1] as List<ServiceSlot>;
    if (pets.isNotEmpty) _pet = pets.first;
    final dates = _uniqueDates(slots);
    if (dates.isNotEmpty) {
      _date = dates.first;
      _slot = _slotsForDay(slots, dates.first).firstOrNull;
    }
    return _BookingFormData(pets, slots);
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _setDate(DateTime value, List<ServiceSlot> slots) {
    final daySlots = _slotsForDay(slots, value);
    setState(() {
      _date = value;
      _slot = daySlots.isEmpty ? null : daySlots.first;
    });
  }

  Future<void> _pickDate(List<ServiceSlot> slots) async {
    final dates = _uniqueDates(slots);
    if (dates.isEmpty) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? dates.first,
      firstDate: dates.first,
      lastDate: dates.last,
      selectableDayPredicate: (day) => dates.any((item) => _sameDay(item, day)),
      helpText: 'Choose an available date',
    );
    if (picked != null && mounted) _setDate(picked, slots);
  }

  Future<void> _book() async {
    if (_pet == null) {
      _notice(
        context,
        'Add a pet profile before you make a booking.',
        error: true,
      );
      return;
    }
    if (_slot == null) {
      _notice(context, 'Choose an available date and time.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<PawlyRepository>().createBooking(
        petId: _pet!.id,
        slotId: _slot!.id,
        notes: _notes.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _notice(context, _friendlyBookingError(error), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: .92,
    child: FutureBuilder<_BookingFormData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const _SheetLoader();
        if (snapshot.hasError)
          return _LoadFailure(
            onRetry: () async => setState(() => _future = _load()),
            error: snapshot.error,
          );
        final data = snapshot.data!;
        final dates = _uniqueDates(data.slots);
        final daySlots = _date == null
            ? const <ServiceSlot>[]
            : _slotsForDay(data.slots, _date!);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            18 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            children: [
              const _SheetHandle(),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Choose your booking',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.5,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  children: [
                    _BookingServiceSummary(service: widget.service),
                    const SizedBox(height: 24),
                    const _StepLabel(number: '1', title: 'Choose a pet'),
                    const SizedBox(height: 10),
                    if (data.pets.isEmpty)
                      _SheetNotice(
                        icon: Icons.pets_outlined,
                        text:
                            'You need a pet profile before this booking can be sent. Close this sheet and add one in the Pets tab.',
                      )
                    else
                      DropdownButtonFormField<Pet>(
                        value: _pet,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Pet profile',
                        ),
                        items: [
                          for (final pet in data.pets)
                            DropdownMenuItem(
                              value: pet,
                              child: Text('${pet.name} - ${pet.breed}'),
                            ),
                        ],
                        onChanged: (value) => setState(() => _pet = value),
                      ),
                    const SizedBox(height: 24),
                    const _StepLabel(number: '2', title: 'Choose a date'),
                    const SizedBox(height: 10),
                    if (dates.isEmpty)
                      const _SheetNotice(
                        icon: Icons.event_busy_outlined,
                        text:
                            'There are no upcoming times for this service just now. Please try another service or come back later.',
                      )
                    else ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final date in dates.take(8)) ...[
                              _DateChip(
                                date: date,
                                selected:
                                    _date != null && _sameDay(date, _date!),
                                onTap: () => _setDate(date, data.slots),
                              ),
                              const SizedBox(width: 8),
                            ],
                            OutlinedButton.icon(
                              onPressed: () => _pickDate(data.slots),
                              icon: const Icon(
                                Icons.calendar_month_outlined,
                                size: 18,
                              ),
                              label: const Text('More dates'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const _StepLabel(number: '3', title: 'Choose a time'),
                    const SizedBox(height: 10),
                    if (daySlots.isEmpty)
                      const _SheetNotice(
                        icon: Icons.schedule_outlined,
                        text: 'Choose a date with an available time.',
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final slot in daySlots)
                            ChoiceChip(
                              label: Text(_timeText(slot.startsAt)),
                              selected: _slot?.id == slot.id,
                              onSelected: (_) => setState(() => _slot = slot),
                            ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    const _StepLabel(
                      number: '4',
                      title: 'A note for the provider (optional)',
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _notes,
                      minLines: 2,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Anything the provider should know?',
                        hintText: 'e.g. Please call before the appointment.',
                      ),
                    ),
                    const SizedBox(height: 18),
                    _BookingFootnote(slot: _slot, service: widget.service),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _saving ? null : _book,
                child: _saving
                    ? const _InlineSpinner()
                    : const Text('Send booking request'),
              ),
              const SizedBox(height: 8),
              const Text(
                'You will receive a confirmation after the provider accepts the request.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: PawlyColors.muted),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _BookingFormData {
  const _BookingFormData(this.pets, this.slots);
  final List<Pet> pets;
  final List<ServiceSlot> slots;
}

class _CareTaskSheet extends StatefulWidget {
  const _CareTaskSheet({required this.pets});
  final List<Pet> pets;
  @override
  State<_CareTaskSheet> createState() => _CareTaskSheetState();
}

class _CareTaskSheetState extends State<_CareTaskSheet> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  late Pet _pet = widget.pets.first;
  String _category = 'care';
  TimeOfDay _time = TimeOfDay.now();
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    try {
      await context.read<PawlyRepository>().addCareTask(
        petId: _pet.id,
        title: _title.text,
        category: _category,
        dueAt: DateTime(now.year, now.month, now.day, _time.hour, _time.minute),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted)
        _notice(
          context,
          'The care task could not be saved. Check your connection and try again.',
          error: true,
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _FormSheet(
    title: 'Add care task',
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'A small routine makes the day easier. Add only what needs attention today.',
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<Pet>(
            value: _pet,
            decoration: const InputDecoration(labelText: 'Pet'),
            items: [
              for (final pet in widget.pets)
                DropdownMenuItem(value: pet, child: Text(pet.name)),
            ],
            onChanged: (value) => setState(() => _pet = value!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Care task',
              hintText: 'e.g. Evening medication',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Describe this care task'
                : null,
          ),
          const SizedBox(height: 16),
          const Text('Category', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final item in const [
                ('meal', 'Meal'),
                ('walk', 'Walk'),
                ('medication', 'Medication'),
                ('care', 'Other care'),
              ])
                ChoiceChip(
                  label: Text(item.$2),
                  selected: _category == item.$1,
                  onSelected: (_) => setState(() => _category = item.$1),
                ),
            ],
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _time,
                helpText: 'Choose a reminder time',
              );
              if (picked != null && mounted) setState(() => _time = picked);
            },
            icon: const Icon(Icons.schedule_outlined),
            label: Text('Today at ${_time.format(context)}'),
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const _InlineSpinner()
                : const Text('Save care task'),
          ),
        ],
      ),
    ),
  );
}

class _PetProfileSheet extends StatefulWidget {
  const _PetProfileSheet({this.pet});
  final Pet? pet;
  @override
  State<_PetProfileSheet> createState() => _PetProfileSheetState();
}

class _PetProfileSheetState extends State<_PetProfileSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _customBreed = TextEditingController();
  final _weight = TextEditingController();
  String _species = 'Dog';
  String _breed = _dogBreeds.first;
  String _gender = 'Unknown';
  DateTime _birthday = DateTime.now();
  bool _saving = false;

  List<String> get _breeds => _species == 'Dog' ? _dogBreeds : _catBreeds;

  @override
  void initState() {
    super.initState();
    final pet = widget.pet;
    if (pet == null) return;
    _name.text = pet.name;
    _species = pet.species;
    _breed = _breeds.contains(pet.breed) ? pet.breed : 'Custom breed';
    if (_breed == 'Custom breed') _customBreed.text = pet.breed;
    _gender = pet.gender;
    _birthday = pet.birthday;
    if (pet.weight > 0) _weight.text = pet.weight.toString();
  }

  @override
  void dispose() {
    _name.dispose();
    _customBreed.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final selectedBreed = _breed == 'Custom breed'
        ? _customBreed.text.trim()
        : _breed;
    try {
      final pet = Pet(
        id: widget.pet?.id ?? '',
        name: _name.text.trim(),
        species: _species,
        breed: selectedBreed,
        gender: _gender,
        birthday: _birthday,
        weight: double.tryParse(_weight.text.trim()) ?? 0,
        imageUrl: widget.pet?.imageUrl ?? '',
      );
      if (widget.pet == null) {
        await context.read<PawlyRepository>().addPet(pet);
      } else {
        await context.read<PawlyRepository>().updatePet(pet);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted)
        _notice(
          context,
          'The pet profile could not be saved. Check your connection and try again.',
          error: true,
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _FormSheet(
    title: widget.pet == null ? 'Add pet profile' : 'Edit pet profile',
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Keep the important details ready for care reminders and future bookings.',
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Pet name'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter your pet\'s name'
                : null,
          ),
          const SizedBox(height: 16),
          const Text('Species', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final species in const ['Dog', 'Cat'])
                ChoiceChip(
                  avatar: _PetMark(species: species, size: 24),
                  label: Text(species),
                  selected: _species == species,
                  onSelected: (_) => setState(() {
                    _species = species;
                    _breed = _breeds.first;
                    _customBreed.clear();
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _breed,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Breed'),
            items: [
              for (final breed in _breeds)
                DropdownMenuItem(value: breed, child: Text(breed)),
            ],
            onChanged: (value) => setState(() => _breed = value!),
          ),
          if (_breed == 'Custom breed') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _customBreed,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Custom breed'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your pet\'s breed'
                  : null,
            ),
          ],
          const SizedBox(height: 16),
          const Text('Gender', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final gender in const ['Female', 'Male', 'Unknown'])
                ChoiceChip(
                  label: Text(gender),
                  selected: _gender == gender,
                  onSelected: (_) => setState(() => _gender = gender),
                ),
            ],
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _birthday,
                firstDate: DateTime(1995),
                lastDate: DateTime.now(),
                helpText: 'Choose date of birth',
              );
              if (picked != null && mounted) setState(() => _birthday = picked);
            },
            icon: const Icon(Icons.cake_outlined),
            label: Text('Born ${_longDate(_birthday)}'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Weight (kg, optional)',
              hintText: 'e.g. 6.5',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              return double.tryParse(value) == null
                  ? 'Enter a valid number'
                  : null;
            },
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const _InlineSpinner()
                : Text(
                    widget.pet == null ? 'Save pet profile' : 'Save changes',
                  ),
          ),
        ],
      ),
    ),
  );
}

class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet({required this.profile});
  final UserProfile profile;
  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.displayName);
  late final _phone = TextEditingController(text: widget.profile.phone);
  late final _city = TextEditingController(text: widget.profile.city);
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
        _notice(
          context,
          'Your details could not be saved. Check your connection and try again.',
          error: true,
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _FormSheet(
    title: 'Personal details',
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const _InlineSpinner()
                : const Text('Save changes'),
          ),
        ],
      ),
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
  int _rating = 0;
  final _comment = TextEditingController();
  bool _saving = false;
  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_rating == 0) {
      _notice(context, 'Choose a rating from 1 to 5 stars.', error: true);
      return;
    }
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
      if (mounted)
        _notice(
          context,
          'Your review could not be saved. Please try again.',
          error: true,
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _FormSheet(
    title: 'Rate your visit',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${widget.booking.serviceName} at ${widget.booking.providerName}'),
        const SizedBox(height: 18),
        const Text(
          'How was the service?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (var value = 1; value <= 5; value++)
              IconButton(
                tooltip: '$value star${value == 1 ? '' : 's'}',
                onPressed: () => setState(() => _rating = value),
                icon: Icon(
                  value <= _rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: PawlyColors.apricot,
                  size: 34,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _comment,
          minLines: 3,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Share a short review (optional)',
            hintText: 'What did your pet enjoy?',
          ),
        ),
        const SizedBox(height: 22),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const _InlineSpinner()
              : const Text('Publish review'),
        ),
      ],
    ),
  );
}

class _FormSheet extends StatelessWidget {
  const _FormSheet({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      20,
      12,
      20,
      28 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.eyebrow, required this.title});
  final String eyebrow;
  final String title;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: const TextStyle(
          color: PawlyColors.teal,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: .9,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        title,
        style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 30),
      ),
    ],
  );
}

class _RowHeader extends StatelessWidget {
  const _RowHeader({required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
        ),
      ),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
    ],
  );
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.city});
  final String city;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 40),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: PawlyColors.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.location_on_outlined,
          color: PawlyColors.teal,
          size: 17,
        ),
        const SizedBox(width: 4),
        Text(
          city,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _CareTaskTile extends StatelessWidget {
  const _CareTaskTile({
    required this.task,
    this.onChanged,
    this.readOnly = false,
  });
  final CareTask task;
  final ValueChanged<bool>? onChanged;
  final bool readOnly;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 9),
    child: CheckboxListTile(
      value: task.isCompleted,
      onChanged: readOnly ? null : (value) => onChanged?.call(value ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      title: Text(
        task.title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          color: task.isCompleted ? PawlyColors.muted : PawlyColors.ink,
        ),
      ),
      subtitle: Text(
        '${_careCategoryLabel(task.category)} - ${_timeText(task.dueAt)}',
      ),
      secondary: _CategoryIcon(category: task.category),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
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
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: PawlyColors.tealSoft,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: PawlyColors.teal, size: 27),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 7),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.4),
          ),
          const SizedBox(height: 13),
          TextButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '$label filter',
    child: ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
            color: selected ? PawlyColors.darkTeal : PawlyColors.muted,
          ),
          const SizedBox(width: 5),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
    ),
  );
}

class _ServiceIcon extends StatelessWidget {
  const _ServiceIcon({required this.icon, required this.background});
  final IconData icon;
  final Color background;
  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, color: PawlyColors.darkTeal),
  );
}

class _ServiceTag extends StatelessWidget {
  const _ServiceTag({required this.tag});
  final String tag;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: PawlyColors.mist,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      tag,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: PawlyColors.darkTeal,
        letterSpacing: .4,
      ),
    ),
  );
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label, this.accent});
  final IconData icon;
  final String label;
  final Color? accent;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: accent ?? PawlyColors.muted),
      const SizedBox(width: 3),
      Text(
        label,
        style: const TextStyle(fontSize: 11.5, color: PawlyColors.muted),
      ),
    ],
  );
}

class _DisclosureNote extends StatelessWidget {
  const _DisclosureNote();
  @override
  Widget build(BuildContext context) => const _InfoCard(
    icon: Icons.info_outline_rounded,
    title: 'About Pawly partner listings',
    body:
        'Only verified and active partner services are shown. Confirmed bookings may be paid at the venue during the pilot.',
  );
}

class _CareProgressCard extends StatelessWidget {
  const _CareProgressCard({required this.total, required this.complete});
  final int total;
  final int complete;
  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : complete / total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 7,
                    backgroundColor: PawlyColors.tealSoft,
                    color: PawlyColors.teal,
                  ),
                  Center(
                    child: Text(
                      '$complete/$total',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A steady day for your pet',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Mark care tasks as you finish them. Small routines add up.',
                    style: TextStyle(fontSize: 12.5, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CareHubInfo extends StatelessWidget {
  const _CareHubInfo({required this.pets});
  final List<Pet> pets;
  @override
  Widget build(BuildContext context) => _InfoCard(
    icon: Icons.health_and_safety_outlined,
    title: 'What belongs in the Care Hub',
    body: pets.isEmpty
        ? 'Once you add a profile, set simple reminders for meals, walks, medication, vaccinations and other routines.'
        : 'Use it for meals, medication, walks, vaccination reminders and any care routine you do not want to forget.',
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Card(
    color: PawlyColors.tealSoft,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: PawlyColors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(fontSize: 12.5, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _PetProfileCard extends StatelessWidget {
  const _PetProfileCard({
    required this.pet,
    required this.onEdit,
    required this.onDelete,
  });
  final Pet pet;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth > 440;
          final avatar = Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: pet.species == 'Cat'
                  ? PawlyColors.apricotSoft
                  : PawlyColors.tealSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: _PetMark(species: pet.species, size: 50),
          );
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pet.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Pet options',
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit profile')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Remove profile'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                pet.breed,
                style: const TextStyle(
                  color: PawlyColors.teal,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 11),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _PetFact(
                    icon: Icons.cake_outlined,
                    label: '${_ageText(pet.birthday)} old',
                  ),
                  if (pet.weight > 0)
                    _PetFact(
                      icon: Icons.monitor_weight_outlined,
                      label:
                          '${pet.weight.toStringAsFixed(pet.weight % 1 == 0 ? 0 : 1)} kg',
                    ),
                  _PetFact(icon: Icons.wc_outlined, label: pet.gender),
                ],
              ),
            ],
          );
          return horizontal
              ? Row(
                  children: [
                    avatar,
                    const SizedBox(width: 14),
                    Expanded(child: details),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [avatar, const SizedBox(height: 16), details],
                );
        },
      ),
    ),
  );
}

class _PetMark extends StatelessWidget {
  const _PetMark({required this.species, required this.size});
  final String species;
  final double size;

  @override
  Widget build(BuildContext context) => ClipOval(
    child: SizedBox.square(
      dimension: size,
      child: Align(
        widthFactor: 2.05,
        alignment: species == 'Cat'
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Image.asset(
          'assets/illustrations/pawly-pet-icons.png',
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
    ),
  );
}

class _PetFact extends StatelessWidget {
  const _PetFact({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: PawlyColors.muted),
      const SizedBox(width: 3),
      Text(
        label,
        style: const TextStyle(fontSize: 11.5, color: PawlyColors.muted),
      ),
    ],
  );
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
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
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 9),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      leading: Icon(icon, color: PawlyColors.teal),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name, required this.size});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: size / 2,
    backgroundColor: PawlyColors.tealSoft,
    child: Text(
      _initials(name),
      style: TextStyle(
        color: PawlyColors.darkTeal,
        fontSize: size * .3,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _BookingServiceSummary extends StatelessWidget {
  const _BookingServiceSummary({required this.service});
  final ServiceListing service;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: PawlyColors.mist,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: PawlyColors.line),
    ),
    child: Row(
      children: [
        _ServiceIcon(
          icon: service.serviceType == 'boarding'
              ? Icons.bed_outlined
              : Icons.content_cut_rounded,
          background: service.serviceType == 'boarding'
              ? PawlyColors.apricotSoft
              : PawlyColors.tealSoft,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                '${service.providerName} - ${_durationText(service.durationMinutes)}',
                style: const TextStyle(fontSize: 12, color: PawlyColors.muted),
              ),
            ],
          ),
        ),
        Text(
          'RM ${_money(service.price)}',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: PawlyColors.darkTeal,
          ),
        ),
      ],
    ),
  );
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.number, required this.title});
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
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    ],
  );
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.selected,
    required this.onTap,
  });
  final DateTime date;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(15),
    onTap: onTap,
    child: Container(
      width: 66,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: selected ? PawlyColors.teal : PawlyColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: selected ? PawlyColors.teal : PawlyColors.line,
        ),
      ),
      child: Column(
        children: [
          Text(
            _weekday(date),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : PawlyColors.muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : PawlyColors.ink,
            ),
          ),
          Text(
            _month(date),
            style: TextStyle(
              fontSize: 10,
              color: selected ? Colors.white : PawlyColors.muted,
            ),
          ),
        ],
      ),
    ),
  );
}

class _BookingFootnote extends StatelessWidget {
  const _BookingFootnote({required this.slot, required this.service});
  final ServiceSlot? slot;
  final ServiceListing service;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: PawlyColors.apricotSoft,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(Icons.receipt_long_outlined, color: PawlyColors.apricot),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Booking summary',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                slot == null
                    ? 'Choose a date and time to complete the summary.'
                    : '${_bookingDateText(slot!.startsAt)} - ${service.name}',
                style: const TextStyle(fontSize: 12, height: 1.3),
              ),
            ],
          ),
        ),
        Text(
          'RM ${_money(service.price)}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: PawlyColors.darkTeal,
          ),
        ),
      ],
    ),
  );
}

class _SheetNotice extends StatelessWidget {
  const _SheetNotice({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: PawlyColors.mist,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: PawlyColors.teal),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, height: 1.35)),
        ),
      ],
    ),
  );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 38,
      height: 4,
      decoration: BoxDecoration(
        color: PawlyColors.line,
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: _bookingTone(status),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      _bookingStatus(status),
      style: TextStyle(
        color: _bookingColor(status),
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
        letterSpacing: .3,
      ),
    ),
  );
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.category});
  final String category;
  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: PawlyColors.mist,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(_careIcon(category), color: PawlyColors.teal, size: 20),
  );
}

class _ScreenLoader extends StatelessWidget {
  const _ScreenLoader();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(44),
      child: CircularProgressIndicator(),
    ),
  );
}

class _SheetLoader extends StatelessWidget {
  const _SheetLoader();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 380,
    child: Center(child: CircularProgressIndicator()),
  );
}

class _InlineSpinner extends StatelessWidget {
  const _InlineSpinner();
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 21,
    height: 21,
    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
  );
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry, this.error});
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
            size: 42,
          ),
          const SizedBox(height: 14),
          const Text(
            'We could not load this right now.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          const Text(
            'Check your connection or Supabase configuration, then try again.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

const _dogBreeds = [
  'Affenpinscher',
  'Afghan Hound',
  'Airedale Terrier',
  'Akita',
  'Alaskan Malamute',
  'Australian Shepherd',
  'Basenji',
  'Beagle',
  'Bernese Mountain Dog',
  'Bichon Frise',
  'Border Collie',
  'Boston Terrier',
  'Boxer',
  'Bull Terrier',
  'Bulldog',
  'Cavalier King Charles Spaniel',
  'Chihuahua',
  'Chow Chow',
  'Cocker Spaniel',
  'Corgi',
  'Dachshund',
  'Dalmatian',
  'Doberman Pinscher',
  'French Bulldog',
  'German Shepherd',
  'Golden Retriever',
  'Great Dane',
  'Husky',
  'Jack Russell Terrier',
  'Labrador Retriever',
  'Maltese',
  'Mixed breed',
  'Pomeranian',
  'Poodle',
  'Pug',
  'Rottweiler',
  'Samoyed',
  'Shiba Inu',
  'Shih Tzu',
  'Siberian Husky',
  'Staffordshire Bull Terrier',
  'Toy Poodle',
  'Whippet',
  'Yorkshire Terrier',
  'Custom breed',
];

const _catBreeds = [
  'Abyssinian',
  'American Curl',
  'American Shorthair',
  'Balinese',
  'Bengal',
  'Birman',
  'Bombay',
  'British Shorthair',
  'Burmese',
  'Chartreux',
  'Cornish Rex',
  'Devon Rex',
  'Domestic Longhair',
  'Domestic Shorthair',
  'Egyptian Mau',
  'Exotic Shorthair',
  'Himalayan',
  'Japanese Bobtail',
  'Maine Coon',
  'Manx',
  'Mixed breed',
  'Munchkin',
  'Norwegian Forest Cat',
  'Ocicat',
  'Oriental Shorthair',
  'Persian',
  'Ragdoll',
  'Russian Blue',
  'Scottish Fold',
  'Siamese',
  'Siberian',
  'Singapura',
  'Sphynx',
  'Tonkinese',
  'Turkish Angora',
  'Custom breed',
];

bool _isVet(ServiceListing service) =>
    '${service.name} ${service.providerName}'.toLowerCase().contains('vet') ||
    '${service.name} ${service.providerName}'.toLowerCase().contains('klinik');
bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;
List<DateTime> _uniqueDates(List<ServiceSlot> slots) {
  final dates = <DateTime>[];
  for (final slot in slots) {
    final day = DateTime(
      slot.startsAt.year,
      slot.startsAt.month,
      slot.startsAt.day,
    );
    if (!dates.any((date) => _sameDay(date, day))) dates.add(day);
  }
  dates.sort();
  return dates;
}

List<ServiceSlot> _slotsForDay(List<ServiceSlot> slots, DateTime day) =>
    slots.where((slot) => _sameDay(slot.startsAt, day)).toList();

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

String _money(num value) =>
    value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
String _durationText(int minutes) => minutes >= 1440
    ? '${(minutes / 1440).toStringAsFixed(minutes % 1440 == 0 ? 0 : 1)} day${minutes == 1440 ? '' : 's'}'
    : minutes >= 60
    ? '${minutes ~/ 60}h${minutes % 60 == 0 ? '' : ' ${minutes % 60}m'}'
    : '${minutes} min';
String _weekday(DateTime value) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][value.weekday - 1];
String _month(DateTime value) => const [
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
][value.month - 1];
String _timeText(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  return '${hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')} ${value.hour >= 12 ? 'PM' : 'AM'}';
}

String _bookingDateText(DateTime value) =>
    '${_weekday(value)}, ${value.day} ${_month(value)} - ${_timeText(value)}';
String _longDate(DateTime value) =>
    '${value.day} ${_month(value)} ${value.year}';
String _ageText(DateTime birthday) {
  final days = DateTime.now().difference(birthday).inDays;
  if (days < 30) return '$days days';
  final months = days ~/ 30;
  if (months < 24) return '$months months';
  return '${months ~/ 12} years';
}

String _careCategoryLabel(String category) => switch (category) {
  'meal' => 'Meal',
  'walk' => 'Walk',
  'medication' => 'Medication',
  _ => 'Care',
};
IconData _careIcon(String category) => switch (category) {
  'meal' => Icons.restaurant_outlined,
  'walk' => Icons.directions_walk_outlined,
  'medication' => Icons.medication_outlined,
  _ => Icons.favorite_border_rounded,
};
String _bookingStatus(String status) => switch (status) {
  'confirmed' => 'CONFIRMED',
  'completed' => 'COMPLETED',
  'cancelled' => 'CANCELLED',
  _ => 'REQUESTED',
};
Color _bookingColor(String status) => switch (status) {
  'confirmed' || 'completed' => PawlyColors.success,
  'cancelled' => PawlyColors.danger,
  _ => PawlyColors.apricot,
};
Color _bookingTone(String status) => switch (status) {
  'confirmed' || 'completed' => const Color(0xFFE5F6EC),
  'cancelled' => const Color(0xFFFFE9E7),
  _ => PawlyColors.apricotSoft,
};
IconData _bookingIcon(String status) => switch (status) {
  'confirmed' => Icons.event_available_outlined,
  'completed' => Icons.task_alt_rounded,
  'cancelled' => Icons.event_busy_outlined,
  _ => Icons.schedule_outlined,
};
String _initials(String name) {
  final result = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
  return result.isEmpty ? 'P' : result;
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required' : null;
String _friendlyBookingError(Object error) {
  final text = error.toString();
  if (text.contains('no longer available'))
    return 'That time was just taken. Pick another available time.';
  if (text.contains('signed in'))
    return 'Please sign in again before you book.';
  return 'The booking could not be sent. Check your connection and try again.';
}

void _notice(BuildContext context, String message, {bool error = false}) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? PawlyColors.danger : PawlyColors.ink,
      ),
    );
