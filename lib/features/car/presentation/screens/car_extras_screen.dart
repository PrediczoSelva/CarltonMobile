import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../data/repositories/car_repository.dart';
import '../../domain/car_checkout_args.dart';
import '../../domain/entities/car_extra_option.dart';
import '../../domain/entities/car_vehicle.dart';
import '../utils/car_extras_ui.dart';

class CarExtrasScreen extends StatefulWidget {
  const CarExtrasScreen({super.key, required this.args});
  final CarCheckoutArgs args;

  @override
  State<CarExtrasScreen> createState() => _CarExtrasScreenState();
}

class _CarExtrasScreenState extends State<CarExtrasScreen> {
  late final CarRepository _repository;
  List<CarExtraOption> _extras = [];
  Map<String, int> _quantities = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = getIt<CarRepository>();
    _loadExtras();
  }

  Future<void> _loadExtras() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loaded = await _repository.getExtraOptions(widget.args.car.id);
      if (!mounted) return;
      final seeded = <String, int>{};
      for (final e in loaded) {
        final existing = widget.args.selectedExtras
            .firstWhere((s) => s.id == e.id, orElse: () => e);
        seeded[e.id] = existing.selectedQuantity > 0
            ? existing.selectedQuantity
            : 0;
      }
      setState(() {
        _extras = loaded;
        _quantities = seeded;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  bool _isSelected(CarExtraOption extra) =>
      (_quantities[extra.id] ?? 0) > 0;

  int _quantity(CarExtraOption extra) => _quantities[extra.id] ?? 0;

  void _toggle(CarExtraOption extra) {
    setState(() {
      if (_isSelected(extra)) {
        _quantities[extra.id] = 0;
      } else {
        _quantities[extra.id] = 1;
      }
    });
  }

  void _changeQuantity(CarExtraOption extra, int newQty) {
    final max = extra.maxQuantity;
    if (max != null && newQty > max) newQty = max;
    if (newQty <= 0) return;
    setState(() => _quantities[extra.id] = newQty);
  }

  List<CarExtraOption> get _selectedExtras => _extras
      .where((e) => _isSelected(e))
      .map((e) => e.copyWith(selectedQuantity: _quantities[e.id]!))
      .toList();

  CarCheckoutArgs get _nextArgs => widget.args.copyWith(
        selectedExtras: _selectedExtras,
      );

  @override
  Widget build(BuildContext context) {
    final car = widget.args.car;
    final days = widget.args.rentalDays;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add-ons & extras'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _buildContent(car, days),
    );
  }

  Widget _buildLoading() => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(height: 16),
            Text('Loading available add-ons...'),
          ]),
        ),
      );

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _error ?? 'Unable to load add-ons.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );

  Widget _buildContent(CarVehicle car, int days) {
    final selected = _selectedExtras;
    final extrasSubtotal =
        selected.fold(0.0, (sum, e) => sum + e.totalCost(days));
    final vehicleSubtotal = car.dailyPrice * days;
    final subtotal = vehicleSubtotal + extrasSubtotal;
    final taxes = subtotal * 0.2;
    final total = subtotal + taxes;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(car, days),
                const SizedBox(height: 16),
                if (_extras.isEmpty)
                  _buildEmptyState()
                else
                  ..._extras.map((e) => _buildExtraCard(e, days)),
              ],
            ),
          )),
        _buildSummary(car, days, vehicleSubtotal, extrasSubtotal, subtotal,
            taxes, total, selected),
        _buildFooter(selected, days, total),
      ],
    );
  }

  Widget _buildHeader(CarVehicle car, int days) => Card(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(car.name,
                  style: AppTextStyles.h4.copyWith(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                  '${car.companyName} · $days day${days > 1 ? 's' : ''} · £${car.dailyPrice.toStringAsFixed(0)}/day',
                  style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text('No optional add-ons are available for this vehicle.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ),
      );

  Widget _buildExtraCard(CarExtraOption extra, int days) {
    final selected = _isSelected(extra);
    final qty = _quantity(extra);
    final total = extra.totalCost(days);
    final category = extra.category;
    final isIncluded = extra.isIncluded;

    IconData icon = extraIconFor(extra.icon);
    final Color categoryColor = switch (category?.toLowerCase()) {
      'equipment' => const Color(0xFF0369A1),
      'coverage' => const Color(0xFF6D28D9),
      'protection' => const Color(0xFFBE185D),
      _ => AppColors.textSecondary,
    };
    final Color categoryBg = switch (category?.toLowerCase()) {
      'equipment' => const Color(0xFFE0F2FE),
      'coverage' => const Color(0xFFEDE9FE),
      'protection' => const Color(0xFFF2FCE7),
      _ => AppColors.surfaceVariant,
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
            color: selected
                ? AppColors.primary
                : AppColors.border,
            width: selected ? 2 : 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceVariant,
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(extra.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        if (category != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: categoryBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(category,
                                style: AppTextStyles.caption.copyWith(
                                    color: categoryColor,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ]),
                      if (extra.productCode != null) ...[
                        const SizedBox(height: 2),
                        Text(extra.productCode!,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                      if (extra.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(extra.description,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ]),
              ),
              const SizedBox(width: 8),
              if (isIncluded)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(999)),
                child: Text('Included', style: AppTextStyles.caption),
                ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Text(
                formatExtraPrice(
                  pricePerDay: extra.pricePerDay,
                  priceType: extra.priceType,
                  rentalDays: days,
                ),
                style: AppTextStyles.bodySmall.copyWith(
                    color: isIncluded
                        ? AppColors.textSecondary
                        : AppColors.primary,
                    fontWeight: isIncluded
                        ? FontWeight.w400
                        : FontWeight.w600),
              ),
              const Spacer(),
              if (selected && (extra.maxQuantity ?? 1) > 1 && !isIncluded)
                _buildQuantityStepper(extra, qty, days),
              if (!isIncluded)
                SizedBox(
                  width: 96,
                  child: TextButton(
                    onPressed: () => _toggle(extra),
                    style: TextButton.styleFrom(
                      foregroundColor: selected
                          ? AppColors.textOnPrimary
                          : AppColors.primary,
                      backgroundColor: selected
                          ? AppColors.primary
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.border)),
                    ),
                    child: Text(selected ? 'Added' : 'Add',
                        style: const TextStyle(fontSize: 13)),
                  ),
                ),
            ]),
            if (selected && !isIncluded && total > 0) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '£${total.toStringAsFixed(total % 1 == 0 ? 0 : 2)}',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityStepper(CarExtraOption extra, int qty, int days) {
    final max = extra.maxQuantity;
    final canDecrease = qty > 1;
    final canIncrease = max == null || qty < max;
    return Row(children: [
      IconButton(
        visualDensity: VisualDensity.compact,
        iconSize: 16,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        icon: const Icon(Icons.remove, size: 16),
        onPressed: canDecrease ? () => _changeQuantity(extra, qty - 1) : null,
      ),
      Text('$qty', style: AppTextStyles.bodySmall),
      IconButton(
        visualDensity: VisualDensity.compact,
        iconSize: 16,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        icon: const Icon(Icons.add, size: 16),
        onPressed: canIncrease ? () => _changeQuantity(extra, qty + 1) : null,
      ),
      Text('x £${extra.totalCost(days).toStringAsFixed(extra.totalCost(days) % 1 == 0 ? 0 : 2)}',
          style: AppTextStyles.caption),
    ]);
  }

  Widget _buildSummary(
    CarVehicle car,
    int days,
    double vehicleSubtotal,
    double extrasSubtotal,
    double subtotal,
    double taxes,
    double total,
    List<CarExtraOption> selected,
  ) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Booking summary',
              style: AppTextStyles.h4.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _summaryRow('Vehicle ($days day${days > 1 ? 's' : ''})',
              vehicleSubtotal),
          if (selected.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...selected.map((e) => _summaryRow(
                e.name +
                    (e.selectedQuantity > 1
                        ? ' ×${e.selectedQuantity}'
                        : ''),
                e.totalCost(days))),
          ],
          const SizedBox(height: 4),
          _summaryRow('Extras total', extrasSubtotal),
          const SizedBox(height: 4),
          _summaryRow('Taxes & fees', taxes),
          const Divider(height: 20, color: AppColors.divider),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grand Total',
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
              Text('£${total.toStringAsFixed(total % 1 == 0 ? 0 : 2)}',
                  style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _summaryRow(String label, double amount) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            Text('£${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textPrimary)),
          ],
        ),
      );

  Widget _buildFooter(List<CarExtraOption> selected, int days, double total) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: PrimaryButton(
          label: 'Continue to guest details',
          onPressed: () {
            final next = _nextArgs;
            context.push('/cars/${widget.args.car.id}/guest-details', extra: {
              'car': next.car,
              'criteria': next.criteria,
              'extras': next.selectedExtras,
            });
          },
        ),
      );
}
