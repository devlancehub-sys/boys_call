class ApiConstants {
  static const quickLogin = '/auth/quick-login';
  static const refresh = '/auth/refresh';
  static const logout = '/auth/logout';

  static const profile = '/users/profile';
  static const deviceSync = '/users/device';
  static const languages = '/users/languages';
  static const onlineStatus = '/users/online-status';

  static const hosts = '/hosts';
  static const hostsOnline = '/hosts/online';
  static const hostsFeatured = '/hosts/featured';

  static const callsInitiate = '/calls/initiate';
  static const callsHistory = '/calls/history';
  static const callToken = '/call/token';

  static const walletBalance = '/wallet/balance';
  static const walletTransactions = '/wallet/transactions';
  static const walletRecharge = '/wallet/recharge';
  static const walletRechargeConfirm = '/wallet/recharge/confirm';

  static const languagesList = '/languages';
  static const health = '/health';

  static String callAccept(int id) => '/calls/$id/accept';
  static String callReject(int id) => '/calls/$id/reject';
  static String callEnd(int id) => '/calls/$id/end';
  static String callJoinVoice(int id) => '/calls/$id/join-voice';
  static String hostById(int id) => '/hosts/$id';
}
