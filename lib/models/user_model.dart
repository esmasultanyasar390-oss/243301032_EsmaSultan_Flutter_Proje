class UserModel {
  final String uid;
  final String email;
  final String role; // 'admin', 'bayi', 'kullanici'
  final String displayName; // bireysel kullanıcı için ad soyad
  final String companyName; // bayi için firma adı
  final String taxNumber;   // bayi için vergi no
  final double creditLimit;
  final double currentDebt;
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
    required this.createdAt,
  });

  /// Kullanıcının ekranda gösterilecek adı
  String get name =>
      companyName.isNotEmpty ? companyName : displayName.isNotEmpty ? displayName : email;

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        uid: map['uid'] ?? '',
        email: map['email'] ?? '',
        role: map['role'] ?? 'kullanici',
        displayName: map['displayName'] ?? '',
        companyName: map['companyName'] ?? '',
        taxNumber: map['taxNumber'] ?? '',
        creditLimit: (map['creditLimit'] ?? 50000).toDouble(),
        currentDebt: (map['currentDebt'] ?? 0).toDouble(),
        createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'role': role,
        'displayName': displayName,
        'companyName': companyName,
        'taxNumber': taxNumber,
        'creditLimit': creditLimit,
        'currentDebt': currentDebt,
        'createdAt': createdAt,
      };
}
