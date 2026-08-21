// ============================================================================
// RAZORPAY NATIVE SDK CONFIGURATION NOTES (ANDROID & IOS)
// ============================================================================
//
// 1. ANDROID CONFIGURATION (`android/app/build.gradle` & `android/app/proguard-rules.pro`):
//    - Ensure minSdkVersion is at least 19 (recommended 21 or higher):
//        android {
//            defaultConfig {
//                minSdkVersion 21
//                targetSdkVersion 34
//                multiDexEnabled true
//            }
//        }
//    - If code shrinking / R8 / ProGuard is enabled, add the following to `proguard-rules.pro`:
//        -keepclassmembers class * {
//            @android.webkit.JavascriptInterface <methods>;
//        }
//        -keepattributes JavascriptInterface
//        -dontwarn com.razorpay.**
//        -keep class com.razorpay.** {*;}
//
// 2. IOS CONFIGURATION (`ios/Runner/Info.plist`):
//    - For UPI App redirection (GPay, PhonePe, Paytm, BHIM), include the following
//      LSApplicationQueriesSchemes inside `<dict>` in `ios/Runner/Info.plist`:
//        <key>LSApplicationQueriesSchemes</key>
//        <array>
//            <string>tez</string>
//            <string>phonepe</string>
//            <string>paytmmp</string>
//            <string>bhim</string>
//            <string>credpay</string>
//        </array>
//
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

typedef PaymentSuccessCallback = void Function(PaymentSuccessResponse response);
typedef PaymentErrorCallback = void Function(PaymentFailureResponse response);
typedef ExternalWalletCallback = void Function(ExternalWalletResponse response);

/// Native Razorpay payment lifecycle manager
class PaymentService {
  late Razorpay _razorpay;
  bool _isInitialized = false;

  void initialize({
    required PaymentSuccessCallback onSuccess,
    required PaymentErrorCallback onError,
    required ExternalWalletCallback onExternalWallet,
  }) {
    if (_isInitialized) {
      _razorpay.clear();
    }

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
    _isInitialized = true;
  }

  /// Open Native Razorpay Checkout Modal
  void openCheckout({
    required String key,
    required int amountInPaise,
    required String orderId,
    required String campaignTitle,
    required String userEmail,
    required String userContact,
  }) {
    final options = {
      'key': key,
      'amount': amountInPaise,
      'name': 'AlumniConnect Fund',
      'description': campaignTitle,
      'order_id': orderId,
      'timeout': 300, // 5 minutes
      'prefill': {
        'contact': userContact.isNotEmpty ? userContact : '+919999999999',
        'email': userEmail.isNotEmpty ? userEmail : 'donor@alumnix.edu',
      },
      'theme': {
        'color': '#1B2A4A', // Deep Ink Navy
      },
      'modal': {
        'confirm_close': true,
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error launching Razorpay checkout: $e');
    }
  }

  /// Clean up event listeners to prevent memory leaks
  void dispose() {
    if (_isInitialized) {
      _razorpay.clear();
      _isInitialized = false;
    }
  }
}
