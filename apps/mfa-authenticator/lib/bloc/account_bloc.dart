import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/account.dart';
import '../services/storage_service.dart';

// Events
abstract class AccountEvent {}

class LoadAccounts extends AccountEvent {}

class AddAccount extends AccountEvent {
  final Account account;
  AddAccount(this.account);
}

class UpdateAccount extends AccountEvent {
  final Account account;
  UpdateAccount(this.account);
}

class DeleteAccount extends AccountEvent {
  final String accountId;
  DeleteAccount(this.accountId);
}

class RefreshCodes extends AccountEvent {}

// States
abstract class AccountState {}

class AccountsLoading extends AccountState {}

class AccountsLoaded extends AccountState {
  final List<Account> accounts;
  final DateTime lastUpdate;

  AccountsLoaded(this.accounts, {DateTime? lastUpdate})
      : lastUpdate = lastUpdate ?? DateTime.now();
}

class AccountsError extends AccountState {
  final String message;
  AccountsError(this.message);
}

// BLoC
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final StorageService storageService;

  AccountBloc({required this.storageService}) : super(AccountsLoading()) {
    on<LoadAccounts>(_onLoadAccounts);
    on<AddAccount>(_onAddAccount);
    on<UpdateAccount>(_onUpdateAccount);
    on<DeleteAccount>(_onDeleteAccount);
    on<RefreshCodes>(_onRefreshCodes);
  }

  Future<void> _onLoadAccounts(
    LoadAccounts event,
    Emitter<AccountState> emit,
  ) async {
    try {
      emit(AccountsLoading());
      final accounts = await storageService.loadAccounts();
      emit(AccountsLoaded(accounts));
    } catch (e) {
      emit(AccountsError('Failed to load accounts: $e'));
    }
  }

  Future<void> _onAddAccount(
    AddAccount event,
    Emitter<AccountState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is AccountsLoaded) {
        await storageService.addAccount(event.account);
        final accounts = await storageService.loadAccounts();
        emit(AccountsLoaded(accounts));
      }
    } catch (e) {
      emit(AccountsError('Failed to add account: $e'));
    }
  }

  Future<void> _onUpdateAccount(
    UpdateAccount event,
    Emitter<AccountState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is AccountsLoaded) {
        await storageService.updateAccount(event.account);
        final accounts = await storageService.loadAccounts();
        emit(AccountsLoaded(accounts));
      }
    } catch (e) {
      emit(AccountsError('Failed to update account: $e'));
    }
  }

  Future<void> _onDeleteAccount(
    DeleteAccount event,
    Emitter<AccountState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is AccountsLoaded) {
        await storageService.deleteAccount(event.accountId);
        final accounts = await storageService.loadAccounts();
        emit(AccountsLoaded(accounts));
      }
    } catch (e) {
      emit(AccountsError('Failed to delete account: $e'));
    }
  }

  Future<void> _onRefreshCodes(
    RefreshCodes event,
    Emitter<AccountState> emit,
  ) async {
    final currentState = state;
    if (currentState is AccountsLoaded) {
      // Re-emit the same state with updated timestamp to trigger UI refresh
      emit(AccountsLoaded(currentState.accounts));
    }
  }
}
