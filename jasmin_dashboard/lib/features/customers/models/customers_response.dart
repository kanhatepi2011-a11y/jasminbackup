import 'customer_summary_model.dart';

class CustomersResponse {
  const CustomersResponse({required this.customers, required this.total});
  final List<CustomerSummaryModel> customers;
  final int total;

  factory CustomersResponse.fromJson(Map<String, dynamic> json) =>
      CustomersResponse(
        customers: (json['customers'] as List? ?? const <dynamic>[])
            .whereType<Map>()
            .map((item) =>
                CustomerSummaryModel.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
        total: _intFrom(json['total']),
      );

  static int _intFrom(dynamic value) => value is int
      ? value
      : value is num
          ? value.toInt()
          : int.tryParse(value?.toString() ?? '') ?? 0;
}
