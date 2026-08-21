import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/fundraiser.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/primary_button.dart';

class DonateBottomSheet extends StatefulWidget {
  final Fundraiser fundraiser;
  final ValueChanged<double> onProceedToCheckout;
  final bool isLoading;

  const DonateBottomSheet({
    super.key,
    required this.fundraiser,
    required this.onProceedToCheckout,
    this.isLoading = false,
  });

  @override
  State<DonateBottomSheet> createState() => _DonateBottomSheetState();
}

class _DonateBottomSheetState extends State<DonateBottomSheet> {
  final _amountController = TextEditingController(text: '1000');
  double _selectedAmount = 1000.0;
  String? _errorMessage;

  final List<double> _quickAmounts = [500.0, 1000.0, 5000.0];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectQuickAmount(double amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = amount.toInt().toString();
      _errorMessage = null;
    });
  }

  void _handleConfirm() {
    final parsed = double.tryParse(_amountController.text.trim());
    if (parsed == null || parsed < 50.0) {
      setState(() {
        _errorMessage = 'Minimum contribution is ₹50.';
      });
      return;
    }

    widget.onProceedToCheckout(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Container(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 20.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusMd),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Back this Venture',
                      style: GoogleFonts.fraunces(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapV2,
                    Text(
                      'Contributing to ${widget.fundraiser.startupName}',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          AppSpacing.gapV16,
          const Divider(),
          AppSpacing.gapV16,

          // Quick Amount Preset Chips
          Text(
            'Select Contribution Tier',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapV8,

          Row(
            children: [
              ..._quickAmounts.map((amount) {
                final isSelected = _selectedAmount == amount;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () => _selectQuickAmount(amount),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.background,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusXs),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            currencyFormatter.format(amount),
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          AppSpacing.gapV16,

          // Custom Amount Input
          AppTextField(
            label: 'Custom Amount (₹)',
            hint: 'Enter contribution in INR',
            controller: _amountController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.currency_rupee_rounded,
            onChanged: (val) {
              final parsed = double.tryParse(val.trim());
              setState(() {
                _selectedAmount = parsed ?? 0.0;
                _errorMessage = null;
              });
            },
          ),

          if (_errorMessage != null) ...[
            AppSpacing.gapV8,
            Text(
              _errorMessage!,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 12,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          AppSpacing.gapV24,

          // Payment Gateway Note
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 14, color: AppColors.textLight),
              AppSpacing.gapH6,
              Text(
                'Secured via Razorpay Native UPI, NetBanking & Cards',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 11,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          AppSpacing.gapV12,

          PrimaryButton(
            text: widget.isLoading ? 'Initiating Checkout...' : 'Proceed to Checkout',
            icon: Icons.payments_outlined,
            isLoading: widget.isLoading,
            onPressed: widget.isLoading ? null : _handleConfirm,
          ),
        ],
      ),
    );
  }
}
