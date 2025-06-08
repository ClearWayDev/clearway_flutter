// router/app_router.dart
import 'package:flutter/material.dart';
import 'package:clearway/components/splashscreen.dart';
import 'package:clearway/components/welcomescreen.dart';
import 'package:clearway/components/signinscreen.dart';
import 'package:clearway/components/signupscreen.dart';
import 'package:clearway/components/resetpasswordscreen.dart';
import 'package:clearway/components/dashboards/blind_dashboard.dart';
import 'package:clearway/components/dashboards/guide_dashboard.dart';
import 'package:clearway/components/dashboards/blind/home_screen.dart';
import 'package:clearway/components/dashboards/blind/profile_screen.dart';
import 'package:clearway/components/dashboards/blind/video_screen.dart';
import 'package:clearway/components/dashboards/blind/ai_assistance_screen.dart';
import 'package:clearway/components/dashboards/guide/home_screen.dart';
import 'package:clearway/components/dashboards/guide/profile_screen.dart';
import 'package:clearway/components/dashboards/guide/gps_tracking_screen.dart';
import 'package:clearway/utils/route_guard.dart';
import 'package:clearway/models/user.dart';
import 'package:clearway/components/accessmediascreen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => _buildScreen(context, settings),
    );
  }

  static Widget _buildScreen(BuildContext context, RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return const SplashScreen();
      case '/welcome':
        return const WelcomeScreen();

      case '/signin':
        return RouteGuard(
          requireAuth: false,
          builder: (_) => const SigninScreen(),
        );
      case '/signup':
        return RouteGuard(
          requireAuth: false,
          builder: (_) => const SignupFlowScreen(),
        );
        case '/access-media':
        return RouteGuard(
          requireAuth: false,
          builder: (_) => const AccessMediaScreen(),
        );
      case '/reset-password':
        return const ResetPasswordScreen();

      case '/dashboard/blind/home':
        return RouteGuard(
          requireAuth: true,
          requiredUserType: UserType.blind,
          builder: (_) => BlindDashboard(child: const  BlindHomeScreen()),
        );
      case '/dashboard/blind/profile':
        return RouteGuard(
          requireAuth: true,
          requiredUserType: UserType.blind,
          builder: (_) => BlindDashboard(child: const BlindProfileScreen()),
        );
        case '/dashboard/blind/video-call':
        return RouteGuard(
          requireAuth: true,
          requiredUserType: UserType.blind,
          builder: (_) => BlindDashboard(child: const BlindVideoCallScreen()),
        );
        case '/dashboard/blind/ai-assistance':
        return RouteGuard(
          requireAuth: true,
          requiredUserType: UserType.blind,
          builder: (_) => BlindDashboard(child: const AiAssistanceScreen()),
        );
      case '/dashboard/guide/home':
        return RouteGuard(
          requireAuth: true,
          requiredUserType: UserType.volunteer,
          builder: (_) => GuideDashboard(child: const GuideHomeScreen()),
        );
      case '/dashboard/guide/profile':
        return RouteGuard(
          requireAuth: true,
          requiredUserType: UserType.volunteer,
          builder: (_) => GuideDashboard(child: const GuideProfileScreen()),
        );
        case '/dashboard/guide/gps':
        return RouteGuard(
          requireAuth: true,
          requiredUserType: UserType.volunteer,
          builder: (_) => GuideDashboard(child: const GpsTrackingScreen()),
        );
      default:
        return const SplashScreen();
    }
  }
}