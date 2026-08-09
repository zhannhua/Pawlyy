import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/pawly_theme.dart';
import '../../data/pawly_repository.dart';
import '../../models/pawly_models.dart';
import '../../providers/auth_controller.dart';

/// The operational workspace shown only to an account that is linked to a
/// service_providers.merchant_id record. Verification is controlled in
/// Supabase, never from this screen.
class MerchantShell extends StatefulWidget {
  const MerchantShell({super.key, required this.provider});

  final ProviderProfile provider;

  @override
  State<MerchantShell> createState() => _MerchantShellState();
}

class _MerchantShellState extends State<MerchantShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _MerchantOverview(provider: widget.provider),
      _MerchantCalendar(provider: widget.provider),
      _MerchantServices(provider: widget.provider),
      _MerchantProfile(provider: widget.provider),
    ];
    const items = [
      _MerchantDestination('Today', Icons.today_outlined, Icons.today_rounded),
      _MerchantDestination(
        'Availability',
        Icons.calendar_month_outlined,
        Icons.calendar_month_rounded,
      ),
      _MerchantDestination(
        'Services',
        Icons.content_cut_outlined,
        Icons.content_cut_rounded,
      ),
      _MerchantDestination(
        'Business',
        Icons.storefront_outlined,
        Icons.storefront_rounded,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final rail = constraints.maxWidth >= 960;
        final content = IndexedStack(index: _index, children: pages);
        if (!rail) {
          return Scaffold(
            body: content,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: [
                for (final item in items)
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
                  minWidth: 128,
                  selectedIndex: _index,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (value) =>
                      setState(() => _index = value),
                  leading: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 18, 12, 30),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/branding/pawly-logo.png',
                          width: 82,
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'PARTNER',
                          style: TextStyle(
                            color: PawlyColors.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  destinations: [
                    for (final item in items)
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

class _MerchantDestination {
  const _MerchantDestination(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _MerchantPage extends StatelessWidget {
  const _MerchantPage({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              constraints.maxWidth >= 720 ? 36 : 20,
              24,
              constraints.maxWidth >= 720 ? 36 : 20,
              40,
            ),
            child: child,
          ),
        ),
      ),
    ),
  );
}

class _MerchantOverview extends StatefulWidget {
  const _MerchantOverview({required this.provider});
  final ProviderProfile provider;

  @override
  State<_MerchantOverview> createState() => _MerchantOverviewState();
}

class _MerchantOverviewState extends State<_MerchantOverview> {
  late Future<List<MerchantBooking>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<PawlyRepository>().getMerchantBookings();
  }

  Future<void> _reload() async {
    setState(
      () => _future = context.read<PawlyRepository>().getMerchantBookings(),
    );
  }

  Future<void> _changeStatus(MerchantBooking booking, String status) async {
    try {
      await context.read<PawlyRepository>().updateMerchantBooking(
        bookingId: booking.id,
        status: status,
      );
      await _reload();
      if (mounted) {
        _merchantNotice(
          context,
          status == 'confirmed'
              ? 'Booking confirmed.'
              : status == 'declined'
              ? 'Booking declined.'
              : 'Appointment marked complete.',
        );
      }
    } catch (_) {
      if (mounted) {
        _merchantNotice(
          context,
          'That booking could not be updated. Please try again.',
          error: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => _MerchantPage(
    child: FutureBuilder<List<MerchantBooking>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _MerchantFailure(onRetry: _reload);
        }
        final bookings = snapshot.data!;
        final now = DateTime.now();
        final today = bookings
            .where((item) => _sameDay(item.startsAt, now))
            .toList();
        final requests = bookings
            .where((item) => item.status == 'requested')
            .toList();
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PARTNER WORKSPACE',
                          style: TextStyle(
                            color: PawlyColors.teal,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Good morning, ${widget.provider.name}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  _VerificationStamp(verified: widget.provider.isVerified),
                ],
              ),
              const SizedBox(height: 28),
              _PartnerRibbon(
                todayCount: today.length,
                requestCount: requests.length,
                city: widget.provider.city,
              ),
              const SizedBox(height: 36),
              _MerchantSectionHeader(
                eyebrow: requests.isEmpty ? 'TODAY' : 'NEEDS YOUR REPLY',
                title: requests.isEmpty
                    ? 'Today’s appointments'
                    : '${requests.length} booking request${requests.length == 1 ? '' : 's'}',
              ),
              const SizedBox(height: 14),
              if (requests.isNotEmpty)
                ...requests.map(
                  (booking) => _MerchantBookingRow(
                    booking: booking,
                    onConfirm: () => _changeStatus(booking, 'confirmed'),
                    onDecline: () => _changeStatus(booking, 'declined'),
                    onComplete: () => _changeStatus(booking, 'completed'),
                  ),
                )
              else if (today.isNotEmpty)
                ...today.map(
                  (booking) => _MerchantBookingRow(
                    booking: booking,
                    onConfirm: () => _changeStatus(booking, 'confirmed'),
                    onDecline: () => _changeStatus(booking, 'declined'),
                    onComplete: () => _changeStatus(booking, 'completed'),
                  ),
                )
              else
                const _MerchantEmpty(
                  icon: Icons.event_available_outlined,
                  title: 'Your day is clear',
                  body: 'New appointment requests will appear here.',
                ),
              const SizedBox(height: 34),
              const _MerchantSectionHeader(
                eyebrow: 'UPCOMING',
                title: 'All scheduled care',
              ),
              const SizedBox(height: 14),
              if (bookings.isEmpty)
                const _MerchantEmpty(
                  icon: Icons.calendar_month_outlined,
                  title: 'No bookings yet',
                  body:
                      'Add availability in the Availability tab to accept bookings.',
                )
              else
                ...bookings
                    .where((item) => item.startsAt.isAfter(now))
                    .take(8)
                    .map(
                      (booking) => _MerchantBookingRow(
                        booking: booking,
                        onConfirm: () => _changeStatus(booking, 'confirmed'),
                        onDecline: () => _changeStatus(booking, 'declined'),
                        onComplete: () => _changeStatus(booking, 'completed'),
                        compact: true,
                      ),
                    ),
            ],
          ),
        );
      },
    ),
  );
}

class _PartnerRibbon extends StatelessWidget {
  const _PartnerRibbon({
    required this.todayCount,
    required this.requestCount,
    required this.city,
  });
  final int todayCount;
  final int requestCount;
  final String city;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: PawlyColors.darkTeal,
      borderRadius: BorderRadius.circular(24),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 520;
        final details = [
          _RibbonMetric(value: '$todayCount', label: 'today'),
          _RibbonMetric(value: '$requestCount', label: 'to review'),
          _RibbonMetric(value: city, label: 'location'),
        ];
        return narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your care desk is open.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(spacing: 26, runSpacing: 14, children: details),
                ],
              )
            : Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Your care desk\nis open.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  for (final detail in details) ...[
                    detail,
                    const SizedBox(width: 28),
                  ],
                ],
              );
      },
    ),
  );
}

class _RibbonMetric extends StatelessWidget {
  const _RibbonMetric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      Text(
        label,
        style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12),
      ),
    ],
  );
}

class _MerchantCalendar extends StatefulWidget {
  const _MerchantCalendar({required this.provider});
  final ProviderProfile provider;

  @override
  State<_MerchantCalendar> createState() => _MerchantCalendarState();
}

class _MerchantCalendarState extends State<_MerchantCalendar> {
  late Future<List<ServiceListing>> _servicesFuture;
  String? _serviceId;
  Future<List<ServiceSlot>>? _slotsFuture;

  @override
  void initState() {
    super.initState();
    _servicesFuture = context.read<PawlyRepository>().getMerchantServices(
      widget.provider.id,
    );
  }

  void _selectService(String? serviceId) {
    setState(() {
      _serviceId = serviceId;
      _slotsFuture = serviceId == null
          ? null
          : context.read<PawlyRepository>().getMerchantSlots(serviceId);
    });
  }

  Future<void> _addSlot() async {
    if (_serviceId == null) return;
    final slot = await showModalBottomSheet<_NewSlot>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddSlotSheet(),
    );
    if (slot == null || !mounted) return;
    try {
      await context.read<PawlyRepository>().addMerchantSlot(
        serviceId: _serviceId!,
        startsAt: slot.startsAt,
        capacity: slot.capacity,
      );
      _selectService(_serviceId);
      if (mounted) _merchantNotice(context, 'Availability added.');
    } catch (_) {
      if (mounted) {
        _merchantNotice(
          context,
          'Availability could not be saved.',
          error: true,
        );
      }
    }
  }

  Future<void> _setActive(ServiceSlot slot, bool active) async {
    try {
      await context.read<PawlyRepository>().setMerchantSlotActive(
        slot.id,
        active,
      );
      _selectService(_serviceId);
    } catch (_) {
      if (mounted)
        _merchantNotice(context, 'Slot could not be updated.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) => _MerchantPage(
    child: FutureBuilder<List<ServiceListing>>(
      future: _servicesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError)
          return _MerchantFailure(
            onRetry: () async {
              setState(() {
                _servicesFuture = context
                    .read<PawlyRepository>()
                    .getMerchantServices(widget.provider.id);
              });
            },
          );
        final services = snapshot.data!;
        if (services.isEmpty) {
          return const _MerchantEmpty(
            icon: Icons.content_cut_outlined,
            title: 'Add a service first',
            body:
                'Your availability can be attached to a service once it is listed.',
          );
        }
        _serviceId ??= services.first.id;
        _slotsFuture ??= context.read<PawlyRepository>().getMerchantSlots(
          _serviceId!,
        );
        return ListView(
          children: [
            const _MerchantSectionHeader(
              eyebrow: 'AVAILABILITY',
              title: 'Set the moments you can care',
            ),
            const SizedBox(height: 8),
            const Text(
              'Customers only see future, active times for your verified service.',
            ),
            const SizedBox(height: 22),
            DropdownButtonFormField<String>(
              value: _serviceId,
              decoration: const InputDecoration(labelText: 'Service'),
              items: [
                for (final service in services)
                  DropdownMenuItem(
                    value: service.id,
                    child: Text(service.name),
                  ),
              ],
              onChanged: _selectService,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addSlot,
              icon: const Icon(Icons.add),
              label: const Text('Add available time'),
            ),
            const SizedBox(height: 30),
            const _MerchantSectionHeader(
              eyebrow: 'SCHEDULE',
              title: 'Upcoming times',
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<ServiceSlot>>(
              future: _slotsFuture,
              builder: (context, slots) {
                if (slots.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (slots.hasError)
                  return _MerchantFailure(
                    onRetry: () async => _selectService(_serviceId),
                  );
                final data = slots.data!;
                if (data.isEmpty) {
                  return const _MerchantEmpty(
                    icon: Icons.schedule_outlined,
                    title: 'No availability yet',
                    body:
                        'Add a time and customers will be able to request it.',
                  );
                }
                return Column(
                  children: [
                    for (final slot in data)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 5),
                        leading: Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: PawlyColors.tealSoft,
                          ),
                          child: const Icon(
                            Icons.schedule_outlined,
                            color: PawlyColors.teal,
                          ),
                        ),
                        title: Text(_merchantDateTime(slot.startsAt)),
                        subtitle: Text(
                          '${slot.capacity} pet${slot.capacity == 1 ? '' : 's'} per time',
                        ),
                        trailing: Switch(
                          value: slot.isActive,
                          onChanged: (value) => _setActive(slot, value),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    ),
  );
}

class _MerchantServices extends StatefulWidget {
  const _MerchantServices({required this.provider});
  final ProviderProfile provider;

  @override
  State<_MerchantServices> createState() => _MerchantServicesState();
}

class _MerchantServicesState extends State<_MerchantServices> {
  late Future<List<ServiceListing>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<PawlyRepository>().getMerchantServices(
      widget.provider.id,
    );
  }

  Future<void> _reload() async => setState(() {
    _future = context.read<PawlyRepository>().getMerchantServices(
      widget.provider.id,
    );
  });

  Future<void> _edit([ServiceListing? service]) async {
    final complete = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Provider.value(
        value: context.read<PawlyRepository>(),
        child: _ServiceEditorSheet(
          providerId: widget.provider.id,
          service: service,
        ),
      ),
    );
    if (complete == true && mounted) await _reload();
  }

  Future<void> _delete(ServiceListing service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${service.name}?'),
        content: const Text(
          'This cannot be undone. Existing bookings are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: PawlyColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await context.read<PawlyRepository>().deleteMerchantService(service.id);
      await _reload();
    } catch (_) {
      if (mounted)
        _merchantNotice(
          context,
          'This service could not be removed.',
          error: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) => _MerchantPage(
    child: FutureBuilder<List<ServiceListing>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return _MerchantFailure(onRetry: _reload);
        final services = snapshot.data!;
        return ListView(
          children: [
            Row(
              children: [
                const Expanded(
                  child: _MerchantSectionHeader(
                    eyebrow: 'YOUR MENU',
                    title: 'Services and pricing',
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Add service',
                  onPressed: () => _edit(),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Keep each service clear: what it includes, how long it takes, and its Ringgit price.',
            ),
            const SizedBox(height: 24),
            if (services.isEmpty)
              _MerchantEmpty(
                icon: Icons.content_cut_outlined,
                title: 'Your menu is empty',
                body: 'Start with one clear, bookable service.',
                action: 'Add a service',
                onAction: () => _edit(),
              )
            else
              ...services.map(
                (service) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    tileColor: PawlyColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 9,
                    ),
                    leading: _MerchantServiceIcon(type: service.serviceType),
                    title: Text(
                      service.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${_serviceTypeLabel(service.serviceType)} · ${service.durationMinutes} min',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'RM ${service.price}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (choice) {
                            if (choice == 'edit') _edit(service);
                            if (choice == 'delete') _delete(service);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit service'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Remove service'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _MerchantProfile extends StatefulWidget {
  const _MerchantProfile({required this.provider});
  final ProviderProfile provider;

  @override
  State<_MerchantProfile> createState() => _MerchantProfileState();
}

class _MerchantProfileState extends State<_MerchantProfile> {
  late final TextEditingController _name = TextEditingController(
    text: widget.provider.name,
  );
  late final TextEditingController _city = TextEditingController(
    text: widget.provider.city,
  );
  late final TextEditingController _address = TextEditingController(
    text: widget.provider.address,
  );
  late final TextEditingController _phone = TextEditingController(
    text: widget.provider.phone,
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.provider.description,
  );
  late final TextEditingController _cover = TextEditingController(
    text: widget.provider.coverUrl,
  );
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _address.dispose();
    _phone.dispose();
    _description.dispose();
    _cover.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<PawlyRepository>().updateMerchantProvider(
        name: _name.text,
        city: _city.text,
        address: _address.text,
        phone: _phone.text,
        description: _description.text,
        coverUrl: _cover.text,
      );
      if (mounted) _merchantNotice(context, 'Business profile saved.');
    } catch (_) {
      if (mounted)
        _merchantNotice(context, 'Profile could not be saved.', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _MerchantPage(
    child: ListView(
      children: [
        const _MerchantSectionHeader(
          eyebrow: 'BUSINESS PROFILE',
          title: 'The details pet parents see',
        ),
        const SizedBox(height: 8),
        const Text(
          'Your verification and partner status are managed by Pawly for customer trust.',
        ),
        const SizedBox(height: 24),
        _VerificationStamp(verified: widget.provider.isVerified),
        const SizedBox(height: 22),
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Business name'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _city,
          decoration: const InputDecoration(labelText: 'City'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _address,
          decoration: const InputDecoration(labelText: 'Address'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _description,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'About your care'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _cover,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Real business photo URL (optional)',
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Save business profile'),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () => context.read<AuthController>().signOut(),
          icon: const Icon(Icons.logout_outlined),
          label: const Text('Sign out'),
        ),
      ],
    ),
  );
}

class _ServiceEditorSheet extends StatefulWidget {
  const _ServiceEditorSheet({required this.providerId, this.service});
  final String providerId;
  final ServiceListing? service;

  @override
  State<_ServiceEditorSheet> createState() => _ServiceEditorSheetState();
}

class _ServiceEditorSheetState extends State<_ServiceEditorSheet> {
  late final _name = TextEditingController(text: widget.service?.name ?? '');
  late final _description = TextEditingController(
    text: widget.service?.description ?? '',
  );
  late final _price = TextEditingController(
    text: widget.service?.price.toString() ?? '',
  );
  late final _duration = TextEditingController(
    text: widget.service?.durationMinutes.toString() ?? '60',
  );
  late String _type = widget.service?.serviceType ?? 'grooming';
  late bool _isActive = widget.service?.isActive ?? true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final price = num.tryParse(_price.text);
    final duration = int.tryParse(_duration.text);
    if (_name.text.trim().isEmpty ||
        price == null ||
        price <= 0 ||
        duration == null ||
        duration <= 0) {
      _merchantNotice(
        context,
        'Add a service name, valid price and duration.',
        error: true,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<PawlyRepository>().saveMerchantService(
        id: widget.service?.id,
        providerId: widget.providerId,
        name: _name.text,
        description: _description.text,
        serviceType: _type,
        price: price,
        durationMinutes: duration,
        isActive: _isActive,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted)
        _merchantNotice(
          context,
          'The service could not be saved.',
          error: true,
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: PawlyColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.service == null ? 'Add a service' : 'Edit service',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Service name'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Care category'),
              items: const [
                DropdownMenuItem(value: 'grooming', child: Text('Grooming')),
                DropdownMenuItem(value: 'boarding', child: Text('Boarding')),
                DropdownMenuItem(
                  value: 'veterinary',
                  child: Text('Veterinary'),
                ),
              ],
              onChanged: (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Price (RM)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _duration,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Minutes'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _description,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'What is included?'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Available for booking'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Save service'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AddSlotSheet extends StatefulWidget {
  const _AddSlotSheet();
  @override
  State<_AddSlotSheet> createState() => _AddSlotSheetState();
}

class _AddSlotSheetState extends State<_AddSlotSheet> {
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  int _capacity = 1;

  Future<void> _chooseDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Choose available date',
    );
    if (value != null && mounted) setState(() => _date = value);
  }

  Future<void> _chooseTime() async {
    final value = await showTimePicker(context: context, initialTime: _time);
    if (value != null && mounted) setState(() => _time = value);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: PawlyColors.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Add available time',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _chooseDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(_merchantDate(_date)),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _chooseTime,
            icon: const Icon(Icons.schedule_outlined),
            label: Text(_timeOfDay(_time)),
          ),
          const SizedBox(height: 18),
          const Text('Capacity', style: TextStyle(fontWeight: FontWeight.w800)),
          Slider(
            value: _capacity.toDouble(),
            min: 1,
            max: 6,
            divisions: 5,
            label: '$_capacity pet${_capacity == 1 ? '' : 's'}',
            onChanged: (value) => setState(() => _capacity = value.round()),
          ),
          Text(
            '$_capacity pet${_capacity == 1 ? '' : 's'} can be booked at this time.',
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              context,
              _NewSlot(
                DateTime(
                  _date.year,
                  _date.month,
                  _date.day,
                  _time.hour,
                  _time.minute,
                ),
                _capacity,
              ),
            ),
            child: const Text('Add to schedule'),
          ),
        ],
      ),
    ),
  );
}

class _NewSlot {
  const _NewSlot(this.startsAt, this.capacity);
  final DateTime startsAt;
  final int capacity;
}

class _MerchantBookingRow extends StatelessWidget {
  const _MerchantBookingRow({
    required this.booking,
    required this.onConfirm,
    required this.onDecline,
    required this.onComplete,
    this.compact = false,
  });
  final MerchantBooking booking;
  final VoidCallback onConfirm;
  final VoidCallback onDecline;
  final VoidCallback onComplete;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: PawlyColors.surface,
      border: Border.all(color: PawlyColors.line),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _MerchantServiceIcon(
              type: booking.petSpecies == 'Cat' ? 'cat' : 'dog',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${booking.petName} · ${booking.customerName}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            _MerchantStatus(status: booking.status),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          booking.serviceName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 3),
        Text(
          _merchantDateTime(booking.startsAt),
          style: const TextStyle(color: PawlyColors.muted),
        ),
        if (!compact && booking.notes.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            '“${booking.notes}”',
            style: const TextStyle(
              color: PawlyColors.muted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        if (!compact && booking.status == 'requested') ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ] else if (!compact && booking.status == 'confirmed') ...[
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onComplete,
              icon: const Icon(Icons.task_alt_outlined),
              label: const Text('Mark complete'),
            ),
          ),
        ],
      ],
    ),
  );
}

class _MerchantServiceIcon extends StatelessWidget {
  const _MerchantServiceIcon({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final isVet = type == 'veterinary';
    final isBoarding = type == 'boarding';
    final icon = isVet
        ? Icons.medical_services_outlined
        : isBoarding
        ? Icons.bed_outlined
        : type == 'cat'
        ? Icons.pets_outlined
        : type == 'dog'
        ? Icons.pets_outlined
        : Icons.content_cut_outlined;
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: PawlyColors.tealSoft,
      ),
      child: Icon(icon, color: PawlyColors.teal),
    );
  }
}

class _MerchantSectionHeader extends StatelessWidget {
  const _MerchantSectionHeader({required this.eyebrow, required this.title});
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
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(height: 5),
      Text(title, style: Theme.of(context).textTheme.titleLarge),
    ],
  );
}

class _MerchantStatus extends StatelessWidget {
  const _MerchantStatus({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final requested = status == 'requested';
    final declined = status == 'declined' || status == 'cancelled';
    final color = requested
        ? PawlyColors.apricot
        : declined
        ? PawlyColors.danger
        : PawlyColors.teal;
    return Text(
      status[0].toUpperCase() + status.substring(1),
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
    );
  }
}

class _VerificationStamp extends StatelessWidget {
  const _VerificationStamp({required this.verified});
  final bool verified;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: verified ? PawlyColors.tealSoft : PawlyColors.apricotSoft,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          verified ? Icons.verified_outlined : Icons.pending_outlined,
          size: 16,
          color: verified ? PawlyColors.teal : PawlyColors.apricot,
        ),
        const SizedBox(width: 5),
        Text(
          verified ? 'Verified partner' : 'Verification pending',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _MerchantEmpty extends StatelessWidget {
  const _MerchantEmpty({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      border: Border.all(color: PawlyColors.line),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Icon(icon, size: 32, color: PawlyColors.teal),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(color: PawlyColors.muted),
        ),
        if (action != null) ...[
          const SizedBox(height: 12),
          TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ],
    ),
  );
}

class _MerchantFailure extends StatelessWidget {
  const _MerchantFailure({required this.onRetry});
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: _MerchantEmpty(
      icon: Icons.cloud_off_outlined,
      title: 'We could not load this yet',
      body: 'Check your connection and try again.',
      action: 'Try again',
      onAction: () => onRetry(),
    ),
  );
}

void _merchantNotice(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? PawlyColors.danger : PawlyColors.ink,
    ),
  );
}

String _serviceTypeLabel(String value) => switch (value) {
  'boarding' => 'Boarding',
  'veterinary' => 'Veterinary',
  _ => 'Grooming',
};

String _merchantDate(DateTime date) =>
    '${_weekday(date.weekday)}, ${date.day} ${_month(date.month)} ${date.year}';
String _merchantDateTime(DateTime date) =>
    '${_merchantDate(date)} · ${_time(date)}';
String _time(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
String _timeOfDay(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
String _weekday(int value) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][value - 1];
String _month(int value) => const [
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
][value - 1];
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
