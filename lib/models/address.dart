// filename: lib/models/address.dart
class Address {
  final String customerName;
  final String address1;
  final String address2;
  final String address3;
  final String address4;

  const Address({
    required this.customerName,
    required this.address1,
    required this.address2,
    required this.address3,
    required this.address4,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      customerName: json['customer_list'] as String? ?? 'N/A',
      address1: json['address_1'] as String? ?? 'N/A',
      address2: json['address_2'] as String? ?? 'N/A',
      address3: json['address_3'] as String? ?? 'N/A',
      address4: json['address_4'] as String? ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() => {
    'customer_list': customerName,
    'address_1': address1,
    'address_2': address2,
    'address_3': address3,
    'address_4': address4,
  };

  @override
  String toString() {
    return 'Address(customerName:$customerName, address1:$address1, address2:$address2, address3:$address3, address4:$address4)';
  }
}
