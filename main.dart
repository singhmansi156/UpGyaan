import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_development_app/backend/templates/reset-password.dart';
import 'package:skill_development_app/screens/add_category_type_screen.dart';
import 'package:skill_development_app/screens/chatbot_screen.dart';
import 'package:skill_development_app/screens/course_detail_screen.dart';
import 'package:skill_development_app/screens/course_lessons_screen.dart';
import 'package:skill_development_app/screens/jobs_opportunities.dart';
import 'package:skill_development_app/screens/manage_course_content_screen%20.dart';
import 'package:skill_development_app/screens/my_course_screen.dart';
import 'package:skill_development_app/screens/splash_screen.dart';
import 'package:skill_development_app/screens/log_in.dart';
import 'package:skill_development_app/screens/sign_up.dart';
import 'package:skill_development_app/screens/forgot_password_screen.dart';
import 'package:skill_development_app/screens/user_dashboard.dart';
import 'package:skill_development_app/screens/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MyApp(
      initialRoute: '/',
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  MyApp({required this.initialRoute});

  
  late final GoRouter _router = GoRouter(
    initialLocation: initialRoute,
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        pageBuilder: (context, state) {
          final token = state.uri.queryParameters['token'];
          return MaterialPage(child: ResetPasswordScreen(token: token));
        },
      ),

      GoRoute(
        path: '/user-dashboard',
        name: 'user-dashboard',
        builder: (context, state) => UserDashboard(),
      ),
      GoRoute(
        path: '/admin-dashboard',
        name: 'admin-dashboard',
        builder: (context, state) => AdminDashboard(),
      ),
      GoRoute(
        path: '/course-detail/:courseName',
        builder: (context, state) {
          final courseName = state.pathParameters['courseName']!;
          return CourseDetailScreen(courseName: courseName);
        },
      ),
      GoRoute(
        path: '/my-courses',
        name: 'my-courses',
        builder: (context, state) {
          // 👇 Safely get the enrolled courses from state.extra
          final enrolledCourses = (state.extra as List<dynamic>?) ?? [];

          return MyCourseScreen(enrolledCourses: enrolledCourses);
        },
      ),
      GoRoute(
        path: '/course-lessons',
        name: 'course_lessons',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final courseId = extra['courseId'] ?? 0;
          final courseName = extra['courseName'] ?? '';
          final courseContent = extra['courseContent'] ?? [];

          return CourseLessonScreen(
            courseId: courseId,
            courseName: courseName,
            courseContent: courseContent,
          );
        },
      ),

      GoRoute(
        path: '/manage-course-content',
        name: 'manage-course-content',
        builder: (context, state) => ManageCourseContentScreen(),
      ),
      GoRoute(
        path: '/jobs',
        name: 'jobs',
        builder: (context, state) => JobOpportunitiesScreen(),
      ),
      GoRoute(
        path: '/chatbot-screen',
        name: 'chatbot-screen',
        builder: (context, state) => ChatbotScreen(),
      ),
      GoRoute(
        path: '/manage-category-type',
        name: 'managecategory-type',
        builder: (context, state) => AddCategoryTypeScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      routerConfig: _router, 
    );
  }
}
