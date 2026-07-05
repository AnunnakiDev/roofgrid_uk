class CustomerQuoteBranding {
  final String companyName;
  final String address;
  final String phone;
  final String email;
  final String logoAssetPath;
  final String vatNumber;
  final String quoteFooterNotes;

  const CustomerQuoteBranding({
    this.companyName = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.logoAssetPath = '',
    this.vatNumber = '',
    this.quoteFooterNotes = '',
  });

  bool get hasLogo => logoAssetPath.trim().isNotEmpty;

  bool get hasCompanyDetails =>
      companyName.trim().isNotEmpty ||
      address.trim().isNotEmpty ||
      phone.trim().isNotEmpty ||
      email.trim().isNotEmpty ||
      vatNumber.trim().isNotEmpty;

  CustomerQuoteBranding copyWith({
    String? companyName,
    String? address,
    String? phone,
    String? email,
    String? logoAssetPath,
    String? vatNumber,
    String? quoteFooterNotes,
  }) {
    return CustomerQuoteBranding(
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logoAssetPath: logoAssetPath ?? this.logoAssetPath,
      vatNumber: vatNumber ?? this.vatNumber,
      quoteFooterNotes: quoteFooterNotes ?? this.quoteFooterNotes,
    );
  }

  Map<String, dynamic> toJson() => {
        'companyName': companyName,
        'address': address,
        'phone': phone,
        'email': email,
        'logoAssetPath': logoAssetPath,
        'vatNumber': vatNumber,
        'quoteFooterNotes': quoteFooterNotes,
      };

  factory CustomerQuoteBranding.fromJson(Map<String, dynamic> json) {
    return CustomerQuoteBranding(
      companyName: json['companyName'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      logoAssetPath: json['logoAssetPath'] as String? ?? '',
      vatNumber: json['vatNumber'] as String? ?? '',
      quoteFooterNotes: json['quoteFooterNotes'] as String? ?? '',
    );
  }

  static const empty = CustomerQuoteBranding();
}