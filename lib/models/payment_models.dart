class RechargeOrderResponse {
  final bool success;
  final OrderData? data;

  RechargeOrderResponse({required this.success, this.data});

  factory RechargeOrderResponse.fromJson(Map<String, dynamic> json) {
    return RechargeOrderResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? OrderData.fromJson(json['data']) : null,
    );
  }
}

class OrderData {
  final String orderId;
  final int amount; // in paise
  final String currency;
  final String razorpayKeyId;
  final String receipt;

  OrderData({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.razorpayKeyId,
    required this.receipt,
  });

  factory OrderData.fromJson(Map<String, dynamic> json) {
    return OrderData(
      orderId: json['orderId'],
      amount: json['amount'],
      currency: json['currency'],
      razorpayKeyId: json['razorpayKeyId'],
      receipt: json['receipt'],
    );
  }
}

class VerifyPaymentRequest {
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  VerifyPaymentRequest({
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  Map<String, dynamic> toJson() {
    return {
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
    };
  }
}
