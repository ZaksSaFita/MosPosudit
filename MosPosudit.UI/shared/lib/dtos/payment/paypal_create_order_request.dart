import '../order/order_insert_request.dart';

class PayPalCreateOrderRequest {
  final OrderInsertRequest orderData;

  PayPalCreateOrderRequest({
    required this.orderData,
  });

  Map<String, dynamic> toJson() => {
        'orderData': orderData.toJson(),
      };
}

