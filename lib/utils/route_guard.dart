import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clearway/models/user.dart';
import 'package:clearway/providers/auth_provider.dart';
import 'package:clearway/providers/user_state.dart';

class RouteGuard extends ConsumerWidget {
  final WidgetBuilder builder;
  final bool requireAuth;
  final UserType? requiredUserType;

  const RouteGuard({
    super.key,
    required this.builder,
    required this.requireAuth,
    this.requiredUserType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userInfo = ref.watch(userProvider);

    return authState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text("Error loading user")),
      data: (fbUser) {
        if (requireAuth && fbUser == null) {
          _safeRedirect(context, '/signin');
          return const SizedBox.shrink();
        }

        if (requireAuth && fbUser != null) {
          if (userInfo == null) {
            return const Center(child: Text("User info not loaded"));
          }

          if (requiredUserType != null && userInfo.userType != requiredUserType) {
            final redirectRoute = userInfo.userType == UserType.blind
                ? '/dashboard/blind/home'
                : '/dashboard/guide/home';

            _safeRedirect(context, redirectRoute);
            return const SizedBox.shrink();
          }

          return builder(context);
        }

        return builder(context); 
      },
    );
  }

  void _safeRedirect(BuildContext context, String route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pushReplacementNamed(route);
      }
    });
  }
}
