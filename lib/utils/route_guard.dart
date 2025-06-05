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
        // Not logged in and route needs auth → redirect to /signin
        if (requireAuth && fbUser == null) {
          Future.microtask(() => Navigator.pushReplacementNamed(context, '/signin'));
          return const SizedBox.shrink();
        }

        //Logged in, and route requires auth
        if (requireAuth && fbUser != null) {
          //userProvider state not available → show error
          if (userInfo == null) {
            return const Center(child: Text("User info not loaded"));
          }

          // Wrong user type → redirect to correct dashboard
          if (requiredUserType != null && userInfo.userType != requiredUserType) {
            final redirectRoute = userInfo.userType == UserType.blind
                ? '/dashboard/blind/home'
                : '/dashboard/guide/home';

            Future.microtask(() => Navigator.pushReplacementNamed(context, redirectRoute));
            return const SizedBox.shrink();
          }

          // show the protected route
          return builder(context);
        }

        // Public route (no auth required)
        return builder(context);
      },
    );
  }
}
