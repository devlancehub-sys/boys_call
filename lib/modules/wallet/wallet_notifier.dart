import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/service_providers.dart';
import '../../core/constants/api_constants.dart';
import '../../core/messaging/app_messenger.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/parse_utils.dart';

class WalletState {
  const WalletState({
    this.balance = 0,
    this.transactions = const [],
    this.isLoading = false,
    this.isRecharging = false,
    this.selectedAmount = 500,
  });

  final double balance;
  final List<Map<String, dynamic>> transactions;
  final bool isLoading;
  final bool isRecharging;
  final int selectedAmount;

  WalletState copyWith({
    double? balance,
    List<Map<String, dynamic>>? transactions,
    bool? isLoading,
    bool? isRecharging,
    int? selectedAmount,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      isRecharging: isRecharging ?? this.isRecharging,
      selectedAmount: selectedAmount ?? this.selectedAmount,
    );
  }
}

final walletProvider = NotifierProvider<WalletNotifier, WalletState>(WalletNotifier.new);

class WalletNotifier extends Notifier<WalletState> {
  static const rechargeAmounts = [100, 200, 500, 1000, 2000, 0];

  late final ApiService _api;

  @override
  WalletState build() {
    _api = ref.read(apiServiceProvider);
    Future.microtask(loadAll);
    return const WalletState();
  }

  void selectAmount(int amount) {
    state = state.copyWith(selectedAmount: amount);
  }

  Future<void> paySelected() async {
    final amount = state.selectedAmount;
    if (amount <= 0) {
      AppMessenger.show('Select amount', 'Please choose a recharge amount');
      return;
    }
    await recharge(amount);
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    try {
      await loadBalance();
      await loadTransactions();
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadBalance() async {
    try {
      final res = await _api.get(ApiConstants.walletBalance);
      final data = JsonParse.toMap(res['data']);
      state = state.copyWith(balance: JsonParse.toDouble(data?['balance']));
    } catch (e) {
      AppMessenger.error(_api.errorMessage(e));
    }
  }

  Future<void> loadTransactions() async {
    try {
      final res = await _api.get(ApiConstants.walletTransactions, query: {'page': 1, 'limit': 30});
      state = state.copyWith(transactions: JsonParse.toMapList(res['data']));
    } catch (e) {
      AppMessenger.error(_api.errorMessage(e));
    }
  }

  Future<void> recharge(int amount) async {
    state = state.copyWith(isRecharging: true);
    try {
      final res = await _api.post(ApiConstants.walletRecharge, data: {'amount': amount});
      final data = JsonParse.toMap(res['data']);
      final orderId = data?['order_id']?.toString();
      if (orderId == null || orderId.isEmpty) {
        AppMessenger.error('Invalid payment response');
        return;
      }

      await _api.post(ApiConstants.walletRechargeConfirm, data: {
        'payment_id': orderId,
        'amount': amount,
      });

      await loadBalance();
      await loadTransactions();
      AppMessenger.success('₹$amount added to wallet');
    } catch (e) {
      AppMessenger.error(_api.errorMessage(e));
    } finally {
      state = state.copyWith(isRecharging: false);
    }
  }
}
