import 'dart:convert';

class Account {
  final String id;
  final String issuer;
  final String accountName;
  final String secret;
  final int digits;
  final int period;
  final DateTime createdAt;

  Account({
    required this.id,
    required this.issuer,
    required this.accountName,
    required this.secret,
    this.digits = 6,
    this.period = 30,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert Account to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'issuer': issuer,
      'accountName': accountName,
      'secret': secret,
      'digits': digits,
      'period': period,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create Account from JSON
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      issuer: json['issuer'],
      accountName: json['accountName'],
      secret: json['secret'],
      digits: json['digits'] ?? 6,
      period: json['period'] ?? 30,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // Parse OTP Auth URL (otpauth://totp/...)
  factory Account.fromOtpAuthUrl(String url) {
    final uri = Uri.parse(url);

    if (uri.scheme != 'otpauth' || uri.host != 'totp') {
      throw ArgumentError('Invalid OTP Auth URL');
    }

    final path = uri.path.substring(1); // Remove leading '/'
    final parts = path.split(':');

    String issuer = uri.queryParameters['issuer'] ?? '';
    String accountName = path;

    if (parts.length == 2) {
      issuer = parts[0];
      accountName = parts[1];
    }

    final secret = uri.queryParameters['secret'];
    if (secret == null || secret.isEmpty) {
      throw ArgumentError('Secret is required');
    }

    return Account(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      issuer: issuer,
      accountName: accountName,
      secret: secret,
      digits: int.tryParse(uri.queryParameters['digits'] ?? '6') ?? 6,
      period: int.tryParse(uri.queryParameters['period'] ?? '30') ?? 30,
    );
  }

  // Create a display name for the account
  String get displayName {
    if (issuer.isNotEmpty && accountName.isNotEmpty) {
      return '$issuer ($accountName)';
    } else if (issuer.isNotEmpty) {
      return issuer;
    } else {
      return accountName;
    }
  }

  // Copy with method for immutability
  Account copyWith({
    String? id,
    String? issuer,
    String? accountName,
    String? secret,
    int? digits,
    int? period,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      issuer: issuer ?? this.issuer,
      accountName: accountName ?? this.accountName,
      secret: secret ?? this.secret,
      digits: digits ?? this.digits,
      period: period ?? this.period,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Account{id: $id, issuer: $issuer, accountName: $accountName}';
  }
}
