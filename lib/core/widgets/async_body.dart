import 'package:flutter/material.dart';

import 'app_loading_indicator.dart';

/// Shows a loading indicator while loading.
class AsyncBody extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.isLoading,
    required this.builder,
    this.loadingWhen,
  });

  final bool isLoading;
  final Widget Function() builder;
  final bool Function()? loadingWhen;

  @override
  Widget build(BuildContext context) {
    final loading = loadingWhen != null ? loadingWhen!() : isLoading;
    if (loading) return const AppLoadingIndicator.center();
    return builder();
  }
}
