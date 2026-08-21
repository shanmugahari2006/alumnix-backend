class Fundraiser {
  final String id;
  final String title;
  final String startupName;
  final String description;
  final double targetAmount;
  final double raisedAmount;
  final String creatorId;
  final String creatorName;
  final int donorsCount;
  final String? imageUrl;
  final DateTime createdAt;

  const Fundraiser({
    required this.id,
    required this.title,
    required this.startupName,
    required this.description,
    required this.targetAmount,
    this.raisedAmount = 0.0,
    required this.creatorId,
    this.creatorName = 'Collegiate Founder',
    this.donorsCount = 0,
    this.imageUrl,
    required this.createdAt,
  });

  double get progressRatio {
    if (targetAmount <= 0) return 0.0;
    return (raisedAmount / targetAmount).clamp(0.0, 1.0);
  }

  int get percentFunded {
    if (targetAmount <= 0) return 0;
    return ((raisedAmount / targetAmount) * 100).round();
  }

  factory Fundraiser.fromJson(Map<String, dynamic> json) {
    return Fundraiser(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Collegiate Venture Campaign',
      startupName: json['startup_name'] as String? ?? 'Stealth Startup',
      description: json['description'] as String? ?? '',
      targetAmount: (json['target_amount'] as num?)?.toDouble() ?? 100000.0,
      raisedAmount: (json['raised_amount'] as num?)?.toDouble() ?? 0.0,
      creatorId: json['creator_id']?.toString() ?? '',
      creatorName: json['creator_name'] as String? ?? 'Collegiate Founder',
      donorsCount: (json['donors_count'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startup_name': startupName,
      'description': description,
      'target_amount': targetAmount,
      'raised_amount': raisedAmount,
      'creator_id': creatorId,
      'creator_name': creatorName,
      'donors_count': donorsCount,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Fundraiser copyWith({
    String? id,
    String? title,
    String? startupName,
    String? description,
    double? targetAmount,
    double? raisedAmount,
    String? creatorId,
    String? creatorName,
    int? donorsCount,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return Fundraiser(
      id: id ?? this.id,
      title: title ?? this.title,
      startupName: startupName ?? this.startupName,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      raisedAmount: raisedAmount ?? this.raisedAmount,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      donorsCount: donorsCount ?? this.donorsCount,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DonateOrderResponse {
  final String key;
  final int amount; // in paise
  final String currency;
  final String razorpayOrderId;

  const DonateOrderResponse({
    required this.key,
    required this.amount,
    required this.currency,
    required this.razorpayOrderId,
  });

  factory DonateOrderResponse.fromJson(Map<String, dynamic> json) {
    return DonateOrderResponse(
      key: json['key'] as String? ?? 'rzp_test_placeholder',
      amount: (json['amount'] as num?)?.toInt() ?? 50000,
      currency: json['currency'] as String? ?? 'INR',
      razorpayOrderId: json['razorpay_order_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'amount': amount,
      'currency': currency,
      'razorpay_order_id': razorpayOrderId,
    };
  }
}

class DonationVerifyRequest {
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  const DonationVerifyRequest({
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  Map<String, dynamic> toJson() {
    return {
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
    };
  }
}
