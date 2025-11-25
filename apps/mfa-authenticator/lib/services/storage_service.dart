import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/account.dart';

class StorageService {
  static const String _accountsKey = 'totp_accounts';
  late FlutterSecureStorage _storage;

  Future<void> init() async {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
  }

  /// Save all accounts to secure storage
  Future<void> saveAccounts(List<Account> accounts) async {
    final accountsJson = accounts.map((a) => a.toJson()).toList();
    final jsonString = jsonEncode(accountsJson);
    await _storage.write(key: _accountsKey, value: jsonString);
  }

  /// Load all accounts from secure storage
  Future<List<Account>> loadAccounts() async {
    try {
      final jsonString = await _storage.read(key: _accountsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> accountsJson = jsonDecode(jsonString);
      return accountsJson.map((json) => Account.fromJson(json)).toList();
    } catch (e) {
      print('Error loading accounts: $e');
      return [];
    }
  }

  /// Add a new account
  Future<void> addAccount(Account account) async {
    final accounts = await loadAccounts();
    accounts.add(account);
    await saveAccounts(accounts);
  }

  /// Update an existing account
  Future<void> updateAccount(Account account) async {
    final accounts = await loadAccounts();
    final index = accounts.indexWhere((a) => a.id == account.id);

    if (index != -1) {
      accounts[index] = account;
      await saveAccounts(accounts);
    }
  }

  /// Delete an account
  Future<void> deleteAccount(String accountId) async {
    final accounts = await loadAccounts();
    accounts.removeWhere((a) => a.id == accountId);
    await saveAccounts(accounts);
  }

  /// Clear all accounts (use with caution)
  Future<void> clearAllAccounts() async {
    await _storage.delete(key: _accountsKey);
  }

  /// Check if an account with the same issuer and account name exists
  Future<bool> accountExists(String issuer, String accountName) async {
    final accounts = await loadAccounts();
    return accounts.any(
      (a) => a.issuer == issuer && a.accountName == accountName,
    );
  }
}
