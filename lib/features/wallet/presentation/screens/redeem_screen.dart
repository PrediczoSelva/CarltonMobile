import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../domain/repositories/wallet_repository.dart';

class RedeemScreen extends StatefulWidget {
  const RedeemScreen({
    super.key,
    required this.availablePoints,
    required this.currencyCode,
  });

  final int availablePoints;
  final String currencyCode;

  @override
  State<RedeemScreen> createState() => _RedeemScreenState();
}

class _RedeemScreenState extends State<RedeemScreen> {
  final WalletRepository _walletRepository = getIt<WalletRepository>();

  int _pointsRate = 1;
  int _minRedemptionPoints = 100;
  int _redemptionStep = 100;
  int _selectedPoints = 100;
  bool _isLoading = false;
  String? _error;
  bool _configLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadRedemptionConfig();
  }

  Future<void> _loadRedemptionConfig() async {
    try {
      final config = await _walletRepository.getRedemptionConfig();
      if (mounted) {
        setState(() {
          _pointsRate = (config['pointsRate'] as num?)?.toInt() ?? 1;
          _minRedemptionPoints = (config['minRedemptionPoints'] as num?)?.toInt() ?? 100;
          _redemptionStep = (config['redemptionStep'] as num?)?.toInt() ?? 100;
          _selectedPoints = _minRedemptionPoints * 5;
          if (_selectedPoints > widget.availablePoints) {
            _selectedPoints = widget.availablePoints;
          }
          _configLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _configLoaded = true;
        });
      }
    }
  }

  String get _currencySymbol {
    switch (widget.currencyCode.toUpperCase()) {
      case 'LKR':
        return 'Rs.';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'USD':
        return '\$';
      default:
        return '${widget.currencyCode} ';
    }
  }

  String _formatCurrency(double amount) {
    return '$_currencySymbol${amount.toStringAsFixed(2)}';
  }

  double get _creditValue => _selectedPoints * _pointsRate / 100;

  bool get _isValid =>
      _selectedPoints >= _minRedemptionPoints &&
      _selectedPoints <= widget.availablePoints;

  List<int> get _quickOptions {
    final options = [
      _minRedemptionPoints,
      (_minRedemptionPoints * 2.5).round(),
      _minRedemptionPoints * 5,
      _minRedemptionPoints * 10,
    ];
    return options
        .map((v) => (v / _redemptionStep).round() * _redemptionStep)
        .toSet()
        .toList();
  }

  Future<void> _handleRedeem() async {
    if (!_isValid) return;

    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      await _walletRepository.redeemPoints(pointsToRedeem: _selectedPoints);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Redeemed ${_selectedPoints.toString()} pts → ${_formatCurrency(_creditValue)} added to wallet!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = 'Redemption failed. You may not have enough points.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redeem Points'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _configLoaded
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildInfoBanner(),
                  const SizedBox(height: 24),
                  _buildQuickSelect(),
                  const SizedBox(height: 24),
                  _buildSlider(),
                  const SizedBox(height: 24),
                  _buildCreditPreview(),
                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildRedeemButton(),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.stars,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Redeem Points',
                  style: AppTextStyles.h4.copyWith(color: Colors.white),
                ),
                Text(
                  '${widget.availablePoints.toString()} points available',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFEF3C7)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.flash_on, color: Color(0xFFF59E0B), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$_minRedemptionPoints points = ${_formatCurrency(_minRedemptionPoints * _pointsRate / 100)} wallet credit',
              style: AppTextStyles.bodySmall.copyWith(
                color: const Color(0xFF92400E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Select',
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickOptions.map((opt) {
            final isSelected = _selectedPoints == opt;
            final isDisabled = opt > widget.availablePoints;
            return GestureDetector(
              onTap: isDisabled ? null : () => setState(() => _selectedPoints = opt),
              child: Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF59E0B) : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFF59E0B) : AppColors.border,
                  ),
                ),
                child: Text(
                  opt.toString(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDisabled
                        ? AppColors.disabled
                        : isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Or select manually',
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Slider(
          value: _selectedPoints.toDouble(),
          min: _minRedemptionPoints.toDouble(),
          max: widget.availablePoints.toDouble(),
          divisions: ((widget.availablePoints - _minRedemptionPoints) / _redemptionStep).round().clamp(1, 100),
          activeColor: const Color(0xFFF59E0B),
          onChanged: (value) {
            setState(() {
              _selectedPoints = (value / _redemptionStep).round() * _redemptionStep;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _minRedemptionPoints.toString(),
              style: AppTextStyles.caption,
            ),
            Text(
              widget.availablePoints.toString(),
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCreditPreview() {
    final remainingPoints = widget.availablePoints - _selectedPoints;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEF3C7)),
      ),
      child: Column(
        children: [
          Text(
            "You'll receive",
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFF92400E),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(_creditValue),
            style: AppTextStyles.h1.copyWith(color: const Color(0xFF92400E)),
          ),
          const SizedBox(height: 8),
          Text(
            '${_selectedPoints.toString()} pts → ${remainingPoints > 0 ? '${remainingPoints.toString()} pts remaining' : 'All points used'}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemButton() {
    if (!_isValid && _selectedPoints < _minRedemptionPoints) {
      return Column(
        children: [
          Text(
            'Minimum redemption is $_minRedemptionPoints points.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading || !_isValid ? null : _handleRedeem,
        icon: _isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.stars, size: 18),
        label: Text(_isLoading ? 'Redeeming...' : 'Redeem $_selectedPoints Points'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF59E0B),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
