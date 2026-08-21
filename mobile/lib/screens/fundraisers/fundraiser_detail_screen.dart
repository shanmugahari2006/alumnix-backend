import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../models/fundraiser.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fundraisers_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/primary_button.dart';
import 'widgets/donate_bottom_sheet.dart';

class FundraiserDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const FundraiserDetailScreen({super.key, required this.id});

  @override
  ConsumerState<FundraiserDetailScreen> createState() =>
      _FundraiserDetailScreenState();
}

class _FundraiserDetailScreenState
    extends ConsumerState<FundraiserDetailScreen> {
  late Razorpay _razorpay;
  bool _isInitiatingPayment = false;
  double _lastDonationAmount = 0.0;
  String? _currentOrderId;

  @override
  void initState() {
    super.initState();
    _initRazorpay();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    // Critical: Always call clear() to remove native listeners and prevent leaks
    _razorpay.clear();
    super.dispose();
  }

  void _openDonateModal(Fundraiser campaign) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DonateBottomSheet(
        fundraiser: campaign,
        isLoading: _isInitiatingPayment,
        onProceedToCheckout: (amount) {
          Navigator.pop(ctx);
          _startCheckout(campaign, amount);
        },
      ),
    );
  }

  Future<void> _startCheckout(Fundraiser campaign, double amount) async {
    setState(() {
      _isInitiatingPayment = true;
      _lastDonationAmount = amount;
    });

    final service = ref.read(fundraisersServiceProvider);
    final user = ref.read(authStateProvider).user;

    try {
      final orderResponse = await service.initiateDonation(
        fundraiserId: campaign.id,
        amount: amount,
      );

      _currentOrderId = orderResponse.razorpayOrderId;

      final options = {
        'key': orderResponse.key,
        'amount': orderResponse.amount,
        'name': 'AlumniConnect',
        'description': campaign.title,
        'order_id': orderResponse.razorpayOrderId,
        'timeout': 300,
        'prefill': {
          'contact': user?.phoneNumber ?? '',
          'email': user?.email ?? '',
        },
        'theme': {
          'color': '#1B2A4A', // Deep Ink Navy
        },
        'modal': {
          'confirm_close': true,
        },
      };

      setState(() => _isInitiatingPayment = false);
      _razorpay.open(options);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isInitiatingPayment = false);
      _showPaymentErrorDialog('Could not initiate checkout with payment gateway.');
    }
  }

  /// 1. Handle Successful Payment
  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final service = ref.read(fundraisersServiceProvider);

    final isVerified = await service.verifyDonation(
      razorpayOrderId: response.orderId ?? _currentOrderId ?? '',
      razorpayPaymentId: response.paymentId ?? '',
      razorpaySignature: response.signature ?? '',
    );

    if (!mounted) return;

    if (isVerified) {
      // Optimistically update progress & refresh campaign
      ref
          .read(fundraisersListProvider.notifier)
          .recordDonationOptimistic(widget.id, _lastDonationAmount);
      ref.refresh(fundraiserDetailProvider(widget.id));

      _showSuccessCelebrationDialog();
    } else {
      _showPendingConfirmationDialog(response);
    }
  }

  /// 2. Handle Payment Error
  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    _showPaymentErrorDialog(
      response.message ?? 'Payment was cancelled or could not be processed.',
    );
  }

  /// 3. Handle External Wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Redirected to external wallet: ${response.walletName ?? "Wallet"}',
          style: GoogleFonts.ibmPlexSans(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showSuccessCelebrationDialog() {
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          side: const BorderSide(color: AppColors.secondary, width: 1.2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.successBg,
                border: Border.all(color: AppColors.success, width: 2.0),
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 36,
                ),
              ),
            ),
            AppSpacing.gapV16,
            Text(
              'Thank You for Backing!',
              style: GoogleFonts.fraunces(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapV8,
            Text(
              'Your contribution of ${currencyFormatter.format(_lastDonationAmount)} has been credited towards this startup venture.',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapV24,
            PrimaryButton(
              text: 'View Updated Campaign',
              icon: Icons.done_all_rounded,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showPendingConfirmationDialog(PaymentSuccessResponse response) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        title: Text(
          'Payment Processing',
          style: GoogleFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          "We're confirming your payment with the banking network — this can take a minute.",
          style: GoogleFonts.ibmPlexSans(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _handlePaymentSuccess(response);
            },
            child: const Text('Check Status'),
          ),
        ],
      ),
    );
  }

  void _showPaymentErrorDialog(String message) {
    final campaignAsync = ref.read(fundraiserDetailProvider(widget.id));
    final campaign = campaignAsync.valueOrNull;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 22),
            AppSpacing.gapH8,
            Text(
              'Payment Incomplete',
              style: GoogleFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
          if (campaign != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _openDonateModal(campaign);
              },
              child: const Text('Try Again'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fundraiserAsync = ref.watch(fundraiserDetailProvider(widget.id));

    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return fundraiserAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Campaign Overview'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: LoadingSkeleton.card(height: 300),
          ),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Campaign'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: EmptyState(
          icon: Icons.rocket_outlined,
          title: 'Campaign Unavailable',
          message: 'Unable to retrieve this fundraising campaign.',
          actionText: 'Back to Campaigns',
          onAction: () => context.pop(),
        ),
      ),
      data: (campaign) {
        if (campaign == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Not Found'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
            ),
            body: const EmptyState(
              title: 'Not Found',
              message: 'Fundraising campaign was not found.',
            ),
          );
        }

        final formattedRaised = currencyFormatter.format(campaign.raisedAmount);
        final formattedTarget = currencyFormatter.format(campaign.targetAmount);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Venture Campaign'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: AppSpacing.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.goldLight,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusXs),
                                border: Border.all(
                                  color: AppColors.secondary,
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                campaign.startupName,
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            AppSpacing.gapV12,

                            Text(
                              campaign.title,
                              style: GoogleFonts.fraunces(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                            ),
                            AppSpacing.gapV8,

                            Row(
                              children: [
                                const Icon(Icons.person_outline_rounded,
                                    size: 15, color: AppColors.textSecondary),
                                AppSpacing.gapH6,
                                Text(
                                  'Pitched by ${campaign.creatorName}',
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusXs,
                                    ),
                                    border: Border.all(
                                      color: AppColors.border,
                                    ),
                                  ),
                                  child: Text(
                                    '${campaign.donorsCount} Backers',
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.gapV20,

                            // Large Funding Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: campaign.progressRatio,
                                minHeight: 10.0,
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.12),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.success, // Forest Green
                                ),
                              ),
                            ),
                            AppSpacing.gapV12,

                            // Progress Text Line
                            Text(
                              '$formattedRaised raised of $formattedTarget goal (${campaign.percentFunded}%)',
                              style: GoogleFonts.fraunces(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapV16,

                      // Description Narrative Card
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Executive Pitch & Vision',
                              style: GoogleFonts.fraunces(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            AppSpacing.gapV12,
                            Text(
                              campaign.description,
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom-Pinned Donate Action Bar
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 1.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 10,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: PrimaryButton(
                    text: 'Donate & Back Venture',
                    icon: Icons.payments_outlined,
                    onPressed: () => _openDonateModal(campaign),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
