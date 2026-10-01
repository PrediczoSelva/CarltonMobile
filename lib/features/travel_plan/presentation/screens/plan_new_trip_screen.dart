import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class PlanNewTripScreen extends StatefulWidget {
  const PlanNewTripScreen({super.key});

  @override
  State<PlanNewTripScreen> createState() => _PlanNewTripScreenState();
}

class _PlanNewTripScreenState extends State<PlanNewTripScreen> {
  final List<_FlightLeg> _legs = [_FlightLeg()];
  DateTime? _departing;
  DateTime? _returning;
  final _tripNameController = TextEditingController();
  String _cabinClass = 'Economy';
  int _adults = 1;
  int _children = 0;
  int _infants = 0;

  @override
  void dispose() {
    _tripNameController.dispose();
    for (final leg in _legs) {
      leg.departure.dispose();
      leg.arrival.dispose();
    }
    super.dispose();
  }

  String _fmtDate(DateTime? d) => d == null
      ? 'mm/dd/yyyy'
      : '${d.month.toString().padLeft(2, '0')}/'
      '${d.day.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate({required bool isDeparting}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isDeparting ? _departing : _returning) ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() {
      if (isDeparting) {
        _departing = picked;
      } else {
        _returning = picked;
      }
    });
  }

  void _addLeg() => setState(() => _legs.add(_FlightLeg()));

  void _removeLeg(int index) => setState(() {
    _legs[index].departure.dispose();
    _legs[index].arrival.dispose();
    _legs.removeAt(index);
  });

  void _submit() {
    if (_legs.first.departure.text.trim().isEmpty ||
        _legs.first.arrival.text.trim().isEmpty ||
        _departing == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text(
              'Add at least one flight leg and a departing date to continue.'),
        ));
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Saving your trip plan…')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.surface,
      appBar: AppBar(
        title: const Text('Plan a New Trip'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () =>
          context.canPop() ? context.pop() : context.go('/travel-plan'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text(
            "Save now — book whenever you're ready",
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _SectionCard(
            title: 'Flight Legs',
            trailing: TextButton.icon(
              onPressed: _addLeg,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add another flight leg'),
              style: TextButton.styleFrom(
                textStyle:
                AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _legs.length; i++) ...[
                  _FlightLegCard(
                    index: i,
                    leg: _legs[i],
                    onRemove: _legs.length > 1 ? () => _removeLeg(i) : null,
                  ),
                  if (i != _legs.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Date Range',
            child: Row(
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
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Trip Info',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                _LabeledField(
                  label: 'Cabin class',
                  child: _Dropdown<String>(
                    value: _cabinClass,
                    items: const [
                      'Economy',
                      'Premium Economy',
                      'Business',
                      'First',
                    ],
                    onChanged: (v) => setState(() => _cabinClass = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Passengers',
            child: Row(
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
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/travel-plan'),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    minimumSize: const Size(0, 52),
                  ),
                  child: const Text('Save Trip Plan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlightLeg {
  final departure = TextEditingController();
  final arrival = TextEditingController();
  DateTime? fromDate;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title.toUpperCase(), style: AppTextStyles.caption),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
          if (trailing != null) ...[
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: trailing!),
          ],
        ],
      ),
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
        Text(label, style: AppTextStyles.bodySmall),
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
  });

  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
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
            const Icon(Icons.calendar_today_outlined, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
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
      padding: const EdgeInsets.all(12),
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
                child: Text('FLIGHT ${index + 1}', style: AppTextStyles.caption),
              ),
              if (onRemove != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onRemove,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
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
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StepperButton(
                icon: Icons.remove,
                onTap: value > min ? () => onChanged(value - 1) : null,
              ),
              Text('$value',
                  style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700)),
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