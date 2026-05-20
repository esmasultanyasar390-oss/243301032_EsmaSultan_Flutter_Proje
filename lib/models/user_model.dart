class UserModel {
  final String uid;
  final String email;
  final String role; // 'admin', 'bayi', 'kullanici'
  final String displayName;
  final String companyName;
  final String taxNumber;
  final double creditLimit;
  final double currentDebt;
  final double accountBalance;
  final Map<String, double> customPrices; // ürünId -> kullanıcıya özel fiyat
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.displayName = '',
    this.companyName = '',
    this.taxNumber = '',
    this.creditLimit = 50000,
    this.currentDebt = 0,
    this.accountBalance = 10000,
    this.customPrices = const {},
    required this.createdAt,
  });

  String get name =>
      companyName.isNotEmpty
          ? companyName
          : displayName.isNotEmpty
              ? displayName
              : email;

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final limit = (map['creditLimit'] ?? 50000).toDouble();
    final debt = (map['currentDebt'] ?? 0).toDouble();
    final balance = map['accountBalance'] != null
        ? (map['accountBalance'] as num).toDouble()
        : (limit - debt).clamp(0, double.infinity);
    final pricesRaw = map['customPrices'] as Map<String, dynamic>?;
    final prices = <String, double>{};
    pricesRaw?.forEach((k, v) {
      prices[k] = (v as num).toDouble();
    });

    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'kullanici',
      displayName: map['displayName'] ?? '',
      companyName: map['companyName'] ?? '',
      taxNumber: map['taxNumber'] ?? '',
      creditLimit: limit,
      currentDebt: debt,
      accountBalance: balance,
      customPrices: prices,
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'role': role,
        'displayName': displayName,
        'companyName': companyName,
        'taxNumber': taxNumber,
        'creditLimit': creditLimit,
        'currentDebt': currentDebt,
        'accountBalance': accountBalance,
        'customPrices': customPrices,
        'createdAt': createdAt,
      };

  UserModel copyWith({
    String? uid,
    String? email,
    String? role,
    String? displayName,
    String? companyName,
    String? taxNumber,
    double? creditLimit,
    double? currentDebt,
    double? accountBalance,
    Map<String, double>? customPrices,
    DateTime? createdAt,
  }) =>
      UserModel(
        uid: uid ?? this.uid,
        email: email ?? this.email,
        role: role ?? this.role,
        displayName: displayName ?? this.displayName,
        companyName: companyName ?? this.companyName,
        taxNumber: taxNumber ?? this.taxNumber,
        creditLimit: creditLimit ?? this.creditLimit,
        currentDebt: currentDebt ?? this.currentDebt,
        accountBalance: accountBalance ?? this.accountBalance,
        customPrices: customPrices ?? this.customPrices,
        createdAt: createdAt ?? this.createdAt,
      );
}
