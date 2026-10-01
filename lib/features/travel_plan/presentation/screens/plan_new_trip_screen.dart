import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'travel_plan_screen.dart';

class PlanNewTripScreen extends StatefulWidget {
  const PlanNewTripScreen({super.key});

  @override
  State<PlanNewTripScreen> createState() => _PlanNewTripScreenState();
}

class _PlanNewTripScreenState extends State<PlanNewTripScreen> {
  static const _cabinClasses = [
    'Economy',
    'Premium Economy',
    'Business',
    'First',
  ];
  static const _budgetTypes = ['Maximum', 'Approximate'];
  static const _currencies = ['USD', 'GBP', 'EUR', 'LKR', 'AUD'];
  static const double _sliderMax = 10000;

  final List<_FlightLeg> _legs = [_FlightLeg()];
  DateTime? _departing;
  DateTime? _returning;
  final _tripNameController = TextEditingController();
  final _airlineController = TextEditingController();
  final _budgetController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  String _cabinClass = 'Economy';
  String _budgetType = 'Maximum';
  String _currency = 'USD';
  int _adults = 1;
  int _children = 0;
  int _infants = 0;
  bool _autoBooking = false;
  bool _notifyBooking = true;

  bool _initialised = false;
  TravelPlan? _editing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final extra = GoRouterState.of(context).extra;
    if (extra is TravelPlan) {
      _editing = extra;
      _applyPlan(extra);
    }
  }

  void _applyPlan(TravelPlan plan) {
    for (final leg in _legs) {
      leg.dispose();
    }
    _legs
      ..clear()
      ..addAll(plan.flights.map((f) => _FlightLeg(
        departure: f.departureAirport,
        arrival: f.arrivalAirport,
      )));
    if (_legs.isEmpty) _legs.add(_FlightLeg());

    _departing = plan.fromDate;
    _returning = plan.toDate;
    _tripNameController.text = plan.tripName;
    _airlineController.text = plan.preferredAirline ?? '';
    _notesController.text = plan.notes ?? '';
    _budgetController.text = plan.maxBudget.toStringAsFixed(0);
    _cabinClass =
    _cabinClasses.contains(plan.cabinClass) ? plan.cabinClass : 'Economy';
    _budgetType =
    _budgetTypes.contains(plan.budgetType) ? plan.budgetType : 'Maximum';
    _currency = _currencies.contains(plan.currency) ? plan.currency : 'USD';
    _adults = plan.adults;
    _children = plan.children;
    _infants = plan.infants;
    _autoBooking = plan.autoBookingEnabled;
    _notifyBooking = plan.receiveBookingNotification;
  }

  @override
  void dispose() {
    _tripNameController.dispose();
    _airlineController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    for (final leg in _legs) {
      leg.dispose();
    }
    super.dispose();
  }

  double get _budgetValue =>
      (double.tryParse(_budgetController.text.trim()) ?? 0)
          .clamp(0, _sliderMax)
          .toDouble();

  String _fmtDate(DateTime? d) => d == null
      ? 'mm/dd/yyyy'
      : '${d.month.toString().padLeft(2, '0')}/'
      '${d.day.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate({required bool isDeparting}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = isDeparting ? _departing : _returning;
    var first = isDeparting ? today : (_departing ?? today);
    final initial = current ?? first;
    if (initial.isBefore(first)) first = initial;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: today.add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() {
      if (isDeparting) {
        _departing = picked;
        if (_returning != null && _returning!.isBefore(picked)) {
          _returning = null;
        }
      } else {
        _returning = picked;
      }
    });
  }

  void _addLeg() => setState(() => _legs.add(_FlightLeg()));

  void _removeLeg(int index) => setState(() {
    _legs[index].dispose();
    _legs.removeAt(index);
  });

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    final filledLegs = _legs
        .where((l) =>
    l.departure.text.trim().isNotEmpty &&
        l.arrival.text.trim().isNotEmpty)
        .toList();

    if (filledLegs.isEmpty || _departing == null) {
      _showMessage(
          'Add at least one flight leg and a departing date to continue.');
      return;
    }

    final flights = filledLegs
        .map((l) => TravelPlanFlight(
      departureAirport: l.departure.text.trim(),
      arrivalAirport: l.arrival.text.trim(),
    ))
        .toList();

    final TripType type = flights.length > 1
        ? TripType.multiCity
        : (_returning != null ? TripType.returnTrip : TripType.oneWay);

    final typedName = _tripNameController.text.trim();
    final name = typedName.isNotEmpty
        ? typedName
        : '${flights.first.departureAirport} → ${flights.first.arrivalAirport}';

    final airline = _airlineController.text.trim();
    final notes = _notesController.text.trim();

    final plan = TravelPlan(
      tripName: name,
      tripType: type,
      cabinClass: _cabinClass,
      preferredAirline: airline.isEmpty ? null : airline,
      adults: _adults,
      children: _children,
      infants: _infants,
      fromDate: _departing!,
      toDate: _returning,
      budgetType: _budgetType,
      currency: _currency,
      maxBudget: double.tryParse(_budgetController.text.trim()) ?? 0,
      savedAt: _editing?.savedAt ?? DateTime.now(),
      notes: notes.isEmpty ? null : notes,
      flights: flights,
      autoBookingEnabled: _autoBooking,
      receiveBookingNotification: _notifyBooking,
    );

    context.pop(plan);
  }

  void _close() =>
      context.canPop() ? context.pop() : context.go('/travel-plan');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = _editing != null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        toolbarHeight: 76,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEditing ? 'Edit Trip Plan' : 'Plan a New Trip',
              style: AppTextStyles.h4.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              "Save now — book whenever you're ready",
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _close,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [

          _SectionLabel(
            title: 'Flight legs',
            trailing: TextButton(
              onPressed: _addLeg,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.primary,
                textStyle: AppTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w800),
              ),
              child: const Text('+ Add another flight leg'),
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < _legs.length; i++) ...[
            _FlightLegCard(
              index: i,
              leg: _legs[i],
              onRemove: _legs.length > 1 ? () => _removeLeg(i) : null,
            ),
            if (i != _legs.length - 1) const SizedBox(height: 12),
          ],
          const SizedBox(height: 24),


          const _SectionLabel(title: 'Date range'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Departing',
                  child: _DateField(
                    text: _fmtDate(_departing),
                    onTap: () => _pickDate(isDeparting: true),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LabeledField(
                  label: 'Returning (optional)',
                  child: _DateField(
                    text: _fmtDate(_returning),
                    onTap: () => _pickDate(isDeparting: false),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),


          const _SectionLabel(title: 'Trip info'),
          const SizedBox(height: 10),
          _LabeledField(
            label: 'Trip name',
            child: TextField(
              controller: _tripNameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Dubai Family Holiday 2026',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Preferred airline (optional)',
                  child: TextField(
                    controller: _airlineController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Any'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LabeledField(
                  label: 'Cabin class',
                  child: _Dropdown<String>(
                    value: _cabinClass,
                    items: _cabinClasses,
                    onChanged: (v) => setState(() => _cabinClass = v),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),


          Text('Passengers', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PassengerCounter(
                  label: 'Adults',
                  value: _adults,
                  min: 1,
                  onChanged: (v) => setState(() => _adults = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PassengerCounter(
                  label: 'Children',
                  value: _children,
                  onChanged: (v) => setState(() => _children = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PassengerCounter(
                  label: 'Infants',
                  value: _infants,
                  onChanged: (v) => setState(() => _infants = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),


          const _SectionLabel(title: 'Budget'),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Budget type',
                  child: _Dropdown<String>(
                    value: _budgetType,
                    items: _budgetTypes,
                    filled: true,
                    onChanged: (v) => setState(() => _budgetType = v),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LabeledField(
                  label: 'Currency',
                  child: _Dropdown<String>(
                    value: _currency,
                    items: _currencies,
                    onChanged: (v) => setState(() => _currency = v),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('$_budgetType budget', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _budgetValue,
                  min: 0,
                  max: _sliderMax,
                  divisions: 200,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(
                          () => _budgetController.text = v.round().toString()),
                ),
              ),
              Text(_currency,
                  style: AppTextStyles.bodySmall
                      .copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              SizedBox(
                width: 88,
                child: TextField(
                  controller: _budgetController,
                  textAlign: TextAlign.right,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: '0',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ---------------- NOTES ----------------
          const _SectionLabel(title: 'Notes'),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText:
              'e.g. Anniversary trip — need aisle seats, vegetarian meals, airport lounge access…',
            ),
          ),
          const SizedBox(height: 24),


          const _SectionLabel(title: 'Booking'),
          const SizedBox(height: 4),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primary,
            title: Text('Auto booking', style: AppTextStyles.bodyMedium),
            value: _autoBooking,
            onChanged: (v) => setState(() => _autoBooking = v ?? false),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primary,
            title: Text('Receive a notification to book trip plan',
                style: AppTextStyles.bodyMedium),
            value: _notifyBooking,
            onChanged: (v) => setState(() => _notifyBooking = v ?? false),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.background,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.divider,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _close,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isEditing ? 'Update Trip Plan' : 'Save Trip Plan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlightLeg {
  _FlightLeg({String departure = '', String arrival = ''})
      : departure = TextEditingController(text: departure),
        arrival = TextEditingController(text: arrival);

  final TextEditingController departure;
  final TextEditingController arrival;

  void dispose() {
    departure.dispose();
    arrival.dispose();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.caption
                .copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.6),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.filled = false,
  });

  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: filled
            ? (isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.04))
            : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: [
            for (final item in items)
              DropdownMenuItem(value: item, child: Text('$item')),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
            const Icon(Icons.calendar_today_outlined, size: 16),
          ],
        ),
      ),
    );
  }
}

class _FlightLegCard extends StatelessWidget {
  const _FlightLegCard({
    required this.index,
    required this.leg,
    required this.onRemove,
  });

  final int index;
  final _FlightLeg leg;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('FLIGHT ${index + 1}',
                    style: AppTextStyles.caption
                        .copyWith(fontWeight: FontWeight.w800)),
              ),
              if (onRemove != null)
                InkWell(
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.close,
                        size: 18, color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Departure',
                  child: TextField(
                    controller: leg.departure,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(hintText: 'e.g. LHR'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LabeledField(
                  label: 'Arrival',
                  child: TextField(
                    controller: leg.arrival,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(hintText: 'e.g. DXB'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PassengerCounter extends StatelessWidget {
  const _PassengerCounter({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
  });

  final String label;
  final int value;
  final int min;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
              AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              _StepperButton(
                icon: Icons.remove,
                onTap: value > min ? () => onChanged(value - 1) : null,
              ),
              Expanded(
                child: Text('$value',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
              _StepperButton(
                  icon: Icons.add, onTap: () => onChanged(value + 1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: enabled ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}